import os
import glob
import re
import zipfile

folder_path = r"C:\eldercare_rcfms\form_templates\Social Service"
docx_files = sorted(glob.glob(os.path.join(folder_path, "*.docx")))
output_file = r"c:\eldercare_rcfms\found_tags.txt"

tag_pattern = re.compile(r"\{\{\s*([a-zA-Z0-9_]+)\s*\}\}")

with open(output_file, "w", encoding="utf-8") as f:
    f.write(f"Scanning {len(docx_files)} files in {folder_path}...\n\n")

    for file_path in docx_files:
        filename = os.path.basename(file_path)
        try:
            found_tags = set()
            with zipfile.ZipFile(file_path) as zf:
                if 'word/document.xml' in zf.namelist():
                    xml_content = zf.read('word/document.xml').decode('utf-8')
                    found_tags.update(tag_pattern.findall(xml_content))
                
                for name in zf.namelist():
                    if name.startswith('word/header') and name.endswith('.xml'):
                         xml_content = zf.read(name).decode('utf-8')
                         found_tags.update(tag_pattern.findall(xml_content))

            if found_tags:
                f.write(f"[{filename}]\n")
                f.write(f"  Tags: {', '.join(sorted(found_tags))}\n")
            else:
                f.write(f"[{filename}] - No obvious tags found.\n")
                
        except Exception as e:
            f.write(f"[{filename}] - Error: {e}\n")
        
        f.write("-" * 40 + "\n")

print("Done.")
