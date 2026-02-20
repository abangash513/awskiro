#!/usr/bin/env python3
"""
Unit tests for discover_accounts Lambda function
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lambda'))

from discover_accounts import (
    filter_active_accounts,
    extract_account_metadata,
    retry_with_exponential_backoff
)


class TestDiscoverAccounts(unittest.TestCase):
    
    def test_filter_active_accounts_filters_inactive(self):
        """Test that inactive accounts are filtered out"""
        accounts = [
            {'Id': '111111111111', 'Name': 'Active1', 'Status': 'ACTIVE'},
            {'Id': '222222222222', 'Name': 'Suspended', 'Status': 'SUSPENDED'},
            {'Id': '333333333333', 'Name': 'Active2', 'Status': 'ACTIVE'},
            {'Id': '444444444444', 'Name': 'Closed', 'Status': 'CLOSED'},
        ]
        
        result = filter_active_accounts(accounts)
        
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]['Id'], '111111111111')
        self.assertEqual(result[1]['Id'], '333333333333')
    
    def test_extract_account_metadata_completeness(self):
        """Test that all required metadata fields are extracted"""
        account = {
            'Id': '123456789012',
            'Name': 'Production',
            'Arn': 'arn:aws:organizations::123456789012:account/o-abc123/ou-xyz/123456789012'
        }
        
        metadata = extract_account_metadata(account)
        
        self.assertIn('account_id', metadata)
        self.assertIn('account_name', metadata)
        self.assertIn('organizational_unit', metadata)
        self.assertEqual(metadata['account_id'], '123456789012')
        self.assertEqual(metadata['account_name'], 'Production')
        self.assertNotEqual(metadata['organizational_unit'], '')
    
    def test_retry_logic_exponential_backoff(self):
        """Test that retry logic implements exponential backoff"""
        from botocore.exceptions import ClientError
        
        call_count = 0
        delays = []
        
        def failing_func():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                error_response = {'Error': {'Code': 'ThrottlingException'}}
                raise ClientError(error_response, 'test_operation')
            return 'success'
        
        # Mock time.sleep to capture delays
        with patch('time.sleep') as mock_sleep:
            result = retry_with_exponential_backoff(failing_func, max_retries=3, base_delay=1)
            
            # Should have retried 2 times before success
            self.assertEqual(call_count, 3)
            self.assertEqual(result, 'success')
            
            # Verify exponential backoff (delays should increase)
            self.assertEqual(mock_sleep.call_count, 2)
            delays = [call.args[0] for call in mock_sleep.call_args_list]
            self.assertGreater(delays[1], delays[0])


if __name__ == '__main__':
    unittest.main()
