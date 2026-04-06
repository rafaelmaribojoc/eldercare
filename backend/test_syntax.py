import os
from dotenv import load_dotenv

load_dotenv()
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

from supabase import create_client, Client
supabase: Client = create_client(supabase_url, supabase_key)

print("Testing in_ syntax for update")
try:
    # Just do a dummy update that affects no rows
    res = supabase.table('form_approvals').update({'comment': 'test'}).eq('id', '00000000-0000-0000-0000-000000000000').in_('status', ['pending', 'approved']).execute()
    print("Update with in_ success!")
except Exception as e:
    print(f"Update failed: {e}")

print("Testing in_ syntax for delete")
try:
    res = supabase.table('form_signatures').delete().eq('id', '00000000-0000-0000-0000-000000000000').in_('field_name', ['received_social', 'received_medical']).execute()
    print("Delete with in_ success!")
except Exception as e:
    print(f"Delete failed: {e}")
