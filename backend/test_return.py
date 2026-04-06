import os
import requests
import json
from dotenv import load_dotenv

load_dotenv('C:/Flutter_Projects/ec/.env')
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_KEY")

if not supabase_url or not supabase_key:
    print("Missing auth.")
    exit(1)

from supabase import create_client, Client
supabase: Client = create_client(supabase_url, supabase_key)

# Find an incident report in pending_multi_approval
res = supabase.table('form_submissions').select('id, status, template_id, template_type').eq('status', 'pending_multi_approval').execute()

if not res.data:
    print("No pending_multi_approval forms found.")
    
    # Alternatively find *any* form and return it to see if there's a 500
    res = supabase.table('form_submissions').select('id, status').limit(1).execute()
    if not res.data:
        print("No forms at all.")
        exit()

form_id = res.data[-1]['id'] # Grab the last one just in case
print(f"Testing return on form: {form_id}")

# Fake user_id for the test (just grab any active user)
user_res = supabase.table('profiles').select('id').limit(1).execute()
user_id = user_res.data[0]['id']

url = "http://127.0.0.1:5000/api/return-form"
payload = {
    "form_id": form_id,
    "user_id": user_id,
    "comment": "Test return script comment"
}
headers = {'Content-Type': 'application/json'}

print(f"Calling POST {url}")
response = requests.post(url, json=payload, headers=headers)

print(f"Status Code: {response.status_code}")
print(f"Response: {response.text}")

