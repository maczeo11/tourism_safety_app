# blockchain/serializers.py

from rest_framework import serializers
from .models import Blockchain, Block, UserUUID
from django.contrib.auth import get_user_model

User = get_user_model()


class UserUUIDSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source='user.username', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    block_index = serializers.IntegerField(source='block.index', read_only=True)
    block_hash = serializers.CharField(source='block.hash', read_only=True)
    
    class Meta:
        model = UserUUID
        fields = [
            'id', 'uuid_value', 'user_username', 'user_email', 
            'block_index', 'block_hash', 'created_at', 'is_active'
        ]
        read_only_fields = ['id', 'created_at', 'uuid_value']


class BlockSerializer(serializers.ModelSerializer):
    user_uuids = UserUUIDSerializer(many=True, read_only=True)
    
    class Meta:
        model = Block
        fields = [
            'id', 'index', 'timestamp', 'previous_hash', 
            'hash', 'nonce', 'user_uuids'
        ]
        read_only_fields = ['id', 'timestamp', 'hash']


class BlockchainSerializer(serializers.ModelSerializer):
    blocks = BlockSerializer(many=True, read_only=True)
    total_blocks = serializers.SerializerMethodField()
    total_uuids = serializers.SerializerMethodField()
    
    class Meta:
        model = Blockchain
        fields = [
            'id', 'name', 'created_at', 'is_active', 
            'total_blocks', 'total_uuids', 'blocks'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_total_blocks(self, obj):
        return obj.blocks.count()
    
    def get_total_uuids(self, obj):
        return UserUUID.objects.filter(block__blockchain=obj, is_active=True).count()


class UUIDGenerationSerializer(serializers.Serializer):
    """Serializer for UUID generation request"""
    user_id = serializers.IntegerField(required=False)
    
    def validate_user_id(self, value):
        try:
            User.objects.get(id=value)
            return value
        except User.DoesNotExist:
            raise serializers.ValidationError("User does not exist")


class UUIDVerificationSerializer(serializers.Serializer):
    """Serializer for UUID verification request"""
    uuid_value = serializers.UUIDField()
    
    def validate_uuid_value(self, value):
        # Just validate the UUID format, don't check existence here
        # The verification logic will be handled in the view
        return value


class BlockchainInfoSerializer(serializers.Serializer):
    """Serializer for blockchain information"""
    blockchain_name = serializers.CharField()
    total_blocks = serializers.IntegerField()
    latest_block_index = serializers.IntegerField()
    total_uuids = serializers.IntegerField()
    created_at = serializers.DateTimeField()
