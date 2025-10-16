/**
 * Project Analyzer - Analyzes workspace to understand project context
 */

import * as vscode from 'vscode';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface ProjectAnalysis {
    projectPath: string;
    fileCount: number;
    totalLines: number;
    languages: string[];
    framework?: string;
    dependencies: string[];
    structure: any;
}

export class ProjectAnalyzer {
    constructor(private context: vscode.ExtensionContext) {}
    
    async analyze(): Promise<ProjectAnalysis> {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        
        if (!workspaceFolder) {
            throw new Error('No workspace folder open');
        }
        
        const projectPath = workspaceFolder.uri.fsPath;
        
        try {
            const [fileCount, totalLines, languages, framework, dependencies] = await Promise.all([
                this.countFiles(projectPath),
                this.countLines(projectPath),
                this.detectLanguages(projectPath),
                this.detectFramework(projectPath),
                this.getDependencies(projectPath)
            ]);
            
            const structure = await this.analyzeStructure(projectPath);
            
            return {
                projectPath,
                fileCount,
                totalLines,
                languages,
                framework,
                dependencies,
                structure
            };
            
        } catch (error) {
            throw new Error(`Project analysis failed: ${error}`);
        }
    }
    
    private async countFiles(projectPath: string): Promise<number> {
        let count = 0;
        
        async function walk(dir: string) {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                if (entry.name.startsWith('.') || entry.name === 'node_modules') {
                    continue;
                }
                
                const fullPath = path.join(dir, entry.name);
                
                if (entry.isDirectory()) {
                    await walk(fullPath);
                } else if (entry.isFile()) {
                    count++;
                }
            }
        }
        
        await walk(projectPath);
        return count;
    }
    
    private async countLines(projectPath: string): Promise<number> {
        let totalLines = 0;
        
        async function walk(dir: string) {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                if (entry.name.startsWith('.') || entry.name === 'node_modules') {
                    continue;
                }
                
                const fullPath = path.join(dir, entry.name);
                
                if (entry.isDirectory()) {
                    await walk(fullPath);
                } else if (entry.isFile() && isCodeFile(entry.name)) {
                    const content = await fs.readFile(fullPath, 'utf8');
                    totalLines += content.split('\n').length;
                }
            }
        }
        
        await walk(projectPath);
        return totalLines;
    }
    
    private async detectLanguages(projectPath: string): Promise<string[]> {
        const languages = new Set<string>();
        
        async function walk(dir: string) {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                if (entry.name.startsWith('.') || entry.name === 'node_modules') {
                    continue;
                }
                
                const fullPath = path.join(dir, entry.name);
                
                if (entry.isDirectory()) {
                    await walk(fullPath);
                } else if (entry.isFile()) {
                    const ext = path.extname(entry.name).slice(1);
                    const lang = getLanguageFromExtension(ext);
                    if (lang) {
                        languages.add(lang);
                    }
                }
            }
        }
        
        await walk(projectPath);
        return Array.from(languages);
    }
    
    private async detectFramework(projectPath: string): Promise<string | undefined> {
        // Check for common framework files
        const checks = [
            { file: 'requirements.txt', framework: 'python' },
            { file: 'package.json', framework: 'node' },
            { file: 'go.mod', framework: 'go' },
            { file: 'Cargo.toml', framework: 'rust' }
        ];
        
        for (const check of checks) {
            try {
                await fs.access(path.join(projectPath, check.file));
                
                // Read file to detect specific framework
                const content = await fs.readFile(path.join(projectPath, check.file), 'utf8');
                
                if (check.framework === 'python') {
                    if (content.includes('fastapi')) return 'fastapi';
                    if (content.includes('flask')) return 'flask';
                    if (content.includes('django')) return 'django';
                }
                
                if (check.framework === 'node') {
                    const pkg = JSON.parse(content);
                    if (pkg.dependencies?.react) return 'react';
                    if (pkg.dependencies?.next) return 'nextjs';
                    if (pkg.dependencies?.express) return 'express';
                }
                
                return check.framework;
            } catch {
                continue;
            }
        }
        
        return undefined;
    }
    
    private async getDependencies(projectPath: string): Promise<string[]> {
        const dependencies: string[] = [];
        
        // Check requirements.txt
        try {
            const reqPath = path.join(projectPath, 'requirements.txt');
            const content = await fs.readFile(reqPath, 'utf8');
            const deps = content.split('\n')
                .filter(line => line.trim() && !line.startsWith('#'))
                .map(line => line.split('==')[0].trim());
            dependencies.push(...deps);
        } catch {}
        
        // Check package.json
        try {
            const pkgPath = path.join(projectPath, 'package.json');
            const content = await fs.readFile(pkgPath, 'utf8');
            const pkg = JSON.parse(content);
            if (pkg.dependencies) {
                dependencies.push(...Object.keys(pkg.dependencies));
            }
        } catch {}
        
        return dependencies;
    }
    
    private async analyzeStructure(projectPath: string): Promise<any> {
        const structure: any = {
            directories: [],
            files: []
        };
        
        try {
            const entries = await fs.readdir(projectPath, { withFileTypes: true });
            
            for (const entry of entries) {
                if (entry.name.startsWith('.') || entry.name === 'node_modules') {
                    continue;
                }
                
                if (entry.isDirectory()) {
                    structure.directories.push(entry.name);
                } else {
                    structure.files.push(entry.name);
                }
            }
        } catch (error) {
            // Ignore errors
        }
        
        return structure;
    }
}

function isCodeFile(filename: string): boolean {
    const codeExtensions = ['.py', '.js', '.ts', '.java', '.go', '.rs', '.cpp', '.c', '.h'];
    return codeExtensions.some(ext => filename.endsWith(ext));
}

function getLanguageFromExtension(ext: string): string | null {
    const map: Record<string, string> = {
        'py': 'Python',
        'js': 'JavaScript',
        'ts': 'TypeScript',
        'java': 'Java',
        'go': 'Go',
        'rs': 'Rust',
        'cpp': 'C++',
        'c': 'C'
    };
    
    return map[ext] || null;
}

