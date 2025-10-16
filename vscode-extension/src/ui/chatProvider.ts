/**
 * Chat Provider - Tree view for chat interface
 */

import * as vscode from 'vscode';
import { AgentController } from '../agent/controller';

export class ChatProvider implements vscode.TreeDataProvider<ChatItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<ChatItem | undefined | null | void> = new vscode.EventEmitter<ChatItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<ChatItem | undefined | null | void> = this._onDidChangeTreeData.event;
    
    constructor(
        private context: vscode.ExtensionContext,
        private agentController: AgentController
    ) {}
    
    refresh(): void {
        this._onDidChangeTreeData.fire();
    }
    
    getTreeItem(element: ChatItem): vscode.TreeItem {
        return element;
    }
    
    getChildren(element?: ChatItem): Thenable<ChatItem[]> {
        if (!element) {
            return Promise.resolve([
                new ChatItem('Start New Chat', vscode.TreeItemCollapsibleState.None, {
                    command: 'ai-la.chat',
                    title: 'Open Chat'
                })
            ]);
        }
        
        return Promise.resolve([]);
    }
}

class ChatItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly command?: vscode.Command
    ) {
        super(label, collapsibleState);
    }
}

