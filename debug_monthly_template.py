import docx
from docxtpl import DocxTemplate
import re
import os
import zipfile

template_path = r'c:\eldercare_rcfms\form_templates\Home Life Service\inventory_monthly.docx'

print(f"Inspecting: {template_path}")

if not os.path.exists(template_path):
    print("Error: File not found!")
    exit()

# method 1: Try to load with docxtpl to see error details
try:
    doc = DocxTemplate(template_path)
    # data is empty, just parsing
    print("basic DocxTemplate load success (syntax might be valid enough to load).")
except Exception as e:
    print(f"DocxTemplate load failed: {e}")

# Method 2: Extract XML and hunt for tags regex
print("\n--- RAW TAG SEARCH ---")
try:
    with zipfile.ZipFile(template_path, 'r') as docx:
        xml_content = docx.read('word/document.xml').decode('utf-8')
        
        # Simple regex to find content between {% and %}
        # Note: formatting might split tags in xml, this is a rough check
        tags = re.findall(r'\{%.*?%\}', xml_content)
        
        print(f"Found {len(tags)} potential tags:")
        for i, tag in enumerate(tags):
            print(f"{i+1}: {tag}")
            if " or" in tag or "or " in tag: # Simple check for the 'or' issue
                print(f"   ^^^ SUSPICIOUS: Contains 'or' ^^^")
                
except Exception as e:
    print(f"Failed to read raw XML: {e}")
