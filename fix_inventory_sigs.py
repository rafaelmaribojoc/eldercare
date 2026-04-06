import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv('c:\\Flutter_Projects\\ec\\backend\\.env')
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("Supabase credentials not found.")
    exit()

supabase: Client = create_client(url, key)

forms = supabase.table('form_submissions').select('id').in_('template_type', ['hl_inventory_monthly', 'inventory_monthly', 'hl_inventory_admission', 'inventory_admission', 'hl_inventory_discharge', 'inventory_discharge']).execute()
form_ids = [f['id'] for f in forms.data]

if form_ids:
    print(f"Found {len(form_ids)} inventory forms. Checking for incorrect signatures...")
    
    # We want to change 'noted_by' to 'submitted_by' for Supervising Houseparents
    sigs = supabase.table('form_signatures').select('id, field_name, signer_title').in_('form_submission_id', form_ids).eq('field_name', 'noted_by').execute()
    
    updated_count = 0
    for sig in sigs.data:
        title = (sig.get('signer_title') or '').lower()
        # If it's a Supervising HP (not a Center Head), it should be submitted_by
        if 'supervising' in title or 'supervisor' in title:
            print(f"Updating signature ID {sig['id']} from 'noted_by' to 'submitted_by' (Title: {title})")
            supabase.table('form_signatures').update({
                'field_name': 'submitted_by',
                'field_label': 'Submitted By'
            }).eq('id', sig['id']).execute()
            updated_count += 1
            
    print(f"Successfully fixed {updated_count} signatures.")
else:
    print("No inventory forms found.")
