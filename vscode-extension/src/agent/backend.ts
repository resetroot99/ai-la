/**
 * AI Backend - Handles communication with AI models (local or cloud)
 */

import * as vscode from 'vscode';
import * as child_process from 'child_process';
import { promisify } from 'util';

const exec = promisify(child_process.exec);

export interface Plan {
    steps: Array<{
        description: string;
        files: string[];
        dependencies: string[];
    }>;
    architecture: {
        framework: string;
        database?: string;
        authentication?: string;
    };
}

export class AIBackend {
    private config: vscode.WorkspaceConfiguration;
    private modelType: 'local' | 'cloud';
    
    constructor(private context: vscode.ExtensionContext) {
        this.config = vscode.workspace.getConfiguration('ai-la');
        this.modelType = this.config.get('model', 'local');
    }
    
    async initialize(): Promise<void> {
        if (this.modelType === 'local') {
            await this.checkOllamaInstalled();
        } else {
            await this.validateApiKey();
        }
    }
    
    async generatePlan(description: string, projectContext: any): Promise<Plan> {
        const prompt = this.buildPlanPrompt(description, projectContext);
        
        try {
            const response = await this.query(prompt);
            return this.parsePlan(response);
        } catch (error) {
            throw new Error(`Failed to generate plan: ${error}`);
        }
    }
    
    async generateCode(step: string, context: any): Promise<string> {
        const prompt = this.buildCodePrompt(step, context);
        
        try {
            return await this.query(prompt);
        } catch (error) {
            throw new Error(`Failed to generate code: ${error}`);
        }
    }
    
    async chat(message: string): Promise<string> {
        try {
            return await this.query(message);
        } catch (error) {
            throw new Error(`Chat failed: ${error}`);
        }
    }
    
    private async query(prompt: string): Promise<string> {
        if (this.modelType === 'local') {
            return await this.queryLocal(prompt);
        } else {
            return await this.queryCloud(prompt);
        }
    }
    
    private async queryLocal(prompt: string): Promise<string> {
        const model = this.config.get('localModel', 'qwen2.5-coder:7b');
        
        try {
            // Use Ollama API
            const { stdout } = await exec(
                `curl -s http://localhost:11434/api/generate -d '${JSON.stringify({
                    model,
                    prompt,
                    stream: false
                })}'`
            );
            
            const response = JSON.parse(stdout);
            return response.response;
            
        } catch (error) {
            throw new Error(`Local model query failed. Is Ollama running? ${error}`);
        }
    }
    
    private async queryCloud(prompt: string): Promise<string> {
        const apiKey = this.config.get('apiKey', '');
        
        if (!apiKey) {
            throw new Error('API key not configured. Set ai-la.apiKey in settings.');
        }
        
        try {
            // Use cloud API (OpenAI-compatible)
            const { stdout } = await exec(
                `curl -s https://api.openai.com/v1/chat/completions \\
                -H "Content-Type: application/json" \\
                -H "Authorization: Bearer ${apiKey}" \\
                -d '${JSON.stringify({
                    model: 'gpt-4',
                    messages: [{ role: 'user', content: prompt }]
                })}'`
            );
            
            const response = JSON.parse(stdout);
            return response.choices[0].message.content;
            
        } catch (error) {
            throw new Error(`Cloud API query failed: ${error}`);
        }
    }
    
    private buildPlanPrompt(description: string, projectContext: any): string {
        return `You are an expert software architect. Create a detailed implementation plan.

Task: ${description}

Project Context:
- Framework: ${projectContext.framework || 'Unknown'}
- Languages: ${projectContext.languages?.join(', ') || 'Unknown'}
- File Count: ${projectContext.fileCount || 0}

Generate a JSON plan with this structure:
{
  "steps": [
    {
      "description": "Step description",
      "files": ["file1.py", "file2.py"],
      "dependencies": ["package1", "package2"]
    }
  ],
  "architecture": {
    "framework": "fastapi",
    "database": "postgresql",
    "authentication": "jwt"
  }
}

Respond with ONLY the JSON, no other text.`;
    }
    
    private buildCodePrompt(step: string, context: any): string {
        return `Generate production-ready code for: ${step}

Context:
${JSON.stringify(context, null, 2)}

Requirements:
- Include error handling
- Add type hints (Python) or types (TypeScript)
- Include docstrings/comments
- Follow best practices
- Make it production-ready

Respond with ONLY the code, no explanations.`;
    }
    
    private parsePlan(response: string): Plan {
        try {
            // Extract JSON from response (handle markdown code blocks)
            const jsonMatch = response.match(/\{[\s\S]*\}/);
            if (!jsonMatch) {
                throw new Error('No JSON found in response');
            }
            
            const plan = JSON.parse(jsonMatch[0]);
            
            // Validate plan structure
            if (!plan.steps || !Array.isArray(plan.steps)) {
                throw new Error('Invalid plan structure: missing steps array');
            }
            
            if (!plan.architecture) {
                throw new Error('Invalid plan structure: missing architecture');
            }
            
            return plan;
            
        } catch (error) {
            throw new Error(`Failed to parse plan: ${error}`);
        }
    }
    
    private async checkOllamaInstalled(): Promise<void> {
        try {
            await exec('ollama --version');
        } catch (error) {
            throw new Error(
                'Ollama not found. Install from https://ollama.ai or switch to cloud mode in settings.'
            );
        }
    }
    
    private async validateApiKey(): Promise<void> {
        const apiKey = this.config.get<string>('apiKey', '');
        
        if (!apiKey) {
            throw new Error('API key required for cloud mode. Set ai-la.apiKey in settings.');
        }
        
        if (apiKey.length < 20) {
            throw new Error('Invalid API key format');
        }
    }
}

