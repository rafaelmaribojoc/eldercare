import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv('c:\\Flutter_Projects\\ec\\backend\\.env')
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

supabase: Client = create_client(url, key)
profiles = supabase.table('profiles').select('id, full_name, role, unit').eq('is_active', True).execute()
with open('c:\\Flutter_Projects\\ec\\profiles_out.txt', 'w') as f:
    for p in profiles.data:
        f.write(f"{p['full_name']} | Role: {p['role']} | Unit: {p['unit']}\n")
