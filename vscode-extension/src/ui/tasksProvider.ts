/**
 * Tasks Provider - Shows active and completed tasks
 */

import * as vscode from 'vscode';
import { AgentController, Task } from '../agent/controller';

export class TasksProvider implements vscode.TreeDataProvider<TaskItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<TaskItem | undefined | null | void> = new vscode.EventEmitter<TaskItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<TaskItem | undefined | null | void> = this._onDidChangeTreeData.event;
    
    constructor(
        private context: vscode.ExtensionContext,
        private agentController: AgentController
    ) {
        // Refresh every 2 seconds when tasks are active
        setInterval(() => this.refresh(), 2000);
    }
    
    refresh(): void {
        this._onDidChangeTreeData.fire();
    }
    
    getTreeItem(element: TaskItem): vscode.TreeItem {
        return element;
    }
    
    getChildren(element?: TaskItem): Thenable<TaskItem[]> {
        if (!element) {
            const tasks = this.agentController.getActiveTasks();
            
            if (tasks.length === 0) {
                return Promise.resolve([
                    new TaskItem('No active tasks', '', 'none', vscode.TreeItemCollapsibleState.None)
                ]);
            }
            
            return Promise.resolve(
                tasks.map(task => new TaskItem(
                    task.description,
                    task.id,
                    task.status,
                    vscode.TreeItemCollapsibleState.None,
                    task.progress
                ))
            );
        }
        
        return Promise.resolve([]);
    }
}

class TaskItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly taskId: string,
        public readonly status: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly progress?: number
    ) {
        super(label, collapsibleState);
        
        this.description = this.getStatusDescription();
        this.iconPath = this.getIcon();
        this.tooltip = this.getTooltip();
    }
    
    private getStatusDescription(): string {
        if (this.status === 'running' && this.progress !== undefined) {
            return `${this.progress}%`;
        }
        return this.status;
    }
    
    private getIcon(): vscode.ThemeIcon {
        switch (this.status) {
            case 'running':
                return new vscode.ThemeIcon('loading~spin');
            case 'completed':
                return new vscode.ThemeIcon('check');
            case 'failed':
                return new vscode.ThemeIcon('error');
            case 'pending':
                return new vscode.ThemeIcon('clock');
            default:
                return new vscode.ThemeIcon('info');
        }
    }
    
    private getTooltip(): string {
        return `Task: ${this.label}\nStatus: ${this.status}${this.progress ? `\nProgress: ${this.progress}%` : ''}`;
    }
}

