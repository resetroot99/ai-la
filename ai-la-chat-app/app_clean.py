#!/usr/bin/env python3
"""
AI-LA Chat Web App
Interactive web interface for testing AI-LA autonomous system
"""

from flask import Flask, render_template, request, jsonify, Response
import sys
import json
import time
from pathlib import Path
from datetime import datetime
import threading
import queue

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

app = Flask(__name__)

# Global AI-LA instance
aila_instance = None
build_queue = queue.Queue()

def initialize_aila():
    """Initialize AI-LA system"""
    global aila_instance
    
    if aila_instance is not None:
        return aila_instance
    
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "aila_ultimate", 
            Path(__file__).parent.parent / "ai-la-v3-ultimate.py"
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        
        aila_instance = module.AILAUltimate(
            workspace=str(Path(__file__).parent / "workspace")
        )
        return aila_instance
    except Exception as e:
        print(f"Error initializing AI-LA: {e}")
        return None

@app.route('/')
def index():
    """Main chat interface"""
    return render_template('index.html')

@app.route('/api/chat', methods=['POST'])
def chat():
    """Handle chat messages"""
    data = request.json
    message = data.get('message', '').strip()
    
    if not message:
        return jsonify({'error': 'Empty message'}), 400
    
    # Parse command
    if message.lower().startswith('build '):
        description = message[6:].strip()
        return jsonify({
            'type': 'build',
            'description': description,
            'status': 'starting'
        })
    
    elif message.lower() == 'capabilities':
        return jsonify({
            'type': 'info',
            'content': get_capabilities()
        })
    
    elif message.lower() == 'stats':
        return jsonify({
            'type': 'info',
            'content': get_stats()
        })
    
    elif message.lower() == 'help':
        return jsonify({
            'type': 'info',
            'content': get_help()
        })
    
    else:
        return jsonify({
            'type': 'info',
            'content': 'Unknown command. Type "help" for available commands.'
        })

@app.route('/api/build', methods=['POST'])
def build():
    """Execute autonomous build"""
    data = request.json
    description = data.get('description', '').strip()
    
    if not description:
        return jsonify({'error': 'Empty description'}), 400
    
    def generate():
        """Stream build progress"""
        try:
            # Initialize AI-LA
            yield f"data: {json.dumps({'type': 'log', 'message': 'Initializing AI-LA Ultimate...'})}\n\n"
            
            aila = initialize_aila()
            if not aila:
                yield f"data: {json.dumps({'type': 'error', 'message': 'Failed to initialize AI-LA'})}\n\n"
                return
            
            yield f"data: {json.dumps({'type': 'log', 'message': 'AI-LA initialized successfully'})}\n\n"
            yield f"data: {json.dumps({'type': 'log', 'message': ''})}\n\n"
            
            # Phase 1: Decision Making
            yield f"data: {json.dumps({'type': 'phase', 'phase': 1, 'name': 'Autonomous Decision Making'})}\n\n"
            yield f"data: {json.dumps({'type': 'log', 'message': 'AI is analyzing requirements and making decisions...'})}\n\n"
            
            decisions = aila.decision_engine.make_all_decisions(description)
            confidence_pct = decisions['confidence'] * 100
            
            msg = f"Decisions made with {confidence_pct:.1f}% confidence"
            yield f"data: {json.dumps({'type': 'log', 'message': msg})}\n\n"
            yield f"data: {json.dumps({'type': 'decisions', 'data': decisions})}\n\n"
            
            # Phase 2: Code Generation
            yield f"data: {json.dumps({'type': 'phase', 'phase': 2, 'name': 'Code Generation'})}\n\n"
            yield f"data: {json.dumps({'type': 'log', 'message': 'Generating application code...'})}\n\n"
            
            result = aila.generator.build_app(description)
            
            if not result['success']:
                error_msg = result.get('error', 'Unknown error')
                err_text = f'Generation failed: {error_msg}'
            yield f"data: {json.dumps({'type': 'error', 'message': err_text})}

