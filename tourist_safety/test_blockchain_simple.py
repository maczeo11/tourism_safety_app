#!/usr/bin/env python3
"""
Simple Blockchain UUID API Test
Tests the core blockchain functionality with proper API calls
"""

import os
import sys
import django
import requests
import json
import time
from datetime import datetime

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tourist_safety.settings')
django.setup()

from django.contrib.auth import get_user_model
from blockchain.models import BlockchainService, Blockchain, Block, UserUUID

User = get_user_model()

def test_blockchain_models():
    """Test blockchain models directly"""
    print("🔧 Testing Blockchain Models...")
    
    try:
        # Test blockchain creation
        blockchain = BlockchainService.get_or_create_blockchain()
        print(f"✅ Blockchain created: {blockchain.name}")
        
        # Test user creation
        user, created = User.objects.get_or_create(
            username='test_user_api',
            defaults={
                'email': 'test_api@example.com',
                'first_name': 'Test',
                'last_name': 'User'
            }
        )
        if created:
            user.set_password('testpass123')
            user.save()
        print(f"✅ User {'created' if created else 'found'}: {user.username}")
        
        # Test UUID generation
        user_uuid = BlockchainService.generate_uuid_for_user(user)
        print(f"✅ UUID generated: {user_uuid.uuid_value}")
        
        # Test UUID verification
        verification = BlockchainService.verify_uuid_integrity(user_uuid.uuid_value)
        print(f"✅ UUID verification: {verification['valid']}")
        
        # Test blockchain info
        info = BlockchainService.get_blockchain_info()
        print(f"✅ Blockchain info: {info['total_blocks']} blocks, {info['total_uuids']} UUIDs")
        
        return True, user, str(user_uuid.uuid_value)
        
    except Exception as e:
        print(f"❌ Model test failed: {e}")
        return False, None, None

def test_api_with_auth():
    """Test API with proper authentication"""
    print("\n🌐 Testing API with Authentication...")
    
    base_url = "http://localhost:8000"
    
    try:
        # Test server connectivity
        response = requests.get(f"{base_url}/admin/", timeout=5)
        if response.status_code != 200:
            print(f"❌ Server not accessible: {response.status_code}")
            return False, None
        
        print("✅ Server is running")
        
        # Register user with correct field names
        register_data = {
            "username": "api_test_user_2",
            "email": "api_test_2@example.com",
            "password": "testpass123",
            "password2": "testpass123"  # Correct field name
        }
        
        response = requests.post(f"{base_url}/auth/register/", json=register_data)
        if response.status_code in [200, 201]:
            print("✅ User registered successfully")
        else:
            print(f"❌ Registration failed: {response.status_code} - {response.text}")
            return False, None
        
        # Login
        login_data = {
            "username": "api_test_user_2",
            "password": "testpass123"
        }
        
        response = requests.post(f"{base_url}/auth/login/", json=login_data)
        if response.status_code == 200:
            data = response.json()
            if data.get('success') and 'token' in data:
                token = data['token']
                print(f"✅ Login successful, token: {token[:20]}...")
                return True, token
            else:
                print(f"❌ Login failed: {data}")
                return False, None
        else:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            return False, None
            
    except requests.exceptions.ConnectionError:
        print("❌ Server not running or not accessible")
        return False, None
    except Exception as e:
        print(f"❌ API test failed: {e}")
        return False, None

def test_blockchain_api(token):
    """Test blockchain API endpoints"""
    print("\n🔗 Testing Blockchain API Endpoints...")
    
    base_url = "http://localhost:8000"
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    try:
        # Test blockchain info
        response = requests.get(f"{base_url}/blockchain/info/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Blockchain info: {data.get('data', {}).get('total_uuids', 0)} UUIDs")
        else:
            print(f"❌ Blockchain info failed: {response.status_code}")
            return False
        
        # Test UUID generation
        response = requests.post(f"{base_url}/blockchain/generate-uuid/", headers=headers)
        if response.status_code == 201:
            data = response.json()
            if data.get('success'):
                uuid_value = data['data']['uuid_value']
                print(f"✅ UUID generated: {uuid_value}")
                
                # Test UUID verification
                verify_data = {'uuid_value': uuid_value}
                response = requests.post(f"{base_url}/blockchain/verify-uuid/", 
                                       headers=headers, json=verify_data)
                if response.status_code == 200:
                    verify_result = response.json()
                    print(f"✅ UUID verification: {verify_result.get('data', {}).get('valid', False)}")
                else:
                    print(f"❌ UUID verification failed: {response.status_code}")
                    return False
            else:
                print(f"❌ UUID generation failed: {data}")
                return False
        else:
            print(f"❌ UUID generation failed: {response.status_code}")
            return False
        
        # Test get user UUIDs
        response = requests.get(f"{base_url}/blockchain/user-uuids/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ User UUIDs retrieved: {len(data.get('data', []))} UUIDs")
        else:
            print(f"❌ Get user UUIDs failed: {response.status_code}")
            return False
        
        # Test get latest UUID
        response = requests.get(f"{base_url}/blockchain/latest-uuid/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Latest UUID retrieved: {data.get('data', {}).get('uuid_value', 'N/A')}")
        else:
            print(f"❌ Get latest UUID failed: {response.status_code}")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Blockchain API test failed: {e}")
        return False

