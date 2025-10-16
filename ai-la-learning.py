#!/usr/bin/env python3
"""
AI-LA v2.0: Self-Learning Feedback System
Learns from every app generated to improve future generations
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import hashlib

class AILALearningSystem:
    """
    Self-learning system that improves with every app generated
    """
    
    def __init__(self, data_dir: str = "~/.ai-la/learning"):
        self.data_dir = Path(data_dir).expanduser()
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Learning database
        self.db_path = self.data_dir / "learning.db"
        self.db = sqlite3.connect(str(self.db_path))
        self._init_database()
        
        # Pattern library
        self.patterns_file = self.data_dir / "patterns.json"
        self.load_patterns()
    
    def _init_database(self):
        """Initialize learning database schema"""
        c = self.db.cursor()
        
        # Generated apps history
        c.execute('''
            CREATE TABLE IF NOT EXISTS generated_apps (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                description TEXT NOT NULL,
                framework TEXT NOT NULL,
                features TEXT,
                success BOOLEAN,
                tests_passed BOOLEAN,
                deployed BOOLEAN,
                user_rating INTEGER,
                feedback TEXT,
                code_hash TEXT,
                created_at TEXT,
                metadata TEXT
            )
        ''')
        
        # Code patterns that work well
        c.execute('''
            CREATE TABLE IF NOT EXISTS successful_patterns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                pattern_type TEXT,
                pattern_code TEXT,
                use_case TEXT,
                success_count INTEGER DEFAULT 1,
                failure_count INTEGER DEFAULT 0,
                avg_rating REAL,
                last_used TEXT,
                metadata TEXT
            )
        ''')
        
        # Common errors and solutions
        c.execute('''
            CREATE TABLE IF NOT EXISTS error_solutions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                error_type TEXT,
                error_message TEXT,
                solution TEXT,
                success_rate REAL,
                times_used INTEGER DEFAULT 0,
                created_at TEXT
            )
        ''')
        
        # Feature combinations that work
        c.execute('''
            CREATE TABLE IF NOT EXISTS feature_combinations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                features TEXT,
                framework TEXT,
                success_rate REAL,
                sample_count INTEGER,
                avg_build_time REAL,
                metadata TEXT
            )
        ''')
        
        # User preferences
        c.execute('''
            CREATE TABLE IF NOT EXISTS user_preferences (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                preference_type TEXT,
                preference_value TEXT,
                frequency INTEGER DEFAULT 1,
                last_used TEXT
            )
        ''')
        
        self.db.commit()
    
    def load_patterns(self):
        """Load pattern library"""
        if self.patterns_file.exists():
            self.patterns = json.loads(self.patterns_file.read_text())
        else:
            self.patterns = {
                'code_templates': {},
                'architecture_patterns': {},
                'best_practices': {}
            }
    
    def save_patterns(self):
        """Save pattern library"""
        self.patterns_file.write_text(json.dumps(self.patterns, indent=2))
    
    def record_generation(self, app_data: Dict) -> int:
        """
        Record a generated app for learning
        Returns: generation_id
        """
        c = self.db.cursor()
        
        # Calculate code hash for deduplication
        code_hash = self._hash_code(app_data.get('code', ''))
        
        c.execute('''
            INSERT INTO generated_apps (
                description, framework, features, success, 
                tests_passed, deployed, code_hash, created_at, metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            app_data['description'],
            app_data['framework'],
            json.dumps(app_data.get('features', [])),
            app_data.get('success', False),
            app_data.get('tests_passed', False),
            app_data.get('deployed', False),
            code_hash,
            datetime.now().isoformat(),
            json.dumps(app_data.get('metadata', {}))
        ))
        
        self.db.commit()
        return c.lastrowid
    
    def record_feedback(self, generation_id: int, rating: int, feedback: str):
        """Record user feedback on generated app"""
        c = self.db.cursor()
        
        c.execute('''
            UPDATE generated_apps
            SET user_rating = ?, feedback = ?
            WHERE id = ?
        ''', (rating, feedback, generation_id))
        
        self.db.commit()
        
        # Learn from feedback
        self._learn_from_feedback(generation_id, rating, feedback)
    
    def _learn_from_feedback(self, generation_id: int, rating: int, feedback: str):
        """Extract learnings from user feedback"""
        c = self.db.cursor()
        
        # Get the app details
        c.execute('''
            SELECT description, framework, features, code_hash
            FROM generated_apps
            WHERE id = ?
        ''', (generation_id,))
        
        row = c.fetchone()
        if not row:
            return
        
        description, framework, features, code_hash = row
        features_list = json.loads(features)
        
        # If rating is good (4-5), record successful pattern
        if rating >= 4:
            self._record_successful_pattern(
                framework,
                features_list,
                code_hash,
                rating
            )
        
        # If rating is poor (1-2), analyze what went wrong
        elif rating <= 2:
            self._analyze_failure(
                description,
                framework,
                features_list,
                feedback
            )
    
    def _record_successful_pattern(self, framework: str, features: List[str], 
                                   code_hash: str, rating: int):
        """Record a successful code pattern"""
        c = self.db.cursor()
        
        # Update or insert feature combination
        features_str = json.dumps(sorted(features))
        
        c.execute('''
            SELECT id, success_rate, sample_count
            FROM feature_combinations
            WHERE features = ? AND framework = ?
        ''', (features_str, framework))
        
        row = c.fetchone()
        
        if row:
            # Update existing
            combo_id, success_rate, sample_count = row
            new_success_rate = (success_rate * sample_count + rating/5.0) / (sample_count + 1)
            
            c.execute('''
                UPDATE feature_combinations
                SET success_rate = ?, sample_count = sample_count + 1
                WHERE id = ?
            ''', (new_success_rate, combo_id))
        else:
            # Insert new
            c.execute('''
                INSERT INTO feature_combinations (
                    features, framework, success_rate, sample_count, metadata
                ) VALUES (?, ?, ?, 1, ?)
            ''', (features_str, framework, rating/5.0, json.dumps({})))
        
        self.db.commit()
    
    def _analyze_failure(self, description: str, framework: str, 
                        features: List[str], feedback: str):
        """Analyze what went wrong with a generation"""
        # Extract common error patterns from feedback
        error_keywords = {
            'bug': 'code_quality',
            'error': 'runtime_error',
            'crash': 'stability',
            'slow': 'performance',
            'confusing': 'usability',
            'missing': 'incomplete_feature'
        }
        
        for keyword, error_type in error_keywords.items():
            if keyword in feedback.lower():
                self._record_error_pattern(error_type, feedback, framework)
    
    def _record_error_pattern(self, error_type: str, feedback: str, framework: str):
        """Record an error pattern for future avoidance"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO error_solutions (
                error_type, error_message, solution, success_rate, created_at
            ) VALUES (?, ?, ?, 0.0, ?)
        ''', (
            error_type,
            feedback[:200],  # Truncate
            f"Avoid this pattern in {framework}",
            datetime.now().isoformat()
        ))
        
        self.db.commit()
    
    def get_recommendations(self, description: str, framework: str = None) -> Dict:
        """
        Get recommendations based on learned patterns
        """
        c = self.db.cursor()
        
        recommendations = {
            'framework': None,
            'features': [],
            'patterns': [],
            'warnings': []
        }
        
        # Recommend framework if not specified
        if not framework:
            c.execute('''
                SELECT framework, AVG(user_rating) as avg_rating, COUNT(*) as count
                FROM generated_apps
                WHERE user_rating IS NOT NULL
                GROUP BY framework
                HAVING count >= 3
                ORDER BY avg_rating DESC
                LIMIT 1
            ''')
            
            row = c.fetchone()
            if row:
                recommendations['framework'] = row[0]
        
        # Recommend features based on description keywords
        keywords = description.lower().split()
        
        c.execute('''
            SELECT features, success_rate
            FROM feature_combinations
            WHERE framework = ?
            ORDER BY success_rate DESC, sample_count DESC
            LIMIT 5
        ''', (framework or recommendations['framework'] or 'flask',))
        
        for row in c.fetchall():
            features = json.loads(row[0])
            success_rate = row[1]
            
            # Check if features match description
            matching = sum(1 for f in features if any(k in f for k in keywords))
            if matching > 0:
                recommendations['features'].extend(features)
        
        # Get successful patterns
        c.execute('''
            SELECT pattern_type, pattern_code, success_count
            FROM successful_patterns
            WHERE success_count > failure_count
            ORDER BY success_count DESC
            LIMIT 5
        ''')
        
        for row in c.fetchall():
            recommendations['patterns'].append({
                'type': row[0],
                'code': row[1],
                'success_count': row[2]
            })
        
        # Get warnings about common errors
        c.execute('''
            SELECT error_type, error_message
            FROM error_solutions
            WHERE times_used > 0
            ORDER BY times_used DESC
            LIMIT 3
        ''')
        
        for row in c.fetchall():
            recommendations['warnings'].append({
                'type': row[0],
                'message': row[1]
            })
        
        return recommendations
    
    def get_statistics(self) -> Dict:
        """Get learning statistics"""
        c = self.db.cursor()
        
        stats = {}
        
        # Total apps generated
        c.execute('SELECT COUNT(*) FROM generated_apps')
        stats['total_apps'] = c.fetchone()[0]
        
        # Success rate
        c.execute('''
            SELECT 
                COUNT(CASE WHEN success = 1 THEN 1 END) * 100.0 / COUNT(*) as success_rate
            FROM generated_apps
        ''')
        stats['success_rate'] = round(c.fetchone()[0], 2)
        
        # Average rating
        c.execute('''
            SELECT AVG(user_rating)
            FROM generated_apps
            WHERE user_rating IS NOT NULL
        ''')
        avg_rating = c.fetchone()[0]
        stats['avg_rating'] = round(avg_rating, 2) if avg_rating else 0
        
        # Most used framework
        c.execute('''
            SELECT framework, COUNT(*) as count
            FROM generated_apps
            GROUP BY framework
            ORDER BY count DESC
            LIMIT 1
        ''')
        row = c.fetchone()
        stats['most_used_framework'] = row[0] if row else 'none'
        
        # Patterns learned
        c.execute('SELECT COUNT(*) FROM successful_patterns')
        stats['patterns_learned'] = c.fetchone()[0]
        
        # Errors catalogued
        c.execute('SELECT COUNT(*) FROM error_solutions')
        stats['errors_catalogued'] = c.fetchone()[0]
        
        return stats
    
    def export_learnings(self, output_file: str):
        """Export all learnings to JSON file"""
        c = self.db.cursor()
        
        export_data = {
            'statistics': self.get_statistics(),
            'patterns': [],
            'feature_combinations': [],
            'error_solutions': []
        }
        
        # Export patterns
        c.execute('''
            SELECT pattern_type, pattern_code, use_case, success_count
            FROM successful_patterns
            WHERE success_count > 0
        ''')
        
        for row in c.fetchall():
            export_data['patterns'].append({
                'type': row[0],
                'code': row[1],
                'use_case': row[2],
                'success_count': row[3]
            })
        
        # Export feature combinations
        c.execute('''
            SELECT features, framework, success_rate, sample_count
            FROM feature_combinations
            WHERE sample_count >= 3
        ''')
        
        for row in c.fetchall():
            export_data['feature_combinations'].append({
                'features': json.loads(row[0]),
                'framework': row[1],
                'success_rate': row[2],
                'sample_count': row[3]
            })
        
        # Export error solutions
        c.execute('''
            SELECT error_type, error_message, solution, success_rate
            FROM error_solutions
        ''')
        
        for row in c.fetchall():
            export_data['error_solutions'].append({
                'type': row[0],
                'message': row[1],
                'solution': row[2],
                'success_rate': row[3]
            })
        
        # Write to file
        Path(output_file).write_text(json.dumps(export_data, indent=2))
        
        return export_data
    
    def _hash_code(self, code: str) -> str:
        """Generate hash of code for deduplication"""
        return hashlib.sha256(code.encode()).hexdigest()[:16]


def main():
    """Test learning system"""
    learning = AILALearningSystem()
    
    # Record a generation
    gen_id = learning.record_generation({
        'description': 'Build a REST API',
        'framework': 'flask',
        'features': ['database', 'auth'],
        'success': True,
        'tests_passed': True,
        'code': 'sample code'
    })
    
    print(f"Recorded generation: {gen_id}")
    
    # Record feedback
    learning.record_feedback(gen_id, 5, "Works perfectly!")
    print("Recorded feedback")
    
    # Get recommendations
    recs = learning.get_recommendations("Build an API with auth")
    print(f"\nRecommendations: {json.dumps(recs, indent=2)}")
    
    # Get statistics
    stats = learning.get_statistics()
    print(f"\nStatistics: {json.dumps(stats, indent=2)}")


if __name__ == "__main__":
    main()

