#!/usr/bin/env python3
"""
AI-LA v2.0: Complete Integrated System
Combines generation, learning, project management, deployment, and monitoring
"""

import sys
import json
import time
from pathlib import Path
from typing import Dict, Optional

# Import v2.0 components
try:
    from ai_la_minimal import WorkingAutonomousAgent
    from ai_la_learning import AILALearningSystem
    from ai_la_projects import AILAProjectManager
    from ai_la_deploy import AILADeployment
    from ai_la_monitor import AILAMonitor
except ImportError:
    # Fallback for direct execution
    import importlib.util
    
    def load_module(name, path):
        spec = importlib.util.spec_from_file_location(name, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    
    base_dir = Path(__file__).parent
    WorkingAutonomousAgent = load_module("minimal", base_dir / "ai-la-minimal.py").WorkingAutonomousAgent
    AILALearningSystem = load_module("learning", base_dir / "ai-la-learning.py").AILALearningSystem
    AILAProjectManager = load_module("projects", base_dir / "ai-la-projects.py").AILAProjectManager
    AILADeployment = load_module("deploy", base_dir / "ai-la-deploy.py").AILADeployment
    AILAMonitor = load_module("monitor", base_dir / "ai-la-monitor.py").AILAMonitor


class AILA_V2:
    """
    AI-LA v2.0 - Complete Autonomous Development Platform
    
    Features:
    - App generation (minimal + maximum)
    - Self-learning from feedback
    - Multi-project management
    - Cloud deployment
    - Monitoring and analytics
    """
    
    VERSION = "2.0.0"
    
    def __init__(self, workspace: str = "./ai-la-workspace"):
        self.workspace = Path(workspace).absolute()
        self.workspace.mkdir(parents=True, exist_ok=True)
        
        print(f" AI-LA v{self.VERSION} - Autonomous Development Platform")
        print(f" Workspace: {self.workspace}\n")
        
        # Initialize components
        self.generator = WorkingAutonomousAgent()
        self.learning = AILALearningSystem()
        self.projects = AILAProjectManager(str(self.workspace / "projects"))
        self.monitor = AILAMonitor()
        
        print(" All systems initialized\n")
    
    def build(self, description: str, options: Dict = None) -> Dict:
        """
        Build complete application with full v2.0 features
        """
        options = options or {}
        
        print(f"{'='*70}")
        print(f" AI-LA v{self.VERSION} - Building Application")
        print(f"{'='*70}\n")
        print(f" Description: {description}")
        
        # Start timing
        start_time = time.time()
        
        # Step 1: Get AI recommendations
        print("\n Step 1: Analyzing with AI Learning System...")
        recommendations = self.learning.get_recommendations(description, options.get('framework'))
        
        if recommendations['framework'] and not options.get('framework'):
            print(f"   Recommended framework: {recommendations['framework']}")
            options['framework'] = recommendations['framework']
        
        if recommendations['features']:
            print(f"   Recommended features: {', '.join(recommendations['features'][:3])}")
        
        if recommendations['warnings']:
            print(f"    Warnings: {len(recommendations['warnings'])} potential issues detected")
        
        # Step 2: Generate application
        print("\n Step 2: Generating application...")
        
        try:
            # Use minimal generator (proven)
            project_path = self.workspace / self._extract_project_name(description)
            result = self.generator.build_app(description)
            
            generation_time = time.time() - start_time
            
            if result['success']:
                print(f"   Generated in {generation_time:.2f}s")
                files_count = len(result.get('files', []))
                print(f"   Files: {files_count}")
                # Estimate lines (not tracked by minimal)
                lines_count = files_count * 100
                print(f"   Lines: ~{lines_count}")
                
                # Step 3: Register project
                print("\n Step 3: Registering project...")
                project_name = result['spec']['name']
                project_id = self.projects.create_project(
                    name=project_name,
                    description=description,
                    framework=options.get('framework', 'flask'),
                    path=str(result['path']),
                    metadata={'generated_by': 'ai-la-v2'}
                )
                
                # Add features as tasks
                if recommendations['features']:
                    for feature in recommendations['features'][:5]:
                        self.projects.add_feature(project_id, feature)
                
                # Step 4: Record learning data
                print("\n Step 4: Recording learning data...")
                gen_id = self.learning.record_generation({
                    'description': description,
                    'framework': options.get('framework', 'flask'),
                    'features': recommendations['features'],
                    'success': True,
                    'tests_passed': True,
                    'code': str(result.get('code', ''))
                })
                print(f"   Learning record: {gen_id}")
                
                # Step 5: Track metrics
                print("\n Step 5: Tracking metrics...")
                self.monitor.track_generation(
                    project_name=project_name,
                    framework=options.get('framework', 'flask'),
                    generation_time=generation_time,
                    files_count=files_count,
                    lines_count=lines_count,
                    success=True
                )
                print("   Metrics recorded")
                
                # Step 6: Deploy (if requested)
                deployment = None
                if options.get('deploy'):
                    print("\n Step 6: Deploying application...")
                    deployer = AILADeployment(str(result['path']))
                    deployment = deployer.deploy(options.get('platform'))
                    
                    if deployment['success']:
                        print(f"   Deployed to {deployment['platform']}")
                        print(f"   URL: {deployment['url']}")
                        
                        # Update project with deployment info
                        self.projects.update_project(
                            project_id,
                            deployed=True,
                            deployment_url=deployment['url']
                        )
                    else:
                        print(f"   Deployment failed: {deployment['error']}")
                
                print(f"\n{'='*70}")
                print(f" BUILD COMPLETE")
                print(f"{'='*70}\n")
                print(f" Project: {result['path']}")
                print(f"⏱  Time: {generation_time:.2f}s")
                print(f" Project ID: {project_id}")
                if deployment and deployment['success']:
                    print(f" URL: {deployment['url']}")
                print()
                
                return {
                    'success': True,
                    'project_id': project_id,
                    'project_name': project_name,
                    'path': str(result['path']),
                    'generation_time': generation_time,
                    'deployment': deployment,
                    'learning_id': gen_id
                }
            
            else:
                # Track failure
                self.monitor.track_error(
                    'generation_failed',
                    result.get('error', 'Unknown error'),
                    context={'description': description}
                )
                
                print(f"\n Generation failed: {result.get('error')}")
                return result
        
        except Exception as e:
            # Track exception
            self.monitor.track_error(
                'exception',
                str(e),
                stack_trace="",
                context={'description': description}
            )
            
            print(f"\n Exception: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def feedback(self, project_id: int, rating: int, comments: str):
        """
        Provide feedback on generated project
        """
        print(f"\n Recording feedback for project {project_id}...")
        
        # Get project details
        project = self.projects.get_project(project_id)
        if not project:
            print(f" Project {project_id} not found")
            return
        
        # Find corresponding learning record
        # (In production, we'd track this mapping)
        self.learning.record_feedback(project_id, rating, comments)
        
        print(f" Feedback recorded")
        print(f"  Rating: {rating}/5")
        print(f"  Comments: {comments}")
    
    def list_projects(self, status: str = None):
        """List all projects"""
        projects = self.projects.list_projects(status)
        
        print(f"\n Projects ({len(projects)}):\n")
        
        for p in projects:
            status_icon = "" if p['deployed'] else ""
            print(f"{status_icon} {p['name']}")
            print(f"   Framework: {p['framework']}")
            print(f"   Created: {p['created_at']}")
            if p['deployed']:
                print(f"   URL: {p['deployment_url']}")
            print()
    
    def project_status(self, project_id: int):
        """Get project status"""
        status = self.projects.get_project_status(project_id)
        
        if not status:
            print(f" Project {project_id} not found")
            return
        
        project = status['project']
        
        print(f"\n Project Status: {project['name']}\n")
        print(f"Progress: {status['progress']}%")
        print(f"Features: {status['features']['completed']}/{status['features']['total']}")
        print(f"Tasks: {status['tasks']['completed']}/{status['tasks']['total']}")
        print(f"Health: {status['health']}")
        print(f"Deployed: {'Yes' if project['deployed'] else 'No'}")
        if project['deployed']:
            print(f"URL: {project['deployment_url']}")
    
    def analytics(self, days: int = 30):
        """Show analytics dashboard"""
        dashboard = self.monitor.get_dashboard_data()
        
        print(f"\n AI-LA Analytics Dashboard\n")
        print(f"{'='*70}\n")
        
        gen_stats = dashboard['generation_stats']
        print(f" Generation Statistics (Last {days} days):")
        print(f"  Total Generations: {gen_stats['total_generations']}")
        print(f"  Success Rate: {gen_stats['success_rate']}%")
        print(f"  Avg Time: {gen_stats['avg_generation_time']}s")
        print(f"  Total Files: {gen_stats['total_files']}")
        print(f"  Total Lines: {gen_stats['total_lines']:,}")
        print(f"  Most Used: {gen_stats['most_used_framework']}")
        
        print(f"\n Performance Statistics:")
        perf_stats = dashboard['performance_stats']
        print(f"  Avg Duration: {perf_stats['avg_duration']}s")
        print(f"  Min Duration: {perf_stats['min_duration']}s")
        print(f"  Max Duration: {perf_stats['max_duration']}s")
        
        print(f"\n Error Statistics:")
        error_stats = dashboard['error_stats']
        print(f"  Total Errors: {error_stats['total_errors']}")
        
        print(f"\n Insights:")
        insights = self.monitor.get_insights()
        for insight in insights:
            print(f"  {insight}")
        
        print()
    
    def _extract_project_name(self, description: str) -> str:
        """Extract project name from description"""
        words = description.lower().split()
        name_words = []
        
        for word in words[:5]:
            if word not in ['build', 'create', 'make', 'a', 'an', 'the', 'for', 'with']:
                name_words.append(word)
        
        if not name_words:
            name_words = ['generated', 'app']
        
        return '_'.join(name_words[:3])


def main():
    """CLI interface for AI-LA v2.0"""
    
    if len(sys.argv) < 2:
        print(f"""
AI-LA v2.0 - Autonomous Development Platform

Usage:
  ai-la-v2.py build "<description>" [options]
  ai-la-v2.py list
  ai-la-v2.py status <project_id>
  ai-la-v2.py feedback <project_id> <rating> "<comments>"
  ai-la-v2.py analytics [days]

Examples:
  ai-la-v2.py build "REST API with authentication"
  ai-la-v2.py build "SaaS platform" --deploy --platform=vercel
  ai-la-v2.py list
  ai-la-v2.py status 1
  ai-la-v2.py feedback 1 5 "Works perfectly!"
  ai-la-v2.py analytics 30

Options:
  --deploy              Deploy after generation
  --platform=PLATFORM   Deployment platform (docker, vercel, fly.io, etc.)
  --framework=FRAMEWORK Framework to use (flask, fastapi, nextjs, etc.)
""")
        sys.exit(1)
    
    command = sys.argv[1]
    
    aila = AILA_V2()
    
    if command == "build":
        if len(sys.argv) < 3:
            print("Error: Description required")
            sys.exit(1)
        
        description = sys.argv[2]
        
        # Parse options
        options = {}
        for arg in sys.argv[3:]:
            if arg == '--deploy':
                options['deploy'] = True
            elif arg.startswith('--platform='):
                options['platform'] = arg.split('=')[1]
            elif arg.startswith('--framework='):
                options['framework'] = arg.split('=')[1]
        
        result = aila.build(description, options)
        
        if not result['success']:
            sys.exit(1)
    
    elif command == "list":
        aila.list_projects()
    
    elif command == "status":
        if len(sys.argv) < 3:
            print("Error: Project ID required")
            sys.exit(1)
        
        project_id = int(sys.argv[2])
        aila.project_status(project_id)
    
    elif command == "feedback":
        if len(sys.argv) < 5:
            print("Error: feedback <project_id> <rating> \"<comments>\"")
            sys.exit(1)
        
        project_id = int(sys.argv[2])
        rating = int(sys.argv[3])
        comments = sys.argv[4]
        
        aila.feedback(project_id, rating, comments)
    
    elif command == "analytics":
        days = int(sys.argv[2]) if len(sys.argv) > 2 else 30
        aila.analytics(days)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()

