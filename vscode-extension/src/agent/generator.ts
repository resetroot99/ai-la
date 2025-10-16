/**
 * Code Generator - Generates production-ready code from plans
 */

import * as vscode from 'vscode';
import { TECPManager } from '../tecp/manager';
import { AIBackend, Plan } from './backend';

export interface GeneratedFile {
    path: string;
    content: string;
    lines: number;
}

export interface GeneratedCode {
    files: GeneratedFile[];
    totalLines: number;
    dependencies: string[];
}

export class CodeGenerator {
    private backend: AIBackend;
    
    constructor(
        private context: vscode.ExtensionContext,
        private tecpManager: TECPManager
    ) {
        this.backend = new AIBackend(context);
    }
    
    async generate(plan: Plan): Promise<GeneratedCode> {
        const files: GeneratedFile[] = [];
        const dependencies = new Set<string>();
        let totalLines = 0;
        
        try {
            // Generate code for each step
            for (const step of plan.steps) {
                const stepFiles = await this.generateStep(step, plan.architecture);
                files.push(...stepFiles);
                
                // Collect dependencies
                step.dependencies.forEach(dep => dependencies.add(dep));
                
                // Count lines
                stepFiles.forEach(file => {
                    totalLines += file.lines;
                });
            }
            
            // Generate additional files
            const additionalFiles = await this.generateAdditionalFiles(plan);
            files.push(...additionalFiles);
            
            return {
                files,
                totalLines,
                dependencies: Array.from(dependencies)
            };
            
        } catch (error) {
            throw new Error(`Code generation failed: ${error}`);
        }
    }
    
    private async generateStep(step: any, architecture: any): Promise<GeneratedFile[]> {
        const files: GeneratedFile[] = [];
        
        for (const filePath of step.files) {
            const content = await this.generateFile(filePath, step.description, architecture);
            const lines = content.split('\n').length;
            
            files.push({
                path: filePath,
                content,
                lines
            });
            
            // Create TECP receipt for each file
            await this.tecpManager.createReceipt({
                operation: 'generate_file',
                input: `${filePath}: ${step.description}`,
                output: content
            });
        }
        
        return files;
    }
    
    private async generateFile(
        filePath: string,
        description: string,
        architecture: any
    ): Promise<string> {
        const extension = filePath.split('.').pop();
        const language = this.getLanguage(extension || '');
        
        const context = {
            filePath,
            description,
            architecture,
            language
        };
        
        let content = await this.backend.generateCode(description, context);
        
        // Post-process content
        content = this.postProcess(content, filePath);
        
        return content;
    }
    
    private async generateAdditionalFiles(plan: Plan): Promise<GeneratedFile[]> {
        const files: GeneratedFile[] = [];
        
        // Generate requirements.txt / package.json
        if (plan.architecture.framework === 'fastapi' || plan.architecture.framework === 'flask') {
            const requirements = this.generateRequirements(plan);
            files.push({
                path: 'requirements.txt',
                content: requirements,
                lines: requirements.split('\n').length
            });
        }
        
        // Generate README.md
        const readme = this.generateReadme(plan);
        files.push({
            path: 'README.md',
            content: readme,
            lines: readme.split('\n').length
        });
        
        // Generate .gitignore
        const gitignore = this.generateGitignore(plan);
        files.push({
            path: '.gitignore',
            content: gitignore,
            lines: gitignore.split('\n').length
        });
        
        // Generate tests
        const testFile = this.generateTests(plan);
        files.push({
            path: 'test_main.py',
            content: testFile,
            lines: testFile.split('\n').length
        });
        
        return files;
    }
    
    private generateRequirements(plan: Plan): string {
        const deps = new Set<string>();
        
        // Add framework
        if (plan.architecture.framework === 'fastapi') {
            deps.add('fastapi');
            deps.add('uvicorn');
        } else if (plan.architecture.framework === 'flask') {
            deps.add('flask');
        }
        
        // Add database
        if (plan.architecture.database === 'postgresql') {
            deps.add('psycopg2-binary');
            deps.add('sqlalchemy');
        }
        
        // Add authentication
        if (plan.architecture.authentication === 'jwt') {
            deps.add('pyjwt');
            deps.add('passlib');
        }
        
        // Add testing
        deps.add('pytest');
        deps.add('pytest-cov');
        
        return Array.from(deps).sort().join('\n') + '\n';
    }
    
    private generateReadme(plan: Plan): string {
        return `# Generated by AI-LA Agent

## Architecture

- Framework: ${plan.architecture.framework}
- Database: ${plan.architecture.database || 'None'}
- Authentication: ${plan.architecture.authentication || 'None'}

## Installation

\`\`\`bash
pip install -r requirements.txt
\`\`\`

## Running

\`\`\`bash
python main.py
\`\`\`

## Testing

\`\`\`bash
pytest
\`\`\`

## Verification

This project was built with AI-LA Agent and includes TECP cryptographic verification.
All changes are verifiable and auditable.

## Generated Steps

${plan.steps.map((step, i) => `${i + 1}. ${step.description}`).join('\n')}
`;
    }
    
    private generateGitignore(plan: Plan): string {
        return `__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.env
.venv
*.log
.DS_Store
.vscode/
.idea/
*.db
*.sqlite
`;
    }
    
    private generateTests(plan: Plan): string {
        return `"""
Generated tests by AI-LA Agent
"""

import pytest

def test_example():
    """Example test"""
    assert True

# Add more tests based on generated code
`;
    }
    
    private postProcess(content: string, filePath: string): string {
        // Remove markdown code blocks if present
        content = content.replace(/```[a-z]*\n/g, '').replace(/```\n?$/g, '');
        
        // Ensure proper line endings
        content = content.replace(/\r\n/g, '\n');
        
        // Add header comment
        const header = `"""
Generated by AI-LA Agent
File: ${filePath}
Verified with TECP cryptographic receipts
"""

`;
        
        if (filePath.endsWith('.py')) {
            content = header + content;
        }
        
        return content.trim() + '\n';
    }
    
    private getLanguage(extension: string): string {
        const languageMap: Record<string, string> = {
            'py': 'python',
            'js': 'javascript',
            'ts': 'typescript',
            'java': 'java',
            'go': 'go',
            'rs': 'rust'
        };
        
        return languageMap[extension] || 'unknown';
    }
}

