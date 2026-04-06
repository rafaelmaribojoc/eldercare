import os
import sys
import json
backend_dir = os.path.join(os.getcwd(), 'backend')
sys.path.append(backend_dir)
os.chdir(backend_dir)
from app import supabase
u1 = supabase.table('profiles').select('full_name, role, unit').ilike('full_name', '%rosa medical%').execute()
u2 = supabase.table('profiles').select('full_name, role, unit').ilike('full_name', '%social unit head%').execute()

out_path = os.path.join(os.path.dirname(backend_dir), 'roles_debug.txt')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(json.dumps({'Rosa Medical': u1.data, 'Social Unit Head': u2.data}, indent=2))
