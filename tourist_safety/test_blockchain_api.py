#!/usr/bin/env python3
"""
Simple test script for the Blockchain UUID API
Run this after starting the Django server
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:8000"
USERNAME = "testuser"
EMAIL = "test@example.com"
PASSWORD = "testpass123"

def create_test_user():
    """Create a test user and get authentication token"""
    print("Creating test user...")
    
    # Register user
    register_data = {
        "username": USERNAME,
        "email": EMAIL,
        "password": PASSWORD,
        "password_confirm": PASSWORD
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/register/", json=register_data)
        if response.status_code == 201:
            print("✓ User created successfully")
        else:
            print(f"User creation response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error creating user: {e}")
    
    # Login to get token
    login_data = {
        "username": USERNAME,
        "password": PASSWORD
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login/", json=login_data)
        if response.status_code == 200:
            data = response.json()
            token = data.get('token')
            print("✓ Login successful")
            return token
        else:
            print(f"Login failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Error logging in: {e}")
        return None

def test_blockchain_api(token):
    """Test the blockchain API endpoints"""
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    print("\n=== Testing Blockchain API ===")
    
    # 1. Get blockchain info
    print("\n1. Getting blockchain info...")
    try:
        response = requests.get(f"{BASE_URL}/blockchain/info/", headers=headers)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")
    
    # 2. Generate UUID
    print("\n2. Generating UUID...")
    try:
        response = requests.post(f"{BASE_URL}/blockchain/generate-uuid/", headers=headers)
        print(f"Status: {response.status_code}")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        
        if data.get('success') and 'data' in data:
            uuid_value = data['data']['uuid_value']
            print(f"Generated UUID: {uuid_value}")
            return uuid_value
    except Exception as e:
        print(f"Error: {e}")
        return None
    
    return None

def test_uuid_verification(token, uuid_value):
    """Test UUID verification"""
    if not uuid_value:
        print("\nSkipping verification test - no UUID generated")
        return
    
    print(f"\n3. Verifying UUID: {uuid_value}")
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    verify_data = {
        'uuid_value': uuid_value
    }
    
    try:
        response = requests.post(f"{BASE_URL}/blockchain/verify-uuid/", 
                               headers=headers, json=verify_data)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

def test_get_user_uuids(token):
    """Test getting user UUIDs"""
    print("\n4. Getting user UUIDs...")
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(f"{BASE_URL}/blockchain/user-uuids/", headers=headers)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

def main():
    print("Blockchain UUID API Test")
    print("=" * 50)
    
    # Wait a moment for server to start
    print("Waiting for server to start...")
    time.sleep(3)
    
    # Test server connectivity
    try:
        response = requests.get(f"{BASE_URL}/admin/")
        print("✓ Server is running")
    except Exception as e:
        print(f"✗ Server not accessible: {e}")
        return
    
    # Create user and get token
    token = create_test_user()
    if not token:
        print("Failed to get authentication token")
        return
    
    # Test blockchain API
    uuid_value = test_blockchain_api(token)
    
    # Test UUID verification
    test_uuid_verification(token, uuid_value)
    
    # Test getting user UUIDs
    test_get_user_uuids(token)
    
    print("\n" + "=" * 50)
    print("Test completed!")

if __name__ == "__main__":
    main()
