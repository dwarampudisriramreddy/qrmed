import re
import json

def process_requirements():
    file_path = r'C:\Users\Welcome\Desktop\my projects\QRmed\lib\data\requirements_data.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to parse the Dart map. Since it's a simple structure, we can try to use regex or a more robust approach.
    # Actually, it's easier to manipulate the string if we are careful.
    
    bds_split = [
        'PROSTHODONTICS AND CROWN & BRIDGE',
        'CONSERVATIVE DENTISTRY AND ENDODONTICS',
        'ORAL & MAXILLOFACIAL SURGERY',
        'PERIODONTOLOGY',
        'ORTHODONTICS & DENTOFACIAL ORTHOPEDICS',
        'PAEDIATRIC AND PREVENTIVE DENTISTRY',
        'ORAL MEDICINE & RADIOLOGY',
        'ORAL MEDICINE AND RADIOLOGY',
        'ORAL PATHOLOGY AND MICROBIOLOGY',
        'PUBLIC HEALTH DENTISTRY',
        'ORAL & MAXILLOFACIAL PATHOLOGY AND ORAL MICROBIOLOGY',
        'DENTAL ANATOMY, EMBRYOLOGY, ORAL HISTOLOGY AND ORAL PATHOLOGY'
    ]
    
    mbbs_split = [
        'ANATOMY',
        'PHYSIOLOGY',
        'BIOCHEMISTRY',
        'PATHOLOGY',
        'GENERAL MEDICINE',
        'GENERAL SURGERY'
    ]

    # I will use a simple approach: find the blocks and replace.
    # But wait, it's better to use a real parser if possible or a very good regex.
    # Given the structure, I can find each seat capacity block.
    
    # Let's try to extract 'BDS' and 'MBBS' sections.
    
    def split_department(section_content, departments_to_split):
        new_content = section_content
        for dept in departments_to_split:
            # Pattern to match the department entry: 'DEPT': { ... },
            # We need to match the curly braces correctly.
            pattern = re.compile(rf"'{re.escape(dept)}':\s*\{{(?:[^{{}}]|(?:\{{(?:[^{{}}]|(?:\{{[^{{}}]*\}}))*\}}))*\}},?")
            
            matches = list(pattern.finditer(new_content))
            # Work backwards to avoid index shifts
            for match in reversed(matches):
                original_entry = match.group(0)
                # Remove trailing comma if it exists for clean duplication
                entry_data = original_entry.strip()
                if entry_data.endswith(','):
                    entry_data = entry_data[:-1]
                
                # Extract the data part after the first colon
                data_part = entry_data[entry_data.find(':')+1:].strip()
                
                ug_entry = f"'{dept} (UG)': {data_part},"
                pg_entry = f"'{dept} (PG)': {data_part},"
                
                # Replace original with UG and PG
                new_content = new_content[:match.start()] + ug_entry + "\n      " + pg_entry + new_content[match.end():]
        
        return new_content

    # Separate BDS and MBBS
    bds_match = re.search(r"'BDS':\s*\{(.*?)'MBBS':", content, re.DOTALL)
    if bds_match:
        bds_section = bds_match.group(1)
        new_bds_section = split_department(bds_section, bds_split)
        content = content.replace(bds_section, new_bds_section)
    
    mbbs_match = re.search(r"'MBBS':\s*\{(.*)\};", content, re.DOTALL)
    if mbbs_match:
        mbbs_section = mbbs_match.group(1)
        new_mbbs_section = split_department(mbbs_section, mbbs_split)
        content = content.replace(mbbs_section, new_mbbs_section)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def process_groups():
    file_path = r'C:\Users\Welcome\Desktop\my projects\QRmed\lib\data\department_group.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    bds_split = [
        'PROSTHODONTICS AND CROWN & BRIDGE',
        'CONSERVATIVE DENTISTRY AND ENDODONTICS',
        'ORAL & MAXILLOFACIAL SURGERY',
        'PERIODONTOLOGY',
        'ORTHODONTICS & DENTOFACIAL ORTHOPEDICS',
        'PAEDIATRIC AND PREVENTIVE DENTISTRY',
        'ORAL MEDICINE & RADIOLOGY',
        'ORAL MEDICINE AND RADIOLOGY',
        'ORAL PATHOLOGY AND MICROBIOLOGY',
        'PUBLIC HEALTH DENTISTRY',
        'ORAL & MAXILLOFACIAL PATHOLOGY AND ORAL MICROBIOLOGY',
        'DENTAL ANATOMY, EMBRYOLOGY, ORAL HISTOLOGY AND ORAL PATHOLOGY'
    ]
    
    mbbs_split = [
        'ANATOMY',
        'PHYSIOLOGY',
        'BIOCHEMISTRY',
        'PATHOLOGY',
        'GENERAL MEDICINE',
        'GENERAL SURGERY'
    ]
    
    all_to_split = bds_split + mbbs_split
    
    new_lines = []
    lines = content.splitlines()
    for line in lines:
        matched = False
        for dept in all_to_split:
            if f"'{dept}':" in line:
                # Extract group
                group_match = re.search(rf"'{re.escape(dept)}':\s*'([^']+)'", line)
                if group_match:
                    group = group_match.group(1)
                    indent = line[:line.find("'")]
                    new_lines.append(f"{indent}'{dept} (UG)': '{group}',")
                    new_lines.append(f"{indent}'{dept} (PG)': '{group}',")
                    matched = True
                    break
        if not matched:
            new_lines.append(line)
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines) + '\n')

if __name__ == '__main__':
    process_requirements()
    process_groups()
