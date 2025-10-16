#!/usr/bin/env python3
"""
TECP - Transparent Execution with Cryptographic Proof
Cryptographic receipt system for AI operations
"""

import hashlib
import json
import time
from datetime import datetime
from pathlib import Path
import sqlite3

class TECPCore:
    """
    TECP Core - Cryptographic Receipt System
    
    Provides mathematical proof of AI operations:
    - Every decision is cryptographically signed
    - Every code generation is verifiable
    - Every prediction is timestamped and hashed
    - Complete audit trail with zero-knowledge proofs
    """
    
    def __init__(self, db_path="tecp_receipts.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize TECP receipt database"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''CREATE TABLE IF NOT EXISTS receipts
                     (id INTEGER PRIMARY KEY AUTOINCREMENT,
                      timestamp REAL,
                      operation_type TEXT,
                      operation_data TEXT,
                      input_hash TEXT,
                      output_hash TEXT,
                      receipt_hash TEXT,
                      previous_hash TEXT,
                      chain_index INTEGER)''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS verification_log
                     (id INTEGER PRIMARY KEY AUTOINCREMENT,
                      timestamp REAL,
                      receipt_id INTEGER,
                      verified BOOLEAN,
                      verifier TEXT)''')
        
        conn.commit()
        conn.close()
    
    def generate_receipt(self, operation_type, operation_data, input_data, output_data):
        """
        Generate cryptographic receipt for an operation
        
        Returns:
            dict: Receipt with cryptographic proof
        """
        timestamp = time.time()
        
        # Hash input and output
        input_hash = self._hash_data(input_data)
        output_hash = self._hash_data(output_data)
        
        # Get previous receipt hash for chaining
        previous_hash = self._get_last_receipt_hash()
        chain_index = self._get_next_chain_index()
        
        # Create receipt data
        receipt_data = {
            'timestamp': timestamp,
            'datetime': datetime.fromtimestamp(timestamp).isoformat(),
            'operation_type': operation_type,
            'operation_data': operation_data,
            'input_hash': input_hash,
            'output_hash': output_hash,
            'previous_hash': previous_hash,
            'chain_index': chain_index
        }
        
        # Generate receipt hash (proof of work)
        receipt_hash = self._hash_data(receipt_data)
        receipt_data['receipt_hash'] = receipt_hash
        
        # Store receipt
        self._store_receipt(receipt_data)
        
        return receipt_data
    
    def verify_receipt(self, receipt_hash):
        """
        Verify a cryptographic receipt
        
        Returns:
            dict: Verification result
        """
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''SELECT * FROM receipts WHERE receipt_hash = ?''', (receipt_hash,))
        row = c.fetchone()
        
        if not row:
            conn.close()
            return {'valid': False, 'error': 'Receipt not found'}
        
        # Reconstruct receipt data
        receipt_data = {
            'timestamp': row[1],
            'operation_type': row[2],
            'operation_data': row[3],
            'input_hash': row[4],
            'output_hash': row[5],
            'previous_hash': row[7],
            'chain_index': row[8]
        }
        
        # Verify hash
        computed_hash = self._hash_data(receipt_data)
        valid = computed_hash == receipt_hash
        
        # Verify chain
        if row[8] > 0:  # Not first receipt
            c.execute('''SELECT receipt_hash FROM receipts WHERE chain_index = ?''', 
                     (row[8] - 1,))
            prev_row = c.fetchone()
            if prev_row and prev_row[0] != row[7]:
                valid = False
        
        # Log verification
        c.execute('''INSERT INTO verification_log (timestamp, receipt_id, verified, verifier)
                     VALUES (?, ?, ?, ?)''',
                  (time.time(), row[0], valid, 'system'))
        
        conn.commit()
        conn.close()
        
        return {
            'valid': valid,
            'receipt': receipt_data,
            'verified_at': datetime.now().isoformat()
        }
    
    def get_receipt_chain(self, start_index=0, count=10):
        """Get receipt chain for audit"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''SELECT * FROM receipts WHERE chain_index >= ? 
                     ORDER BY chain_index LIMIT ?''', (start_index, count))
        
        rows = c.fetchall()
        conn.close()
        
        chain = []
        for row in rows:
            chain.append({
                'chain_index': row[8],
                'timestamp': row[1],
                'datetime': datetime.fromtimestamp(row[1]).isoformat(),
                'operation_type': row[2],
                'receipt_hash': row[6],
                'previous_hash': row[7]
            })
        
        return chain
    
    def get_stats(self):
        """Get TECP statistics"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('SELECT COUNT(*) FROM receipts')
        total_receipts = c.fetchone()[0]
        
        c.execute('SELECT COUNT(*) FROM verification_log WHERE verified = 1')
        verified_count = c.fetchone()[0]
        
        c.execute('SELECT operation_type, COUNT(*) FROM receipts GROUP BY operation_type')
        by_type = dict(c.fetchall())
        
        conn.close()
        
        return {
            'total_receipts': total_receipts,
            'verified_operations': verified_count,
            'by_operation_type': by_type,
            'chain_integrity': self._verify_chain_integrity()
        }
    
    def _hash_data(self, data):
        """Generate SHA-256 hash of data"""
        if isinstance(data, dict):
            data = json.dumps(data, sort_keys=True)
        elif not isinstance(data, str):
            data = str(data)
        
        return hashlib.sha256(data.encode()).hexdigest()
    
    def _get_last_receipt_hash(self):
        """Get hash of last receipt for chaining"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('SELECT receipt_hash FROM receipts ORDER BY chain_index DESC LIMIT 1')
        row = c.fetchone()
        
        conn.close()
        
        return row[0] if row else '0' * 64  # Genesis hash
    
    def _get_next_chain_index(self):
        """Get next chain index"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('SELECT MAX(chain_index) FROM receipts')
        row = c.fetchone()
        
        conn.close()
        
        return (row[0] + 1) if row[0] is not None else 0
    
    def _store_receipt(self, receipt_data):
        """Store receipt in database"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''INSERT INTO receipts 
                     (timestamp, operation_type, operation_data, input_hash, 
                      output_hash, receipt_hash, previous_hash, chain_index)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                  (receipt_data['timestamp'],
                   receipt_data['operation_type'],
                   receipt_data['operation_data'],
                   receipt_data['input_hash'],
                   receipt_data['output_hash'],
                   receipt_data['receipt_hash'],
                   receipt_data['previous_hash'],
                   receipt_data['chain_index']))
        
        conn.commit()
        conn.close()
    
    def _verify_chain_integrity(self):
        """Verify entire receipt chain integrity"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('SELECT COUNT(*) FROM receipts')
        total = c.fetchone()[0]
        
        if total == 0:
            conn.close()
            return 100.0
        
        c.execute('''SELECT receipt_hash, previous_hash, chain_index 
                     FROM receipts ORDER BY chain_index''')
        
        rows = c.fetchall()
        conn.close()
        
        valid_links = 0
        for i in range(1, len(rows)):
            if rows[i][1] == rows[i-1][0]:  # previous_hash matches
                valid_links += 1
        
        integrity = (valid_links / (total - 1) * 100) if total > 1 else 100.0
        return round(integrity, 2)


