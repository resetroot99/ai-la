/**
 * Agent Controller - Core autonomous agent logic
 * Handles feature building, code generation, and project analysis
 */

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs/promises';
import { TECPManager } from '../tecp/manager';
import { Telemetry } from '../api/telemetry';
import { AIBackend } from './backend';
import { CodeGenerator } from './generator';
import { ProjectAnalyzer } from './analyzer';

export interface Task {
    id: string;
    description: string;
    status: 'pending' | 'running' | 'completed' | 'failed';
    progress: number;
    startTime: number;
    endTime?: number;
    error?: string;
    tecpReceipt?: string;
}

export class AgentController {
    private backend: AIBackend;
    private generator: CodeGenerator;
    private analyzer: ProjectAnalyzer;
    private activeTasks: Map<string, Task> = new Map();
    private outputChannel: vscode.OutputChannel;
    
    constructor(
        private context: vscode.ExtensionContext,
        private tecpManager: TECPManager,
        private telemetry: Telemetry
    ) {
        this.outputChannel = vscode.window.createOutputChannel('AI-LA Agent');
        this.backend = new AIBackend(context);
        this.generator = new CodeGenerator(context, tecpManager);
        this.analyzer = new ProjectAnalyzer(context);
    }
    
    async initialize(): Promise<void> {
        try {
            await this.backend.initialize();
            this.log('Agent controller initialized successfully');
        } catch (error) {
            this.log(`Failed to initialize agent controller: ${error}`);
            throw error;
        }
    }
    
