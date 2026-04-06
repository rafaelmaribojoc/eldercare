import os
import sys
import win32com.client
from docxtpl import DocxTemplate
import uuid
import tempfile

file_path = r"C:\eldercare_rcfms\form_templates\Home Life Service\inventory_admission.docx"
temp_dir = tempfile.gettempdir()
filled_path = os.path.join(temp_dir, f"debug_filled_{uuid.uuid4()}.docx")

print(f"--- DIAGNOSTIC STEP 2: RENDER TEST ---")
print(f"Template: {file_path}")

try:
    print("1. Loading template with DocxTemplate...")
    doc = DocxTemplate(file_path)

    print("2. Rendering with dummy data...")
    context = {
        'client_name': 'TEST CLIENT',
        'inventory_date': '2025-01-01',
        'admission_items': [
            {
                'particulars': 'Test Item 1',
                'qty': 1,
                'unit': 'pc',
                'description': 'Desc 1',
                'unit_cost': 100,
                'balance': 100
            },
            {
                'particulars': 'Test Item 2',
                'qty': 2,
                'unit': 'kg',
                'description': 'Desc 2',
                'unit_cost': 200,
                'balance': 200
            }
        ],
        'referring_party': 'Ref Party',
        'inspected_by': 'Insp Party',
        'attested_by': 'Att Party',
        'noted_by': 'Not Party'
    }
    doc.render(context)
    
    print(f"3. Saving filled file to: {filled_path}")
    doc.save(filled_path)
    print("   Save Successful.")

    print("4. Attempting to open FILLED file with Word COM...")
    word = win32com.client.Dispatch("Word.Application")
    word.Visible = False
    try:
        wb = word.Documents.Open(filled_path)
        print("SUCCESS: Word opened the filled file without error.")
        wb.Close(False)
    except Exception as e:
        print(f"FAIL: Word could NOT open the filled file. It is corrupted.")
        print(f"Error: {e}")
    finally:
        word.Quit()

except Exception as e:
    print(f"CRASH: Script failed during processing: {e}")

print("--- DIAGNOSTIC END ---")
