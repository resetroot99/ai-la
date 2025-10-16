#!/usr/bin/env python3
"""
AI-LA v2.0: Cloud Deployment Integration
Deploys applications to AWS, GCP, Vercel, Fly.io, and more
"""

import json
import subprocess
import os
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

class AILADeployment:
    """
    Multi-cloud deployment system
    Supports AWS, GCP, Vercel, Fly.io, Docker, Kubernetes
    """
    
    SUPPORTED_PLATFORMS = [
        'docker',
        'vercel',
        'fly.io',
        'aws-lambda',
        'aws-ecs',
        'gcp-cloud-run',
        'kubernetes',
        'heroku'
    ]
    
    def __init__(self, project_path: str):
        self.project_path = Path(project_path).absolute()
        self.deployment_config = self.project_path / ".ai-la-deploy.json"
        self.load_config()
    
    def load_config(self):
        """Load deployment configuration"""
        if self.deployment_config.exists():
            self.config = json.loads(self.deployment_config.read_text())
        else:
            self.config = {
                'platform': None,
                'deployments': [],
                'environment': {}
            }
    
    def save_config(self):
        """Save deployment configuration"""
        self.deployment_config.write_text(json.dumps(self.config, indent=2))
    
    def detect_framework(self) -> str:
        """Auto-detect project framework"""
        if (self.project_path / "package.json").exists():
            pkg = json.loads((self.project_path / "package.json").read_text())
            if "next" in pkg.get("dependencies", {}):
                return "nextjs"
            elif "react" in pkg.get("dependencies", {}):
                return "react"
            else:
                return "node"
        elif (self.project_path / "requirements.txt").exists():
            reqs = (self.project_path / "requirements.txt").read_text()
            if "fastapi" in reqs:
                return "fastapi"
            elif "flask" in reqs:
                return "flask"
            elif "django" in reqs:
                return "django"
            else:
                return "python"
        else:
            return "unknown"
    
    def recommend_platform(self, framework: str) -> str:
        """Recommend deployment platform based on framework"""
        recommendations = {
            'nextjs': 'vercel',
            'react': 'vercel',
            'flask': 'fly.io',
            'fastapi': 'fly.io',
            'django': 'aws-ecs',
            'node': 'fly.io'
        }
        return recommendations.get(framework, 'docker')
    
    def generate_dockerfile(self, framework: str) -> str:
        """Generate optimized Dockerfile"""
        dockerfiles = {
            'flask': '''FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "app.py"]
''',
            'fastapi': '''FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
''',
            'nextjs': '''FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:18-alpine AS runner

WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

CMD ["npm", "start"]
''',
            'node': '''FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "index.js"]
'''
        }
        
        return dockerfiles.get(framework, dockerfiles['flask'])
    
    def generate_docker_compose(self, framework: str) -> str:
        """Generate docker-compose.yml"""
        if framework in ['flask', 'fastapi', 'django']:
            return '''version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/app
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=app
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
'''
        else:
            return '''version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
'''
    
    def deploy_docker(self) -> Dict:
        """Deploy using Docker"""
        print("🐳 Deploying with Docker...")
        
        framework = self.detect_framework()
        
        # Generate Dockerfile if not exists
        dockerfile = self.project_path / "Dockerfile"
        if not dockerfile.exists():
            dockerfile.write_text(self.generate_dockerfile(framework))
            print("✓ Generated Dockerfile")
        
        # Generate docker-compose.yml
        compose_file = self.project_path / "docker-compose.yml"
        if not compose_file.exists():
            compose_file.write_text(self.generate_docker_compose(framework))
            print("✓ Generated docker-compose.yml")
        
        # Build image
        result = subprocess.run(
            ['docker', 'build', '-t', f'ai-la-{self.project_path.name}', '.'],
            cwd=self.project_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✓ Docker image built successfully")
            
            # Start containers
            result = subprocess.run(
                ['docker-compose', 'up', '-d'],
                cwd=self.project_path,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print("✓ Containers started")
                
                return {
                    'success': True,
                    'platform': 'docker',
                    'url': 'http://localhost:8000',
                    'deployed_at': datetime.now().isoformat()
                }
        
        return {
            'success': False,
            'error': result.stderr
        }
    
    def deploy_vercel(self) -> Dict:
        """Deploy to Vercel"""
        print("▲ Deploying to Vercel...")
        
        # Check if vercel CLI is installed
        result = subprocess.run(['which', 'vercel'], capture_output=True)
        if result.returncode != 0:
            return {
                'success': False,
                'error': 'Vercel CLI not installed. Run: npm i -g vercel'
            }
        
        # Deploy
        result = subprocess.run(
            ['vercel', '--prod', '--yes'],
            cwd=self.project_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            # Extract URL from output
            url = None
            for line in result.stdout.split('\n'):
                if 'https://' in line:
                    url = line.strip()
                    break
            
            print(f"✓ Deployed to Vercel: {url}")
            
            return {
                'success': True,
                'platform': 'vercel',
                'url': url,
                'deployed_at': datetime.now().isoformat()
            }
        
        return {
            'success': False,
            'error': result.stderr
        }
    
    def deploy_flyio(self) -> Dict:
        """Deploy to Fly.io"""
        print("🚀 Deploying to Fly.io...")
        
        # Check if flyctl is installed
        result = subprocess.run(['which', 'flyctl'], capture_output=True)
        if result.returncode != 0:
            return {
                'success': False,
                'error': 'Fly.io CLI not installed. Visit: https://fly.io/docs/hands-on/install-flyctl/'
            }
        
        # Generate fly.toml if not exists
        fly_config = self.project_path / "fly.toml"
        if not fly_config.exists():
            framework = self.detect_framework()
            port = 8000 if framework in ['flask', 'fastapi'] else 3000
            
            config = f'''app = "ai-la-{self.project_path.name}"
primary_region = "sjc"

[build]

[http_service]
  internal_port = {port}
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 256
'''
            fly_config.write_text(config)
            print("✓ Generated fly.toml")
        
        # Launch app
        result = subprocess.run(
            ['flyctl', 'launch', '--yes'],
            cwd=self.project_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            # Deploy
            result = subprocess.run(
                ['flyctl', 'deploy'],
                cwd=self.project_path,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                url = f"https://ai-la-{self.project_path.name}.fly.dev"
                print(f"✓ Deployed to Fly.io: {url}")
                
                return {
                    'success': True,
                    'platform': 'fly.io',
                    'url': url,
                    'deployed_at': datetime.now().isoformat()
                }
        
        return {
            'success': False,
            'error': result.stderr
        }
    
    def deploy_kubernetes(self) -> Dict:
        """Deploy to Kubernetes"""
        print("☸️  Deploying to Kubernetes...")
        
        framework = self.detect_framework()
        app_name = self.project_path.name
        
        # Generate Kubernetes manifests
        k8s_dir = self.project_path / "k8s"
        k8s_dir.mkdir(exist_ok=True)
        
        # Deployment manifest
        deployment = f'''apiVersion: apps/v1
kind: Deployment
metadata:
  name: {app_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: {app_name}
  template:
    metadata:
      labels:
        app: {app_name}
    spec:
      containers:
      - name: {app_name}
        image: {app_name}:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: {app_name}-secrets
              key: database-url
'''
        (k8s_dir / "deployment.yaml").write_text(deployment)
        
        # Service manifest
        service = f'''apiVersion: v1
kind: Service
metadata:
  name: {app_name}
spec:
  selector:
    app: {app_name}
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
'''
        (k8s_dir / "service.yaml").write_text(service)
        
        print("✓ Generated Kubernetes manifests")
        
        # Apply manifests
        result = subprocess.run(
            ['kubectl', 'apply', '-f', 'k8s/'],
            cwd=self.project_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✓ Deployed to Kubernetes")
            
            return {
                'success': True,
                'platform': 'kubernetes',
                'url': 'Check kubectl get svc for LoadBalancer IP',
                'deployed_at': datetime.now().isoformat()
            }
        
        return {
            'success': False,
            'error': result.stderr
        }
    
    def deploy(self, platform: str = None) -> Dict:
        """
        Deploy to specified platform or auto-detect best platform
        """
        if not platform:
            framework = self.detect_framework()
            platform = self.recommend_platform(framework)
            print(f"Auto-detected framework: {framework}")
            print(f"Recommended platform: {platform}")
        
        # Validate platform
        if platform not in self.SUPPORTED_PLATFORMS:
            return {
                'success': False,
                'error': f'Unsupported platform: {platform}. Supported: {", ".join(self.SUPPORTED_PLATFORMS)}'
            }
        
        # Deploy to platform
        if platform == 'docker':
            result = self.deploy_docker()
        elif platform == 'vercel':
            result = self.deploy_vercel()
        elif platform == 'fly.io':
            result = self.deploy_flyio()
        elif platform == 'kubernetes':
            result = self.deploy_kubernetes()
        else:
            result = {
                'success': False,
                'error': f'Platform {platform} not yet implemented'
            }
        
        # Save deployment record
        if result['success']:
            self.config['platform'] = platform
            self.config['deployments'].append(result)
            self.save_config()
        
        return result
    
    def get_deployment_status(self) -> Dict:
        """Get current deployment status"""
        if not self.config['deployments']:
            return {
                'deployed': False,
                'message': 'No deployments found'
            }
        
        latest = self.config['deployments'][-1]
        return {
            'deployed': True,
            'platform': latest['platform'],
            'url': latest['url'],
            'deployed_at': latest['deployed_at']
        }


def main():
    """CLI interface for deployment"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: ai-la-deploy.py <project_path> [platform]")
        print(f"\nSupported platforms: {', '.join(AILADeployment.SUPPORTED_PLATFORMS)}")
        sys.exit(1)
    
    project_path = sys.argv[1]
    platform = sys.argv[2] if len(sys.argv) > 2 else None
    
    deployer = AILADeployment(project_path)
    result = deployer.deploy(platform)
    
    if result['success']:
        print(f"\n✅ Deployment successful!")
        print(f"   Platform: {result['platform']}")
        print(f"   URL: {result['url']}")
    else:
        print(f"\n❌ Deployment failed:")
        print(f"   {result['error']}")
        sys.exit(1)


if __name__ == "__main__":
    main()

