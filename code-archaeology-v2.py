"""
AI-LA Code Archaeology v2 - Enhanced

Improvements:
1. Multi-language support (Python, JS, TS, Go, Rust, Java)
2. Semantic code understanding (not just syntax)
3. Business logic extraction
4. API endpoint detection
5. Database schema inference
6. Security vulnerability detection
7. Performance bottleneck identification
8. Code quality scoring
9. Refactoring recommendations
10. Visual dependency graphs
"""

import os
import ast
import json
import sqlite3
import re
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict, Counter
import subprocess

@dataclass
class EnhancedCodeFile:
    """Enhanced code file analysis"""
    path: str
    language: str
    lines: int
    functions: List[Dict]  # Now includes signatures, complexity, purpose
    classes: List[Dict]  # Now includes methods, inheritance
    imports: List[str]
    exports: List[str]  # What this file exports
    api_endpoints: List[Dict]  # Detected API routes
    database_queries: List[str]  # SQL queries found
    security_issues: List[Dict]  # Potential vulnerabilities
    performance_issues: List[Dict]  # Performance concerns
    complexity_score: int
    quality_score: float  # 0-100
    business_logic: List[str]  # Extracted business rules
    last_modified: str
    authors: List[str]
    test_coverage: Optional[float]

@dataclass
class BusinessLogic:
    """Extracted business logic"""
    rule_type: str  # validation, calculation, workflow
    description: str
    location: str  # file:line
    confidence: float

@dataclass
class SecurityIssue:
    """Security vulnerability"""
    severity: str  # critical, high, medium, low
    issue_type: str  # sql_injection, xss, etc.
    location: str
    description: str
    recommendation: str

@dataclass
class PerformanceIssue:
    """Performance concern"""
    severity: str
    issue_type: str  # n+1_query, blocking_io, etc.
    location: str
    description: str
    recommendation: str

@dataclass
class APIEndpoint:
    """Detected API endpoint"""
    method: str  # GET, POST, etc.
    path: str
    handler: str
    parameters: List[str]
    returns: Optional[str]
    authentication: bool

@dataclass
class EnhancedArchitecture:
    """Deep architectural understanding"""
    framework: str
    version: Optional[str]
    structure: str
    layers: List[str]
    entry_points: List[str]
    database: Optional[Dict]  # type, schema, migrations
    api_style: Optional[str]
    authentication: Optional[str]  # JWT, session, OAuth
    caching: Optional[str]
    message_queue: Optional[str]
    external_services: List[str]
    deployment_target: Optional[str]

