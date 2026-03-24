import re, os, glob

BASE = r"C:\Users\shaik\OneDrive\Desktop\tf-modules"

# Remove blank lines that appear inside a provider block like:
#   aws = {
#
#     source  = "hashicorp/aws"
#
#     version = ">= 5.0"
#
#   }
# --> should have no blank lines inside
blank_in_provider = re.compile(
    r'((\w+)\s*=\s*\{)\n(\n[ \t]+source[^\n]+)\n(\n[ \t]+version[^\n]+)\n(\n[ \t]+\})'
)

def clean_blank_lines(content):
    # Remove spurious blank lines inside provider sub-blocks
    # Pattern: line with "key = {", blank, "  source = ...", blank, "  version = ...", blank, "  }"
    fixed = re.sub(
        r'([ \t]*\w[\w ]*=\s*\{)\n\n([ \t]+source[^\n]+)\n\n([ \t]+version[^\n]+)\n\n([ \t]+\})',
        r'\1\n\2\n\3\n\4',
        content
    )
    return fixed

files_fixed = 0
for tf_file in glob.glob(os.path.join(BASE, "**", "*.tf"), recursive=True):
    with open(tf_file, "r", encoding="utf-8") as f:
        original = f.read()
    updated = clean_blank_lines(original)
    if updated != original:
        with open(tf_file, "w", encoding="utf-8") as f:
            f.write(updated)
        files_fixed += 1
        print(f"Cleaned: {tf_file.replace(BASE, '')}")

print(f"\nTotal files cleaned: {files_fixed}")
