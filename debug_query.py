import os
import sys

# Add backend directory to path so we can import app.py environment
backend_dir = os.path.join(os.getcwd(), 'backend')
sys.path.append(backend_dir)
os.chdir(backend_dir)

from app import supabase

res = supabase.table('form_submissions').select('id, status, form_data').eq('template_type', 'out_on_pass').order('created_at', desc=True).limit(1).execute()
if res.data:
    form = res.data[0]
    print('Form status:', form.get('status'))
    print('Doctor:', form.get('form_data').get('center_doctor'))
    print('SW:', form.get('form_data').get('social_worker'))
    
    apps = supabase.table('form_approvals').select('*').eq('form_submission_id', form['id']).execute()
    for a in apps.data:
        print(a)
else:
    print("No forms found")
