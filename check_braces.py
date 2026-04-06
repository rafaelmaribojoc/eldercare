
def check_braces(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    stack = []
    pairs = {'{': '}', '[': ']', '(': ')'}
    
    in_comment_block = False
    in_line_comment = False
    in_string = False
    string_char = ''
    
    i = 0
    while i < len(content):
        char = content[i]
        
        # Handle comments and strings
        if in_comment_block:
            if char == '*' and i + 1 < len(content) and content[i+1] == '/':
                in_comment_block = False
                i += 1
            i += 1
            continue
            
        if in_line_comment:
            if char == '\n':
                in_line_comment = False
            i += 1
            continue
            
        if in_string:
            if char == string_char:
                if i > 0 and content[i-1] != '\\':
                    in_string = False
            i += 1
            continue
            
        # Check start of comments/strings
        if char == '/' and i + 1 < len(content):
            if content[i+1] == '*':
                in_comment_block = True
                print(f"Comment block starts at position {i}")
                i += 2
                continue
            elif content[i+1] == '/':
                in_line_comment = True
                i += 2
                continue
        
        if char == '"' or char == "'":
            in_string = True
            string_char = char
            i += 1
            continue
            
        # Check brackets
        if char in pairs:
            stack.append((char, i))
        elif char in pairs.values():
            if not stack:
                print(f"Error: Unexpected closing {char} at position {i}")
            else:
                last_char, last_pos = stack.pop()
                expected = pairs[last_char]
                if char != expected:
                    print(f"Error: Mismatch! Expected {expected} for {last_char} at {last_pos}, found {char} at {i}")
                    return

        i += 1

    if in_comment_block:
        print("Error: Unterminated comment block!")
    elif stack:
        char, pos = stack[-1]
        line_num = content[:pos].count('\n') + 1
        print(f"Error: Unclosed {char} at line {line_num} (pos {pos})")
    else:
        print("All brackets balanced.")

check_braces('rcfms/lib/features/forms/templates/homelife_service_forms.dart')
