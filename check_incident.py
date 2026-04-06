import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv('c:\\Flutter_Projects\\ec\\backend\\.env')
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

supabase: Client = create_client(url, key)
forms = supabase.table('form_submissions').select('id, status, template_type').in_('template_type', ['incident_report', 'hl_incident_report']).order('created_at', desc=True).limit(2).execute()

output = []
for f in forms.data:
    output.append(f"Form ID: {f['id']}, Status: {f['status']}, Template: {f['template_type']}")
    apvs = supabase.table('form_approvals').select('*').eq('form_submission_id', f['id']).execute()
    for a in apvs.data:
        output.append(f"  Approval: {a['recipient_name']} (Role: {a.get('recipient_role', 'N/A')}, Status: {a['status']})")

with open('c:\\Flutter_Projects\\ec\\incident_output.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output))