    async buildFeature(description: string): Promise<void> {
        const taskId = this.generateTaskId();
        const task: Task = {
            id: taskId,
            description,
            status: 'pending',
            progress: 0,
            startTime: Date.now()
        };
        
        this.activeTasks.set(taskId, task);
        
        try {
            // Show progress
            await vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: `AI-LA: Building ${description}`,
                cancellable: true
            }, async (progress, token) => {
                task.status = 'running';
                
                // Step 1: Analyze project context
                progress.report({ increment: 10, message: 'Analyzing project...' });
                const projectContext = await this.analyzer.analyze();
                
                if (token.isCancellationRequested) {
                    throw new Error('Task cancelled by user');
                }
                
                // Step 2: Generate plan
                progress.report({ increment: 20, message: 'Creating implementation plan...' });
                const plan = await this.backend.generatePlan(description, projectContext);
                
                if (token.isCancellationRequested) {
                    throw new Error('Task cancelled by user');
                }
                
                // Step 3: Generate code
                progress.report({ increment: 30, message: 'Generating code...' });
                const code = await this.generator.generate(plan);
                
                if (token.isCancellationRequested) {
                    throw new Error('Task cancelled by user');
                }
                
                // Step 4: Write files
                progress.report({ increment: 20, message: 'Writing files...' });
                await this.writeFiles(code.files);
                
                // Step 5: Create TECP receipt
                progress.report({ increment: 10, message: 'Creating verification receipt...' });
                const receipt = await this.tecpManager.createReceipt({
                    operation: 'build_feature',
                    input: description,
                    output: JSON.stringify(code.files.map(f => f.path))
                });
                
                task.tecpReceipt = receipt.hash;
                
                // Step 6: Complete
                progress.report({ increment: 10, message: 'Complete!' });
                task.status = 'completed';
                task.endTime = Date.now();
                task.progress = 100;
                
                const duration = ((task.endTime - task.startTime) / 1000).toFixed(2);
                
                this.telemetry.trackEvent('feature.built', {
                    duration,
                    filesCreated: code.files.length,
                    linesOfCode: code.totalLines
                });
                
                vscode.window.showInformationMessage(
                    `Feature built successfully in ${duration}s! Created ${code.files.length} files.`,
                    'View Changes',
                    'Verify (TECP)'
                ).then(action => {
                    if (action === 'View Changes') {
                        this.showChanges(code.files);
                    } else if (action === 'Verify (TECP)') {
                        vscode.commands.executeCommand('ai-la.verify');
                    }
                });
            });
            
        } catch (error) {
            task.status = 'failed';
            task.error = error instanceof Error ? error.message : String(error);
            task.endTime = Date.now();
            
            this.telemetry.trackError('feature.build.failed', error);
            
            vscode.window.showErrorMessage(
                `Failed to build feature: ${task.error}`,
                'View Logs'
            ).then(action => {
                if (action === 'View Logs') {
                    this.outputChannel.show();
                }
            });
            
            throw error;
        } finally {
            this.activeTasks.set(taskId, task);
        }
    }
    
    async openChat(): Promise<void> {
        // Open chat webview panel
        const panel = vscode.window.createWebviewPanel(
            'ai-la-chat',
            'AI-LA Chat',
            vscode.ViewColumn.Beside,
            {
                enableScripts: true,
                retainContextWhenHidden: true
            }
        );
        
        panel.webview.html = this.getChatHtml();
        
        // Handle messages from webview
        panel.webview.onDidReceiveMessage(
            async message => {
                switch (message.command) {
                    case 'send':
                        const response = await this.backend.chat(message.text);
                        panel.webview.postMessage({ command: 'response', text: response });
                        break;
                }
            },
            undefined,
            this.context.subscriptions
        );
    }
    
    async analyzeProject(): Promise<void> {
        try {
            await vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: 'AI-LA: Analyzing project...'
            }, async () => {
                const analysis = await this.analyzer.analyze();
                
                // Create TECP receipt
                await this.tecpManager.createReceipt({
                    operation: 'analyze_project',
                    input: analysis.projectPath,
                    output: JSON.stringify({
                        files: analysis.fileCount,
                        lines: analysis.totalLines,
                        languages: analysis.languages
                    })
                });
                
                this.telemetry.trackEvent('project.analyzed', {
                    files: analysis.fileCount,
                    lines: analysis.totalLines
                });
                
                vscode.window.showInformationMessage(
                    `Project analyzed: ${analysis.fileCount} files, ${analysis.totalLines} lines of code`,
                    'View Details'
                ).then(action => {
                    if (action === 'View Details') {
                        this.showAnalysisDetails(analysis);
                    }
                });
            });
        } catch (error) {
            this.telemetry.trackError('project.analyze.failed', error);
            throw error;
        }
    }
    
    getActiveTasks(): Task[] {
        return Array.from(this.activeTasks.values());
    }
    
    private async writeFiles(files: Array<{ path: string; content: string }>): Promise<void> {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) {
            throw new Error('No workspace folder open');
        }
        
        for (const file of files) {
            const fullPath = path.join(workspaceFolder.uri.fsPath, file.path);
            const dir = path.dirname(fullPath);
            
            // Create directory if it doesn't exist
            await fs.mkdir(dir, { recursive: true });
            
            // Write file
            await fs.writeFile(fullPath, file.content, 'utf8');
            
            this.log(`Created file: ${file.path}`);
        }
    }
    
    private async showChanges(files: Array<{ path: string; content: string }>): Promise<void> {
        // Open first file in editor
        if (files.length > 0) {
            const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
            if (workspaceFolder) {
                const fullPath = path.join(workspaceFolder.uri.fsPath, files[0].path);
                const document = await vscode.workspace.openTextDocument(fullPath);
                await vscode.window.showTextDocument(document);
            }
        }
    }
    
    private showAnalysisDetails(analysis: any): void {
        const panel = vscode.window.createWebviewPanel(
            'ai-la-analysis',
            'Project Analysis',
            vscode.ViewColumn.Beside,
            {}
        );
        
        panel.webview.html = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: sans-serif; padding: 20px; }
                    .stat { margin: 10px 0; }
                    .label { font-weight: bold; }
                </style>
            </head>
            <body>
                <h1>Project Analysis</h1>
                <div class="stat"><span class="label">Files:</span> ${analysis.fileCount}</div>
                <div class="stat"><span class="label">Lines of Code:</span> ${analysis.totalLines}</div>
                <div class="stat"><span class="label">Languages:</span> ${analysis.languages.join(', ')}</div>
            </body>
            </html>
        `;
    }
    
    private getChatHtml(): string {
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: sans-serif; padding: 20px; }
                    #messages { height: 400px; overflow-y: auto; border: 1px solid #ccc; padding: 10px; margin-bottom: 10px; }
                    #input { width: 100%; padding: 10px; }
                </style>
            </head>
            <body>
                <div id="messages"></div>
                <input type="text" id="input" placeholder="Ask AI-LA anything..." />
                <script>
                    const vscode = acquireVsCodeApi();
                    const input = document.getElementById('input');
                    const messages = document.getElementById('messages');
                    
                    input.addEventListener('keypress', (e) => {
                        if (e.key === 'Enter') {
                            const text = input.value;
                            messages.innerHTML += '<div><strong>You:</strong> ' + text + '</div>';
                            vscode.postMessage({ command: 'send', text });
                            input.value = '';
                        }
                    });
                    
                    window.addEventListener('message', event => {
                        const message = event.data;
                        if (message.command === 'response') {
                            messages.innerHTML += '<div><strong>AI-LA:</strong> ' + message.text + '</div>';
                            messages.scrollTop = messages.scrollHeight;
                        }
                    });
                </script>
            </body>
            </html>
        `;
    }
    
    private generateTaskId(): string {
        return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    private log(message: string): void {
        this.outputChannel.appendLine(`[${new Date().toISOString()}] ${message}`);
    }
}

