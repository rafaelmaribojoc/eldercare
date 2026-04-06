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

forms = supabase.table('form_submissions').select('id, status').in_('template_type', ['hl_inventory_monthly', 'inventory_monthly']).execute()
form_ids = [f['id'] for f in forms.data]

if form_ids:
    print(f"Checking signatures for forms: {form_ids}")
    sigs = supabase.table('form_signatures').select('id, field_name, signer_name, signer_title').in_('form_submission_id', form_ids).execute()
    for sig in sigs.data:
        print(f"ID: {sig['id']}, Field: {sig['field_name']}, Name: {sig['signer_name']}, Title: {sig['signer_title']}")
