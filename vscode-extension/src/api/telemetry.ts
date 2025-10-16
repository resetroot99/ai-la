/**
 * Telemetry - Anonymous usage analytics for product improvement
 * Users can opt-out in settings
 */

import * as vscode from 'vscode';
import * as os from 'os';

export class Telemetry {
    private enabled: boolean;
    private sessionId: string;
    private userId: string;
    
    constructor(private context: vscode.ExtensionContext) {
        const config = vscode.workspace.getConfiguration('ai-la');
        this.enabled = config.get('telemetry.enabled', true);
        
        // Generate anonymous IDs
        this.sessionId = this.generateId();
        this.userId = context.globalState.get('userId') || this.generateId();
        context.globalState.update('userId', this.userId);
    }
    
    async initialize(): Promise<void> {
        if (this.enabled) {
            await this.trackEvent('session.started', {
                platform: os.platform(),
                arch: os.arch(),
                vscodeVersion: vscode.version
            });
        }
    }
    
    async trackEvent(event: string, properties?: Record<string, any>): Promise<void> {
        if (!this.enabled) {
            return;
        }
        
        try {
            const data = {
                event,
                userId: this.userId,
                sessionId: this.sessionId,
                timestamp: Date.now(),
                properties: properties || {}
            };
            
            // Store locally for now (can be sent to analytics service later)
            await this.storeEvent(data);
            
        } catch (error) {
            // Silently fail - telemetry should never break the extension
            console.error('Telemetry error:', error);
        }
    }
    
    async trackError(event: string, error: unknown): Promise<void> {
        if (!this.enabled) {
            return;
        }
        
        const errorMessage = error instanceof Error ? error.message : String(error);
        const errorStack = error instanceof Error ? error.stack : undefined;
        
        await this.trackEvent(event, {
            error: errorMessage,
            stack: errorStack
        });
    }
    
    dispose(): void {
        if (this.enabled) {
            this.trackEvent('session.ended');
        }
    }
    
    private async storeEvent(data: any): Promise<void> {
        // Store events locally
        const events = this.context.globalState.get<any[]>('telemetry.events', []);
        events.push(data);
        
        // Keep only last 1000 events
        if (events.length > 1000) {
            events.shift();
        }
        
        await this.context.globalState.update('telemetry.events', events);
    }
    
    private generateId(): string {
        return `${Date.now()}-${Math.random().toString(36).substring(2, 15)}`;
    }
    
    async getStats(): Promise<any> {
        const events = this.context.globalState.get<any[]>('telemetry.events', []);
        
        const stats = {
            totalEvents: events.length,
            eventTypes: {} as Record<string, number>,
            lastEvent: events.length > 0 ? events[events.length - 1] : null
        };
        
        events.forEach(event => {
            stats.eventTypes[event.event] = (stats.eventTypes[event.event] || 0) + 1;
        });
        
        return stats;
    }
}

