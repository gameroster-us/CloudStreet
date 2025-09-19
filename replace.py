#!/usr/bin/env python3
import os
import re

# -----------------------------
# Configurations / Replacements
# -----------------------------
replacements_content = {
    r'(?i)CloudStreet': 'CloudStreet',           # CloudStreet variants
    r'(?i)CS': 'CS',                       # CS variants
    r'(?i)cs': 'cs',                        # any substring 'cs' anywhere
    r'CSLogger': 'CSLogger',               # class-safe
    r'(?i)CloudStreet': 'CloudStreet',         # CloudStreet variants
    r'\bCB\b': 'CS',                         # exact CS
    r'\bcb\b': 'cs',                         # exact cs
    r'CSIntegration': 'CSIntegration',       # CamelCase namespace
    r'cs_integration': 'cs_integration',     # snake_case namespace
}

# image extensions to remove
image_exts = ('.png', '.jpg', '.jpeg', '.gif', '.svg')

# project root
project_root = os.path.abspath('.')

# -----------------------------
# Function: Replace inside files
# -----------------------------
def replace_in_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        new_content = content
        for pattern, repl in replacements_content.items():
            new_content = re.sub(pattern, repl, new_content)
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"[UPDATED] {file_path}")
    except Exception as e:
        print(f"[ERROR] {file_path}: {e}")

# -----------------------------
# Function: Rename files/directories
# -----------------------------
def rename_paths():
    # Walk bottom-up to rename files before directories
    for root, dirs, files in os.walk(project_root, topdown=False):
        # Rename files
        for name in files:
            old_path = os.path.join(root, name)
            new_name = name
            for pattern, repl in replacements_content.items():
                new_name = re.sub(pattern, repl, new_name, flags=re.IGNORECASE)
            if new_name != name:
                new_path = os.path.join(root, new_name)
                os.rename(old_path, new_path)
                print(f"[RENAMED FILE] {old_path} -> {new_path}")
        # Rename directories
        for name in dirs:
            old_path = os.path.join(root, name)
            new_name = name
            for pattern, repl in replacements_content.items():
                new_name = re.sub(pattern, repl, new_name, flags=re.IGNORECASE)
            if new_name != name:
                new_path = os.path.join(root, new_name)
                os.rename(old_path, new_path)
                print(f"[RENAMED DIR] {old_path} -> {new_path}")

# -----------------------------
# Function: Delete images
# -----------------------------
def delete_images():
    for root, dirs, files in os.walk(project_root):
        for name in files:
            if name.lower().endswith(image_exts):
                path = os.path.join(root, name)
                os.remove(path)
                print(f"[DELETED IMAGE] {path}")

# -----------------------------
# Main Execution
# -----------------------------
def main():
    print("Replacing content inside files...")
    for root, dirs, files in os.walk(project_root):
        for name in files:
            if not name.lower().endswith(image_exts):
                replace_in_file(os.path.join(root, name))

    print("Renaming files and directories...")
    rename_paths()

    print("Deleting image files...")
    delete_images()

    print("\n✅ All done! Check the project for replacements and renames.")

if __name__ == "__main__":
    main()

