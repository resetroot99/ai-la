"""
AI-LA Code Archaeology Module

The ability to understand existing codebases instantly.
This is what makes AI-LA different - it doesn't just generate new code,
it understands and works with what you already have.

Key Capabilities:
1. Codebase Mapping - Understand architecture in seconds
2. Pattern Detection - Identify coding patterns and conventions
3. Technical Debt Analysis - Find refactoring opportunities
4. Dependency Graphing - Map relationships between components
5. Historical Analysis - Understand evolution through git history
"""

import os
import ast
import json
import sqlite3
from pathlib import Path
from typing import Dict, List, Set, Optional
from dataclasses import dataclass, asdict
from collections import defaultdict
import subprocess

@dataclass
class CodeFile:
    """Represents a code file in the codebase"""
    path: str
    language: str
    lines: int
    functions: List[str]
    classes: List[str]
    imports: List[str]
    complexity: int
    last_modified: str
    authors: List[str]

@dataclass
class CodePattern:
    """A detected coding pattern"""
    pattern_type: str
    description: str
    examples: List[str]
    frequency: int
    confidence: float

@dataclass
class TechnicalDebt:
    """Technical debt item"""
    file: str
    line: int
    debt_type: str
    severity: str
    description: str
    suggestion: str

@dataclass
class Architecture:
    """Overall architecture understanding"""
    framework: str
    structure: str  # monolith, microservices, etc.
    layers: List[str]
    entry_points: List[str]
    database: Optional[str]
    api_style: Optional[str]  # REST, GraphQL, etc.

