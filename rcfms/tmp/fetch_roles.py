
import requests
import json

SUPABASE_URL = "https://xkurkaykkywfslakemez.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrdXJrYXlra3l3ZnNsYWtlbWV6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODgzNDE2MSwiZXhwIjoyMDg0NDEwMTYxfQ.qrV6ywXNfqfvR2iWTUMw0r-rLzFq7Abf1ArdcD7ECS0"

def get_unique_roles():
    headers = {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    url = f"{SUPABASE_URL}/rest/v1/profiles?select=role"
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            roles = set(item['role'] for item in data if item.get('role'))
            with open("c:/Flutter_Projects/ec/rcfms/tmp/roles_list.json", "w") as f:
                json.dump(sorted(list(roles)), f)
            print("Successfully wrote roles to tmp/roles_list.json")
        else:
            print(f"Error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    get_unique_roles()