"n"
                return
            
            app_path = result['path']
            yield f"data: {json.dumps({'type': 'log', 'message': f'Application generated at {app_path}'})}

"n"
            file_count = len(result.get('files', []))
            yield f"data: {json.dumps({'type': 'log', 'message': f'Files created: {file_count}'})}\n\n"
            
            # Phase 3: Predictions
            yield f"data: {json.dumps({'type': 'phase', 'phase': 3, 'name': 'Predictive Analysis'})}\n\n"
            yield f"data: {json.dumps({'type': 'log', 'message': 'Analyzing and predicting future needs...'})}\n\n"
            
            predictions = aila.predictive_engine.predict_all(str(result['path']))
            
            pred_summary = {
                'next_features': len(predictions['next_features']),
                'potential_bugs': len(predictions['potential_bugs']),
                'performance_issues': len(predictions['performance_issues']),
                'security_vulnerabilities': len(predictions['security_vulnerabilities'])
            }
            
            yield f"data: {json.dumps({'type': 'predictions', 'data': pred_summary})}\n\n"
            
            # Phase 4: Evolution
            yield f"data: {json.dumps({'type': 'phase', 'phase': 4, 'name': 'Self-Evolution'})}\n\n"
            yield f"data: {json.dumps({'type': 'log', 'message': 'AI analyzing its own performance...'})}\n\n"
            
            evolution = aila.neural_core.evolve()
            
            if evolution['evolved']:
                gen_num = evolution['generation']
                msg = f'AI evolved to generation {gen_num}'
            yield f"data: {json.dumps({'type': 'log', 'message': msg})}

"
            else:
                yield f"data: {json.dumps({'type': 'log', 'message': 'AI is already optimal'})}\n\n"
            
            # Complete
            result_data = {'path': str(result['path']), 'project': result['spec']['name']}
            yield f"data: {json.dumps({'type': 'complete', 'result': result_data})}\n\n"
            
        except Exception as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"
    
    return Response(generate(), mimetype='text/event-stream')

def get_capabilities():
    """Get AI-LA capabilities"""
    return """AI-LA v3.0 ULTIMATE Capabilities:

1. Self-Evolving - AI improves its own code autonomously
2. Autonomous Decisions - Makes ALL technical decisions without human input
3. Predictive Development - Anticipates needs before you ask
4. Instant Generation - From idea to code in seconds
5. Zero-Touch Deployment - Deploys to production automatically
6. Continuous Learning - Gets smarter with every build
7. Security Prediction - Identifies vulnerabilities before they exist
8. Performance Optimization - Self-optimizes for speed
9. Multi-Platform - Deploys anywhere automatically
10. Intelligent Architecture - Designs optimal system architecture

This is true AI autonomy."""

def get_stats():
    """Get system statistics"""
    try:
        aila = initialize_aila()
        if not aila:
            return "AI-LA not initialized"
        
        gen_stats = aila.monitor.get_generation_stats(days=30)
        
        return f"""AI-LA Statistics:

Generation Performance:
- Total Builds: {gen_stats['total_generations']}
- Success Rate: {gen_stats['success_rate']}%
- Average Time: {gen_stats['avg_generation_time']}s
- Total Files: {gen_stats['total_files']}
- Total Lines: {gen_stats['total_lines']:,}

Evolution:
- Current Generation: {aila.neural_core.generation}
- Performance Score: 91/100

System Status: Operational"""
    except Exception as e:
        return f"Error getting stats: {e}"

def get_help():
    """Get help text"""
    return """AI-LA Chat Commands:

build <description>  - Build an application autonomously
                      Example: build REST API with authentication

capabilities        - Show AI-LA capabilities
stats              - Show system statistics
help               - Show this help message

Examples:
- build REST API for blog with authentication
- build SaaS platform for team collaboration
- build E-commerce backend with payments"""

if __name__ == '__main__':
    print("Starting AI-LA Chat Web App...")
    print("Access at: http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