class CodeArchaeologist:
    """
    Understands existing codebases deeply and quickly
    
    This is the killer feature - while other tools start from scratch,
    AI-LA understands what you already have and works with it.
    """
    
    def __init__(self, codebase_path: str, db_path: str = "archaeology.db"):
        self.codebase_path = Path(codebase_path)
        self.db_path = db_path
        self.initialize_db()
        
    def initialize_db(self):
        """Initialize archaeology database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS files (
                path TEXT PRIMARY KEY,
                language TEXT,
                lines INTEGER,
                functions TEXT,
                classes TEXT,
                imports TEXT,
                complexity INTEGER,
                last_modified TEXT,
                authors TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS patterns (
                id INTEGER PRIMARY KEY,
                pattern_type TEXT,
                description TEXT,
                examples TEXT,
                frequency INTEGER,
                confidence REAL
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS technical_debt (
                id INTEGER PRIMARY KEY,
                file TEXT,
                line INTEGER,
                debt_type TEXT,
                severity TEXT,
                description TEXT,
                suggestion TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dependencies (
                id INTEGER PRIMARY KEY,
                source_file TEXT,
                target_file TEXT,
                dependency_type TEXT,
                strength INTEGER
            )
        """)
        
        conn.commit()
        conn.close()
    
    def excavate(self) -> Dict:
        """
        Excavate the codebase - understand everything about it
        
        This is the main entry point. It analyzes the entire codebase
        and builds a comprehensive understanding.
        """
        
        print(f"Excavating codebase at {self.codebase_path}...")
        
        # Step 1: Scan all files
        files = self._scan_files()
        print(f"Found {len(files)} code files")
        
        # Step 2: Analyze each file
        analyzed_files = []
        for file_path in files:
            analysis = self._analyze_file(file_path)
            if analysis:
                analyzed_files.append(analysis)
                self._store_file_analysis(analysis)
        
        print(f"Analyzed {len(analyzed_files)} files")
        
        # Step 3: Detect patterns
        patterns = self._detect_patterns(analyzed_files)
        print(f"Detected {len(patterns)} coding patterns")
        
        # Step 4: Identify technical debt
        debt = self._identify_technical_debt(analyzed_files)
        print(f"Found {len(debt)} technical debt items")
        
        # Step 5: Map architecture
        architecture = self._map_architecture(analyzed_files)
        print(f"Architecture: {architecture.framework} {architecture.structure}")
        
        # Step 6: Build dependency graph
        dependencies = self._build_dependency_graph(analyzed_files)
        print(f"Mapped {len(dependencies)} dependencies")
        
        # Step 7: Analyze git history
        history = self._analyze_git_history()
        print(f"Analyzed git history: {history['commits']} commits")
        
        return {
            'files': analyzed_files,
            'patterns': patterns,
            'technical_debt': debt,
            'architecture': asdict(architecture),
            'dependencies': dependencies,
            'history': history,
            'summary': self._generate_summary(analyzed_files, patterns, debt, architecture)
        }
    
    def _scan_files(self) -> List[Path]:
        """Scan for all code files"""
        code_extensions = {'.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.go', '.rs', '.rb'}
        ignore_dirs = {'node_modules', '.git', '__pycache__', 'venv', 'env', 'dist', 'build'}
        
        files = []
        for root, dirs, filenames in os.walk(self.codebase_path):
            # Remove ignored directories
            dirs[:] = [d for d in dirs if d not in ignore_dirs]
            
            for filename in filenames:
                if Path(filename).suffix in code_extensions:
                    files.append(Path(root) / filename)
        
        return files
    
    def _analyze_file(self, file_path: Path) -> Optional[CodeFile]:
        """Analyze a single code file"""
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Determine language
            language = self._detect_language(file_path)
            
            # Count lines
            lines = len(content.splitlines())
            
            # Language-specific analysis
            if language == 'python':
                return self._analyze_python_file(file_path, content, lines)
            elif language in ['javascript', 'typescript']:
                return self._analyze_js_file(file_path, content, lines)
            else:
                return self._analyze_generic_file(file_path, content, lines, language)
                
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
            return None
    
    def _analyze_python_file(self, file_path: Path, content: str, lines: int) -> CodeFile:
        """Analyze Python file using AST"""
        
        try:
            tree = ast.parse(content)
        except:
            return self._analyze_generic_file(file_path, content, lines, 'python')
        
        functions = []
        classes = []
        imports = []
        
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                functions.append(node.name)
            elif isinstance(node, ast.ClassDef):
                classes.append(node.name)
            elif isinstance(node, (ast.Import, ast.ImportFrom)):
                if isinstance(node, ast.Import):
                    imports.extend([alias.name for alias in node.names])
                else:
                    imports.append(node.module or '')
        
        # Calculate complexity (simplified)
        complexity = len(functions) + len(classes) * 2
        
        # Get git info
        last_modified, authors = self._get_git_info(file_path)
        
        return CodeFile(
            path=str(file_path.relative_to(self.codebase_path)),
            language='python',
            lines=lines,
            functions=functions,
            classes=classes,
            imports=list(set(imports)),
            complexity=complexity,
            last_modified=last_modified,
            authors=authors
        )
    
    def _analyze_js_file(self, file_path: Path, content: str, lines: int) -> CodeFile:
        """Analyze JavaScript/TypeScript file"""
        
        # Simple regex-based analysis (in production, use proper parser)
        import re
        
        functions = re.findall(r'function\s+(\w+)|const\s+(\w+)\s*=\s*\([^)]*\)\s*=>', content)
        functions = [f[0] or f[1] for f in functions]
        
        classes = re.findall(r'class\s+(\w+)', content)
        
        imports = re.findall(r'import.*from\s+[\'"]([^\'"]+)[\'"]', content)
        imports += re.findall(r'require\([\'"]([^\'"]+)[\'"]\)', content)
        
        complexity = len(functions) + len(classes) * 2
        
        last_modified, authors = self._get_git_info(file_path)
        
        return CodeFile(
            path=str(file_path.relative_to(self.codebase_path)),
            language='javascript' if file_path.suffix == '.js' else 'typescript',
            lines=lines,
            functions=functions,
            classes=classes,
            imports=list(set(imports)),
            complexity=complexity,
            last_modified=last_modified,
            authors=authors
        )
    
    def _analyze_generic_file(self, file_path: Path, content: str, lines: int, language: str) -> CodeFile:
        """Generic file analysis"""
        
        last_modified, authors = self._get_git_info(file_path)
        
        return CodeFile(
            path=str(file_path.relative_to(self.codebase_path)),
            language=language,
            lines=lines,
            functions=[],
            classes=[],
            imports=[],
            complexity=0,
            last_modified=last_modified,
            authors=authors
        )
    
    def _detect_language(self, file_path: Path) -> str:
        """Detect programming language from file extension"""
        ext_map = {
            '.py': 'python',
            '.js': 'javascript',
            '.ts': 'typescript',
            '.jsx': 'javascript',
            '.tsx': 'typescript',
            '.java': 'java',
            '.go': 'go',
            '.rs': 'rust',
            '.rb': 'ruby'
        }
        return ext_map.get(file_path.suffix, 'unknown')
    
    def _get_git_info(self, file_path: Path) -> tuple:
        """Get git information for a file"""
        try:
            # Get last modified date
            result = subprocess.run(
                ['git', 'log', '-1', '--format=%ci', str(file_path)],
                capture_output=True,
                text=True,
                cwd=self.codebase_path
            )
            last_modified = result.stdout.strip() or 'unknown'
            
            # Get authors
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
    
    def _detect_patterns(self, files: List[CodeFile]) -> List[CodePattern]:
        """Detect coding patterns across the codebase"""
        
        patterns = []
        
        # Pattern 1: Naming conventions
        function_names = []
        for file in files:
            function_names.extend(file.functions)
        
        if function_names:
            # Check if snake_case
            snake_case_count = sum(1 for name in function_names if '_' in name and name.islower())
            if snake_case_count / len(function_names) > 0.7:
                patterns.append(CodePattern(
                    pattern_type='naming',
                    description='snake_case for functions',
                    examples=function_names[:3],
                    frequency=snake_case_count,
                    confidence=snake_case_count / len(function_names)
                ))
        
        # Pattern 2: Import style
        all_imports = []
        for file in files:
            all_imports.extend(file.imports)
        
        if all_imports:
            # Check for common frameworks
            frameworks = defaultdict(int)
            for imp in all_imports:
                if 'flask' in imp.lower():
                    frameworks['Flask'] += 1
                elif 'fastapi' in imp.lower():
                    frameworks['FastAPI'] += 1
                elif 'django' in imp.lower():
                    frameworks['Django'] += 1
                elif 'react' in imp.lower():
                    frameworks['React'] += 1
            
            for framework, count in frameworks.items():
                patterns.append(CodePattern(
                    pattern_type='framework',
                    description=f'Uses {framework}',
                    examples=[imp for imp in all_imports if framework.lower() in imp.lower()][:3],
                    frequency=count,
                    confidence=min(count / len(files), 1.0)
                ))
        
        # Pattern 3: File organization
        file_paths = [file.path for file in files]
        if any('tests/' in path or 'test_' in path for path in file_paths):
            test_files = [p for p in file_paths if 'test' in p.lower()]
            patterns.append(CodePattern(
                pattern_type='testing',
                description='Has test files',
                examples=test_files[:3],
                frequency=len(test_files),
                confidence=0.9
            ))
        
        # Store patterns
        for pattern in patterns:
            self._store_pattern(pattern)
        
        return patterns
    
    def _identify_technical_debt(self, files: List[CodeFile]) -> List[TechnicalDebt]:
        """Identify technical debt in the codebase"""
        
        debt_items = []
        
        for file in files:
            # Large files
            if file.lines > 500:
                debt_items.append(TechnicalDebt(
                    file=file.path,
                    line=0,
                    debt_type='large_file',
                    severity='medium',
                    description=f'File has {file.lines} lines (>500)',
                    suggestion='Consider splitting into smaller modules'
                ))
            
            # High complexity
            if file.complexity > 20:
                debt_items.append(TechnicalDebt(
                    file=file.path,
                    line=0,
                    debt_type='high_complexity',
                    severity='medium',
                    description=f'High complexity score: {file.complexity}',
                    suggestion='Refactor to reduce complexity'
                ))
            
            # Too many imports
            if len(file.imports) > 15:
                debt_items.append(TechnicalDebt(
                    file=file.path,
                    line=0,
                    debt_type='many_imports',
                    severity='low',
                    description=f'{len(file.imports)} imports',
                    suggestion='Consider reducing dependencies'
                ))
        
        # Store debt items
        for debt in debt_items:
            self._store_technical_debt(debt)
        
        return debt_items
    
    def _map_architecture(self, files: List[CodeFile]) -> Architecture:
        """Map the overall architecture"""
        
        # Detect framework
        all_imports = []
        for file in files:
            all_imports.extend(file.imports)
        
        framework = 'unknown'
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
            elif 'express' in imp.lower():
                framework = 'Express'
                break
            elif 'react' in imp.lower():
                framework = 'React'
                break
        
        # Detect structure
        file_paths = [file.path for file in files]
        if any('microservices' in path or 'services/' in path for path in file_paths):
            structure = 'microservices'
        else:
            structure = 'monolith'
        
        # Detect layers
        layers = []
        if any('models' in path or 'model' in path for path in file_paths):
            layers.append('data')
        if any('views' in path or 'routes' in path or 'controllers' in path for path in file_paths):
            layers.append('presentation')
        if any('services' in path or 'business' in path for path in file_paths):
            layers.append('business')
        
        # Find entry points
        entry_points = []
        for file in files:
            if 'main' in file.path or 'app' in file.path or 'index' in file.path:
                entry_points.append(file.path)
        
        # Detect database
        database = None
        for imp in all_imports:
            if 'postgres' in imp.lower() or 'psycopg' in imp.lower():
                database = 'PostgreSQL'
                break
            elif 'mysql' in imp.lower():
                database = 'MySQL'
                break
            elif 'sqlite' in imp.lower():
                database = 'SQLite'
                break
            elif 'mongo' in imp.lower():
                database = 'MongoDB'
                break
        
        # Detect API style
        api_style = None
        if framework in ['Flask', 'FastAPI', 'Django', 'Express']:
            api_style = 'REST'
        
        return Architecture(
            framework=framework,
            structure=structure,
            layers=layers,
            entry_points=entry_points,
            database=database,
            api_style=api_style
        )
    
    def _build_dependency_graph(self, files: List[CodeFile]) -> List[Dict]:
        """Build dependency graph between files"""
        
        dependencies = []
        
        # Create file lookup by name
        file_lookup = {Path(f.path).stem: f for f in files}
        
        for file in files:
            for imp in file.imports:
                # Check if import is internal
                imp_name = imp.split('.')[-1]
                if imp_name in file_lookup:
                    dependencies.append({
                        'source': file.path,
                        'target': file_lookup[imp_name].path,
                        'type': 'import'
                    })
        
        return dependencies
    
    def _analyze_git_history(self) -> Dict:
        """Analyze git history for insights"""
        
        try:
            # Get commit count
            result = subprocess.run(
                ['git', 'rev-list', '--count', 'HEAD'],
                capture_output=True,
                text=True,
                cwd=self.codebase_path
            )
            commits = int(result.stdout.strip()) if result.stdout else 0
            
            # Get contributors
            result = subprocess.run(
                ['git', 'shortlog', '-sn', 'HEAD'],
                capture_output=True,
                text=True,
                cwd=self.codebase_path
            )
            contributors = len(result.stdout.strip().split('\n')) if result.stdout else 0
            
            # Get age
            result = subprocess.run(
                ['git', 'log', '--reverse', '--format=%ci', '--max-count=1'],
                capture_output=True,
                text=True,
                cwd=self.codebase_path
            )
            first_commit = result.stdout.strip() if result.stdout else 'unknown'
            
            return {
                'commits': commits,
                'contributors': contributors,
                'first_commit': first_commit
            }
        except:
            return {
                'commits': 0,
                'contributors': 0,
                'first_commit': 'unknown'
            }
    
    def _generate_summary(self, files: List[CodeFile], patterns: List[CodePattern], 
                         debt: List[TechnicalDebt], architecture: Architecture) -> str:
        """Generate human-readable summary"""
        
        total_lines = sum(f.lines for f in files)
        languages = defaultdict(int)
        for f in files:
            languages[f.language] += 1
        
        summary = f"""
Codebase Analysis Summary
========================

Files: {len(files)}
Total Lines: {total_lines:,}
Languages: {', '.join(f'{lang} ({count})' for lang, count in languages.items())}

Architecture:
- Framework: {architecture.framework}
- Structure: {architecture.structure}
- Database: {architecture.database or 'None detected'}
- API Style: {architecture.api_style or 'None detected'}
- Layers: {', '.join(architecture.layers) if architecture.layers else 'None detected'}

Patterns Detected: {len(patterns)}
{chr(10).join(f'- {p.description} (confidence: {p.confidence:.0%})' for p in patterns[:5])}

Technical Debt: {len(debt)} items
{chr(10).join(f'- {d.debt_type}: {d.description}' for d in debt[:5])}

Entry Points:
{chr(10).join(f'- {ep}' for ep in architecture.entry_points[:5])}
"""
        return summary
    
    def _store_file_analysis(self, file: CodeFile):
        """Store file analysis in database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT OR REPLACE INTO files 
            (path, language, lines, functions, classes, imports, complexity, last_modified, authors)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            file.path,
            file.language,
            file.lines,
            json.dumps(file.functions),
            json.dumps(file.classes),
            json.dumps(file.imports),
            file.complexity,
            file.last_modified,
            json.dumps(file.authors)
        ))
        
        conn.commit()
        conn.close()
    
    def _store_pattern(self, pattern: CodePattern):
        """Store detected pattern"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO patterns (pattern_type, description, examples, frequency, confidence)
            VALUES (?, ?, ?, ?, ?)
        """, (
            pattern.pattern_type,
            pattern.description,
            json.dumps(pattern.examples),
            pattern.frequency,
            pattern.confidence
        ))
        
        conn.commit()
        conn.close()
    
    def _store_technical_debt(self, debt: TechnicalDebt):
        """Store technical debt item"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO technical_debt (file, line, debt_type, severity, description, suggestion)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            debt.file,
            debt.line,
            debt.debt_type,
            debt.severity,
            debt.description,
            debt.suggestion
        ))
        
        conn.commit()
        conn.close()


# Example usage
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        codebase_path = sys.argv[1]
    else:
        codebase_path = "."  # Current directory
    
    print(f"AI-LA Code Archaeology")
    print(f"======================\n")
    
    archaeologist = CodeArchaeologist(codebase_path)
    results = archaeologist.excavate()
    
    print(f"\n{results['summary']}")
    
    print(f"\nArchaeology complete!")
    print(f"Database saved to: archaeology.db")

