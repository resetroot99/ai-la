#!/usr/bin/env python3
"""
Self-Evolution System
Learns from every build and continuously improves
"""

import json
import sqlite3
from pathlib import Path
from typing import Dict, List
from datetime import datetime
import subprocess

class SelfEvolutionEngine:
    """
    Learns from execution history and improves future builds
    """
    
    def __init__(self):
        self.db_path = Path.home() / ".ai-coding-stack" / "evolution.db"
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()
    
    def _init_database(self):
        """Initialize SQLite database for learning"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Build history table
        c.execute('''
            CREATE TABLE IF NOT EXISTS builds (
                id INTEGER PRIMARY KEY,
                timestamp TEXT,
                description TEXT,
                task_type TEXT,
                tech_stack TEXT,
                success INTEGER,
                duration_seconds REAL,
                code_quality_score REAL,
                test_pass_rate REAL,
                deployment_success INTEGER
            )
        ''')
        
        # Learned patterns table
        c.execute('''
            CREATE TABLE IF NOT EXISTS patterns (
                id INTEGER PRIMARY KEY,
                pattern_type TEXT,
                context TEXT,
                solution TEXT,
                success_count INTEGER,
                failure_count INTEGER,
                confidence_score REAL,
                last_used TEXT
            )
        ''')
        
        # Performance metrics table
        c.execute('''
            CREATE TABLE IF NOT EXISTS metrics (
                id INTEGER PRIMARY KEY,
                metric_name TEXT,
                metric_value REAL,
                timestamp TEXT,
                build_id INTEGER,
                FOREIGN KEY(build_id) REFERENCES builds(id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def record_build(self, build_data: Dict) -> int:
        """Record a build execution"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''
            INSERT INTO builds (
                timestamp, description, task_type, tech_stack,
                success, duration_seconds, code_quality_score,
                test_pass_rate, deployment_success
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            datetime.now().isoformat(),
            build_data.get('description'),
            build_data.get('task_type'),
            json.dumps(build_data.get('tech_stack', {})),
            1 if build_data.get('success') else 0,
            build_data.get('duration_seconds', 0),
            build_data.get('code_quality_score', 0),
            build_data.get('test_pass_rate', 0),
            1 if build_data.get('deployment_success') else 0
        ))
        
        build_id = c.lastrowid
        conn.commit()
        conn.close()
        
        return build_id
    
    def extract_patterns(self, build_id: int, build_data: Dict):
        """Extract successful patterns from a build"""
        if not build_data.get('success'):
            return
        
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Extract architecture patterns
        if 'architecture' in build_data:
            pattern_type = "architecture"
            context = json.dumps({
                "task_type": build_data.get('task_type'),
                "tech_stack": build_data.get('tech_stack')
            })
            solution = json.dumps(build_data['architecture'])
            
            # Check if pattern exists
            c.execute('''
                SELECT id, success_count FROM patterns
                WHERE pattern_type = ? AND context = ? AND solution = ?
            ''', (pattern_type, context, solution))
            
            existing = c.fetchone()
            
            if existing:
                # Update existing pattern
                c.execute('''
                    UPDATE patterns
                    SET success_count = success_count + 1,
                        confidence_score = (success_count + 1.0) / (success_count + failure_count + 1.0),
                        last_used = ?
                    WHERE id = ?
                ''', (datetime.now().isoformat(), existing[0]))
            else:
                # Create new pattern
                c.execute('''
                    INSERT INTO patterns (
                        pattern_type, context, solution,
                        success_count, failure_count, confidence_score, last_used
                    ) VALUES (?, ?, ?, 1, 0, 1.0, ?)
                ''', (pattern_type, context, solution, datetime.now().isoformat()))
        
        # Extract code patterns
        if 'code_patterns' in build_data:
            for pattern in build_data['code_patterns']:
                pattern_type = "code"
                context = json.dumps(pattern.get('context', {}))
                solution = pattern.get('solution', '')
                
                c.execute('''
                    INSERT OR IGNORE INTO patterns (
                        pattern_type, context, solution,
                        success_count, failure_count, confidence_score, last_used
                    ) VALUES (?, ?, ?, 1, 0, 1.0, ?)
                ''', (pattern_type, context, solution, datetime.now().isoformat()))
        
        conn.commit()
        conn.close()
    
    def get_best_pattern(self, pattern_type: str, context: Dict) -> Dict:
        """Retrieve the best matching pattern"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        context_json = json.dumps(context)
        
        c.execute('''
            SELECT solution, confidence_score
            FROM patterns
            WHERE pattern_type = ? AND context = ?
            ORDER BY confidence_score DESC, success_count DESC
            LIMIT 1
        ''', (pattern_type, context_json))
        
        result = c.fetchone()
        conn.close()
        
        if result:
            return {
                "solution": json.loads(result[0]),
                "confidence": result[1]
            }
        
        return None
    
    def get_improvement_suggestions(self) -> List[Dict]:
        """Analyze history and suggest improvements"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        suggestions = []
        
        # Analyze failure patterns
        c.execute('''
            SELECT task_type, tech_stack, COUNT(*) as failures
            FROM builds
            WHERE success = 0
            GROUP BY task_type, tech_stack
            HAVING failures > 2
        ''')
        
        for row in c.fetchall():
            suggestions.append({
                "type": "avoid_combination",
                "task_type": row[0],
                "tech_stack": json.loads(row[1]),
                "reason": f"Failed {row[2]} times",
                "priority": "high"
            })
        
        # Find high-success patterns
        c.execute('''
            SELECT pattern_type, context, solution, confidence_score
            FROM patterns
            WHERE confidence_score > 0.8 AND success_count > 3
            ORDER BY confidence_score DESC
            LIMIT 5
        ''')
        
        for row in c.fetchall():
            suggestions.append({
                "type": "use_pattern",
                "pattern_type": row[0],
                "context": json.loads(row[1]),
                "solution": json.loads(row[2]),
                "confidence": row[3],
                "priority": "medium"
            })
        
        conn.close()
        return suggestions
    
    def optimize_for_task(self, task: Dict) -> Dict:
        """Optimize task based on learned patterns"""
        # Get best architecture pattern
        arch_pattern = self.get_best_pattern("architecture", {
            "task_type": task.get('type'),
            "tech_stack": task.get('tech_stack')
        })
        
        if arch_pattern and arch_pattern['confidence'] > 0.7:
            task['architecture'] = arch_pattern['solution']
            task['optimization_applied'] = True
            task['optimization_confidence'] = arch_pattern['confidence']
        
        # Get improvement suggestions
        suggestions = self.get_improvement_suggestions()
        
        # Apply high-priority suggestions
        for suggestion in suggestions:
            if suggestion['priority'] == 'high' and suggestion['type'] == 'avoid_combination':
                if (task.get('type') == suggestion['task_type'] and 
                    task.get('tech_stack') == suggestion['tech_stack']):
                    # Suggest alternative
                    task['warning'] = f"This combination has failed before. Consider alternatives."
        
        return task
    
    def get_statistics(self) -> Dict:
        """Get evolution statistics"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Total builds
        c.execute('SELECT COUNT(*) FROM builds')
        total_builds = c.fetchone()[0]
        
        # Success rate
        c.execute('SELECT AVG(success) FROM builds')
        success_rate = c.fetchone()[0] or 0
        
        # Average quality score
        c.execute('SELECT AVG(code_quality_score) FROM builds WHERE success = 1')
        avg_quality = c.fetchone()[0] or 0
        
        # Learned patterns
        c.execute('SELECT COUNT(*) FROM patterns WHERE confidence_score > 0.7')
        high_confidence_patterns = c.fetchone()[0]
        
        # Improvement over time
        c.execute('''
            SELECT 
                AVG(CASE WHEN id <= (SELECT MAX(id)/2 FROM builds) THEN success ELSE NULL END) as early_success,
                AVG(CASE WHEN id > (SELECT MAX(id)/2 FROM builds) THEN success ELSE NULL END) as recent_success
            FROM builds
        ''')
        early, recent = c.fetchone()
        
        improvement = ((recent or 0) - (early or 0)) * 100 if early and recent else 0
        
        conn.close()
        
        return {
            "total_builds": total_builds,
            "success_rate": round(success_rate * 100, 1),
            "average_quality_score": round(avg_quality, 1),
            "high_confidence_patterns": high_confidence_patterns,
            "improvement_percentage": round(improvement, 1)
        }


def main():
    """CLI for evolution system"""
    import sys
    
    engine = SelfEvolutionEngine()
    
    if len(sys.argv) < 2:
        print("Usage: self-evolution.py <command>")
        print("\nCommands:")
        print("  stats              Show evolution statistics")
        print("  suggestions        Get improvement suggestions")
        print("  patterns           List learned patterns")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "stats":
        stats = engine.get_statistics()
        print("\n Self-Evolution Statistics\n")
        print(f"Total Builds: {stats['total_builds']}")
        print(f"Success Rate: {stats['success_rate']}%")
        print(f"Avg Quality Score: {stats['average_quality_score']}/100")
        print(f"High-Confidence Patterns: {stats['high_confidence_patterns']}")
        print(f"Improvement: +{stats['improvement_percentage']}%")
        print()
    
    elif command == "suggestions":
        suggestions = engine.get_improvement_suggestions()
        print("\n Improvement Suggestions\n")
        for i, sug in enumerate(suggestions, 1):
            print(f"{i}. [{sug['priority'].upper()}] {sug['type']}")
            if sug['type'] == 'avoid_combination':
                print(f"   Reason: {sug['reason']}")
            elif sug['type'] == 'use_pattern':
                print(f"   Confidence: {sug['confidence']:.0%}")
            print()
    
    elif command == "patterns":
        conn = sqlite3.connect(engine.db_path)
        c = conn.cursor()
        c.execute('''
            SELECT pattern_type, confidence_score, success_count
            FROM patterns
            ORDER BY confidence_score DESC
            LIMIT 10
        ''')
        
        print("\n Learned Patterns (Top 10)\n")
        for row in c.fetchall():
            print(f"• {row[0]}: {row[2]} successes, {row[1]:.0%} confidence")
        print()
        
        conn.close()


if __name__ == "__main__":
    main()

