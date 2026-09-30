import re

file_path = r'c:\Projects\Ketion\test\features\sync\integration\sync_engine_integration_test.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# We look for:
# 'operation': '...',
# 'payload': {
# ...
# }
# and if 'version' and 'updatedAt' are inside payload but not outside, we add them outside.

pattern = re.compile(r"('operation':\s*'[^']+',\s*)('payload':\s*\{\s*[^}]*?('version':\s*\d+,)\s*[^}]*?('updatedAt':\s*DateTime\.now\(\)\.toIso8601String\(\),)\s*[^}]*\},\s*)", re.DOTALL)

def replacer(match):
    operation = match.group(1)
    payload = match.group(2)
    version = match.group(3)
    updatedAt = match.group(4)
    return f"{operation}{version}\n          {updatedAt}\n          {payload}"

new_content = pattern.sub(replacer, content)

# There's also the skew case:
# 'version': 3,
# 'createdAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
# 'updatedAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
pattern2 = re.compile(r"('operation':\s*'[^']+',\s*)('payload':\s*\{\s*[^}]*?('version':\s*\d+,)\s*[^}]*?('updatedAt':\s*now\.subtract\(const Duration\(minutes: \d+\)\)\.toIso8601String\(\),)\s*[^}]*\},\s*)", re.DOTALL)
new_content = pattern2.sub(replacer, new_content)

# There is also the test: test('Multi-entity batch is atomic on error' which has valid and invalid payloads.
# And 'Cursor safety: Cursor is not advanced if batch application fails'
# And 'Validation: payload.id must match change.id'

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Patched.")
