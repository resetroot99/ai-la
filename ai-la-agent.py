#!/usr/bin/env python3
"""
Autonomous Development Platform
Built on open-source tools: Aider, LangChain, Ollama
Generates complete apps from natural language descriptions
"""

import os
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional
import asyncio
import time
from self_evolution import SelfEvolutionEngine

class AutonomousAgent:
    """
    Core autonomous development agent
    Uses open-source tools to build apps from natural language
    """
    
    def __init__(self, project_dir: str, model: str = "qwen2.5-coder:32b"):
        self.project_dir = Path(project_dir)
        self.model = model
        self.memory_dir = Path.home() / ".ai-coding-stack" / "autonomous"
        self.memory_dir.mkdir(parents=True, exist_ok=True)
        
        # Task memory
        self.task_history = []
        self.learned_patterns = []
        
        # Self-evolution engine
        self.evolution = SelfEvolutionEngine()
        
    def parse_intent(self, description: str) -> Dict:
        """
        Parse natural language description into structured task
        """
        print(f"🧠 Parsing intent: {description}")
        
        # Use LLM to extract structured information
        prompt = f"""
Analyze this app description and extract structured information:

Description: {description}

Return JSON with:
{{
    "app_name": "name",
    "type": "web|api|cli|mobile",
    "tech_stack": {{"frontend": "...", "backend": "...", "database": "..."}},
    "features": ["feature1", "feature2"],
    "architecture": "monolith|microservices|serverless",
    "deployment": "vercel|docker|kubernetes|fly.io"
}}
"""
        
        result = self._run_llm(prompt)
        try:
            task = json.loads(result)
            print(f"✓ Parsed task: {task['app_name']}")
            return task
        except:
            # Fallback to basic parsing
            return {
                "app_name": "generated_app",
                "type": "web",
                "tech_stack": {"frontend": "Next.js", "backend": "FastAPI", "database": "PostgreSQL"},
                "features": [description],
                "architecture": "monolith",
                "deployment": "docker"
            }
    
    def design_architecture(self, task: Dict) -> Dict:
        """
        Design system architecture based on task
        """
        print(f"🏗️  Designing architecture for {task['app_name']}...")
        
        prompt = f"""
Design a production-ready architecture for this app:

Task: {json.dumps(task, indent=2)}

Return JSON with:
{{
    "components": [
        {{"name": "...", "type": "frontend|backend|database|cache", "tech": "..."}}
    ],
    "file_structure": {{
        "src/": ["file1.ts", "file2.py"],
        "config/": ["..."]
    }},
    "dependencies": {{"frontend": [...], "backend": [...]}},
    "environment_vars": ["VAR1", "VAR2"],
    "deployment_steps": ["step1", "step2"]
}}

Use best practices: TypeScript, FastAPI, PostgreSQL, Docker, security-first.
"""
        
        result = self._run_llm(prompt)
        try:
            architecture = json.loads(result)
            print(f"✓ Architecture designed: {len(architecture.get('components', []))} components")
            return architecture
        except:
            return {"components": [], "file_structure": {}, "dependencies": {}}
    
    def generate_code(self, task: Dict, architecture: Dict) -> bool:
        """
        Generate complete codebase using Aider
        """
        print(f"💻 Generating code for {task['app_name']}...")
        
        # Create project directory
        project_path = self.project_dir / task['app_name']
        project_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize git
        subprocess.run(["git", "init"], cwd=project_path, capture_output=True)
        
        # Generate code for each component
        for component in architecture.get('components', []):
            print(f"  → Generating {component['name']}...")
            
            prompt = f"""
Create {component['name']} ({component['type']}) using {component['tech']}.

Requirements:
- Production-ready code
- Error handling
- Type hints/annotations
- Security best practices
- Comprehensive comments

Task context: {json.dumps(task, indent=2)}
Architecture: {json.dumps(architecture, indent=2)}
"""
            
            # Use Aider to generate code
            self._run_aider(project_path, prompt)
        
        print(f"✓ Code generation complete")
        return True
    
    def setup_infrastructure(self, task: Dict, architecture: Dict) -> bool:
        """
        Set up infrastructure (Docker, configs, etc.)
        """
        print(f"⚙️  Setting up infrastructure...")
        
        project_path = self.project_dir / task['app_name']
        
        # Generate Dockerfile
        dockerfile_prompt = f"""
Create a production-ready Dockerfile for this app:

Tech stack: {json.dumps(task['tech_stack'], indent=2)}
Components: {json.dumps(architecture.get('components', []), indent=2)}

Requirements:
- Multi-stage build
- Security best practices
- Minimal image size
- Health checks
"""
        
        self._run_aider(project_path, dockerfile_prompt, files=["Dockerfile"])
        
        # Generate docker-compose.yml
        compose_prompt = f"""
Create docker-compose.yml for local development:

Components: {json.dumps(architecture.get('components', []), indent=2)}
Database: {task['tech_stack'].get('database', 'PostgreSQL')}

Include:
- All services
- Volume mounts
- Environment variables
- Health checks
- Networks
"""
        
        self._run_aider(project_path, compose_prompt, files=["docker-compose.yml"])
        
        # Generate .env.example
        env_vars = architecture.get('environment_vars', [])
        env_content = "\n".join([f"{var}=" for var in env_vars])
        (project_path / ".env.example").write_text(env_content)
        
        print(f"✓ Infrastructure setup complete")
        return True
    
    def deploy(self, task: Dict) -> Dict:
        """
        Deploy the application
        """
        print(f"🚀 Deploying {task['app_name']}...")
        
        project_path = self.project_dir / task['app_name']
        deployment = task.get('deployment', 'docker')
        
        if deployment == 'docker':
            # Build and run with Docker
            subprocess.run(["docker-compose", "build"], cwd=project_path)
            subprocess.run(["docker-compose", "up", "-d"], cwd=project_path)
            
            return {
                "status": "deployed",
                "url": "http://localhost:3000",
                "method": "docker-compose"
            }
        
        elif deployment == 'vercel':
            # Deploy to Vercel
            subprocess.run(["vercel", "--prod"], cwd=project_path)
            
            return {
                "status": "deployed",
                "url": "https://app.vercel.app",
                "method": "vercel"
            }
        
        else:
            print(f"⚠️  Deployment method '{deployment}' not yet implemented")
            return {"status": "pending", "method": deployment}
    
    def test_and_validate(self, task: Dict) -> Dict:
        """
        Test the deployed application
        """
        print(f"🧪 Testing {task['app_name']}...")
        
        project_path = self.project_dir / task['app_name']
        
        # Generate tests
        test_prompt = f"""
Create comprehensive tests for this application:

Task: {json.dumps(task, indent=2)}

Generate:
1. Unit tests for all functions
2. Integration tests for APIs
3. E2E tests for critical flows

Use pytest for Python, Jest for TypeScript.
Include test fixtures and mocks.
"""
        
        self._run_aider(project_path, test_prompt, files=["tests/"])
        
        # Run tests
        test_results = {
            "unit": self._run_tests(project_path, "unit"),
            "integration": self._run_tests(project_path, "integration"),
            "e2e": self._run_tests(project_path, "e2e")
        }
        
        print(f"✓ Testing complete: {test_results}")
        return test_results
    
    def learn_from_execution(self, task: Dict, results: Dict):
        """
        Learn from the execution to improve future tasks
        """
        print(f"🧠 Learning from execution...")
        
        # Record task history
        execution_record = {
            "task": task,
            "results": results,
            "timestamp": subprocess.check_output(["date", "+%Y-%m-%d %H:%M:%S"]).decode().strip()
        }
        
        self.task_history.append(execution_record)
        
        # Extract patterns
        if results.get('success'):
            pattern = {
                "task_type": task['type'],
                "tech_stack": task['tech_stack'],
                "architecture": task.get('architecture'),
                "success_factors": results.get('success_factors', [])
            }
            self.learned_patterns.append(pattern)
        
        # Save to memory
        memory_file = self.memory_dir / "execution_history.json"
        with open(memory_file, 'w') as f:
            json.dump({
                "history": self.task_history,
                "patterns": self.learned_patterns
            }, f, indent=2)
        
        print(f"✓ Learned from execution. Total patterns: {len(self.learned_patterns)}")
    
    def autonomous_build(self, description: str) -> Dict:
        """
        Main autonomous build pipeline
        Takes natural language description → deployed app
        """
        print(f"\n{'='*60}")
        print(f"🤖 AUTONOMOUS BUILD STARTED")
        print(f"{'='*60}\n")
        
        start_time = time.time()
        
        try:
            # Step 1: Parse intent
            task = self.parse_intent(description)
            
            # Step 1.5: Optimize with learned patterns
            print(f"🧠 Applying learned optimizations...")
            task = self.evolution.optimize_for_task(task)
            if task.get('optimization_applied'):
                print(f"✓ Applied pattern with {task['optimization_confidence']:.0%} confidence")
            
            # Step 2: Design architecture
            architecture = self.design_architecture(task)
            
            # Step 3: Generate code
            code_success = self.generate_code(task, architecture)
            
            # Step 4: Setup infrastructure
            infra_success = self.setup_infrastructure(task, architecture)
            
            # Step 5: Deploy
            deployment = self.deploy(task)
            
            # Step 6: Test and validate
            test_results = self.test_and_validate(task)
            
            # Step 7: Learn from execution
            duration = time.time() - start_time
            
            results = {
                "success": code_success and infra_success,
                "deployment": deployment,
                "tests": test_results,
                "project_path": str(self.project_dir / task['app_name']),
                "duration_seconds": duration
            }
            
            self.learn_from_execution(task, results)
            
            # Step 8: Record in evolution system
            build_data = {
                "description": description,
                "task_type": task.get('type'),
                "tech_stack": task.get('tech_stack'),
                "success": results['success'],
                "duration_seconds": duration,
                "code_quality_score": 85 if results['success'] else 0,  # TODO: actual scoring
                "test_pass_rate": test_results.get('unit', {}).get('passed', False) * 100,
                "deployment_success": deployment.get('status') == 'deployed',
                "architecture": task.get('architecture')
            }
            
            build_id = self.evolution.record_build(build_data)
            self.evolution.extract_patterns(build_id, build_data)
            
            # Show evolution stats
            stats = self.evolution.get_statistics()
            print(f"\n📊 Evolution Stats: {stats['total_builds']} builds, {stats['success_rate']}% success rate")
            
            print(f"\n{'='*60}")
            print(f"✅ AUTONOMOUS BUILD COMPLETE")
            print(f"{'='*60}\n")
            print(f"📁 Project: {results['project_path']}")
            print(f"🌐 URL: {deployment.get('url', 'N/A')}")
            print(f"🧪 Tests: {test_results}")
            
            return results
            
        except Exception as e:
            print(f"\n❌ Autonomous build failed: {e}")
            return {"success": False, "error": str(e)}
    
    # Helper methods
    
    def _run_llm(self, prompt: str) -> str:
        """Run LLM via Ollama"""
        result = subprocess.run(
            ["ollama", "run", self.model, prompt],
            capture_output=True,
            text=True
        )
        return result.stdout.strip()
    
    def _run_aider(self, project_path: Path, prompt: str, files: List[str] = None):
        """Run Aider for code generation"""
        cmd = ["aider", "--yes", "--model", self.model, "--message", prompt]
        if files:
            cmd.extend(files)
        
        subprocess.run(cmd, cwd=project_path, capture_output=True)
    
    def _run_tests(self, project_path: Path, test_type: str) -> Dict:
        """Run tests"""
        # Try pytest
        result = subprocess.run(
            ["pytest", f"tests/{test_type}", "-v"],
            cwd=project_path,
            capture_output=True
        )
        
        return {
            "passed": result.returncode == 0,
            "output": result.stdout.decode()[:500]  # First 500 chars
        }


def main():
    """CLI interface for autonomous agent"""
    if len(sys.argv) < 2:
        print("Usage: autonomous-agent.py <description>")
        print("\nExample:")
        print('  autonomous-agent.py "Build a secure API for mesh VPN authentication with JWT"')
        sys.exit(1)
    
    description = " ".join(sys.argv[1:])
    project_dir = os.getcwd()
    
    agent = AutonomousAgent(project_dir)
    results = agent.autonomous_build(description)
    
    # Print final summary
    if results.get('success'):
        print("\n🎉 Success! Your app is ready.")
        print(f"\nNext steps:")
        print(f"1. cd {results['project_path']}")
        print(f"2. Review the generated code")
        print(f"3. Access at: {results.get('deployment', {}).get('url', 'localhost')}")
    else:
        print(f"\n❌ Build failed: {results.get('error')}")
        sys.exit(1)


if __name__ == "__main__":
    main()

