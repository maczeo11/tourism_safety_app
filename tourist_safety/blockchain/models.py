# blockchain/models.py

import hashlib
import uuid
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Blockchain(models.Model):
    """Represents a blockchain instance"""
    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"Blockchain: {self.name}"
    
    class Meta:
        ordering = ['-created_at']


class Block(models.Model):
    """Represents a block in the blockchain"""
    blockchain = models.ForeignKey(Blockchain, on_delete=models.CASCADE, related_name='blocks')
    index = models.PositiveIntegerField()
    timestamp = models.DateTimeField(auto_now_add=True)
    previous_hash = models.CharField(max_length=64, blank=True)
    hash = models.CharField(max_length=64, unique=True)
    nonce = models.PositiveIntegerField(default=0)
    
    class Meta:
        ordering = ['index']
        unique_together = ['blockchain', 'index']
    
    def __str__(self):
        return f"Block {self.index} - {self.hash[:10]}..."
    
    def calculate_hash(self):
        """Calculate the hash of this block"""
        block_string = f"{self.index}{self.timestamp}{self.previous_hash}{self.nonce}"
        return hashlib.sha256(block_string.encode()).hexdigest()
    
    def save(self, *args, **kwargs):
        if not self.hash:
            self.hash = self.calculate_hash()
        super().save(*args, **kwargs)


class UserUUID(models.Model):
    """Represents a UUID generated for a user and stored in blockchain"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blockchain_uuids')
    uuid_value = models.UUIDField(default=uuid.uuid4, unique=True)
    block = models.ForeignKey(Block, on_delete=models.CASCADE, related_name='user_uuids')
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['user', 'uuid_value']
    
    def __str__(self):
        return f"UUID for {self.user.username}: {self.uuid_value}"
    
    def get_uuid_string(self):
        """Return the UUID as a string"""
        return str(self.uuid_value)


class BlockchainService:
    """Service class for blockchain operations"""
    
    @staticmethod
    def get_or_create_blockchain(name="TouristSafetyUUID"):
        """Get or create the main blockchain"""
        blockchain, created = Blockchain.objects.get_or_create(
            name=name,
            defaults={'is_active': True}
        )
        return blockchain
    
    @staticmethod
    def get_latest_block(blockchain):
        """Get the latest block in the blockchain"""
        return Block.objects.filter(blockchain=blockchain).order_by('-index').first()
    
    @staticmethod
    def create_new_block(blockchain, user_uuids_data):
        """Create a new block with user UUIDs"""
        latest_block = BlockchainService.get_latest_block(blockchain)
        
        # Calculate new block index
        new_index = (latest_block.index + 1) if latest_block else 0
        
        # Create new block
        new_block = Block.objects.create(
            blockchain=blockchain,
            index=new_index,
            previous_hash=latest_block.hash if latest_block else "",
        )
        
        # Create UserUUID entries for this block
        user_uuids = []
        for user_data in user_uuids_data:
            user_uuid = UserUUID.objects.create(
                user=user_data['user'],
                uuid_value=user_data['uuid_value'],
                block=new_block
            )
            user_uuids.append(user_uuid)
        
        return new_block, user_uuids
    
    @staticmethod
    def generate_uuid_for_user(user):
        """Generate a new UUID for a user and add it to the blockchain"""
        blockchain = BlockchainService.get_or_create_blockchain()
        
        # Create new UUID
        new_uuid = uuid.uuid4()
        
        # Create new block with this UUID
        block, user_uuids = BlockchainService.create_new_block(
            blockchain, 
            [{'user': user, 'uuid_value': new_uuid}]
        )
        
        return user_uuids[0]
    
    @staticmethod
    def get_user_uuids(user):
        """Get all UUIDs for a user"""
        return UserUUID.objects.filter(user=user, is_active=True).order_by('-created_at')
    
    @staticmethod
    def get_latest_user_uuid(user):
        """Get the latest UUID for a user"""
        return UserUUID.objects.filter(user=user, is_active=True).order_by('-created_at').first()
    
    @staticmethod
    def verify_uuid_integrity(uuid_value):
        """Verify that a UUID exists in the blockchain and is valid"""
        try:
            user_uuid = UserUUID.objects.get(uuid_value=uuid_value, is_active=True)
            return {
                'valid': True,
                'user': user_uuid.user.username,  # Return username instead of user object
                'user_id': user_uuid.user.id,
                'created_at': user_uuid.created_at,
                'block_index': user_uuid.block.index,
                'block_hash': user_uuid.block.hash
            }
        except UserUUID.DoesNotExist:
            return {'valid': False, 'error': 'UUID not found in blockchain'}
    
    @staticmethod
    def verify_by_block_id(block_id):
        """Verify blockchain integrity by block ID"""
        try:
            block = Block.objects.get(id=block_id)
            blockchain = block.blockchain
            
            # Get all UUIDs in this block
            user_uuids = UserUUID.objects.filter(block=block, is_active=True)
            
            # Verify block hash integrity
            calculated_hash = block.calculate_hash()
            hash_valid = block.hash == calculated_hash
            
            # Get previous block for chaining verification
            previous_block = Block.objects.filter(
                blockchain=blockchain, 
                index=block.index - 1
            ).first()
            
            chain_valid = True
            if previous_block:
                chain_valid = block.previous_hash == previous_block.hash
            
            return {
                'valid': True,
                'block_id': block.id,
                'block_index': block.index,
                'block_hash': block.hash,
                'calculated_hash': calculated_hash,
                'hash_valid': hash_valid,
                'chain_valid': chain_valid,
                'previous_block_hash': previous_block.hash if previous_block else None,
                'uuids_in_block': [
                    {
                        'uuid': str(uuid.uuid_value),
                        'user': uuid.user.username,
                        'created_at': uuid.created_at.isoformat()
                    } for uuid in user_uuids
                ],
                'blockchain_name': blockchain.name,
                'created_at': block.timestamp.isoformat()
            }
        except Block.DoesNotExist:
            return {'valid': False, 'error': 'Block not found in blockchain'}
        except Exception as e:
            return {'valid': False, 'error': f'Verification failed: {str(e)}'}
    
    @staticmethod
    def get_blockchain_info():
        """Get information about the blockchain"""
        blockchain = BlockchainService.get_or_create_blockchain()
        latest_block = BlockchainService.get_latest_block(blockchain)
        total_uuids = UserUUID.objects.filter(is_active=True).count()
        
        return {
            'blockchain_name': blockchain.name,
            'total_blocks': blockchain.blocks.count(),
            'latest_block_index': latest_block.index if latest_block else -1,
            'total_uuids': total_uuids,
            'created_at': blockchain.created_at
        }