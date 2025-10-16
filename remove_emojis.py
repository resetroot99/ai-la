#!/usr/bin/env python3
import re
import sys
from pathlib import Path

def remove_emojis(text):
    """Remove all emojis from text"""
    # Comprehensive emoji pattern
    emoji_pattern = re.compile("["
        u"\U0001F600-\U0001F64F"  # emoticons
        u"\U0001F300-\U0001F5FF"  # symbols & pictographs
        u"\U0001F680-\U0001F6FF"  # transport & map symbols
        u"\U0001F1E0-\U0001F1FF"  # flags
        u"\U00002702-\U000027B0"
        u"\U000024C2-\U0001F251"
        u"\U0001F900-\U0001F9FF"  # supplemental symbols
        u"\U0001FA00-\U0001FAFF"
        "]+", flags=re.UNICODE)
    return emoji_pattern.sub('', text)

def clean_file(filepath):
    """Remove emojis from a file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        cleaned = remove_emojis(content)
        
        if cleaned != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            print(f"Cleaned: {filepath}")
            return True
        return False
    except Exception as e:
        print(f"Error cleaning {filepath}: {e}")
        return False

# Find and clean all Python and Markdown files
root = Path('.')
count = 0

for pattern in ['**/*.py', '**/*.md']:
    for filepath in root.glob(pattern):
        if '.git' not in str(filepath) and '__pycache__' not in str(filepath):
            if clean_file(filepath):
                count += 1

print(f"\nCleaned {count} files")
