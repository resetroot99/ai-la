#!/usr/bin/env python3
"""
AI-LA v2.0: Monitoring and Analytics System
Tracks performance, usage, and provides insights
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import time

class AILAMonitor:
    """
    Monitoring and analytics system
    Tracks generation performance, usage patterns, and provides insights
    """
    
    def __init__(self, data_dir: str = "~/.ai-la/monitor"):
        self.data_dir = Path(data_dir).expanduser()
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Metrics database
        self.db_path = self.data_dir / "metrics.db"
        self.db = sqlite3.connect(str(self.db_path))
        self._init_database()
    
    def _init_database(self):
        """Initialize metrics database"""
        c = self.db.cursor()
        
        # Generation metrics
        c.execute('''
            CREATE TABLE IF NOT EXISTS generation_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_name TEXT,
                framework TEXT,
                generation_time REAL,
                files_generated INTEGER,
                lines_generated INTEGER,
                success BOOLEAN,
                timestamp TEXT
            )
        ''')
        
        # Usage metrics
        c.execute('''
            CREATE TABLE IF NOT EXISTS usage_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_type TEXT,
                metric_value REAL,
                metadata TEXT,
                timestamp TEXT
            )
        ''')
        
        # Performance metrics
        c.execute('''
            CREATE TABLE IF NOT EXISTS performance_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                operation TEXT,
                duration REAL,
                cpu_percent REAL,
                memory_mb REAL,
                timestamp TEXT
            )
        ''')
        
        # Error tracking
        c.execute('''
            CREATE TABLE IF NOT EXISTS error_tracking (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                error_type TEXT,
                error_message TEXT,
                stack_trace TEXT,
                context TEXT,
                timestamp TEXT
            )
        ''')
        
        self.db.commit()
    
    def track_generation(self, project_name: str, framework: str, 
                        generation_time: float, files_count: int, 
                        lines_count: int, success: bool):
        """Track app generation metrics"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO generation_metrics (
                project_name, framework, generation_time, 
                files_generated, lines_generated, success, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (
            project_name,
            framework,
            generation_time,
            files_count,
            lines_count,
            success,
            datetime.now().isoformat()
        ))
        
        self.db.commit()
    
    def track_usage(self, metric_type: str, value: float, metadata: Dict = None):
        """Track usage metrics"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO usage_metrics (
                metric_type, metric_value, metadata, timestamp
            ) VALUES (?, ?, ?, ?)
        ''', (
            metric_type,
            value,
            json.dumps(metadata or {}),
            datetime.now().isoformat()
        ))
        
        self.db.commit()
    
    def track_performance(self, operation: str, duration: float, 
                         cpu_percent: float = 0, memory_mb: float = 0):
        """Track performance metrics"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO performance_metrics (
                operation, duration, cpu_percent, memory_mb, timestamp
            ) VALUES (?, ?, ?, ?, ?)
        ''', (
            operation,
            duration,
            cpu_percent,
            memory_mb,
            datetime.now().isoformat()
        ))
        
        self.db.commit()
    
    def track_error(self, error_type: str, error_message: str, 
                   stack_trace: str = "", context: Dict = None):
        """Track errors"""
        c = self.db.cursor()
        
        c.execute('''
            INSERT INTO error_tracking (
                error_type, error_message, stack_trace, context, timestamp
            ) VALUES (?, ?, ?, ?, ?)
        ''', (
            error_type,
            error_message,
            stack_trace,
            json.dumps(context or {}),
            datetime.now().isoformat()
        ))
        
        self.db.commit()
    
    def get_generation_stats(self, days: int = 30) -> Dict:
        """Get generation statistics"""
        c = self.db.cursor()
        
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        # Total generations
        c.execute('''
            SELECT COUNT(*) FROM generation_metrics
            WHERE timestamp >= ?
        ''', (since,))
        total = c.fetchone()[0]
        
        # Success rate
        c.execute('''
            SELECT 
                COUNT(CASE WHEN success = 1 THEN 1 END) * 100.0 / COUNT(*)
            FROM generation_metrics
            WHERE timestamp >= ?
        ''', (since,))
        success_rate = c.fetchone()[0] or 0
        
        # Average generation time
        c.execute('''
            SELECT AVG(generation_time)
            FROM generation_metrics
            WHERE timestamp >= ? AND success = 1
        ''', (since,))
        avg_time = c.fetchone()[0] or 0
        
        # Total files generated
        c.execute('''
            SELECT SUM(files_generated)
            FROM generation_metrics
            WHERE timestamp >= ? AND success = 1
        ''', (since,))
        total_files = c.fetchone()[0] or 0
        
        # Total lines generated
        c.execute('''
            SELECT SUM(lines_generated)
            FROM generation_metrics
            WHERE timestamp >= ? AND success = 1
        ''', (since,))
        total_lines = c.fetchone()[0] or 0
        
        # Most used framework
        c.execute('''
            SELECT framework, COUNT(*) as count
            FROM generation_metrics
            WHERE timestamp >= ?
            GROUP BY framework
            ORDER BY count DESC
            LIMIT 1
        ''', (since,))
        row = c.fetchone()
        most_used_framework = row[0] if row else 'none'
        
        return {
            'total_generations': total,
            'success_rate': round(success_rate, 2),
            'avg_generation_time': round(avg_time, 2),
            'total_files': int(total_files),
            'total_lines': int(total_lines),
            'most_used_framework': most_used_framework,
            'period_days': days
        }
    
    def get_performance_stats(self, operation: str = None, days: int = 7) -> Dict:
        """Get performance statistics"""
        c = self.db.cursor()
        
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        if operation:
            c.execute('''
                SELECT 
                    AVG(duration) as avg_duration,
                    MIN(duration) as min_duration,
                    MAX(duration) as max_duration,
                    AVG(cpu_percent) as avg_cpu,
                    AVG(memory_mb) as avg_memory
                FROM performance_metrics
                WHERE operation = ? AND timestamp >= ?
            ''', (operation, since))
        else:
            c.execute('''
                SELECT 
                    AVG(duration) as avg_duration,
                    MIN(duration) as min_duration,
                    MAX(duration) as max_duration,
                    AVG(cpu_percent) as avg_cpu,
                    AVG(memory_mb) as avg_memory
                FROM performance_metrics
                WHERE timestamp >= ?
            ''', (since,))
        
        row = c.fetchone()
        
        return {
            'avg_duration': round(row[0], 3) if row[0] else 0,
            'min_duration': round(row[1], 3) if row[1] else 0,
            'max_duration': round(row[2], 3) if row[2] else 0,
            'avg_cpu_percent': round(row[3], 2) if row[3] else 0,
            'avg_memory_mb': round(row[4], 2) if row[4] else 0,
            'period_days': days
        }
    
    def get_error_stats(self, days: int = 7) -> Dict:
        """Get error statistics"""
        c = self.db.cursor()
        
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        # Total errors
        c.execute('''
            SELECT COUNT(*) FROM error_tracking
            WHERE timestamp >= ?
        ''', (since,))
        total_errors = c.fetchone()[0]
        
        # Errors by type
        c.execute('''
            SELECT error_type, COUNT(*) as count
            FROM error_tracking
            WHERE timestamp >= ?
            GROUP BY error_type
            ORDER BY count DESC
        ''', (since,))
        
        errors_by_type = {}
        for row in c.fetchall():
            errors_by_type[row[0]] = row[1]
        
        # Most common error
        c.execute('''
            SELECT error_message, COUNT(*) as count
            FROM error_tracking
            WHERE timestamp >= ?
            GROUP BY error_message
            ORDER BY count DESC
            LIMIT 1
        ''', (since,))
        
        row = c.fetchone()
        most_common_error = row[0] if row else 'none'
        
        return {
            'total_errors': total_errors,
            'errors_by_type': errors_by_type,
            'most_common_error': most_common_error,
            'period_days': days
        }
    
    def get_usage_trends(self, metric_type: str = None, days: int = 30) -> List[Dict]:
        """Get usage trends over time"""
        c = self.db.cursor()
        
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        if metric_type:
            c.execute('''
                SELECT metric_value, timestamp
                FROM usage_metrics
                WHERE metric_type = ? AND timestamp >= ?
                ORDER BY timestamp ASC
            ''', (metric_type, since))
        else:
            c.execute('''
                SELECT metric_type, metric_value, timestamp
                FROM usage_metrics
                WHERE timestamp >= ?
                ORDER BY timestamp ASC
            ''', (since,))
        
        trends = []
        for row in c.fetchall():
            if metric_type:
                trends.append({
                    'value': row[0],
                    'timestamp': row[1]
                })
            else:
                trends.append({
                    'type': row[0],
                    'value': row[1],
                    'timestamp': row[2]
                })
        
        return trends
    
    def get_dashboard_data(self) -> Dict:
        """Get comprehensive dashboard data"""
        return {
            'generation_stats': self.get_generation_stats(days=30),
            'performance_stats': self.get_performance_stats(days=7),
            'error_stats': self.get_error_stats(days=7),
            'recent_activity': self._get_recent_activity()
        }
    
    def _get_recent_activity(self, limit: int = 10) -> List[Dict]:
        """Get recent activity"""
        c = self.db.cursor()
        
        c.execute('''
            SELECT project_name, framework, generation_time, success, timestamp
            FROM generation_metrics
            ORDER BY timestamp DESC
            LIMIT ?
        ''', (limit,))
        
        activity = []
        for row in c.fetchall():
            activity.append({
                'project': row[0],
                'framework': row[1],
                'time': row[2],
                'success': bool(row[3]),
                'timestamp': row[4]
            })
        
        return activity
    
    def export_report(self, output_file: str, days: int = 30):
        """Export comprehensive analytics report"""
        dashboard = self.get_dashboard_data()
        
        report = f"""# AI-LA Analytics Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Period: Last {days} days

## Generation Statistics

- **Total Generations:** {dashboard['generation_stats']['total_generations']}
- **Success Rate:** {dashboard['generation_stats']['success_rate']}%
- **Avg Generation Time:** {dashboard['generation_stats']['avg_generation_time']}s
- **Total Files Generated:** {dashboard['generation_stats']['total_files']}
- **Total Lines Generated:** {dashboard['generation_stats']['total_lines']:,}
- **Most Used Framework:** {dashboard['generation_stats']['most_used_framework']}

## Performance Statistics

- **Avg Duration:** {dashboard['performance_stats']['avg_duration']}s
- **Min Duration:** {dashboard['performance_stats']['min_duration']}s
- **Max Duration:** {dashboard['performance_stats']['max_duration']}s
- **Avg CPU:** {dashboard['performance_stats']['avg_cpu_percent']}%
- **Avg Memory:** {dashboard['performance_stats']['avg_memory_mb']}MB

## Error Statistics

- **Total Errors:** {dashboard['error_stats']['total_errors']}
- **Errors by Type:** {json.dumps(dashboard['error_stats']['errors_by_type'], indent=2)}
- **Most Common:** {dashboard['error_stats']['most_common_error']}

## Recent Activity

"""
        
        for activity in dashboard['recent_activity']:
            status = "" if activity['success'] else ""
            report += f"- {status} {activity['project']} ({activity['framework']}) - {activity['time']}s - {activity['timestamp']}\n"
        
        report += "\n---\n\nGenerated by AI-LA v2.0 Monitoring System\n"
        
        Path(output_file).write_text(report)
        print(f" Exported report to {output_file}")
    
    def get_insights(self) -> List[str]:
        """Generate insights from analytics"""
        insights = []
        
        gen_stats = self.get_generation_stats(days=30)
        perf_stats = self.get_performance_stats(days=7)
        error_stats = self.get_error_stats(days=7)
        
        # Success rate insights
        if gen_stats['success_rate'] >= 95:
            insights.append(" Excellent success rate! System is highly reliable.")
        elif gen_stats['success_rate'] >= 80:
            insights.append("  Good success rate, but room for improvement.")
        else:
            insights.append(" Low success rate. Investigation needed.")
        
        # Performance insights
        if perf_stats['avg_duration'] < 5:
            insights.append(" Fast generation times! Users will love this.")
        elif perf_stats['avg_duration'] < 15:
            insights.append(" Acceptable generation times.")
        else:
            insights.append(" Slow generation times. Consider optimization.")
        
        # Error insights
        if error_stats['total_errors'] == 0:
            insights.append(" Zero errors! Perfect execution.")
        elif error_stats['total_errors'] < 5:
            insights.append(" Low error count. System is stable.")
        else:
            insights.append(f"  {error_stats['total_errors']} errors detected. Review needed.")
        
        # Usage insights
        if gen_stats['total_generations'] > 100:
            insights.append(" High usage! System is popular.")
        elif gen_stats['total_generations'] > 10:
            insights.append(" Moderate usage. Growing adoption.")
        else:
            insights.append(" Low usage. Consider promotion.")
        
        return insights


def main():
    """Test monitoring system"""
    monitor = AILAMonitor()
    
    # Track some sample data
    monitor.track_generation("test_api", "flask", 3.2, 8, 450, True)
    monitor.track_generation("web_app", "nextjs", 12.5, 15, 1200, True)
    monitor.track_performance("code_generation", 2.8, 45.2, 512)
    
    # Get statistics
    gen_stats = monitor.get_generation_stats(days=30)
    print("\n Generation Statistics:")
    print(json.dumps(gen_stats, indent=2))
    
    # Get insights
    insights = monitor.get_insights()
    print("\n Insights:")
    for insight in insights:
        print(f"  {insight}")
    
    # Export report
    monitor.export_report("/tmp/ai-la-report.md", days=30)


if __name__ == "__main__":
    main()

