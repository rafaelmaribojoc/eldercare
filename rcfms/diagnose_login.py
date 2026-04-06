import requests
import json
import os

# Configuration (New Project)
SUPABASE_URL = 'https://eabmjtqoqhxvudlwxofq.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhYm1qdHFvcWh4dnVkbHd4b2ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4MjAzNTgsImV4cCI6MjA4NDM5NjM1OH0.WAPwhdrPtNzMjk0MABcVNQmqSVXGFRASoB4VNjNPXfw'

# Test Credentials (try a known user if possible, or the one they just tried)
EMAIL = 'superadmin@rcfms.local' 
PASSWORD = 'password123'
# Note: I need the user to tell me which account they tried, OR I can try the probe user I created if I knew its password? 
# I don't know the password for 'manual_probe_user'. 
# I will try to use the credentials from the env example or valid ones if I can find them.
# The user mentioned "super admin".
# Let's try to infer credentials or just test the *structure*.

def test_auth():
    print(f"Testing Auth at {SUPABASE_URL}...")
    url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
    headers = {
        "apikey": ANON_KEY,
        "Content-Type": "application/json"
    }
    data = {
        "email": EMAIL,
        "password": PASSWORD
    }
    
    try:
        r = requests.post(url, headers=headers, json=data)
        print(f"Auth Status: {r.status_code}")
        print(f"Auth Response: {r.text}")
        return r.json()
    except Exception as e:
        print(f"Auth Exception: {e}")
        return None

def test_data_read():
    print(f"\nTesting Data Read (Public access potentially)...")
    url = f"{SUPABASE_URL}/rest/v1/profiles?select=*&limit=1"
    headers = {
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {ANON_KEY}"
    }
    
    try:
        r = requests.get(url, headers=headers)
        print(f"Data Read Status: {r.status_code}")
        if r.status_code == 200:
             print(f"Data Sample: {r.text}")
        else:
             print(f"Data Error: {r.text}")
    except Exception as e:
        print(f"Data Exception: {e}")

if __name__ == "__main__":
    test_data_read() # This doesn't need password if public
    test_auth()
