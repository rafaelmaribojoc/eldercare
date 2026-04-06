
import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

# Force unbuffered output
sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()

url: str = os.environ.get("SUPABASE_URL", "")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

supabase: Client = create_client(url, key)

try:
    print("--- START PROFILES ---")
    response = supabase.table("profiles").select("id, full_name, role, signature_url").execute()
    
    profiles = response.data
    for p in profiles:
        name = p.get('full_name', 'Unknown')
        role = p.get('role', 'Unknown')
        sig = p.get('signature_url')
        has_sig = "YES" if sig and len(sig) > 0 else "NO"
        print(f"User: {name} | Role: {role}")
        print(f"  Sig: {has_sig}")
        if has_sig == "YES":
             print(f"  URL: {sig[:20]}...")
    print("--- END PROFILES ---")
        
except Exception as e:
    print(f"Error: {e}")
