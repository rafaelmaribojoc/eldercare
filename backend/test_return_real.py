import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

from supabase import create_client, Client
supabase: Client = create_client(supabase_url, supabase_key)

# We want an incident report that is in 'pending_multi_approval'
res = supabase.table('form_submissions').select('*').eq('template_type', 'incident_report').order('created_at', desc=True).limit(5).execute()

target_form_id = None
if res.data:
    target_form_id = res.data[0]['id']

if not target_form_id:
    # Just grab any form
    res = supabase.table('form_submissions').select('id').limit(1).execute()
    if res.data:
        target_form_id = res.data[0]['id']

if target_form_id:
    print(f"Testing return API with form: {target_form_id}")
    
    # Grab any active user id
    user_res = supabase.table('profiles').select('id').limit(1).execute()
    user_id = user_res.data[0]['id']
    
    url = "http://127.0.0.1:5000/api/return-form"
    payload = {
        "form_id": target_form_id,
        "user_id": user_id,
        "comment": "Test return script comment to trace 500 errors"
    }
    headers = {'Content-Type': 'application/json'}

    print(f"Calling POST {url}")
    response = requests.post(url, json=payload, headers=headers)

    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    print(f"If 500, we might see the exception inside error block: {response.json()}")