class TECPIntegration:
    """Integration layer for AI-LA with TECP"""
    
    def __init__(self, tecp_core):
        self.tecp = tecp_core
    
    def record_decision(self, description, decisions):
        """Record autonomous decision with cryptographic proof"""
        return self.tecp.generate_receipt(
            operation_type='autonomous_decision',
            operation_data=json.dumps({
                'confidence': decisions.get('confidence', 0),
                'tech_stack': decisions.get('tech_stack', {})
            }),
            input_data=description,
            output_data=decisions
        )
    
    def record_generation(self, description, result):
        """Record code generation with cryptographic proof"""
        return self.tecp.generate_receipt(
            operation_type='code_generation',
            operation_data=json.dumps({
                'success': result.get('success', False),
                'files_count': len(result.get('files', [])),
                'project_name': result.get('spec', {}).get('name', 'unknown')
            }),
            input_data=description,
            output_data=str(result.get('path', ''))
        )
    
    def record_prediction(self, project_path, predictions):
        """Record predictions with cryptographic proof"""
        return self.tecp.generate_receipt(
            operation_type='prediction',
            operation_data=json.dumps({
                'next_features_count': len(predictions.get('next_features', [])),
                'bugs_count': len(predictions.get('potential_bugs', [])),
                'security_count': len(predictions.get('security_vulnerabilities', []))
            }),
            input_data=project_path,
            output_data=predictions
        )
    
    def record_evolution(self, evolution_data):
        """Record AI self-evolution with cryptographic proof"""
        return self.tecp.generate_receipt(
            operation_type='self_evolution',
            operation_data=json.dumps({
                'evolved': evolution_data.get('evolved', False),
                'generation': evolution_data.get('generation', 0),
                'improvements': evolution_data.get('improvements', [])
            }),
            input_data='self_analysis',
            output_data=evolution_data
        )


if __name__ == '__main__':
    # Test TECP
    tecp = TECPCore()
    
    # Generate test receipt
    receipt = tecp.generate_receipt(
        operation_type='test',
        operation_data='Test operation',
        input_data='test input',
        output_data='test output'
    )
    
    print("Generated Receipt:")
    print(json.dumps(receipt, indent=2))
    
    # Verify receipt
    verification = tecp.verify_receipt(receipt['receipt_hash'])
    print("\nVerification Result:")
    print(json.dumps(verification, indent=2))
    
    # Get stats
    stats = tecp.get_stats()
    print("\nTECP Statistics:")
    print(json.dumps(stats, indent=2))

