/**
 * TECP Manager - Cryptographic verification for all AI operations
 */

import * as vscode from 'vscode';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface TECPReceipt {
    timestamp: number;
    operation: string;
    inputHash: string;
    outputHash: string;
    hash: string;
    previousHash: string;
    index: number;
}

export class TECPManager {
    private receipts: TECPReceipt[] = [];
    private dbPath: string;
    
    constructor(private context: vscode.ExtensionContext) {
        this.dbPath = path.join(context.globalStoragePath, 'tecp.json');
    }
    
    async initialize(): Promise<void> {
        try {
            await fs.mkdir(path.dirname(this.dbPath), { recursive: true });
            
            // Load existing receipts
            try {
                const data = await fs.readFile(this.dbPath, 'utf8');
                this.receipts = JSON.parse(data);
            } catch {
                // No existing receipts
                this.receipts = [];
            }
        } catch (error) {
            throw new Error(`TECP initialization failed: ${error}`);
        }
    }
    
    async createReceipt(data: {
        operation: string;
        input: string;
        output: string;
    }): Promise<TECPReceipt> {
        const inputHash = this.hash(data.input);
        const outputHash = this.hash(data.output);
        const previousHash = this.receipts.length > 0 
            ? this.receipts[this.receipts.length - 1].hash 
            : '0';
        
        const receipt: TECPReceipt = {
            timestamp: Date.now(),
            operation: data.operation,
            inputHash,
            outputHash,
            hash: '',
            previousHash,
            index: this.receipts.length
        };
        
        // Calculate receipt hash
        receipt.hash = this.hash(JSON.stringify({
            timestamp: receipt.timestamp,
            operation: receipt.operation,
            inputHash: receipt.inputHash,
            outputHash: receipt.outputHash,
            previousHash: receipt.previousHash,
            index: receipt.index
        }));
        
        this.receipts.push(receipt);
        await this.save();
        
        return receipt;
    }
    
    async verifyChain(): Promise<{ valid: boolean; receipts: number; errors: string[] }> {
        const errors: string[] = [];
        
        for (let i = 0; i < this.receipts.length; i++) {
            const receipt = this.receipts[i];
            
            // Verify hash
            const expectedHash = this.hash(JSON.stringify({
                timestamp: receipt.timestamp,
                operation: receipt.operation,
                inputHash: receipt.inputHash,
                outputHash: receipt.outputHash,
                previousHash: receipt.previousHash,
                index: receipt.index
            }));
            
            if (receipt.hash !== expectedHash) {
                errors.push(`Receipt ${i}: Hash mismatch`);
            }
            
            // Verify chain
            if (i > 0) {
                const prevReceipt = this.receipts[i - 1];
                if (receipt.previousHash !== prevReceipt.hash) {
                    errors.push(`Receipt ${i}: Chain broken`);
                }
            }
        }
        
        return {
            valid: errors.length === 0,
            receipts: this.receipts.length,
            errors
        };
    }
    
    getReceipts(): TECPReceipt[] {
        return [...this.receipts];
    }
    
    private hash(data: string): string {
        return crypto.createHash('sha256').update(data).digest('hex');
    }
    
    private async save(): Promise<void> {
        await fs.writeFile(this.dbPath, JSON.stringify(this.receipts, null, 2));
    }
}
