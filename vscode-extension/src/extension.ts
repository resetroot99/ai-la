/**
 * AI-LA Agent - VS Code Extension
 * Autonomous AI development agent with cryptographic verification
 */

import * as vscode from 'vscode';
import { AgentController } from './agent/controller';
import { TECPManager } from './tecp/manager';
import { ChatProvider } from './ui/chatProvider';
import { TasksProvider } from './ui/tasksProvider';
import { HistoryProvider } from './ui/historyProvider';
import { Telemetry } from './api/telemetry';

let agentController: AgentController;
let tecpManager: TECPManager;
let telemetry: Telemetry;

export async function activate(context: vscode.ExtensionContext) {
    console.log('AI-LA Agent is activating...');
    
    try {
        // Initialize telemetry (anonymous usage stats)
        telemetry = new Telemetry(context);
        await telemetry.initialize();
        
        // Initialize TECP manager
        tecpManager = new TECPManager(context);
        await tecpManager.initialize();
        
        // Initialize agent controller
        agentController = new AgentController(context, tecpManager, telemetry);
        await agentController.initialize();
        
        // Register UI providers
        const chatProvider = new ChatProvider(context, agentController);
        const tasksProvider = new TasksProvider(context, agentController);
        const historyProvider = new HistoryProvider(context, tecpManager);
        
        context.subscriptions.push(
            vscode.window.registerTreeDataProvider('ai-la-chat', chatProvider),
            vscode.window.registerTreeDataProvider('ai-la-tasks', tasksProvider),
            vscode.window.registerTreeDataProvider('ai-la-history', historyProvider)
        );
        
        // Register commands
        registerCommands(context);
        
        // Show welcome message on first install
        const isFirstInstall = context.globalState.get('ai-la.firstInstall', true);
        if (isFirstInstall) {
            await showWelcomeMessage(context);
            context.globalState.update('ai-la.firstInstall', false);
        }
        
        telemetry.trackEvent('extension.activated');
        vscode.window.showInformationMessage('AI-LA Agent activated successfully!');
        
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        vscode.window.showErrorMessage(`AI-LA Agent failed to activate: ${errorMessage}`);
        telemetry?.trackError('extension.activation.failed', error);
        throw error;
    }
}

function registerCommands(context: vscode.ExtensionContext) {
    // Build Feature command
    context.subscriptions.push(
        vscode.commands.registerCommand('ai-la.buildFeature', async () => {
            try {
                const description = await vscode.window.showInputBox({
                    prompt: 'What feature do you want to build?',
                    placeHolder: 'e.g., Add user authentication with JWT tokens',
                    validateInput: (value) => {
                        return value.trim().length < 10 ? 'Please provide a more detailed description' : null;
                    }
                });
                
                if (!description) {
                    return;
                }
                
                telemetry.trackEvent('command.buildFeature', { descriptionLength: description.length });
                await agentController.buildFeature(description);
                
            } catch (error) {
                handleCommandError('buildFeature', error);
            }
        })
    );
    
    // Chat command
    context.subscriptions.push(
        vscode.commands.registerCommand('ai-la.chat', async () => {
            try {
                telemetry.trackEvent('command.chat');
                await agentController.openChat();
            } catch (error) {
                handleCommandError('chat', error);
            }
        })
    );
    
    // Analyze Project command
    context.subscriptions.push(
        vscode.commands.registerCommand('ai-la.analyze', async () => {
            try {
                telemetry.trackEvent('command.analyze');
                await agentController.analyzeProject();
            } catch (error) {
                handleCommandError('analyze', error);
            }
        })
    );
    
    // Verify Changes command (TECP)
    context.subscriptions.push(
        vscode.commands.registerCommand('ai-la.verify', async () => {
            try {
                telemetry.trackEvent('command.verify');
                const verification = await tecpManager.verifyChain();
                
                if (verification.valid) {
                    vscode.window.showInformationMessage(
                        `TECP Verification: All ${verification.receipts} receipts verified. Chain integrity: 100%`
                    );
                } else {
                    vscode.window.showWarningMessage(
                        `TECP Verification: Chain integrity compromised! ${verification.errors.join(', ')}`
                    );
                }
            } catch (error) {
                handleCommandError('verify', error);
            }
        })
    );
}

function handleCommandError(command: string, error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    vscode.window.showErrorMessage(`AI-LA: ${command} failed - ${errorMessage}`);
    telemetry.trackError(`command.${command}.failed`, error);
}

async function showWelcomeMessage(context: vscode.ExtensionContext) {
    const config = vscode.workspace.getConfiguration('ai-la');
    const model = config.get('model', 'local');
    
    const message = model === 'local' 
        ? 'AI-LA Agent is ready! Using local models (free). Make sure Ollama is installed.'
        : 'AI-LA Agent is ready! Configure your API key in settings for premium features.';
    
    const action = await vscode.window.showInformationMessage(
        message,
        'Open Settings',
        'View Documentation'
    );
    
    if (action === 'Open Settings') {
        vscode.commands.executeCommand('workbench.action.openSettings', 'ai-la');
    } else if (action === 'View Documentation') {
        vscode.env.openExternal(vscode.Uri.parse('https://github.com/resetroot99/ai-la'));
    }
}

export function deactivate() {
    telemetry?.trackEvent('extension.deactivated');
    telemetry?.dispose();
}

