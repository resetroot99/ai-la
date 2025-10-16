#!/usr/bin/env python3
"""
AI-LA v2.0: Multi-Project Management System
Manages multiple projects simultaneously with dependencies and relationships
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import subprocess

class AILAProjectManager:
    """
    Multi-project management system
    Handles project lifecycle, dependencies, and relationships
    """
    
    def __init__(self, workspace: str = "~/.ai-la/projects"):
        self.workspace = Path(workspace).expanduser()
        self.workspace.mkdir(parents=True, exist_ok=True)
        
        # Project database
        self.db_path = self.workspace / "projects.db"
        self.db = sqlite3.connect(str(self.db_path))
        self._init_database()
    
    def _init_database(self):
        """Initialize project database schema"""
        c = self.db.cursor()
        
        # Projects table
        c.execute('''
            CREATE TABLE IF NOT EXISTS projects (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                description TEXT,
                path TEXT NOT NULL,
                framework TEXT,
                status TEXT DEFAULT 'active',
                created_at TEXT,
                updated_at TEXT,
                deployed BOOLEAN DEFAULT 0,
                deployment_url TEXT,
                metadata TEXT
            )
        ''')
        
        # Project dependencies
        c.execute('''
            CREATE TABLE IF NOT EXISTS project_dependencies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER,
                depends_on_id INTEGER,
                dependency_type TEXT,
                created_at TEXT,
                FOREIGN KEY (project_id) REFERENCES projects(id),
                FOREIGN KEY (depends_on_id) REFERENCES projects(id)
            )
        ''')
        
        # Project features
        c.execute('''
            CREATE TABLE IF NOT EXISTS project_features (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER,
                feature_name TEXT,
                status TEXT DEFAULT 'pending',
                created_at TEXT,
                completed_at TEXT,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            )
        ''')
        
        # Project tasks
        c.execute('''
            CREATE TABLE IF NOT EXISTS project_tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER,
                task_description TEXT,
                status TEXT DEFAULT 'pending',
                priority INTEGER DEFAULT 1,
                assigned_to TEXT,
                created_at TEXT,
                completed_at TEXT,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            )
        ''')
        
        # Project health metrics
        c.execute('''
            CREATE TABLE IF NOT EXISTS project_health (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER,
                metric_type TEXT,
                metric_value REAL,
                recorded_at TEXT,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            )
        ''')
        
        self.db.commit()
    
    def create_project(self, name: str, description: str, framework: str, 
                      path: str, metadata: Dict = None) -> int:
        """
        Create a new project
        Returns: project_id
        """
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO projects (
                name, description, path, framework, created_at, updated_at, metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (
            name,
            description,
            path,
            framework,
            datetime.now().isoformat(),
            datetime.now().isoformat(),
            json.dumps(metadata or {})
        ))
        
        self.db.commit()
        project_id = c.lastrowid
        
        print(f" Created project: {name} (ID: {project_id})")
        return project_id
    
    def get_project(self, project_id: int = None, name: str = None) -> Optional[Dict]:
        """Get project by ID or name"""
        c = self.db.cursor()
        
        if project_id:
            c.execute('SELECT * FROM projects WHERE id = ?', (project_id,))
        elif name:
            c.execute('SELECT * FROM projects WHERE name = ?', (name,))
        else:
            return None
        
        row = c.fetchone()
        if not row:
            return None
        
        return self._row_to_project(row)
    
    def list_projects(self, status: str = None) -> List[Dict]:
        """List all projects"""
        c = self.db.cursor()
        
        if status:
            c.execute('SELECT * FROM projects WHERE status = ? ORDER BY updated_at DESC', (status,))
        else:
            c.execute('SELECT * FROM projects ORDER BY updated_at DESC')
        
        return [self._row_to_project(row) for row in c.fetchall()]
    
    def update_project(self, project_id: int, **kwargs):
        """Update project fields"""
        c = self.db.cursor()
        
        # Build update query dynamically
        fields = []
        values = []
        
        for key, value in kwargs.items():
            if key in ['name', 'description', 'status', 'deployed', 'deployment_url']:
                fields.append(f"{key} = ?")
                values.append(value)
        
        if not fields:
            return
        
        # Always update updated_at
        fields.append("updated_at = ?")
        values.append(datetime.now().isoformat())
        values.append(project_id)
        
        query = f"UPDATE projects SET {', '.join(fields)} WHERE id = ?"
        c.execute(query, values)
        self.db.commit()
        
        print(f" Updated project {project_id}")
    
    def add_dependency(self, project_id: int, depends_on_id: int, 
                      dependency_type: str = 'requires'):
        """Add dependency between projects"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO project_dependencies (
                project_id, depends_on_id, dependency_type, created_at
            ) VALUES (?, ?, ?, ?)
        ''', (project_id, depends_on_id, dependency_type, datetime.now().isoformat()))
        
        self.db.commit()
        print(f" Added dependency: {project_id} depends on {depends_on_id}")
    
    def get_dependencies(self, project_id: int) -> List[Dict]:
        """Get all dependencies for a project"""
        c = self.db.cursor()
        
        c.execute('''
            SELECT p.*, pd.dependency_type
            FROM projects p
            JOIN project_dependencies pd ON p.id = pd.depends_on_id
            WHERE pd.project_id = ?
        ''', (project_id,))
        
        deps = []
        for row in c.fetchall():
            project = self._row_to_project(row[:-1])
            project['dependency_type'] = row[-1]
            deps.append(project)
        
        return deps
    
    def add_feature(self, project_id: int, feature_name: str):
        """Add feature to project"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO project_features (
                project_id, feature_name, created_at
            ) VALUES (?, ?, ?)
        ''', (project_id, feature_name, datetime.now().isoformat()))
        
        self.db.commit()
        print(f" Added feature: {feature_name}")
    
    def complete_feature(self, project_id: int, feature_name: str):
        """Mark feature as completed"""
        c = self.db.cursor()
        
        c.execute('''
            UPDATE project_features
            SET status = 'completed', completed_at = ?
            WHERE project_id = ? AND feature_name = ?
        ''', (datetime.now().isoformat(), project_id, feature_name))
        
        self.db.commit()
        print(f" Completed feature: {feature_name}")
    
    def get_features(self, project_id: int, status: str = None) -> List[Dict]:
        """Get project features"""
        c = self.db.cursor()
        
        if status:
            c.execute('''
                SELECT * FROM project_features
                WHERE project_id = ? AND status = ?
            ''', (project_id, status))
        else:
            c.execute('''
                SELECT * FROM project_features
                WHERE project_id = ?
            ''', (project_id,))
        
        features = []
        for row in c.fetchall():
            features.append({
                'id': row[0],
                'feature_name': row[2],
                'status': row[3],
                'created_at': row[4],
                'completed_at': row[5]
            })
        
        return features
    
    def add_task(self, project_id: int, task_description: str, 
                priority: int = 1, assigned_to: str = 'ai'):
        """Add task to project"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO project_tasks (
                project_id, task_description, priority, assigned_to, created_at
            ) VALUES (?, ?, ?, ?, ?)
        ''', (project_id, task_description, priority, assigned_to, datetime.now().isoformat()))
        
        self.db.commit()
        task_id = c.lastrowid
        print(f" Added task: {task_description} (ID: {task_id})")
        return task_id
    
    def complete_task(self, task_id: int):
        """Mark task as completed"""
        c = self.db.cursor()
        
        c.execute('''
            UPDATE project_tasks
            SET status = 'completed', completed_at = ?
            WHERE id = ?
        ''', (datetime.now().isoformat(), task_id))
        
        self.db.commit()
        print(f" Completed task {task_id}")
    
    def get_tasks(self, project_id: int, status: str = None) -> List[Dict]:
        """Get project tasks"""
        c = self.db.cursor()
        
        if status:
            c.execute('''
                SELECT * FROM project_tasks
                WHERE project_id = ? AND status = ?
                ORDER BY priority DESC, created_at ASC
            ''', (project_id, status))
        else:
            c.execute('''
                SELECT * FROM project_tasks
                WHERE project_id = ?
                ORDER BY priority DESC, created_at ASC
            ''', (project_id,))
        
        tasks = []
        for row in c.fetchall():
            tasks.append({
                'id': row[0],
                'description': row[2],
                'status': row[3],
                'priority': row[4],
                'assigned_to': row[5],
                'created_at': row[6],
                'completed_at': row[7]
            })
        
        return tasks
    
    def record_health_metric(self, project_id: int, metric_type: str, value: float):
        """Record health metric for project"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO project_health (
                project_id, metric_type, metric_value, recorded_at
            ) VALUES (?, ?, ?, ?)
        ''', (project_id, metric_type, value, datetime.now().isoformat()))
        
        self.db.commit()
    
    def get_health_metrics(self, project_id: int, metric_type: str = None) -> List[Dict]:
        """Get health metrics for project"""
        c = self.db.cursor()
        
        if metric_type:
            c.execute('''
                SELECT * FROM project_health
                WHERE project_id = ? AND metric_type = ?
                ORDER BY recorded_at DESC
                LIMIT 100
            ''', (project_id, metric_type))
        else:
            c.execute('''
                SELECT * FROM project_health
                WHERE project_id = ?
                ORDER BY recorded_at DESC
                LIMIT 100
            ''', (project_id,))
        
        metrics = []
        for row in c.fetchall():
            metrics.append({
                'metric_type': row[2],
                'value': row[3],
                'recorded_at': row[4]
            })
        
        return metrics
    
    def get_project_status(self, project_id: int) -> Dict:
        """Get comprehensive project status"""
        project = self.get_project(project_id)
        if not project:
            return None
        
        # Get features
        features = self.get_features(project_id)
        completed_features = [f for f in features if f['status'] == 'completed']
        
        # Get tasks
        tasks = self.get_tasks(project_id)
        completed_tasks = [t for t in tasks if t['status'] == 'completed']
        pending_tasks = [t for t in tasks if t['status'] == 'pending']
        
        # Get dependencies
        dependencies = self.get_dependencies(project_id)
        
        # Calculate progress
        total_items = len(features) + len(tasks)
        completed_items = len(completed_features) + len(completed_tasks)
        progress = (completed_items / total_items * 100) if total_items > 0 else 0
        
        return {
            'project': project,
            'progress': round(progress, 1),
            'features': {
                'total': len(features),
                'completed': len(completed_features),
                'pending': len(features) - len(completed_features)
            },
            'tasks': {
                'total': len(tasks),
                'completed': len(completed_tasks),
                'pending': len(pending_tasks)
            },
            'dependencies': len(dependencies),
            'health': 'good' if progress > 50 else 'needs_attention'
        }
    
    def _row_to_project(self, row) -> Dict:
        """Convert database row to project dict"""
        return {
            'id': row[0],
            'name': row[1],
            'description': row[2],
            'path': row[3],
            'framework': row[4],
            'status': row[5],
            'created_at': row[6],
            'updated_at': row[7],
            'deployed': bool(row[8]),
            'deployment_url': row[9],
            'metadata': json.loads(row[10]) if row[10] else {}
        }
    
    def export_project_report(self, project_id: int, output_file: str):
        """Export comprehensive project report"""
        status = self.get_project_status(project_id)
        if not status:
            print(f"Project {project_id} not found")
            return
        
        project = status['project']
        
        report = f"""# Project Report: {project['name']}

## Overview
- **Description:** {project['description']}
- **Framework:** {project['framework']}
- **Status:** {project['status']}
- **Created:** {project['created_at']}
- **Progress:** {status['progress']}%

## Features
- Total: {status['features']['total']}
- Completed: {status['features']['completed']}
- Pending: {status['features']['pending']}

## Tasks
- Total: {status['tasks']['total']}
- Completed: {status['tasks']['completed']}
- Pending: {status['tasks']['pending']}

## Dependencies
- Count: {status['dependencies']}

## Health
- Status: {status['health']}

## Deployment
- Deployed: {'Yes' if project['deployed'] else 'No'}
- URL: {project['deployment_url'] or 'N/A'}

---
Generated: {datetime.now().isoformat()}
"""
        
        Path(output_file).write_text(report)
        print(f" Exported report to {output_file}")


def main():
    """Test project manager"""
    pm = AILAProjectManager()
    
    # Create a project
    project_id = pm.create_project(
        name="test_api",
        description="Test REST API",
        framework="flask",
        path="/tmp/test_api"
    )
    
    # Add features
    pm.add_feature(project_id, "user_authentication")
    pm.add_feature(project_id, "database_integration")
    
    # Add tasks
    pm.add_task(project_id, "Implement login endpoint", priority=3)
    pm.add_task(project_id, "Add database models", priority=2)
    
    # Get status
    status = pm.get_project_status(project_id)
    print(f"\nProject Status:")
    print(f"  Progress: {status['progress']}%")
    print(f"  Features: {status['features']}")
    print(f"  Tasks: {status['tasks']}")
    
    # List all projects
    projects = pm.list_projects()
    print(f"\nAll Projects: {len(projects)}")
    for p in projects:
        print(f"  - {p['name']} ({p['framework']})")


if __name__ == "__main__":
    main()

