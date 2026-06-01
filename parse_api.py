import json

with open('api-docs.json', 'r') as f:
    data = json.load(f)

print("API Endpoints:")
for path, methods in data.get('paths', {}).items():
    for method, details in methods.items():
        summary = details.get('summary', 'No summary')
        tags = details.get('tags', [])
        print(f"[{method.upper()}] {path} - {summary} (Tags: {tags})")
