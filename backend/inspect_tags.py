from docxtpl import DocxTemplate
import os
import jinja2

def list_tags(template_path):
    log_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tag_inspection.log')
    if not os.path.exists(template_path):
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"Error: File not found at {template_path}\n")
        return

    try:
        doc = DocxTemplate(template_path)
        vars = doc.get_undeclared_template_variables()
        with open(log_path, 'w', encoding='utf-8') as f:
            f.write(f"--- Tags found in {os.path.basename(template_path)} ---\n")
            all_vars = sorted(list(vars))
            for v in all_vars:
                f.write(f" - {v}\n")
            
            if 'participant_details' not in all_vars:
                f.write("\nWARNING: 'participant_details' NOT FOUND in template variables!\n")
                if 'participants' in all_vars:
                    f.write("HINT: You might be using 'participants' in your loop by mistake.\n")
            else:
                f.write("\nSUCCESS: 'participant_details' found in template variables.\n")

            # Test rendering with minimal context to check for Jinja2 errors
            f.write("\n--- Testing Render with missing context ---\n")
            test_context = {
                'session_date': 'TEST',
                'report_date': 'TEST',
                'participants': 'JOHN DOE', # Simulate the string field
                # Omit participant_details to see if it triggers 'p' is undefined
            }
            try:
                doc.render(test_context)
                f.write("Render successful (no errors triggered with missing context)\n")
            except jinja2.exceptions.UndefinedError as e:
                f.write(f"Caught expected error: {e}\n")
                if "'p' is undefined" in str(e):
                    f.write("CONFIRMED: Template contains {{ p.xyz }} but NO loop defined for 'p' or the loop is broken.\n")
            except Exception as e:
                f.write(f"Caught other error: {type(e).__name__}: {e}\n")
    except Exception as e:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"Error reading template: {e}\n")

if __name__ == "__main__":
    import sys
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    
    if len(sys.argv) > 1:
        path = sys.argv[1]
        # Resolve relative path if needed
        if not os.path.isabs(path):
            path = os.path.abspath(os.path.join(os.getcwd(), path))
    else:
        path = os.path.join(base_dir, 'form_templates', 'Social Service', 'discharge_slip.docx')
    
    print(f"Inspecting: {path}")
    list_tags(path)
    log_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tag_inspection.log')
    print(f"Done. Check {log_path}")