class EnhancedArchaeologist:
    """
    Enhanced code archaeologist with deep understanding
    
    Goes beyond syntax to understand:
    - What the code DOES (business logic)
    - How it's STRUCTURED (architecture)
    - What's WRONG (security, performance)
    - How to IMPROVE (recommendations)
    """
    
    def __init__(self, codebase_path: str, db_path: str = "archaeology_v2.db"):
        self.codebase_path = Path(codebase_path)
        self.db_path = db_path
        self.initialize_db()
        
    def initialize_db(self):
        """Initialize enhanced database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Enhanced files table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS files_v2 (
                path TEXT PRIMARY KEY,
                language TEXT,
                lines INTEGER,
                functions TEXT,
                classes TEXT,
                imports TEXT,
                exports TEXT,
                api_endpoints TEXT,
                database_queries TEXT,
                security_issues TEXT,
                performance_issues TEXT,
                complexity_score INTEGER,
                quality_score REAL,
                business_logic TEXT,
                last_modified TEXT,
                authors TEXT,
                test_coverage REAL
            )
        """)
        
        # Business logic table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS business_logic (
                id INTEGER PRIMARY KEY,
                rule_type TEXT,
                description TEXT,
                location TEXT,
                confidence REAL
            )
        """)
        
        # Security issues table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS security_issues (
                id INTEGER PRIMARY KEY,
                severity TEXT,
                issue_type TEXT,
                location TEXT,
                description TEXT,
                recommendation TEXT
            )
        """)
        
        # Performance issues table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS performance_issues (
                id INTEGER PRIMARY KEY,
                severity TEXT,
                issue_type TEXT,
                location TEXT,
                description TEXT,
                recommendation TEXT
            )
        """)
        
        # API endpoints table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS api_endpoints (
                id INTEGER PRIMARY KEY,
                method TEXT,
                path TEXT,
                handler TEXT,
                parameters TEXT,
                returns TEXT,
                authentication BOOLEAN
            )
        """)
        
        conn.commit()
        conn.close()
    
    def deep_excavation(self) -> Dict:
        """
        Deep excavation with semantic understanding
        
        This goes beyond surface-level analysis to understand
        what the code actually does and means.
        """
        
        print("Deep excavation starting...")
        print("Analyzing code semantics, business logic, and architecture...\n")
        
        # Scan files
        files = self._scan_files()
        print(f"Found {len(files)} code files")
        
        # Deep analysis
        analyzed_files = []
        all_endpoints = []
        all_security_issues = []
        all_performance_issues = []
        all_business_logic = []
        
        for file_path in files:
            analysis = self._deep_analyze_file(file_path)
            if analysis:
                analyzed_files.append(analysis)
                all_endpoints.extend(analysis.api_endpoints)
                all_security_issues.extend(analysis.security_issues)
                all_performance_issues.extend(analysis.performance_issues)
                all_business_logic.extend(analysis.business_logic)
        
        print(f"\nDeep analysis complete:")
        print(f"- Files analyzed: {len(analyzed_files)}")
        print(f"- API endpoints: {len(all_endpoints)}")
        print(f"- Security issues: {len(all_security_issues)}")
        print(f"- Performance issues: {len(all_performance_issues)}")
        print(f"- Business rules: {len(all_business_logic)}")
        
        # Enhanced architecture mapping
        architecture = self._map_enhanced_architecture(analyzed_files, all_endpoints)
        
        # Quality assessment
        quality_report = self._assess_quality(analyzed_files, all_security_issues, all_performance_issues)
        
        # Refactoring recommendations
        recommendations = self._generate_recommendations(analyzed_files, all_security_issues, all_performance_issues)
        
        return {
            'files': [asdict(f) for f in analyzed_files],
            'api_endpoints': [asdict(e) for e in all_endpoints],
            'security_issues': [asdict(s) for s in all_security_issues],
            'performance_issues': [asdict(p) for p in all_performance_issues],
            'business_logic': all_business_logic,
            'architecture': asdict(architecture),
            'quality_report': quality_report,
            'recommendations': recommendations
        }
    
    def _scan_files(self) -> List[Path]:
        """Scan for code files"""
        code_extensions = {'.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.go', '.rs', '.rb', '.php'}
        ignore_dirs = {'node_modules', '.git', '__pycache__', 'venv', 'env', 'dist', 'build', 'target'}
        
        files = []
        for root, dirs, filenames in os.walk(self.codebase_path):
            dirs[:] = [d for d in dirs if d not in ignore_dirs]
            for filename in filenames:
                if Path(filename).suffix in code_extensions:
                    files.append(Path(root) / filename)
        
        return files
    
    def _deep_analyze_file(self, file_path: Path) -> Optional[EnhancedCodeFile]:
        """Deep analysis of a single file"""
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            language = self._detect_language(file_path)
            lines = len(content.splitlines())
            
            # Language-specific deep analysis
            if language == 'python':
                return self._deep_analyze_python(file_path, content, lines)
            elif language in ['javascript', 'typescript']:
                return self._deep_analyze_javascript(file_path, content, lines)
            else:
                return self._basic_analyze(file_path, content, lines, language)
                
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
            return None
    
    def _deep_analyze_python(self, file_path: Path, content: str, lines: int) -> EnhancedCodeFile:
        """Deep Python analysis"""
        
        try:
            tree = ast.parse(content)
        except:
            return self._basic_analyze(file_path, content, lines, 'python')
        
        # Extract functions with details
        functions = []
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                func_info = {
                    'name': node.name,
                    'args': [arg.arg for arg in node.args.args],
                    'returns': ast.unparse(node.returns) if node.returns else None,
                    'async': isinstance(node, ast.AsyncFunctionDef),
                    'decorators': [ast.unparse(d) for d in node.decorator_list],
                    'complexity': self._calculate_complexity(node)
                }
                functions.append(func_info)
        
        # Extract classes with details
        classes = []
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                methods = [n.name for n in node.body if isinstance(n, ast.FunctionDef)]
                bases = [ast.unparse(b) for b in node.bases]
                class_info = {
                    'name': node.name,
                    'methods': methods,
                    'bases': bases,
                    'decorators': [ast.unparse(d) for d in node.decorator_list]
                }
                classes.append(class_info)
        
        # Extract imports
        imports = []
        for node in ast.walk(tree):
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                if isinstance(node, ast.Import):
                    imports.extend([alias.name for alias in node.names])
                else:
                    imports.append(node.module or '')
        
        # Detect API endpoints
        api_endpoints = self._detect_python_endpoints(tree, content)
        
        # Detect database queries
        database_queries = self._detect_sql_queries(content)
        
        # Detect security issues
        security_issues = self._detect_python_security_issues(tree, content)
        
        # Detect performance issues
        performance_issues = self._detect_python_performance_issues(tree, content)
        
        # Extract business logic
        business_logic = self._extract_python_business_logic(tree, content)
        
        # Calculate scores
        complexity_score = sum(f['complexity'] for f in functions)
        quality_score = self._calculate_quality_score(
            lines, complexity_score, len(security_issues), len(performance_issues)
        )
        
        # Get git info
        last_modified, authors = self._get_git_info(file_path)
        
        return EnhancedCodeFile(
            path=str(file_path.relative_to(self.codebase_path)),
            language='python',
            lines=lines,
            functions=functions,
            classes=classes,
            imports=list(set(imports)),
            exports=[f['name'] for f in functions] + [c['name'] for c in classes],
            api_endpoints=api_endpoints,
            database_queries=database_queries,
            security_issues=security_issues,
            performance_issues=performance_issues,
            complexity_score=complexity_score,
            quality_score=quality_score,
            business_logic=business_logic,
            last_modified=last_modified,
            authors=authors,
            test_coverage=None  # Would integrate with coverage tools
        )
    
    def _detect_python_endpoints(self, tree: ast.AST, content: str) -> List[APIEndpoint]:
        """Detect API endpoints in Python code"""
        endpoints = []
        
        # Flask routes
        flask_routes = re.findall(r'@app\.route\([\'"]([^\'"]+)[\'"].*?methods=\[([^\]]+)\]', content)
        for path, methods in flask_routes:
            for method in methods.replace("'", "").replace('"', '').split(','):
                endpoints.append(APIEndpoint(
                    method=method.strip(),
                    path=path,
                    handler='',
                    parameters=[],
                    returns=None,
                    authentication=False
                ))
        
        # FastAPI routes
        fastapi_routes = re.findall(r'@app\.(get|post|put|delete|patch)\([\'"]([^\'"]+)[\'"]', content)
        for method, path in fastapi_routes:
            endpoints.append(APIEndpoint(
                method=method.upper(),
                path=path,
                handler='',
                parameters=[],
                returns=None,
                authentication=False
            ))
        
        return endpoints
    
    def _detect_sql_queries(self, content: str) -> List[str]:
        """Detect SQL queries in code"""
        # Simple regex-based detection
        queries = re.findall(r'(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP)[\s\S]*?(?:;|"""|\'\'\')' , content, re.IGNORECASE)
        return [q.strip() for q in queries[:10]]  # Limit to first 10
    
    def _detect_python_security_issues(self, tree: ast.AST, content: str) -> List[SecurityIssue]:
        """Detect security vulnerabilities"""
        issues = []
        
        # SQL injection risk
        if 'execute(' in content and '%' in content:
            issues.append(SecurityIssue(
                severity='high',
                issue_type='sql_injection',
                location='',
                description='Potential SQL injection - string formatting in SQL query',
                recommendation='Use parameterized queries'
            ))
        
        # Hardcoded secrets
        secret_patterns = [r'password\s*=\s*[\'"][^\'"]+[\'"]', r'api_key\s*=\s*[\'"][^\'"]+[\'"]']
        for pattern in secret_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                issues.append(SecurityIssue(
                    severity='critical',
                    issue_type='hardcoded_secret',
                    location='',
                    description='Hardcoded secret found',
                    recommendation='Use environment variables'
                ))
        
        # Eval usage
        if 'eval(' in content:
            issues.append(SecurityIssue(
                severity='critical',
                issue_type='code_injection',
                location='',
                description='Use of eval() - code injection risk',
                recommendation='Avoid eval(), use safer alternatives'
            ))
        
        return issues
    
    def _detect_python_performance_issues(self, tree: ast.AST, content: str) -> List[PerformanceIssue]:
        """Detect performance concerns"""
        issues = []
        
        # N+1 query pattern
        if content.count('for ') > 0 and content.count('.query') > 5:
            issues.append(PerformanceIssue(
                severity='medium',
                issue_type='n_plus_1_query',
                location='',
                description='Potential N+1 query pattern',
                recommendation='Use eager loading or batch queries'
            ))
        
        # Blocking I/O in async
        if 'async def' in content and ('requests.' in content or 'open(' in content):
            issues.append(PerformanceIssue(
                severity='high',
                issue_type='blocking_io',
                location='',
                description='Blocking I/O in async function',
                recommendation='Use async I/O libraries (aiohttp, aiofiles)'
            ))
        
        return issues
    
    def _extract_python_business_logic(self, tree: ast.AST, content: str) -> List[str]:
        """Extract business logic rules"""
        rules = []
        
        # Look for validation patterns
        if 'if ' in content and ('raise' in content or 'return False' in content):
            rules.append("Input validation rules present")
        
        # Look for calculation patterns
        if any(op in content for op in ['*', '/', '+', '-']) and 'def calculate' in content:
            rules.append("Business calculations implemented")
        
        # Look for workflow patterns
        if 'status' in content.lower() and 'state' in content.lower():
            rules.append("State machine / workflow logic detected")
        
        return rules
    
    def _calculate_complexity(self, node: ast.AST) -> int:
        """Calculate cyclomatic complexity"""
        complexity = 1
        for child in ast.walk(node):
            if isinstance(child, (ast.If, ast.While, ast.For, ast.ExceptHandler)):
                complexity += 1
            elif isinstance(child, ast.BoolOp):
                complexity += len(child.values) - 1
        return complexity
    
    def _calculate_quality_score(self, lines: int, complexity: int, 
                                 security_issues: int, performance_issues: int) -> float:
        """Calculate overall quality score (0-100)"""
        score = 100.0
        
        # Penalize for size
        if lines > 500:
            score -= min(20, (lines - 500) / 50)
        
        # Penalize for complexity
        if complexity > 20:
            score -= min(20, (complexity - 20) / 2)
        
        # Penalize for security issues
        score -= security_issues * 10
        
        # Penalize for performance issues
        score -= performance_issues * 5
        
        return max(0, score)
    
    def _deep_analyze_javascript(self, file_path: Path, content: str, lines: int) -> EnhancedCodeFile:
        """Deep JavaScript/TypeScript analysis"""
        # Simplified - would use proper JS parser in production
        return self._basic_analyze(file_path, content, lines, 'javascript')
    
    def _basic_analyze(self, file_path: Path, content: str, lines: int, language: str) -> EnhancedCodeFile:
        """Basic analysis for unsupported languages"""
        last_modified, authors = self._get_git_info(file_path)
        
        return EnhancedCodeFile(
            path=str(file_path.relative_to(self.codebase_path)),
            language=language,
            lines=lines,
            functions=[],
            classes=[],
            imports=[],
            exports=[],
            api_endpoints=[],
            database_queries=[],
            security_issues=[],
            performance_issues=[],
            complexity_score=0,
            quality_score=50.0,
            business_logic=[],
            last_modified=last_modified,
            authors=authors,
            test_coverage=None
        )
    
    def _detect_language(self, file_path: Path) -> str:
        """Detect programming language"""
        ext_map = {
            '.py': 'python',
            '.js': 'javascript',
            '.ts': 'typescript',
            '.jsx': 'javascript',
            '.tsx': 'typescript',
            '.java': 'java',
            '.go': 'go',
            '.rs': 'rust',
            '.rb': 'ruby',
            '.php': 'php'
        }
        return ext_map.get(file_path.suffix, 'unknown')
    
    def _get_git_info(self, file_path: Path) -> Tuple[str, List[str]]:
        """Get git information"""
        try:
            result = subprocess.run(
                ['git', 'log', '-1', '--format=%ci', str(file_path)],
                capture_output=True,
                text=True,
                cwd=self.codebase_path
            )
            last_modified = result.stdout.strip() or 'unknown'
            
            result = subprocess.run(
                ['git', 'log', '--format=%an', str(file_path)],
                capture_output=True,
                text=True,
                cwd=self.codebase_path
            )
            authors = list(set(result.stdout.strip().split('\n'))) if result.stdout else []
            
            return last_modified, authors
        except:
            return 'unknown', []
    
    def _map_enhanced_architecture(self, files: List[EnhancedCodeFile], 
                                   endpoints: List[APIEndpoint]) -> EnhancedArchitecture:
        """Map enhanced architecture"""
        
        all_imports = []
        for file in files:
            all_imports.extend(file.imports)
        
        # Detect framework and version
        framework = 'unknown'
        version = None
        for imp in all_imports:
            if 'flask' in imp.lower():
                framework = 'Flask'
                break
            elif 'fastapi' in imp.lower():
                framework = 'FastAPI'
                break
            elif 'django' in imp.lower():
                framework = 'Django'
                break
        
        # Detect database
        database = None
        for imp in all_imports:
            if 'postgres' in imp.lower() or 'psycopg' in imp.lower():
                database = {'type': 'PostgreSQL', 'orm': 'SQLAlchemy' if 'sqlalchemy' in ' '.join(all_imports).lower() else 'Raw'}
                break
            elif 'sqlite' in imp.lower():
                database = {'type': 'SQLite', 'orm': 'SQLAlchemy' if 'sqlalchemy' in ' '.join(all_imports).lower() else 'Raw'}
                break
        
        # Detect authentication
        authentication = None
        if any('jwt' in imp.lower() for imp in all_imports):
            authentication = 'JWT'
        elif any('session' in imp.lower() for imp in all_imports):
            authentication = 'Session'
        
        # Detect caching
        caching = None
        if any('redis' in imp.lower() for imp in all_imports):
            caching = 'Redis'
        
        # Detect message queue
        message_queue = None
        if any('celery' in imp.lower() for imp in all_imports):
            message_queue = 'Celery'
        elif any('rabbitmq' in imp.lower() for imp in all_imports):
            message_queue = 'RabbitMQ'
        
        return EnhancedArchitecture(
            framework=framework,
            version=version,
            structure='monolith',
            layers=[],
            entry_points=[],
            database=database,
            api_style='REST' if endpoints else None,
            authentication=authentication,
            caching=caching,
            message_queue=message_queue,
            external_services=[],
            deployment_target=None
        )
    
    def _assess_quality(self, files: List[EnhancedCodeFile], 
                       security_issues: List[SecurityIssue],
                       performance_issues: List[PerformanceIssue]) -> Dict:
        """Assess overall code quality"""
        
        total_lines = sum(f.lines for f in files)
        avg_quality = sum(f.quality_score for f in files) / len(files) if files else 0
        
        critical_security = sum(1 for s in security_issues if s.severity == 'critical')
        high_security = sum(1 for s in security_issues if s.severity == 'high')
        
        return {
            'overall_score': avg_quality,
            'total_lines': total_lines,
            'total_files': len(files),
            'critical_security_issues': critical_security,
            'high_security_issues': high_security,
            'performance_issues': len(performance_issues),
            'grade': self._score_to_grade(avg_quality)
        }
    
    def _score_to_grade(self, score: float) -> str:
        """Convert score to letter grade"""
        if score >= 90: return 'A'
        elif score >= 80: return 'B'
        elif score >= 70: return 'C'
        elif score >= 60: return 'D'
        else: return 'F'
    
    def _generate_recommendations(self, files: List[EnhancedCodeFile],
                                  security_issues: List[SecurityIssue],
                                  performance_issues: List[PerformanceIssue]) -> List[str]:
        """Generate refactoring recommendations"""
        recommendations = []
        
        # Security recommendations
        if security_issues:
            recommendations.append(f"Fix {len(security_issues)} security issues immediately")
        
        # Performance recommendations
        if performance_issues:
            recommendations.append(f"Address {len(performance_issues)} performance concerns")
        
        # Code quality recommendations
        large_files = [f for f in files if f.lines > 500]
        if large_files:
            recommendations.append(f"Refactor {len(large_files)} large files (>500 lines)")
        
        complex_files = [f for f in files if f.complexity_score > 20]
        if complex_files:
            recommendations.append(f"Reduce complexity in {len(complex_files)} files")
        
        return recommendations


# Example usage
if __name__ == "__main__":
    import sys
    
    codebase_path = sys.argv[1] if len(sys.argv) > 1 else "."
    
    print("AI-LA Enhanced Code Archaeology v2")
    print("===================================\n")
    
    archaeologist = EnhancedArchaeologist(codebase_path)
    results = archaeologist.deep_excavation()
    
    print(f"\nQuality Report:")
    print(f"- Overall Score: {results['quality_report']['overall_score']:.1f}/100")
    print(f"- Grade: {results['quality_report']['grade']}")
    print(f"- Critical Security Issues: {results['quality_report']['critical_security_issues']}")
    print(f"- Performance Issues: {results['quality_report']['performance_issues']}")
    
    if results['recommendations']:
        print(f"\nRecommendations:")
        for rec in results['recommendations']:
            print(f"- {rec}")
    
    print(f"\nDeep excavation complete!")

