from docxtpl import DocxTemplate
import os

def list_signature_tags():
    templates_dir = r"C:\Flutter_Projects\ec\form_templates"
    output_file = 'tags_list.md'
    
    print(f"Scanning: {templates_dir}")
    
    results = {}
    
    if not os.path.exists(templates_dir):
        print(f"ERROR: {templates_dir} does not exist.")
        return

    for root, dirs, files in os.walk(templates_dir):
        print(f"Entering directory: {root}")
        for file in files:
            if file.endswith('.docx') and not file.startswith('~'):
                path = os.path.join(root, file)
                rel_path = os.path.relpath(path, templates_dir)
                try:
                    doc = DocxTemplate(path)
                    # Use a more aggressive tag extraction
                    vars = doc.get_undeclared_template_variables()
                    # Just get ALL tags that might be signatures or related
                    sig_tags = [v for v in vars if any(x in v.lower() for x in ['sig', 'noted', 'prepared', 'approved', 'reviewed'])]
                    if sig_tags:
                        results[rel_path] = sorted(sig_tags)
                    else:
                        # Even if no typical name, check for any tag that looks like a URL
                        url_tags = [v for v in vars if 'url' in v.lower()]
                        if url_tags:
                            results[rel_path] = sorted(url_tags)
                except Exception as e:
                    print(f"Error reading {rel_path}: {e}")
    
    print(f"Found {len(results)} forms with signature-related tags.")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Signature Tags for All Forms\n\n")
        f.write("Identified signature and signatory tags extracted from `.docx` templates.\n\n")
        
        if not results:
            f.write("No signature tags found.\n")
        else:
            for form, tags in sorted(results.items()):
                f.write(f"## {form}\n")
                for tag in tags:
                    f.write(f" - `{{{{ {tag} }}}}`\n")
                f.write("\n")
    
    print(f"Results written to {output_file}")

if __name__ == "__main__":
    list_signature_tags()