def test_flutter_simulation(token):
    """Simulate Flutter app usage"""
    print("\n📱 Simulating Flutter App Usage...")
    
    base_url = "http://localhost:8000"
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    try:
        print("1. User opens app and checks for existing UUID...")
        response = requests.get(f"{base_url}/blockchain/latest-uuid/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print(f"   ✅ Found existing UUID: {data['data']['uuid_value']}")
            else:
                print("   ℹ️  No existing UUID found")
        
        print("2. User generates new UUID...")
        response = requests.post(f"{base_url}/blockchain/generate-uuid/", headers=headers)
        if response.status_code == 201:
            data = response.json()
            if data.get('success'):
                uuid_value = data['data']['uuid_value']
                print(f"   ✅ Generated new UUID: {uuid_value}")
                
                print("3. User verifies the UUID...")
                verify_data = {'uuid_value': uuid_value}
                response = requests.post(f"{base_url}/blockchain/verify-uuid/", 
                                       headers=headers, json=verify_data)
                if response.status_code == 200:
                    verify_result = response.json()
                    if verify_result.get('data', {}).get('valid'):
                        print("   ✅ UUID verification successful")
                    else:
                        print("   ❌ UUID verification failed")
                        return False
                else:
                    print(f"   ❌ UUID verification failed: {response.status_code}")
                    return False
            else:
                print(f"   ❌ UUID generation failed: {data}")
                return False
        else:
            print(f"   ❌ UUID generation failed: {response.status_code}")
            return False
        
        print("4. User views all their UUIDs...")
        response = requests.get(f"{base_url}/blockchain/user-uuids/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            uuids = data.get('data', [])
            print(f"   ✅ Retrieved {len(uuids)} UUIDs")
            for i, uuid_data in enumerate(uuids):
                print(f"      {i+1}. {uuid_data['uuid_value']} (Block {uuid_data['block_index']})")
        else:
            print(f"   ❌ Failed to retrieve UUIDs: {response.status_code}")
            return False
        
        print("5. User checks blockchain status...")
        response = requests.get(f"{base_url}/blockchain/info/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            info = data.get('data', {})
            print(f"   ✅ Blockchain status: {info.get('total_blocks', 0)} blocks, {info.get('total_uuids', 0)} UUIDs")
        else:
            print(f"   ❌ Failed to get blockchain info: {response.status_code}")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Flutter simulation failed: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Blockchain UUID System Test")
    print("=" * 50)
    print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    # Test 1: Models
    model_success, user, uuid_value = test_blockchain_models()
    
    # Test 2: API Authentication
    api_success, token = test_api_with_auth()
    
    if not api_success:
        print("\n❌ Cannot proceed with API tests - authentication failed")
        return 1
    
    # Test 3: Blockchain API
    blockchain_success = test_blockchain_api(token)
    
    # Test 4: Flutter Simulation
    flutter_success = test_flutter_simulation(token)
    
    # Summary
    print("\n" + "=" * 50)
    print("TEST SUMMARY")
    print("=" * 50)
    
    tests = [
        ("Django Models", model_success),
        ("API Authentication", api_success),
        ("Blockchain API", blockchain_success),
        ("Flutter Simulation", flutter_success)
    ]
    
    passed = sum(1 for _, success in tests if success)
    total = len(tests)
    
    for test_name, success in tests:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")
    
    print(f"\nOverall: {passed}/{total} tests passed ({(passed/total)*100:.1f}%)")
    
    if passed == total:
        print("\n🎉 All tests passed! The blockchain system is working correctly.")
        print("\n📋 What you can do now:")
        print("   1. Open your Flutter app")
        print("   2. Login with username: api_test_user_2, password: testpass123")
        print("   3. Tap 'Get UUID' to test the blockchain integration")
        print("   4. Generate and verify UUIDs through the app")
        return 0
    else:
        print(f"\n⚠️  {total - passed} tests failed. Please check the output above.")
        return 1

if __name__ == "__main__":
    exit(main())
