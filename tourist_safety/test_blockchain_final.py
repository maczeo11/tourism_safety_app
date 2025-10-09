#!/usr/bin/env python3
"""
Final Blockchain UUID API Test
Tests the blockchain system with proper error handling
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
        print(f"✅ Blockchain: {blockchain.name}")
        
        # Test user creation
        user, created = User.objects.get_or_create(
            username='final_test_user',
            defaults={
                'email': 'final_test@example.com',
                'first_name': 'Final',
                'last_name': 'Test'
            }
        )
        if created:
            user.set_password('testpass123')
            user.save()
        print(f"✅ User: {user.username} ({'created' if created else 'found'})")
        
        # Test UUID generation
        user_uuid = BlockchainService.generate_uuid_for_user(user)
        print(f"✅ UUID generated: {user_uuid.uuid_value}")
        
        # Test UUID verification
        verification = BlockchainService.verify_uuid_integrity(user_uuid.uuid_value)
        print(f"✅ UUID verification: {verification['valid']}")
        
        # Test blockchain info
        info = BlockchainService.get_blockchain_info()
        print(f"✅ Blockchain: {info['total_blocks']} blocks, {info['total_uuids']} UUIDs")
        
        return True, user, str(user_uuid.uuid_value)
        
    except Exception as e:
        print(f"❌ Model test failed: {e}")
        return False, None, None

def test_api_authentication():
    """Test API authentication with existing user"""
    print("\n🌐 Testing API Authentication...")
    
    base_url = "http://localhost:8000"
    
    try:
        # Test server connectivity
        response = requests.get(f"{base_url}/admin/", timeout=5)
        if response.status_code != 200:
            print(f"❌ Server not accessible: {response.status_code}")
            return False, None
        
        print("✅ Server is running")
        
        # Try to login with existing user first
        login_data = {
            "username": "api_test_user_2",  # From previous test
            "password": "testpass123"
        }
        
        response = requests.post(f"{base_url}/auth/login/", json=login_data)
        if response.status_code == 200:
            data = response.json()
            if data.get('success') and 'token' in data:
                token = data['token']
                print(f"✅ Login successful with existing user, token: {token[:20]}...")
                return True, token
        
        # If existing user doesn't work, try to register new user
        print("Trying to register new user...")
        register_data = {
            "username": f"test_user_{int(time.time())}",
            "email": f"test_{int(time.time())}@example.com",
            "password": "testpass123",
            "password2": "testpass123"
        }
        
        response = requests.post(f"{base_url}/auth/register/", json=register_data)
        if response.status_code in [200, 201]:
            print("✅ User registered successfully")
        else:
            print(f"❌ Registration failed: {response.status_code} - {response.text}")
            return False, None
        
        # Login with new user
        login_data = {
            "username": register_data["username"],
            "password": register_data["password"]
        }
        
        response = requests.post(f"{base_url}/auth/login/", json=login_data)
        if response.status_code == 200:
            data = response.json()
            if data.get('success') and 'token' in data:
                token = data['token']
                print(f"✅ Login successful with new user, token: {token[:20]}...")
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
        print("1. Testing blockchain info...")
        response = requests.get(f"{base_url}/blockchain/info/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            info = data.get('data', {})
            print(f"   ✅ Blockchain info: {info.get('total_uuids', 0)} UUIDs, {info.get('total_blocks', 0)} blocks")
        else:
            print(f"   ❌ Blockchain info failed: {response.status_code}")
            return False
        
        # Test UUID generation
        print("2. Testing UUID generation...")
        response = requests.post(f"{base_url}/blockchain/generate-uuid/", headers=headers)
        if response.status_code == 201:
            data = response.json()
            if data.get('success'):
                uuid_value = data['data']['uuid_value']
                print(f"   ✅ UUID generated: {uuid_value}")
                
                # Test UUID verification
                print("3. Testing UUID verification...")
                verify_data = {'uuid_value': uuid_value}
                response = requests.post(f"{base_url}/blockchain/verify-uuid/", 
                                       headers=headers, json=verify_data)
                if response.status_code == 200:
                    verify_result = response.json()
                    if verify_result.get('data', {}).get('valid'):
                        print("   ✅ UUID verification successful")
                    else:
                        print(f"   ❌ UUID verification failed: {verify_result}")
                        return False
                else:
                    print(f"   ❌ UUID verification failed: {response.status_code} - {response.text}")
                    return False
            else:
                print(f"   ❌ UUID generation failed: {data}")
                return False
        else:
            print(f"   ❌ UUID generation failed: {response.status_code} - {response.text}")
            return False
        
        # Test get user UUIDs
        print("4. Testing get user UUIDs...")
        response = requests.get(f"{base_url}/blockchain/user-uuids/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            uuids = data.get('data', [])
            print(f"   ✅ Retrieved {len(uuids)} UUIDs")
        else:
            print(f"   ❌ Get user UUIDs failed: {response.status_code}")
            return False
        
        # Test get latest UUID
        print("5. Testing get latest UUID...")
        response = requests.get(f"{base_url}/blockchain/latest-uuid/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            latest_uuid = data.get('data', {}).get('uuid_value', 'N/A')
            print(f"   ✅ Latest UUID: {latest_uuid}")
        else:
            print(f"   ❌ Get latest UUID failed: {response.status_code}")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Blockchain API test failed: {e}")
        return False

def test_flutter_integration(token):
    """Test Flutter app integration simulation"""
    print("\n📱 Testing Flutter App Integration...")
    
    base_url = "http://localhost:8000"
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    try:
        print("Simulating Flutter app user journey...")
        
        # Step 1: App loads and checks for existing UUID
        print("1. App loads - checking for existing UUID...")
        response = requests.get(f"{base_url}/blockchain/latest-uuid/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            if data.get('success') and data.get('data'):
                existing_uuid = data['data']['uuid_value']
                print(f"   ✅ Found existing UUID: {existing_uuid}")
            else:
                print("   ℹ️  No existing UUID found")
        
        # Step 2: User generates new UUID
        print("2. User generates new UUID...")
        response = requests.post(f"{base_url}/blockchain/generate-uuid/", headers=headers)
        if response.status_code == 201:
            data = response.json()
            if data.get('success'):
                new_uuid = data['data']['uuid_value']
                print(f"   ✅ Generated new UUID: {new_uuid}")
                
                # Step 3: User verifies the UUID
                print("3. User verifies the UUID...")
                verify_data = {'uuid_value': new_uuid}
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
        
        # Step 4: User views all UUIDs
        print("4. User views all their UUIDs...")
        response = requests.get(f"{base_url}/blockchain/user-uuids/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            uuids = data.get('data', [])
            print(f"   ✅ Retrieved {len(uuids)} UUIDs")
            for i, uuid_data in enumerate(uuids[-3:]):  # Show last 3
                print(f"      {i+1}. {uuid_data['uuid_value']} (Block {uuid_data['block_index']})")
        else:
            print(f"   ❌ Failed to retrieve UUIDs: {response.status_code}")
            return False
        
        # Step 5: User checks blockchain status
        print("5. User checks blockchain status...")
        response = requests.get(f"{base_url}/blockchain/info/", headers=headers)
        if response.status_code == 200:
            data = response.json()
            info = data.get('data', {})
            print(f"   ✅ Blockchain: {info.get('total_blocks', 0)} blocks, {info.get('total_uuids', 0)} UUIDs")
        else:
            print(f"   ❌ Failed to get blockchain info: {response.status_code}")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Flutter integration test failed: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Final Blockchain UUID System Test")
    print("=" * 60)
    print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Test 1: Models
    model_success, user, uuid_value = test_blockchain_models()
    
    # Test 2: API Authentication
    api_success, token = test_api_authentication()
    
    if not api_success:
        print("\n❌ Cannot proceed with API tests - authentication failed")
        return 1
    
    # Test 3: Blockchain API
    blockchain_success = test_blockchain_api(token)
    
    # Test 4: Flutter Integration
    flutter_success = test_flutter_integration(token)
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    tests = [
        ("Django Models", model_success),
        ("API Authentication", api_success),
        ("Blockchain API", blockchain_success),
        ("Flutter Integration", flutter_success)
    ]
    
    passed = sum(1 for _, success in tests if success)
    total = len(tests)
    
    for test_name, success in tests:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")
    
    print(f"\nOverall: {passed}/{total} tests passed ({(passed/total)*100:.1f}%)")
    
    if passed == total:
        print("\n🎉 All tests passed! The blockchain system is working correctly.")
        print("\n📋 Next Steps:")
        print("   1. Open your Flutter app")
        print("   2. Login with your credentials")
        print("   3. Tap 'Get UUID' to test the blockchain integration")
        print("   4. Generate and verify UUIDs through the app")
        print("\n🔗 API Endpoints Available:")
        print("   • POST /blockchain/generate-uuid/ - Generate new UUID")
        print("   • GET  /blockchain/user-uuids/ - Get all user UUIDs")
        print("   • GET  /blockchain/latest-uuid/ - Get latest UUID")
        print("   • POST /blockchain/verify-uuid/ - Verify UUID")
        print("   • GET  /blockchain/info/ - Get blockchain info")
        return 0
    else:
        print(f"\n⚠️  {total - passed} tests failed. Please check the output above.")
        return 1

if __name__ == "__main__":
    exit(main())
