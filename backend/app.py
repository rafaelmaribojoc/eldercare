from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import os
import shutil
from dotenv import load_dotenv
from supabase import create_client, Client
from workflow_engine import WorkflowEngine
from document_service import DocumentService
from docxtpl import DocxTemplate
try:
    from docx2pdf import convert
    import pythoncom
except ImportError:
    convert = None
    pythoncom = None
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Role & Field Mapping Helpers ---

def specialize_role(role, unit):
    """Maps generic roles + units to specialized workflow roles."""
    if role in ['head', 'staff'] and unit:
        unit_lower = unit.lower().replace(' service', '').strip()
        if unit_lower == 'home life':
            unit_prefix = 'homelife'
        elif unit_lower == 'psychological':
            unit_prefix = 'psych'
        else:
            unit_prefix = unit_lower
        return f"{unit_prefix}_{role.lower()}"
    return role

PARALLEL_FIELD_MAPPING = {
    'incident_report': {
        'social_head': 'received_social',
        'medical_head': 'received_medical',
        'psych_head': 'received_psych',
    },
    'hl_incident_report': {
        'social_head': 'received_social',
        'medical_head': 'received_medical',
        'psych_head': 'received_psych',
    },
    'after_care_plan': {
        'homelife_head': 'confirmed_homelife',
        'medical_head': 'confirmed_medical',
        'psych_head': 'confirmed_psych',
    },
    'ss_after_care_plan': {
        'homelife_head': 'confirmed_homelife',
        'medical_head': 'confirmed_medical',
        'psych_head': 'confirmed_psych',
    }
}

# --- End Helpers ---

load_dotenv()

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# Supabase Setup
url: str = os.environ.get("SUPABASE_URL", "")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

supabase: Client = None
if url and key:
    try:
        supabase = create_client(url, key)
        print(f" * Supabase configured with URL: {url}")
    except Exception as e:
        print(f" * Failed to initialize Supabase: {e}")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "rcfms-backend",
        "supabase_connected": supabase is not None
    })

