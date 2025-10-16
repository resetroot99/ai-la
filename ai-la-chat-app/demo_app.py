#!/usr/bin/env python3
"""
AI-LA Demo App - Shows actual generated code
"""

from flask import Flask, render_template, request, jsonify, send_file
import sys
import os
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

# Import AI-LA minimal
sys.path.insert(0, str(Path(__file__).parent.parent))

def build_app(description):
    """Build app using AI-LA minimal"""
    import subprocess
    import time
    
    start = time.time()
    cmd = ['python3', str(Path(__file__).parent.parent / 'ai-la-minimal.py'), description]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Parse output to get path
    for line in result.stdout.split('\n'):
        if 'COMPLETE:' in line:
            path = line.split('COMPLETE:')[1].strip()
            return {'success': True, 'path': path, 'time': time.time() - start}
    
    return {'success': False, 'error': result.stderr}

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('demo.html')

@app.route('/api/demo/build', methods=['POST'])
def demo_build():
    data = request.json
    description = data.get('description', '').strip()
    
    if not description:
        return jsonify({'error': 'No description provided'}), 400
    
    # Build the app
    result = build_app(description)
    
    if not result['success']:
        return jsonify({'error': 'Build failed'}), 500
    
    # Read generated files
    app_path = Path(result['path'])
    files = []
    total_lines = 0
    test_files = 0
    
    for file_path in app_path.rglob('*.py'):
        if '__pycache__' in str(file_path):
            continue
            
        relative_path = file_path.relative_to(app_path)
        content = file_path.read_text()
        lines = len(content.split('\n'))
        total_lines += lines
        
        if 'test' in file_path.name:
            test_files += 1
        
        files.append({
            'name': str(relative_path),
            'content': content,
            'lines': lines
        })
    
    # Generate file tree
    file_tree = generate_file_tree(app_path)
    
    # Create download zip
    zip_path = create_zip(app_path)
    
    return jsonify({
        'success': True,
        'path': str(app_path),
        'files': files,
        'total_lines': total_lines,
        'test_files': test_files,
        'file_tree': file_tree,
        'download_url': f'/api/demo/download/{Path(zip_path).name}'
    })

@app.route('/api/demo/download/<filename>')
def download(filename):
    zip_path = Path('/tmp') / filename
    if not zip_path.exists():
        return jsonify({'error': 'File not found'}), 404
    return send_file(zip_path, as_attachment=True)

def generate_file_tree(path):
    """Generate ASCII file tree"""
    lines = []
    lines.append(path.name + '/')
    
    for item in sorted(path.iterdir()):
        if item.name.startswith('.') or item.name == '__pycache__':
            continue
        if item.is_file():
            lines.append(f'├── {item.name}')
    
    return '\n'.join(lines)

def create_zip(app_path):
    """Create zip file of generated app"""
    zip_path = Path('/tmp') / f'{app_path.name}.zip'
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in app_path.rglob('*'):
            if '__pycache__' in str(file_path) or file_path.is_dir():
                continue
            arcname = file_path.relative_to(app_path.parent)
            zipf.write(file_path, arcname)
    
    return str(zip_path)

if __name__ == '__main__':
    print("AI-LA Demo App")
    print("Shows actual generated code and files")
    print("http://localhost:5002")
    app.run(debug=False, host='0.0.0.0', port=5002)

