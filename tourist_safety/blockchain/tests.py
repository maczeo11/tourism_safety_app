# blockchain/tests.py

from django.test import TestCase
from django.contrib.auth import get_user_model
from .models import BlockchainService, Blockchain, Block, UserUUID
import uuid

User = get_user_model()


class BlockchainModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_blockchain_creation(self):
        """Test blockchain creation"""
        blockchain = BlockchainService.get_or_create_blockchain()
        self.assertIsNotNone(blockchain)
        self.assertEqual(blockchain.name, "TouristSafetyUUID")
        self.assertTrue(blockchain.is_active)
    
    def test_uuid_generation(self):
        """Test UUID generation for user"""
        user_uuid = BlockchainService.generate_uuid_for_user(self.user)
        
        self.assertIsNotNone(user_uuid)
        self.assertEqual(user_uuid.user, self.user)
        self.assertIsNotNone(user_uuid.uuid_value)
        self.assertTrue(user_uuid.is_active)
    
    def test_uuid_verification(self):
        """Test UUID verification"""
        user_uuid = BlockchainService.generate_uuid_for_user(self.user)
        
        # Verify the UUID
        verification = BlockchainService.verify_uuid_integrity(user_uuid.uuid_value)
        
        self.assertTrue(verification['valid'])
        self.assertEqual(verification['user'], self.user)
        self.assertIsNotNone(verification['block_index'])
        self.assertIsNotNone(verification['block_hash'])
    
    def test_invalid_uuid_verification(self):
        """Test verification of non-existent UUID"""
        fake_uuid = uuid.uuid4()
        verification = BlockchainService.verify_uuid_integrity(fake_uuid)
        
        self.assertFalse(verification['valid'])
        self.assertIn('error', verification)
    
    def test_get_user_uuids(self):
        """Test getting all UUIDs for a user"""
        # Generate multiple UUIDs
        BlockchainService.generate_uuid_for_user(self.user)
        BlockchainService.generate_uuid_for_user(self.user)
        
        user_uuids = BlockchainService.get_user_uuids(self.user)
        self.assertEqual(len(user_uuids), 2)
    
    def test_get_latest_uuid(self):
        """Test getting the latest UUID for a user"""
        # Generate multiple UUIDs
        first_uuid = BlockchainService.generate_uuid_for_user(self.user)
        second_uuid = BlockchainService.generate_uuid_for_user(self.user)
        
        latest_uuid = BlockchainService.get_latest_user_uuid(self.user)
        self.assertEqual(latest_uuid, second_uuid)
    
    def test_blockchain_info(self):
        """Test blockchain information retrieval"""
        # Generate some data
        BlockchainService.generate_uuid_for_user(self.user)
        
        info = BlockchainService.get_blockchain_info()
        
        self.assertIn('blockchain_name', info)
        self.assertIn('total_blocks', info)
        self.assertIn('total_uuids', info)
        self.assertIn('created_at', info)
        self.assertEqual(info['total_uuids'], 1)