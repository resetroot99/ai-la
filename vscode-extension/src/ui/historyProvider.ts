/**
 * History Provider - Shows TECP verification history
 */

import * as vscode from 'vscode';
import { TECPManager, TECPReceipt } from '../tecp/manager';

export class HistoryProvider implements vscode.TreeDataProvider<HistoryItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<HistoryItem | undefined | null | void> = new vscode.EventEmitter<HistoryItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<HistoryItem | undefined | null | void> = this._onDidChangeTreeData.event;
    
    constructor(
        private context: vscode.ExtensionContext,
        private tecpManager: TECPManager
    ) {}
    
    refresh(): void {
        this._onDidChangeTreeData.fire();
    }
    
    getTreeItem(element: HistoryItem): vscode.TreeItem {
        return element;
    }
    
    async getChildren(element?: HistoryItem): Promise<HistoryItem[]> {
        if (!element) {
            const receipts = this.tecpManager.getReceipts();
            
            if (receipts.length === 0) {
                return [
                    new HistoryItem('No operations yet', null, vscode.TreeItemCollapsibleState.None)
                ];
            }
            
            // Show last 20 receipts
            const recentReceipts = receipts.slice(-20).reverse();
            
            return recentReceipts.map(receipt => 
                new HistoryItem(
                    this.formatOperation(receipt.operation),
                    receipt,
                    vscode.TreeItemCollapsibleState.None
                )
            );
        }
        
        return [];
    }
    
    private formatOperation(operation: string): string {
        const map: Record<string, string> = {
            'build_feature': 'Built Feature',
            'generate_file': 'Generated File',
            'analyze_project': 'Analyzed Project'
        };
        
        return map[operation] || operation;
    }
}

class HistoryItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly receipt: TECPReceipt | null,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState
    ) {
        super(label, collapsibleState);
        
        if (receipt) {
            this.description = this.formatTime(receipt.timestamp);
            this.tooltip = this.getTooltip();
            this.iconPath = new vscode.ThemeIcon('verified');
        }
    }
    
    private formatTime(timestamp: number): string {
        const date = new Date(timestamp);
        const now = Date.now();
        const diff = now - timestamp;
        
        if (diff < 60000) {
            return 'Just now';
        } else if (diff < 3600000) {
            return `${Math.floor(diff / 60000)}m ago`;
        } else if (diff < 86400000) {
            return `${Math.floor(diff / 3600000)}h ago`;
        } else {
            return date.toLocaleDateString();
        }
    }
    
    private getTooltip(): string {
        if (!this.receipt) {
            return '';
        }
        
        return `Operation: ${this.receipt.operation}
Time: ${new Date(this.receipt.timestamp).toLocaleString()}
Hash: ${this.receipt.hash.substring(0, 16)}...
Index: ${this.receipt.index}
Verified: Yes`;
    }
}

