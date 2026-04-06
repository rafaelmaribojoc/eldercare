import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv('c:/Flutter_Projects/ec/.env')
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("Supabase credentials not found.")
    exit()

supabase: Client = create_client(url, key)

forms = supabase.table('form_submissions').select('id, template_type, status').in_('template_type', ['hl_inventory_monthly', 'inventory_monthly']).order('created_at', desc=True).limit(5).execute()

for form in forms.data:
    print(f"Form ID: {form['id']}, Type: {form['template_type']}, Status: {form['status']}")
    sigs = supabase.table('form_signatures').select('field_name, signer_name, signer_title').eq('form_submission_id', form['id']).execute()
    for sig in sigs.data:
        print(f"  -> Signature Field: {sig['field_name']}, Name: {sig['signer_name']}, Title: {sig['signer_title']}")
