#!/usr/bin/env python3
"""
Unit tests for scan_account Lambda function
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lambda'))

from scan_account import AccountScanner


class TestScanAccount(unittest.TestCase):
    
    def setUp(self):
        """Set up test fixtures"""
        os.environ['DYNAMODB_TABLE'] = 'test_hri_findings'
        os.environ['S3_BUCKET'] = 'test-bucket'
        os.environ['REGIONS'] = 'us-east-1'
        
        self.scanner = AccountScanner(
            account_id='123456789012',
            account_name='Test Account',
            execution_id='test-execution-123'
        )
    
    @patch('scan_account.sts_client')
    def test_assume_role_success(self, mock_sts):
        """Test successful role assumption"""
        mock_sts.assume_role.return_value = {
            'Credentials': {
                'AccessKeyId': 'test-key',
                'SecretAccessKey': 'test-secret',
                'SessionToken': 'test-token'
            }
        }
        
        result = self.scanner.assume_role()
        
        self.assertTrue(result)
        self.assertIsNotNone(self.scanner.credentials)
        self.assertEqual(self.scanner.credentials['AccessKeyId'], 'test-key')
    
    @patch('scan_account.sts_client')
    @patch.object(AccountScanner, 'record_unscannable_account')
    def test_assume_role_failure_graceful(self, mock_record, mock_sts):
        """Test graceful handling of role assumption failure"""
        from botocore.exceptions import ClientError
        
        error_response = {'Error': {'Code': 'AccessDenied', 'Message': 'Access denied'}}
        mock_sts.assume_role.side_effect = ClientError(error_response, 'AssumeRole')
        
        result = self.scanner.assume_role()
        
        self.assertFalse(result)
        mock_record.assert_called_once()
    
    def test_check_public_s3_buckets_detection(self):
        """Test detection of public S3 buckets"""
        # Mock S3 client
        mock_s3 = MagicMock()
        mock_s3.list_buckets.return_value = {
            'Buckets': [
                {'Name': 'test-bucket-1'},
                {'Name': 'test-bucket-2'}
            ]
        }
        
        # First bucket has no public access block (public)
        from botocore.exceptions import ClientError
        error_response = {'Error': {'Code': 'NoSuchPublicAccessBlockConfiguration'}}
        mock_s3.get_public_access_block.side_effect = [
            ClientError(error_response, 'GetPublicAccessBlock'),
            {'PublicAccessBlockConfiguration': {
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }}
        ]
        
        with patch.object(self.scanner, 'get_session', return_value=mock_s3):
            findings = self.scanner.check_public_s3_buckets()
        
        # Should find 1 public bucket
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]['check_name'], 'Public S3 Bucket')
        self.assertTrue(findings[0]['hri'])
    
    def test_check_unencrypted_ebs_volumes(self):
        """Test detection of unencrypted EBS volumes"""
        mock_ec2 = MagicMock()
        mock_ec2.describe_volumes.return_value = {
            'Volumes': [
                {'VolumeId': 'vol-123', 'Encrypted': False},
                {'VolumeId': 'vol-456', 'Encrypted': True},
                {'VolumeId': 'vol-789', 'Encrypted': False}
            ]
        }
        
        with patch.object(self.scanner, 'get_session', return_value=mock_ec2):
            findings = self.scanner.check_unencrypted_ebs_volumes()
        
        # Should find 2 unencrypted volumes
        self.assertEqual(len(findings), 2)
        self.assertEqual(findings[0]['check_name'], 'Unencrypted EBS Volume')
    
    def test_check_root_mfa(self):
        """Test detection of root account without MFA"""
        mock_iam = MagicMock()
        mock_iam.get_account_summary.return_value = {
            'SummaryMap': {
                'AccountMFAEnabled': 0
            }
        }
        
        with patch.object(self.scanner, 'get_session', return_value=mock_iam):
            findings = self.scanner.check_root_mfa()
        
        # Should find root MFA issue
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]['check_name'], 'Root Account Without MFA')
        self.assertTrue(findings[0]['hri'])


if __name__ == '__main__':
    unittest.main()