@app.route('/api/generate-document', methods=['POST'])
def generate_document():
    """
    Generate a document from a template.
    Expects JSON: { 
        "template_type": "requirements_checklist", 
        "service_unit": "Social Service", 
        "data": { ... },
        "output_format": "pdf" | "docx"  (optional, default "pdf")
    }
    """
    try:
        req_data = request.json
        template_type = req_data.get('template_type')
        service_unit = req_data.get('service_unit')
        data = req_data.get('data')
        output_format = req_data.get('output_format', 'pdf').lower()

        if not template_type or not service_unit:
            return jsonify({"error": "Missing template_type or service_unit"}), 400

        print(f" * Generating document: {template_type} ({service_unit}) format={output_format}")
        
        # Call the DocumentService
        file_path = DocumentService.generate(template_type, service_unit, data, output_format=output_format)
        
        if not file_path or not os.path.exists(file_path):
             return jsonify({"error": "Failed to generate document file"}), 500

        # Return the file
        filename = os.path.basename(file_path)
        
        # Determine mimetype based on extension
        mimetype = 'application/pdf' if filename.lower().endswith('.pdf') else 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'

        return send_file(
            file_path, 
            as_attachment=True, 
            download_name=filename,
            mimetype=mimetype
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/approve-form', methods=['POST'])
def approve_form():
    """
    Approve a form using Service Role (bypasses RLS).
    Expects JSON: { "form_id": "...", "user_id": "..." }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json
    form_id = data.get('form_id')
    user_id = data.get('user_id')

    if not form_id or not user_id:
        return jsonify({"error": "Missing form_id or user_id"}), 400

    try:
        # 1. Fetch current form details + User Role
        user_profile = supabase.table('profiles').select('role, unit').eq('id', user_id).execute()
        if not user_profile.data:
            return jsonify({"error": "Approver profile not found"}), 404
        
        approver_role = user_profile.data[0]['role']
        approver_unit = user_profile.data[0].get('unit')
        
        # Specialize the role for internal logic
        specialized_approver_role = specialize_role(approver_role, approver_unit)

        current_form = supabase.table('form_submissions').select('template_id, template_type, status, unit, resident_id, form_data').eq('id', form_id).execute()
        if not current_form.data:
             return jsonify({"error": "Form submission not found"}), 404
        
        form_data = current_form.data[0]
        template_id = form_data.get('template_id')
        template_type = form_data.get('template_type')
        current_status = form_data.get('status')
        
        # 2. Determine Next State via Engine
        # IMPORTANT: Use template_id for workflow lookups since the registry keys
        # match template IDs (e.g. 'ss_admission_slip'), not template_type values.
        workflow_key = template_id or template_type
        print(f" * Workflow Lookup: key='{workflow_key}', status='{current_status}', role='{approver_role}' (Specialized: {specialized_approver_role})")
        
        # Use specialized role for lookup
        transition = WorkflowEngine.get_next_state(workflow_key, current_status, specialized_approver_role)

        if not transition:
            error_msg = f"No valid workflow transition for key '{workflow_key}', status '{current_status}' by role '{specialized_approver_role}'"
            print(f" * Workflow ERROR: {error_msg}")
            return jsonify({"error": error_msg}), 403
            
        next_status = transition['next_status']
        print(f" * Workflow SUCCESS: '{current_status}' -> '{next_status}'")
        notify_roles = transition['notify_roles']
        notify_message = transition['notify_message']

        # 2b. Handle Parallel (Roundtable) workflows
        # For P4 forms at 'pending_multi_approval', we need ALL parallel roles to sign
        # before advancing. Record this approval but only advance if all have signed.
        workflow_def = WorkflowEngine.get_workflow(workflow_key)
        is_parallel = workflow_def.get('parallel', False) if workflow_def else False
        parallel_roles = workflow_def.get('parallel_roles', []) if workflow_def else []
        
        if is_parallel and current_status == 'pending_multi_approval' and parallel_roles:
            # Record this user's approval in form_signatures
            # Check which roles have already approved (via form_signatures)
            existing_sigs = supabase.table('form_signatures').select('signer_id').eq('form_submission_id', form_id).execute()
            existing_signer_ids = set(s['signer_id'] for s in existing_sigs.data) if existing_sigs.data else set()
            
            # Add current user
            existing_signer_ids.add(user_id)
            
            # Look up the roles of all signers so far and SPECIALIZE them
            if existing_signer_ids:
                signer_profiles = supabase.table('profiles').select('id, role, unit').in_('id', list(existing_signer_ids)).execute()
                signed_roles = set(specialize_role(p['role'], p.get('unit')) for p in signer_profiles.data) if signer_profiles.data else set()
            else:
                signed_roles = set()
            
            # Check if all required parallel roles have signed
            all_signed = all(role in signed_roles for role in parallel_roles)
            
            if not all_signed:
                # Stay at same status — don't advance yet
                # Just record the signature (done by Flutter side) and notify
                next_status = current_status  # Stay at pending_multi_approval
                remaining = [r for r in parallel_roles if r not in signed_roles]
                notify_message = f"Approval recorded. Still waiting for: {', '.join(str(r) for r in remaining)}"
                notify_roles = remaining  # Notify remaining roles
                print(f" * Parallel workflow: {specialized_approver_role} signed. Remaining: {remaining}")
        
        # 3. Perform Update
        update_data = {
            'status': next_status,
            'reviewed_by': user_id,
            'reviewed_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }

        response = supabase.table('form_submissions').update(update_data).eq('id', form_id).execute()
        
        if len(response.data) == 0:
             return jsonify({"error": "Form update failed"}), 500

        updated_form = response.data[0]

        # 3b. Mark form_approvals status.
        # If not parallel, and the form has advanced to a new status (or fully approved),
        # clear ALL pending approvals for this form to prevent stale entries in others' lists.
        try:
            if not is_parallel:
                supabase.table('form_approvals').update({
                    'status': 'approved',
                    'action_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat()
                }).eq('form_submission_id', form_id).eq('status', 'pending').execute()
                print(f" * Cleared ALL pending form_approvals for form {form_id} (non-parallel advancement)")
            else:
                # Parallel workflow: only clear the current user's approval
                supabase.table('form_approvals').update({
                    'status': 'approved',
                    'action_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat()
                }).eq('form_submission_id', form_id).eq('recipient_id', user_id).eq('status', 'pending').execute()
                print(f" * Updated form_approvals to 'approved' for user {user_id} on form {form_id} (parallel)")
        except Exception as ae:
            print(f" * WARNING: Failed to update form_approvals: {ae}")
        
        # 4. Create Timeline Entry
        try:
            timeline_data = {
                'resident_id': form_data.get('resident_id'),
                'entry_type': 'form',
                'form_submission_id': form_id,
                'form_template_type': template_type,
                'unit': form_data.get('unit'),
                'title': f"Form Status Updated", 
                'description': f"Changed from {current_status} to {next_status}",
                'created_by': user_id,
                'created_at': datetime.now().isoformat()
            }
            supabase.table('timeline_entries').insert(timeline_data).execute()

            # 5. Send Notifications AND create form_approvals row for next step recipient
            if notify_roles and next_status != 'approved':
                recipients = []
                for role in notify_roles:
                    users = supabase.table('profiles').select('id, full_name, role').eq('role', role).eq('is_active', True).execute()
                    if users.data:
                        recipients.extend(users.data)
                
                # Also check generic 'head' role users whose unit matches the NOTIFY ROLE's unit.
                # e.g. notify_role='medical_head' → match head users with unit='medical'
                # e.g. notify_role='social_head' → match head users with unit='social'
                # Also fall back to matching the form's own unit for roles like 'homelife_head'
                ROLE_UNIT_MAP = {
                    'medical_head': 'medical',
                    'social_head': 'social',
                    'psych_head': 'psych',
                    'homelife_head': 'homelife',
                    'nutrition_head': 'nutrition',
                }
                target_units = set()
                for role in notify_roles:
                    if role in ROLE_UNIT_MAP:
                        target_units.add(ROLE_UNIT_MAP[role])
                
                # If no specific unit mapping found, fall back to the form's unit
                if not target_units:
                    form_unit = form_data.get('unit', '')
                    if form_unit:
                        target_units.add(form_unit)
                
                if target_units:
                    head_users = supabase.table('profiles').select('id, full_name, role, unit').eq('role', 'head').eq('is_active', True).execute()
                    if head_users.data:
                        for hu in head_users.data:
                            if hu.get('unit') in target_units:
                                recipients.append(hu)
                
                # Also check 'staff' role users for roles like 'social_worker', 'homelife_staff'
                STAFF_ROLE_UNIT_MAP = {
                    'social_worker': 'social',
                    'homelife_staff': 'homelife',
                }
                for role in notify_roles:
                    if role in STAFF_ROLE_UNIT_MAP:
                        staff_unit = STAFF_ROLE_UNIT_MAP[role]
                        staff_users = supabase.table('profiles').select('id, full_name, role, unit').eq('role', 'staff').eq('unit', staff_unit).eq('is_active', True).execute()
                        if staff_users.data:
                            recipients.extend(staff_users.data)
                
                # SPECIAL CASE: Out on Pass dynamic routing
                # Try to route specifically to the selected center_doctor or social_worker
                if workflow_key in ['hl_out_on_pass', 'out_on_pass']:
                    specific_name = None
                    if next_status == 'pending_doctor_review':
                        specific_name = form_data.get('form_data', {}).get('center_doctor')
                    elif next_status == 'pending_social_worker':
                        specific_name = form_data.get('form_data', {}).get('social_worker')
                        
                    if specific_name:
                        # Find the specifically selected user by name (case-insensitive because frontend upper-cases it)
                        specific_user = supabase.table('profiles').select('id, full_name, role, unit').ilike('full_name', specific_name).eq('is_active', True).execute()
                        if specific_user.data:
                            # Override the recipients list with just this person
                            print(f" * Out on Pass: Routing specifically to selected user '{specific_name}' for step '{next_status}'")
                            recipients = specific_user.data
                        else:
                            print(f" * Out on Pass: Selected user '{specific_name}' not found or inactive. Falling back to default role routing.")
                
                unique_recipients = {}
                for u in recipients:
                    unique_recipients[u['id']] = u
                
                # Determine the signature_field for the NEXT step from the workflow config
                next_sig_field = 'noted_by'  # default
                workflow_def = WorkflowEngine.get_workflow(workflow_key)
                if workflow_def:
                    next_step_config = workflow_def.get('transitions', {}).get(next_status)
                    if next_step_config:
                        next_sig_field = next_step_config.get('signature_field', 'noted_by')
                print(f" * Next step signature_field: '{next_sig_field}' for status '{next_status}'")

                # Create form_approvals rows for next step recipients
                # This ensures they see the form in their pending list
                approver_name = ''
                try:
                    approver_profile = supabase.table('profiles').select('full_name').eq('id', user_id).maybe_single().execute()
                    if approver_profile.data:
                        approver_name = approver_profile.data.get('full_name', '')
                except:
                    pass

                # Form-specific role-to-field mapping for parallel signatures
                field_mapping = PARALLEL_FIELD_MAPPING.get(workflow_key, {})

                # Only create form_approvals if the status actually changed.
                # If we are staying in the same status (e.g., parallel workflow waiting for others),
                # the remaining roles ALREADY have a pending form_approvals row!
                if next_status != current_status:
                    for uid, udata in unique_recipients.items():
                        if uid == user_id:
                            continue  # Don't create approval for the person who just approved
                        
                        # Specialize the recipient's role to find their specific signature field
                        spec_role = specialize_role(udata.get('role'), udata.get('unit'))
                        target_sig_field = field_mapping.get(spec_role, next_sig_field)
                        
                        try:
                            supabase.table('form_approvals').insert({
                                'form_submission_id': form_id,
                                'sender_id': user_id,
                                'sender_name': approver_name,
                                'recipient_id': uid,
                                'recipient_name': udata.get('full_name', ''),
                                'signature_field_name': target_sig_field,
                                'status': 'pending',
                                'created_at': datetime.now().isoformat()
                            }).execute()
                            print(f" * Created form_approvals row for next step: {uid} ({udata.get('full_name', '')}) sig_field='{target_sig_field}' (from role: {spec_role}) on form {form_id}")
                        except Exception as ae:
                            print(f" * WARNING: Failed to create approval row for {uid}: {ae}")
                
                # Send notifications
                notifications = []
                for uid in unique_recipients:
                    if uid == user_id:
                        continue
                    notifications.append({
                        'user_id': uid,
                        'type': 'approval_request',
                        'title': 'Form Workflow Update',
                        'message': notify_message or f"Form is now {next_status}",
                        'form_submission_id': form_id,
                        'is_read': False,
                        'created_at': datetime.now().isoformat()
                    })
                
                if notifications:
                    supabase.table('notifications').insert(notifications).execute()
            
            elif notify_roles and next_status == 'approved':
                # Form is fully approved — just send notifications, no new approval rows
                recipients = []
                for role in notify_roles:
                    users = supabase.table('profiles').select('id').eq('role', role).execute()
                    if users.data:
                        recipients.extend(users.data)
                
                # Also resolve head/staff roles the same way as above
                ROLE_UNIT_MAP_APPROVED = {
                    'medical_head': 'medical', 'social_head': 'social',
                    'psych_head': 'psych', 'homelife_head': 'homelife', 'nutrition_head': 'nutrition',
                }
                STAFF_ROLE_UNIT_MAP_APPROVED = {
                    'social_worker': 'social', 'homelife_staff': 'homelife',
                }
                approved_target_units = set()
                for role in notify_roles:
                    if role in ROLE_UNIT_MAP_APPROVED:
                        approved_target_units.add(ROLE_UNIT_MAP_APPROVED[role])
                if approved_target_units:
                    head_users_approved = supabase.table('profiles').select('id, unit').eq('role', 'head').eq('is_active', True).execute()
                    if head_users_approved.data:
                        for hu in head_users_approved.data:
                            if hu.get('unit') in approved_target_units:
                                recipients.append(hu)
                for role in notify_roles:
                    if role in STAFF_ROLE_UNIT_MAP_APPROVED:
                        staff_unit = STAFF_ROLE_UNIT_MAP_APPROVED[role]
                        staff_users = supabase.table('profiles').select('id').eq('role', 'staff').eq('unit', staff_unit).eq('is_active', True).execute()
                        if staff_users.data:
                            recipients.extend(staff_users.data)
                
                unique_ids = set(u['id'] for u in recipients)
                
                notifications = []
                for uid in unique_ids:
                    notifications.append({
                        'user_id': uid,
                        'type': 'approval_request',
                        'title': 'Form Approved',
                        'message': notify_message or f"Form has been approved.",
                        'form_submission_id': form_id,
                        'is_read': False,
                        'created_at': datetime.now().isoformat()
                    })
                
                if notifications:
                    supabase.table('notifications').insert(notifications).execute()

        except Exception as e:
            print(f"Failed to create timeline/notifications/approvals: {e}")

        return jsonify({"success": True, "data": updated_form}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/return-form', methods=['POST'])
def return_form():
    """
    Return a form using Service Role (bypasses RLS).
    Expects JSON: { "form_id": "...", "user_id": "...", "comment": "..." }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json
    form_id = data.get('form_id')
    user_id = data.get('user_id')
    comment = data.get('comment')

    if not form_id or not user_id or not comment:
        return jsonify({"error": "Missing form_id, user_id, or comment"}), 400

    try:
        # First, query current form to know its status and template
        current_form = supabase.table('form_submissions').select('status', 'template_id', 'template_type', 'unit', 'resident_id', 'submitted_by', 'form_data').eq('id', form_id).execute()
        if not current_form.data:
            return jsonify({"error": "Form not found"}), 404
            
        form_data = current_form.data[0]
        current_status = form_data.get('status')
        workflow_key = form_data.get('template_id') or form_data.get('template_type')
        
        # Check if the form is in a parallel step
        workflow_def = WorkflowEngine.get_workflow(workflow_key)
        is_parallel = workflow_def.get('parallel', False) if workflow_def else False
        parallel_roles = workflow_def.get('parallel_roles', []) if workflow_def else []
        
        update_data = {
            'status': 'returned', # AppConstants.statusReturned
            'reviewed_by': user_id,
            'reviewed_at': datetime.now().isoformat(),
            'review_comment': comment,
            'updated_at': datetime.now().isoformat()
        }
        
        response = supabase.table('form_submissions').update(update_data).eq('id', form_id).execute()
        
        if len(response.data) == 0:
             return jsonify({"error": "Form update failed (0 rows)"}), 500

        updated_form = response.data[0]

        # Handle clearing approvals and signatures
        try:
            if is_parallel and current_status == 'pending_multi_approval' and parallel_roles:
                # 1. Update BOTH pending AND approved approvals for the current form to 'returned'
                # so that people who already signed it see it as returned/voided for this round.
                supabase.table('form_approvals').update({
                    'status': 'returned',
                    'action_at': datetime.now().isoformat(),
                    'comment': f"Returned by another unit head: {comment}",
                    'updated_at': datetime.now().isoformat()
                }).eq('form_submission_id', form_id).in_('status', ['pending', 'approved']).execute()
                
                # 2. Delete the signatures of the parallel roles so they have to re-sign.
                # We identify which signatures to delete based on the PARALLEL_FIELD_MAPPING.
                field_mapping = PARALLEL_FIELD_MAPPING.get(workflow_key, {})
                fields_to_clear = list(field_mapping.values())
                
                if fields_to_clear:
                    supabase.table('form_signatures').delete().eq('form_submission_id', form_id).in_('field_name', fields_to_clear).execute()
                    print(f" * Cleared parallel signatures {fields_to_clear} for returned form {form_id}")
                    
                    # Also strip them from form_data JSON so they don't appear in UI/PDFs anymore
                    current_form_data = form_data.get('form_data', {})
                    if current_form_data and isinstance(current_form_data, dict):
                        modified_data = False
                        for field in fields_to_clear:
                            if field in current_form_data:
                                del current_form_data[field]
                                modified_data = True
                        
                        if modified_data:
                            supabase.table('form_submissions').update({'form_data': current_form_data}).eq('id', form_id).execute()
                            print(f" * Stripped old parallel signatures from form_data JSON")

            else:
                # Normal sequential workflow: just mark all pending approvals as returned
                supabase.table('form_approvals').update({
                    'status': 'returned',
                    'action_at': datetime.now().isoformat(),
                    'comment': comment,
                    'updated_at': datetime.now().isoformat()
                }).eq('form_submission_id', form_id).eq('status', 'pending').execute()
                
            print(f" * Updated form_approvals on return for form {form_id}")
        except Exception as ae:
            print(f" * WARNING: Failed to update form_approvals/signatures on return: {ae}")

        # Create Timeline Entry
        try:
            timeline_data = {
                'resident_id': updated_form.get('resident_id'),
                'entry_type': 'form',
                'form_submission_id': form_id,
                'form_template_type': updated_form.get('template_type'),
                'unit': updated_form.get('unit'),
                'title': f"Form Returned",
                'description': f"Returned for revision: {comment}",
                'created_by': user_id,
                'created_at': datetime.now().isoformat()
            }
            supabase.table('timeline_entries').insert(timeline_data).execute()
        except Exception as e:
            print(f"Failed to create timeline entry: {e}")

        # Notify the Initiator that the form has been returned
        try:
            initiator_id = updated_form.get('submitted_by')
            if initiator_id:
                notification_data = {
                    'user_id': initiator_id,
                    'type': 'form_returned',
                    'title': 'Form Returned',
                    'message': f"Your {updated_form.get('template_type', 'form')} has been returned for revision.",
                    'form_submission_id': form_id,
                    'is_read': False,
                    'created_at': datetime.now().isoformat()
                }
                supabase.table('notifications').insert(notification_data).execute()
        except Exception as e:
            print(f"Failed to create return notification: {e}")

        return jsonify({"success": True, "data": updated_form}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/upload-signed-form', methods=['POST'])
def upload_signed_form():
    """
    Attach an uploaded signed file to an existing form submission.
    This updates the SAME record (no duplicate insert), and moves it to approved.

    Expects JSON:
      {
        "form_id": "...",
        "user_id": "...",
        "signed_image_url": "https://...",
        "file_type": "image" | "pdf" (optional, defaults to "image")
      }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    form_id = data.get('form_id')
    user_id = data.get('user_id')
    signed_image_url = data.get('signed_image_url')
    file_type = data.get('file_type', 'image')

    if not form_id or not user_id or not signed_image_url:
        return jsonify({"error": "Missing form_id, user_id, or signed_image_url"}), 400

    try:
        form_res = supabase.table('form_submissions').select(
            'id, status, submitted_by, unit, resident_id, template_type, form_data'
        ).eq('id', form_id).execute()

        if not form_res.data:
            return jsonify({"error": "Form submission not found"}), 404

        form_row = form_res.data[0]
        status = form_row.get('status')

        for_signing_statuses = {
            'submitted',
            'pending_review',
            'pending_medical_review',
            'pending_final_approval',
            'pending_supervisor',
            'pending_multi_approval',
            'pending_head_approval',
            'pending_doctor_review',
            'pending_social_worker',
        }

        if status not in for_signing_statuses:
            return jsonify({
                "error": "Only forms in 'For Signing' can accept uploaded signed files."
            }), 403

        # Authorization:
        # - original submitter can upload signed file for their own For Signing form
        # - current pending recipient can upload
        # - privileged users (super_admin/center_head/unit head of same unit) can upload
        is_submitter = form_row.get('submitted_by') == user_id

        approval_res = supabase.table('form_approvals').select(
            'id'
        ).eq('form_submission_id', form_id).eq('recipient_id', user_id).eq('status', 'pending').limit(1).execute()
        is_pending_recipient = bool(approval_res.data)

        role = None
        user_unit = None
        try:
            profile_res = supabase.table('profiles').select('role, unit').eq('id', user_id).maybe_single().execute()
            if profile_res.data:
                role = profile_res.data.get('role')
                user_unit = profile_res.data.get('unit')
        except Exception:
            pass

        form_unit = form_row.get('unit')
        is_privileged = (
            role in ('super_admin', 'center_head')
            or ((role == 'head' or (isinstance(role, str) and role.endswith('_head'))) and user_unit == form_unit)
        )

        if not (is_submitter or is_pending_recipient or is_privileged):
            return jsonify({"error": "Not authorized to upload signed file for this form"}), 403

        existing_form_data = form_row.get('form_data')
        if not isinstance(existing_form_data, dict):
            existing_form_data = {}

        merged_form_data = {
            **existing_form_data,
            'signed_image_url': signed_image_url,
            'uploaded_at': datetime.now().isoformat(),
            'is_uploaded_record': True,
            'file_type': file_type,
        }

        update_res = supabase.table('form_submissions').update({
            'form_data': merged_form_data,
            'status': 'approved',
            'reviewed_by': user_id,
            'reviewed_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }).eq('id', form_id).execute()

        if not update_res.data:
            return jsonify({"error": "Failed to update form with uploaded signed file"}), 500

        updated_form = update_res.data[0]

        # Clear stale pending approvals now that the form is finalized.
        try:
            supabase.table('form_approvals').update({
                'status': 'approved',
                'action_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat(),
                'comment': 'Closed via uploaded signed form',
            }).eq('form_submission_id', form_id).eq('status', 'pending').execute()
        except Exception as ae:
            print(f" * WARNING: Failed to close pending form_approvals for upload-signed-form: {ae}")

        # Best-effort timeline entry for audit trail.
        try:
            timeline_data = {
                'resident_id': form_row.get('resident_id'),
                'entry_type': 'form',
                'form_submission_id': form_id,
                'form_template_type': form_row.get('template_type'),
                'unit': form_row.get('unit'),
                'title': 'Signed Form Uploaded',
                'description': 'Signed file uploaded and linked to existing For Signing form.',
                'created_by': user_id,
                'created_at': datetime.now().isoformat(),
            }
            supabase.table('timeline_entries').insert(timeline_data).execute()
        except Exception as te:
            print(f" * WARNING: Failed to create timeline entry for upload-signed-form: {te}")

        return jsonify({"success": True, "data": updated_form}), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/update-form-data', methods=['POST'])
def update_form_data():
    """
    Update form_data for a form using Service Role (bypasses RLS).
    Expects JSON: { "form_id": "...", "user_id": "...", "form_data": { ... } }
    Only allows update if the user is either:
    - the submitter updating a draft/returned form, OR
    - the current pending approval recipient for this form (form_approvals).
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    form_id = data.get('form_id')
    user_id = data.get('user_id')
    new_form_data = data.get('form_data')

    if not form_id or not user_id or new_form_data is None:
        return jsonify({"error": "Missing form_id, user_id, or form_data"}), 400

    if not isinstance(new_form_data, dict):
        return jsonify({"error": "form_data must be an object"}), 400

    try:

        form_res = supabase.table('form_submissions').select(
            'id, status, submitted_by, form_data'
        ).eq('id', form_id).execute()
        if not form_res.data:
            return jsonify({"error": "Form submission not found"}), 404

        form_row = form_res.data[0]
        status = form_row.get('status')
        submitted_by = form_row.get('submitted_by')

        # Authorization: submitter can update draft/returned/submitted(for-signing) forms
        is_submitter_edit = (submitted_by == user_id) and (status in ('draft', 'returned', 'submitted'))

        # Authorization: recipient can update when they have a pending approval row
        approval_res = supabase.table('form_approvals').select(
            'id'
        ).eq('form_submission_id', form_id).eq('recipient_id', user_id).eq('status', 'pending').limit(1).execute()
        is_pending_recipient = bool(approval_res.data)

        if not is_submitter_edit and not is_pending_recipient:
            return jsonify({"error": "Not authorized to update this form"}), 403

        update_payload = {
            'form_data': new_form_data,
            'updated_at': datetime.now().isoformat(),
        }
        # Allow optional status update (e.g. re-saving a 'for signing' form)
        new_status = data.get('status')
        if new_status and is_submitter_edit:
            update_payload['status'] = new_status

        update_res = supabase.table('form_submissions').update(
            update_payload
        ).eq('id', form_id).execute()

        if not update_res.data:
            return jsonify({"error": "Form update failed"}), 500

        return jsonify({"success": True, "data": update_res.data[0]}), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/delete-form', methods=['POST'])
def delete_form():
    """
    Delete a form and its related records using Service Role (bypasses RLS).
    Expects JSON: { "form_id": "...", "user_id": "..." }
    Rules:
    - If archived: Only Social Service Unit Head can permanently delete.
    - If unarchived: Only the original submitter can delete, and only if draft or returned.
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    form_id = data.get('form_id')
    user_id = data.get('user_id')

    if not form_id or not user_id:
        return jsonify({"error": "Missing form_id or user_id"}), 400

    try:
        # Get user details for authorization and logging
        user_res = supabase.table('profiles').select('full_name, role, unit').eq('id', user_id).execute()
        if not user_res.data:
            return jsonify({"error": "User not found"}), 404

        user_role = user_res.data[0].get('role')
        user_unit = user_res.data[0].get('unit')
        user_name = user_res.data[0].get('full_name', 'Unknown')

        # Verify form exists
        form_result = supabase.table('form_submissions').select('id, status, submitted_by, is_archived, resident_id, template_type').eq('id', form_id).execute()
        if not form_result.data:
            return jsonify({"error": "Form not found"}), 404

        form = form_result.data[0]
        is_archived = form.get('is_archived', False)

        if is_archived:
            # AUTHORIZATION: Social Service Unit Head only
            is_social_head = user_role in ('head', 'social_head') and user_unit == 'social'
            if not is_social_head:
                return jsonify({"error": "Not authorized. Only the Social Service Unit Head can permanently delete archived forms."}), 403
        else:
            # Unarchived form deletion rules
            if form.get('submitted_by') != user_id:
                return jsonify({"error": "Only the submitter can delete this form"}), 403

            if form.get('status') not in ('draft', 'returned'):
                return jsonify({"error": f"Cannot delete form with status '{form.get('status')}'. Only draft or returned forms can be deleted."}), 403

        # Delete related records first (foreign key constraints)
        try:
            supabase.table('form_approvals').delete().eq('form_submission_id', form_id).execute()
        except: pass
        try:
            supabase.table('form_signatures').delete().eq('form_submission_id', form_id).execute()
        except: pass
        try:
            supabase.table('notifications').delete().eq('form_submission_id', form_id).execute()
        except: pass
        try:
            # Delete old timeline entries related to this form BEFORE deleting the form
            supabase.table('timeline_entries').delete().eq('form_submission_id', form_id).execute()
        except: pass

        # Delete the form submission itself
        supabase.table('form_submissions').delete().eq('id', form_id).execute()
        print(f" * Deleted form {form_id} by user {user_id}")

        # If it was an archived form being permanently deleted, leave an audit trail
        if is_archived:
            try:
                supabase.table('timeline_entries').insert({
                    'resident_id': form.get('resident_id'),
                    'entry_type': 'form',
                    # No form_submission_id because the form no longer exists
                    'title': 'Form Permanently Deleted',
                    'description': f"Form '{form.get('template_type')}' permanently deleted by {user_name}",
                    'created_by': user_id,
                    'created_at': datetime.now().isoformat()
                }).execute()
            except Exception as te:
                print(f" * WARNING: Failed to create delete timeline entry: {te}")

        return jsonify({"success": True}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/archive-form', methods=['POST'])
def archive_form():
    """
    Archive (soft-delete) a form using Service Role.
    Expects JSON: { "form_id": "...", "user_id": "...", "user_role": "...", "user_unit": "..." }
    Permission rules:
    - Social Service Head: can archive forms from ANY unit (case folder custodian)
    - Other Unit Heads: can archive forms from their OWN unit only
    - Center Head / Super Admin / Staff: cannot archive
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    form_id = data.get('form_id')
    user_id = data.get('user_id')

    if not form_id or not user_id:
        return jsonify({"error": "Missing form_id or user_id"}), 400

    try:
        user_profile = supabase.table('profiles').select('role, unit, full_name').eq('id', user_id).execute()
        if not user_profile.data:
            return jsonify({"error": "User profile not found"}), 404

        user_role = user_profile.data[0]['role']
        user_unit = user_profile.data[0].get('unit')
        user_name = user_profile.data[0].get('full_name', 'Unknown')

        form_result = supabase.table('form_submissions').select('id, unit, status, resident_id, template_type, is_archived').eq('id', form_id).execute()
        if not form_result.data:
            return jsonify({"error": "Form not found"}), 404

        form = form_result.data[0]
        if form.get('is_archived'):
            return jsonify({"error": "Form is already archived"}), 400

        form_unit = form.get('unit')

        is_social_head = user_role in ('head', 'social_head') and user_unit == 'social'
        is_own_unit_head = user_role in ('head',) and user_unit == form_unit and user_role != 'social_head'
        is_specialized_head = user_role.endswith('_head') and user_unit == form_unit

        if not (is_social_head or is_own_unit_head or is_specialized_head):
            return jsonify({"error": "Not authorized to archive this form"}), 403

        # Cancel any pending approvals
        pending_statuses = ['pending_review', 'pending_supervisor', 'pending_multi_approval',
                           'pending_head_approval', 'pending_doctor_review', 'pending_social_worker',
                           'pending_final_approval', 'pending_medical_review']
        if form.get('status') in pending_statuses:
            try:
                supabase.table('form_approvals').update({
                    'status': 'cancelled',
                    'action_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat()
                }).eq('form_submission_id', form_id).eq('status', 'pending').execute()
            except Exception as ae:
                print(f" * WARNING: Failed to cancel pending approvals: {ae}")

            try:
                supabase.table('notifications').update({
                    'is_read': True
                }).eq('form_submission_id', form_id).eq('is_read', False).execute()
            except Exception as ne:
                print(f" * WARNING: Failed to clear notifications: {ne}")

        supabase.table('form_submissions').update({
            'is_archived': True,
            'archived_by': user_id,
            'archived_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }).eq('id', form_id).execute()

        try:
            supabase.table('timeline_entries').insert({
                'resident_id': form.get('resident_id'),
                'entry_type': 'form',
                'form_submission_id': form_id,
                'form_template_type': form.get('template_type'),
                'unit': form_unit,
                'title': 'Form Archived',
                'description': f"Archived by {user_name}",
                'created_by': user_id,
                'created_at': datetime.now().isoformat()
            }).execute()
        except Exception as te:
            print(f" * WARNING: Failed to create archive timeline entry: {te}")

        print(f" * Form {form_id} archived by {user_name} ({user_role}/{user_unit})")
        return jsonify({"success": True}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/api/restore-form', methods=['POST'])
def restore_form():
    """
    Restore an archived form using Service Role.
    Expects JSON: { "form_id": "...", "user_id": "..." }
    Permission: same role that archived, or higher
    - Social head can restore anything
    - Other heads can restore own unit
    - Center head can restore anything
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    form_id = data.get('form_id')
    user_id = data.get('user_id')

    if not form_id or not user_id:
        return jsonify({"error": "Missing form_id or user_id"}), 400

    try:
        user_profile = supabase.table('profiles').select('role, unit, full_name').eq('id', user_id).execute()
        if not user_profile.data:
            return jsonify({"error": "User profile not found"}), 404

        user_role = user_profile.data[0]['role']
        user_unit = user_profile.data[0].get('unit')
        user_name = user_profile.data[0].get('full_name', 'Unknown')

        form_result = supabase.table('form_submissions').select('id, unit, resident_id, template_type, is_archived, archived_by').eq('id', form_id).execute()
        if not form_result.data:
            return jsonify({"error": "Form not found"}), 404

        form = form_result.data[0]
        if not form.get('is_archived'):
            return jsonify({"error": "Form is not archived"}), 400

        form_unit = form.get('unit')

        is_center_head = user_role == 'center_head'
        is_social_head = user_role in ('head', 'social_head') and user_unit == 'social'
        is_own_unit_head = (user_role == 'head' or user_role.endswith('_head')) and user_unit == form_unit
        is_original_archiver = form.get('archived_by') == user_id

        if not (is_center_head or is_social_head or is_own_unit_head or is_original_archiver):
            return jsonify({"error": "Not authorized to restore this form"}), 403

        supabase.table('form_submissions').update({
            'is_archived': False,
            'archived_by': None,
            'archived_at': None,
            'updated_at': datetime.now().isoformat()
        }).eq('id', form_id).execute()

        try:
            supabase.table('timeline_entries').insert({
                'resident_id': form.get('resident_id'),
                'entry_type': 'form',
                'form_submission_id': form_id,
                'form_template_type': form.get('template_type'),
                'unit': form_unit,
                'title': 'Form Restored',
                'description': f"Restored by {user_name}",
                'created_by': user_id,
                'created_at': datetime.now().isoformat()
            }).execute()
        except Exception as te:
            print(f" * WARNING: Failed to create restore timeline entry: {te}")

        print(f" * Form {form_id} restored by {user_name} ({user_role}/{user_unit})")
        return jsonify({"success": True}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/api/delete-resident-note', methods=['POST'])
def delete_resident_note():
    """
    Permanently delete an archived resident note using Service Role.
    Expects JSON: { "note_id": "...", "user_id": "..." }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    note_id = data.get('note_id')
    user_id = data.get('user_id')

    if not note_id or not user_id:
        return jsonify({"error": "Missing note_id or user_id"}), 400

    try:
        # Check permissions
        user_res = supabase.table('profiles').select('full_name, role, unit').eq('id', user_id).execute()
        if not user_res.data:
            return jsonify({"error": "User not found"}), 404

        user_role = user_res.data[0].get('role')
        user_unit = user_res.data[0].get('unit')
        user_name = user_res.data[0].get('full_name', 'Unknown')

        note_result = supabase.table('resident_notes').select('is_archived, author_id').eq('id', note_id).execute()
        if not note_result.data:
            return jsonify({"error": "Note not found"}), 404
            
        note = note_result.data[0]
        if not note.get('is_archived'):
            return jsonify({"error": "Only archived notes can be permanently deleted"}), 400

        # AUTHORIZATION: Note Author or Social Service Unit Head
        is_original_author = note.get('author_id') == user_id
        is_social_head = user_role in ('head', 'social_head') and user_unit == 'social'

        if not (is_original_author or is_social_head):
            return jsonify({"error": "Not authorized to permanently delete this note"}), 403

        # Execute Deletion
        supabase.table('resident_notes').delete().eq('id', note_id).execute()

        print(f" * Note {note_id} permanently deleted by {user_name} ({user_role}/{user_unit})")
        return jsonify({"success": True}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/api/get-signature', methods=['GET'])
def get_signature():
    """
    Get signature URL for a user (Service Role).
    Expects QParam: ?user_id=...
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    try:
        response = supabase.table('profiles').select('signature_url').eq('id', user_id).execute()
        if len(response.data) == 0:
            return jsonify({"signature_url": None}), 200
            
        return jsonify({"signature_url": response.data[0].get('signature_url')}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/update-signature', methods=['POST'])
def update_signature():
    """
    Update signature URL for a user (Service Role).
    Expects JSON: { "user_id": "...", "signature_url": "..." }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json
    user_id = data.get('user_id')
    signature_url = data.get('signature_url')

    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    try:
        response = supabase.table('profiles').update({'signature_url': signature_url}).eq('id', user_id).execute()
        return jsonify({"success": True, "count": len(response.data)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/notify-approvers', methods=['POST'])
def notify_approvers():
    """
    Find approvers for a form and send notifications.
    Expects JSON: { 
        "unit": "...", 
        "form_id": "...", 
        "form_title": "...", 
        "submitter_name": "...",
        "recipient_id": "..." (Optional, for specific targeting)
    }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json
    unit = data.get('unit')
    form_id = data.get('form_id')
    form_title = data.get('form_title')
    submitter_name = data.get('submitter_name')
    recipient_id = data.get('recipient_id') # Specific target

    if not all([unit, form_id, form_title]):
        return jsonify({"error": "Missing required fields"}), 400

    try:
        approvers = []
        
        if recipient_id:
            response = supabase.table('profiles').select('id, role').eq('id', recipient_id).execute()
            if response.data:
                approvers = response.data
        else:
            ch_response = supabase.table('profiles').select('id, role').eq('role', 'center_head').execute()
            if ch_response.data:
                approvers.extend(ch_response.data)
                
            if unit: # Avoid query if unit is somehow empty
                uh_response = supabase.table('profiles').select('id, role').eq('role', 'head').eq('unit', unit).execute()
                if uh_response.data:
                    approvers.extend(uh_response.data)
            
            unique_ids = set()
            unique_approvers = []
            for a in approvers:
                if a['id'] not in unique_ids:
                    unique_ids.add(a['id'])
                    unique_approvers.append(a)
            approvers = unique_approvers

        if not approvers:
            return jsonify({"message": "No approvers found"}), 200

        # Create Notifications
        notifications = []
        now = datetime.now().isoformat()

        for approver in approvers:
            notifications.append({
                'user_id': approver['id'],
                'type': 'approval_request',
                'title': 'New Approval Request',
                'message': f"{submitter_name} submitted {form_title}",
                'form_submission_id': form_id, # Match SQL schema
                'is_read': False,
                'created_at': now
            })

        if notifications:
            supabase.table('notifications').insert(notifications).execute()

        return jsonify({"success": True, "count": len(notifications)}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Notification Error: {e}")
        return jsonify({"error": str(e)}), 500

def send_smtp_email(to_email, subject, body):
    """
    Sends an email using SMTP credentials from environment variables.
    Returns True if successful, False otherwise.
    """
    smtp_host = os.environ.get("SMTP_HOST")
    smtp_port = os.environ.get("SMTP_PORT", 587)
    smtp_user = os.environ.get("SMTP_USER")
    smtp_pass = os.environ.get("SMTP_PASSWORD")
    
    if not smtp_host or not smtp_user or not smtp_pass:
        return False
        
    try:
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart

        msg = MIMEMultipart()
        msg['From'] = str(smtp_user)
        msg['To'] = str(to_email)
        msg['Subject'] = str(subject)

        msg.attach(MIMEText(body, 'plain'))

        server = smtplib.SMTP(str(smtp_host), int(smtp_port))
        server.starttls()
        server.login(str(smtp_user), str(smtp_pass))
        text = msg.as_string()
        server.sendmail(str(smtp_user), str(to_email), text)
        server.quit()
        print(f" * Email sent successfully to {to_email}")
        return True
    except Exception as e:
        print(f" * Failed to send email: {e}")
        return False

@app.route('/api/deactivate-user', methods=['POST'])
def deactivate_user():
    """
    Deactivate a user using Service Role.
    Expects JSON: { "user_id": "...", "status": "inactive" }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    try:
        # Update profile to inactive
        response = supabase.table('profiles').update({
            'is_active': False,
            'updated_at': datetime.now().isoformat()
        }).eq('id', user_id).execute()

        if not response.data:
            return jsonify({"error": "User not found or update failed"}), 404

        # Log action
        try:
            admin_id = request.headers.get('X-Admin-Id') # Optional
            supabase.table('audit_logs').insert({
                'user_id': admin_id or user_id,
                'action': 'DEACTIVATE_USER',
                'details': f"Deactivated user {user_id}",
                'created_at': datetime.now().isoformat()
            }).execute()
        except Exception as log_e:
            print(f" * Warning: Audit log failed: {log_e}")

        return jsonify({"success": True}), 200
    except Exception as e:
        print(f" * Deactivate Error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/reactivate-user', methods=['POST'])
def reactivate_user():
    """
    Reactivate a user using Service Role.
    Expects JSON: { "user_id": "..." }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    try:
        # Update profile to active
        response = supabase.table('profiles').update({
            'is_active': True,
            'updated_at': datetime.now().isoformat()
        }).eq('id', user_id).execute()

        if not response.data:
            return jsonify({"error": "User not found or update failed"}), 404

        # Log action
        try:
            admin_id = request.headers.get('X-Admin-Id')
            supabase.table('audit_logs').insert({
                'user_id': admin_id or user_id,
                'action': 'REACTIVATE_USER',
                'details': f"Reactivated user {user_id}",
                'created_at': datetime.now().isoformat()
            }).execute()
        except Exception as log_e:
            print(f" * Warning: Audit log failed: {log_e}")

        return jsonify({"success": True}), 200
    except Exception as e:
        print(f" * Reactivate Error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/notify-login', methods=['POST'])
def notify_login():
    """
    Send login notification email if enabled by user.
    Expects JSON: { "user_id": "...", "email": "..." }
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500

    data = request.json
    user_id = data.get('user_id')
    email = data.get('email')

    if not user_id or not email:
        return jsonify({"error": "Missing user_id or email"}), 400

    try:
        # Check User Preference
        profile = supabase.table('profiles').select('email_notifications_enabled').eq('id', user_id).execute()
        
        should_send = True # Default to true
        if profile.data:
            should_send = profile.data[0].get('email_notifications_enabled', True)
            
        if not should_send:
            print(f" * Email notification skipped for {email} (preference: disabled)")
            return jsonify({"status": "skipped", "reason": "preference_disabled"}), 200

        # Prepare Email Content
        now = datetime.now()
        timestamp_str = now.strftime("%Y-%m-%d %H:%M:%S")
        
        subject = "Login Alert: RCFMS Account Access"
        body = f"""
        Hello,
        
        Your RCFMS account ({email}) was accessed on {timestamp_str}.
        
        If this was you, you can ignore this email.
        If you did not log in, please contact your administrator immediately.
        
        Regards,
        RCFMS Security Team
        """
        
        # Send Email
        smtp_success = send_smtp_email(email, subject, body)

        if smtp_success:
             return jsonify({"success": True, "message": "Notification sent via SMTP"}), 200

        # Fallback to Mock logging
        print("="*60)
        print(f" [MOCK EMAIL] To: {email}")
        print(f" [Subject]: {subject}")
        print(f" [Body]: \n{body}")
        print("="*60)
        
        return jsonify({"success": True, "message": "Notification logged (Mock - SMTP not configured)"}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# =============================================================================
# ANALYTICS ENDPOINTS
# =============================================================================

@app.route('/api/analytics/overview', methods=['GET'])
def analytics_overview():
    """
    Executive overview: occupancy, demographics, form status summary.
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
    try:
        # --- Resident counts ---
        all_residents = supabase.table('residents').select('id, status, date_of_birth, gender, admission_date, ward_id, is_active').execute()
        residents = all_residents.data or []

        admitted = [r for r in residents if r.get('status') == 'admitted' and r.get('is_active')]
        pre_admission = [r for r in residents if r.get('status') == 'pre_admission' and r.get('is_active')]
        discharged = [r for r in residents if r.get('status') == 'discharged']

        # Gender distribution (admitted only)
        gender_dist = {'male': 0, 'female': 0, 'other': 0}
        for r in admitted:
            g = (r.get('gender') or 'other').lower()
            if g in gender_dist:
                gender_dist[g] += 1
            else:
                gender_dist['other'] += 1

        # Age distribution (admitted only)
        from datetime import date
        today = date.today()
        age_buckets = {'0-17': 0, '18-39': 0, '40-59': 0, '60+': 0}
        total_los_days = 0
        los_count = 0
        for r in admitted:
            dob_str = r.get('date_of_birth')
            if dob_str:
                try:
                    dob = date.fromisoformat(str(dob_str)[:10])
                    age = (today - dob).days // 365
                    if age < 18:
                        age_buckets['0-17'] += 1
                    elif age < 40:
                        age_buckets['18-39'] += 1
                    elif age < 60:
                        age_buckets['40-59'] += 1
                    else:
                        age_buckets['60+'] += 1
                except:
                    pass
            adm_str = r.get('admission_date')
            if adm_str:
                try:
                    adm = date.fromisoformat(str(adm_str)[:10])
                    total_los_days += (today - adm).days
                    los_count += 1
                except:
                    pass

        avg_los = round(total_los_days / los_count, 1) if los_count > 0 else 0

        # --- Ward occupancy ---
        wards_resp = supabase.table('wards').select('id, name, capacity, current_occupancy').eq('is_active', True).execute()
        wards = wards_resp.data or []
        ward_occupancy = [
            {'name': w['name'], 'current': w.get('current_occupancy', 0), 'capacity': w.get('capacity', 0)}
            for w in wards
        ]

        # --- Form status summary ---
        forms_resp = supabase.table('form_submissions').select('status').eq('is_archived', False).execute()
        forms = forms_resp.data or []
        form_status = {}
        for f in forms:
            s = f.get('status', 'unknown')
            form_status[s] = form_status.get(s, 0) + 1

        return jsonify({
            "residents": {
                "admitted": len(admitted),
                "pre_admission": len(pre_admission),
                "discharged": len(discharged),
                "avg_length_of_stay_days": avg_los,
            },
            "gender_distribution": gender_dist,
            "age_distribution": age_buckets,
            "ward_occupancy": ward_occupancy,
            "form_status_summary": form_status,
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/api/analytics/forms', methods=['GET'])
def analytics_forms():
    """
    Form analytics: by unit, turnaround time, monthly trends.
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
    try:
        forms_resp = supabase.table('form_submissions').select(
            'id, unit, status, submitted_at, reviewed_at, created_at, template_type'
        ).eq('is_archived', False).execute()
        forms = forms_resp.data or []

        # Forms by unit
        by_unit = {}
        for f in forms:
            u = f.get('unit', 'unknown')
            by_unit[u] = by_unit.get(u, 0) + 1

        # Forms by unit AND status (for stacked chart)
        unit_status = {}
        for f in forms:
            u = f.get('unit', 'unknown')
            s = f.get('status', 'unknown')
            if u not in unit_status:
                unit_status[u] = {}
            unit_status[u][s] = unit_status[u].get(s, 0) + 1

        # Average turnaround time per unit (submitted_at → reviewed_at, approved only)
        from datetime import datetime as dt_cls
        tat_by_unit = {}
        for f in forms:
            if f.get('status') == 'approved' and f.get('submitted_at') and f.get('reviewed_at'):
                try:
                    sub = dt_cls.fromisoformat(f['submitted_at'].replace('Z', '+00:00'))
                    rev = dt_cls.fromisoformat(f['reviewed_at'].replace('Z', '+00:00'))
                    hours = (rev - sub).total_seconds() / 3600
                    u = f.get('unit', 'unknown')
                    if u not in tat_by_unit:
                        tat_by_unit[u] = []
                    tat_by_unit[u].append(hours)
                except:
                    pass
        avg_tat = {u: round(sum(v) / len(v), 1) for u, v in tat_by_unit.items() if v}

        # Monthly submission trend (last 12 months)
        from datetime import date, timedelta
        today = date.today()
        monthly_submissions = {}
        for i in range(11, -1, -1):
            d = today.replace(day=1) - timedelta(days=i * 28)
            key = d.strftime('%Y-%m')
            monthly_submissions[key] = 0

        for f in forms:
            ca = f.get('created_at')
            if ca:
                try:
                    key = str(ca)[:7]  # 'YYYY-MM'
                    if key in monthly_submissions:
                        monthly_submissions[key] += 1
                except:
                    pass

        return jsonify({
            "by_unit": by_unit,
            "unit_status": unit_status,
            "avg_turnaround_hours": avg_tat,
            "monthly_submissions": monthly_submissions,
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/api/analytics/incidents', methods=['GET'])
def analytics_incidents():
    """
    Incident report analytics: trends, ward breakdown, type breakdown.
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
    try:
        from datetime import date, timedelta

        # Fetch all incident reports
        incidents_resp = supabase.table('form_submissions').select(
            'id, resident_id, created_at, form_data'
        ).eq('is_archived', False).in_(
            'template_type', ['incident_report', 'hl_incident_report']
        ).execute()
        incidents = incidents_resp.data or []

        today = date.today()
        current_month_start = today.replace(day=1)
        if today.month == 1:
            prev_month_start = today.replace(year=today.year - 1, month=12, day=1)
        else:
            prev_month_start = today.replace(month=today.month - 1, day=1)

        current_month_count = 0
        prev_month_count = 0
        monthly_trend = {}
        for i in range(11, -1, -1):
            d = today.replace(day=1) - timedelta(days=i * 28)
            key = d.strftime('%Y-%m')
            monthly_trend[key] = 0

        standard_incident_types = [
            'Fall / Slip',
            'Medical Emergency',
            'Medication Error / Missed Dose',
            'Behavioral Aggression / Altercation',
            'Absconding / Missing Resident',
            'Self-Harm / Suicide Attempt',
            'Abuse / Neglect Allegation',
            'Property Loss / Theft',
            'Property Damage',
            'Fire / Safety Hazard',
            'Infection Control / Outbreak Concern',
            'Death',
            'Other',
        ]

        incident_type_aliases = {
            'fall': 'Fall / Slip',
            'slip': 'Fall / Slip',
            'fall/slip': 'Fall / Slip',
            'medical emergency': 'Medical Emergency',
            'medication error': 'Medication Error / Missed Dose',
            'missed dose': 'Medication Error / Missed Dose',
            'aggression': 'Behavioral Aggression / Altercation',
            'behavioral aggression': 'Behavioral Aggression / Altercation',
            'altercation': 'Behavioral Aggression / Altercation',
            'absconding': 'Absconding / Missing Resident',
            'missing resident': 'Absconding / Missing Resident',
            'self-harm': 'Self-Harm / Suicide Attempt',
            'suicide attempt': 'Self-Harm / Suicide Attempt',
            'abuse': 'Abuse / Neglect Allegation',
            'neglect': 'Abuse / Neglect Allegation',
            'property loss': 'Property Loss / Theft',
            'theft': 'Property Loss / Theft',
            'property damage': 'Property Damage',
            'fire': 'Fire / Safety Hazard',
            'safety hazard': 'Fire / Safety Hazard',
            'infection control': 'Infection Control / Outbreak Concern',
            'outbreak': 'Infection Control / Outbreak Concern',
            'death': 'Death',
            'other': 'Other',
        }

        def normalize_incident_type(raw_value):
            if raw_value is None:
                return 'Unspecified'

            value = str(raw_value).strip()
            if not value:
                return 'Unspecified'

            lower_value = value.lower()

            for standard in standard_incident_types:
                if lower_value == standard.lower():
                    return standard

            if lower_value in incident_type_aliases:
                return incident_type_aliases[lower_value]

            return value

        incident_type_breakdown = {}
        resident_ids = set()
        for inc in incidents:
            ca = inc.get('created_at')
            if ca:
                try:
                    inc_date = date.fromisoformat(str(ca)[:10])
                    key = str(ca)[:7]
                    if key in monthly_trend:
                        monthly_trend[key] += 1
                    if inc_date >= current_month_start:
                        current_month_count += 1
                    elif inc_date >= prev_month_start and inc_date < current_month_start:
                        prev_month_count += 1
                except:
                    pass

            form_data = inc.get('form_data')
            incident_type_raw = None
            if isinstance(form_data, dict):
                incident_type_raw = form_data.get('type_of_incident') or form_data.get('incident_type')
                if incident_type_raw == 'Other' and form_data.get('other_incident_type'):
                    incident_type_raw = form_data.get('other_incident_type')

            normalized_type = normalize_incident_type(incident_type_raw)
            incident_type_breakdown[normalized_type] = (
                incident_type_breakdown.get(normalized_type, 0) + 1
            )

            rid = inc.get('resident_id')
            if rid:
                resident_ids.add(rid)

        incident_type_breakdown = dict(
            sorted(
                incident_type_breakdown.items(),
                key=lambda item: item[1],
                reverse=True,
            )
        )

        # Ward breakdown via resident → ward mapping
        ward_breakdown = {}
        if resident_ids:
            res_resp = supabase.table('residents').select('id, ward_id').in_('id', list(resident_ids)).execute()
            res_ward = {r['id']: r.get('ward_id') for r in (res_resp.data or [])}

            wards_resp = supabase.table('wards').select('id, name').execute()
            ward_names = {w['id']: w['name'] for w in (wards_resp.data or [])}

            for inc in incidents:
                rid = inc.get('resident_id')
                wid = res_ward.get(rid)
                wname = ward_names.get(wid, 'Unknown')
                ward_breakdown[wname] = ward_breakdown.get(wname, 0) + 1

        return jsonify({
            "total": len(incidents),
            "current_month": current_month_count,
            "previous_month": prev_month_count,
            "delta": current_month_count - prev_month_count,
            "monthly_trend": monthly_trend,
            "by_ward": ward_breakdown,
            "by_type": incident_type_breakdown,
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/api/analytics/residents', methods=['GET'])
def analytics_residents():
    """
    Resident population analytics: admission/discharge trends, case categories.
    """
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
    try:
        from datetime import date, timedelta

        today = date.today()

        # All residents (including inactive for discharge data)
        all_resp = supabase.table('residents').select(
            'id, status, admission_date, ward_id, case_category, is_active, updated_at'
        ).execute()
        all_residents = all_resp.data or []

        # Monthly admissions (last 12 months)
        monthly_admissions = {}
        monthly_discharges = {}
        for i in range(11, -1, -1):
            d = today.replace(day=1) - timedelta(days=i * 28)
            key = d.strftime('%Y-%m')
            monthly_admissions[key] = 0
            monthly_discharges[key] = 0

        for r in all_residents:
            adm = r.get('admission_date')
            if adm:
                key = str(adm)[:7]
                if key in monthly_admissions:
                    monthly_admissions[key] += 1

            # Approximate discharge month from updated_at when status is discharged
            if r.get('status') == 'discharged':
                upd = r.get('updated_at')
                if upd:
                    key = str(upd)[:7]
                    if key in monthly_discharges:
                        monthly_discharges[key] += 1

        # Case category distribution (admitted only)
        admitted = [r for r in all_residents if r.get('status') == 'admitted' and r.get('is_active')]
        case_categories = {}
        for r in admitted:
            cc = r.get('case_category') or 'Unspecified'
            case_categories[cc] = case_categories.get(cc, 0) + 1

        # Residents by ward (admitted only)
        wards_resp = supabase.table('wards').select('id, name').execute()
        ward_names = {w['id']: w['name'] for w in (wards_resp.data or [])}
        by_ward = {}
        for r in admitted:
            wid = r.get('ward_id')
            wname = ward_names.get(wid, 'Unassigned')
            by_ward[wname] = by_ward.get(wname, 0) + 1

        return jsonify({
            "monthly_admissions": monthly_admissions,
            "monthly_discharges": monthly_discharges,
            "case_categories": case_categories,
            "by_ward": by_ward,
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
