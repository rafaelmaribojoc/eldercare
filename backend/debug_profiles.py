import os
import sys
from supabase import create_client
from dotenv import load_dotenv

sys.stdout.reconfigure(encoding='utf-8')
load_dotenv()
url = os.environ.get('SUPABASE_URL', '')
key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY', '')

supabase = create_client(url, key)

res = supabase.table('profiles').select('id, full_name, role, title, status').execute()
for p in res.data:
    print(p)
