# blockchain/views.py

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import BlockchainService
from .serializers import (
    UserUUIDSerializer, BlockchainSerializer, 
    UUIDGenerationSerializer, UUIDVerificationSerializer,
    BlockchainInfoSerializer
)

User = get_user_model()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_uuid(request):
    """Generate a new UUID for the authenticated user"""
    try:
        # Generate UUID for the authenticated user
        user_uuid = BlockchainService.generate_uuid_for_user(request.user)
        
        serializer = UserUUIDSerializer(user_uuid)
        return Response({
            'success': True,
            'message': 'UUID generated successfully',
            'data': serializer.data
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error generating UUID: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_uuids(request):
    """Get all UUIDs for the authenticated user"""
    try:
        user_uuids = BlockchainService.get_user_uuids(request.user)
        serializer = UserUUIDSerializer(user_uuids, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {len(user_uuids)} UUIDs for user',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error retrieving UUIDs: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_latest_uuid(request):
    """Get the latest UUID for the authenticated user"""
    try:
        latest_uuid = BlockchainService.get_latest_user_uuid(request.user)
        
        if not latest_uuid:
            return Response({
                'success': False,
                'message': 'No UUIDs found for user'
            }, status=status.HTTP_404_NOT_FOUND)
        
        serializer = UserUUIDSerializer(latest_uuid)
        return Response({
            'success': True,
            'message': 'Latest UUID retrieved successfully',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error retrieving latest UUID: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_uuid(request):
    """Verify a UUID's integrity in the blockchain"""
    serializer = UUIDVerificationSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response({
            'success': False,
            'message': 'Invalid UUID format',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        uuid_value = serializer.validated_data['uuid_value']
        verification_result = BlockchainService.verify_uuid_integrity(uuid_value)
        
        if verification_result['valid']:
            return Response({
                'success': True,
                'message': 'UUID is valid and found in blockchain',
                'data': verification_result
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'message': verification_result['error']
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error verifying UUID: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_block(request):
    """Verify blockchain integrity by block ID"""
    try:
        block_id = request.data.get('block_id')
        if not block_id:
            return Response({
                'success': False,
                'message': 'Block ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        verification_result = BlockchainService.verify_by_block_id(block_id)
        
        if verification_result['valid']:
            return Response({
                'success': True,
                'message': 'Block verification successful',
                'data': verification_result
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'message': verification_result['error']
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error verifying block: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_blockchain_info(request):
    """Get blockchain information"""
    try:
        blockchain_info = BlockchainService.get_blockchain_info()
        serializer = BlockchainInfoSerializer(blockchain_info)
        
        return Response({
            'success': True,
            'message': 'Blockchain information retrieved successfully',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error retrieving blockchain info: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_blockchain_details(request):
    """Get detailed blockchain information including blocks"""
    try:
        blockchain = BlockchainService.get_or_create_blockchain()
        serializer = BlockchainSerializer(blockchain)
        
        return Response({
            'success': True,
            'message': 'Blockchain details retrieved successfully',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error retrieving blockchain details: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)