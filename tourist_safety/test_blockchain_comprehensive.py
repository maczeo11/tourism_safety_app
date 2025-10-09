#!/usr/bin/env python3
"""
Comprehensive Blockchain UUID API Test Suite
Tests all blockchain functionality including models, APIs, and Flutter integration
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
from django.test import Client
from django.urls import reverse

User = get_user_model()

class BlockchainTester:
    def __init__(self):
        self.base_url = "http://localhost:8000"
        self.client = Client()
        self.test_user = None
        self.auth_token = None
        self.test_results = []
        
    def log_test(self, test_name, success, message="", data=None):
        """Log test results"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")
        if message:
            print(f"   {message}")
        if data:
            print(f"   Data: {json.dumps(data, indent=2, default=str)}")
        
        self.test_results.append({
            'test': test_name,
            'success': success,
            'message': message,
            'data': data
        })
        print()

    def test_1_django_models(self):
        """Test 1: Django Models and Database"""
        print("=" * 60)
        print("TEST 1: Django Models and Database")
        print("=" * 60)
        
        try:
            # Test blockchain creation
            blockchain = BlockchainService.get_or_create_blockchain()
            self.log_test(
                "Blockchain Creation", 
                True, 
                f"Created blockchain: {blockchain.name}",
                {'id': blockchain.id, 'name': blockchain.name}
            )
            
            # Test user creation
            self.test_user, created = User.objects.get_or_create(
                username='blockchain_test_user',
                defaults={
                    'email': 'blockchain_test@example.com',
                    'first_name': 'Blockchain',
                    'last_name': 'Tester'
                }
            )
            if created:
                self.test_user.set_password('testpass123')
                self.test_user.save()
            
            self.log_test(
                "User Creation", 
                True, 
                f"User {'created' if created else 'found'}: {self.test_user.username}",
                {'username': self.test_user.username, 'email': self.test_user.email}
            )
            
            # Test UUID generation
            user_uuid = BlockchainService.generate_uuid_for_user(self.test_user)
            self.log_test(
                "UUID Generation", 
                True, 
                f"Generated UUID: {user_uuid.uuid_value}",
                {
                    'uuid': str(user_uuid.uuid_value),
                    'block_index': user_uuid.block.index,
                    'created_at': user_uuid.created_at.isoformat()
                }
            )
            
            # Test UUID verification
            verification = BlockchainService.verify_uuid_integrity(user_uuid.uuid_value)
            self.log_test(
                "UUID Verification", 
                verification['valid'], 
                f"Verification result: {verification}",
                verification
            )
            
            # Test blockchain info
            info = BlockchainService.get_blockchain_info()
            self.log_test(
                "Blockchain Info", 
                True, 
                f"Blockchain has {info['total_blocks']} blocks and {info['total_uuids']} UUIDs",
                info
            )
            
        except Exception as e:
            self.log_test("Django Models Test", False, f"Error: {str(e)}")

    def test_2_api_endpoints(self):
        """Test 2: API Endpoints"""
        print("=" * 60)
        print("TEST 2: API Endpoints")
        print("=" * 60)
        
        try:
            # Test server connectivity
            response = requests.get(f"{self.base_url}/admin/", timeout=5)
            self.log_test(
                "Server Connectivity", 
                response.status_code == 200, 
                f"Server responded with status {response.status_code}"
            )
            
            # Test blockchain info endpoint
            response = requests.get(f"{self.base_url}/blockchain/info/")
            if response.status_code == 401:
                self.log_test("Blockchain Info Endpoint", False, "Authentication required (expected)")
            else:
                self.log_test("Blockchain Info Endpoint", True, f"Status: {response.status_code}")
            
        except requests.exceptions.ConnectionError:
            self.log_test("Server Connectivity", False, "Server not running or not accessible")
        except Exception as e:
            self.log_test("API Endpoints Test", False, f"Error: {str(e)}")

    def test_3_authentication_flow(self):
        """Test 3: Authentication Flow"""
        print("=" * 60)
        print("TEST 3: Authentication Flow")
        print("=" * 60)
        
        try:
            # Test user registration
            register_data = {
                "username": "api_test_user",
                "email": "api_test@example.com",
                "password": "testpass123",
                "password_confirm": "testpass123"
            }
            
            response = requests.post(f"{self.base_url}/auth/register/", json=register_data)
            if response.status_code in [200, 201]:
                self.log_test("User Registration", True, "User registered successfully")
            else:
                self.log_test("User Registration", False, f"Status: {response.status_code}, Response: {response.text}")
            
            # Test user login
            login_data = {
                "username": "api_test_user",
                "password": "testpass123"
            }
            
            response = requests.post(f"{self.base_url}/auth/login/", json=login_data)
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'token' in data:
                    self.auth_token = data['token']
                    self.log_test("User Login", True, f"Login successful, token: {self.auth_token[:20]}...")
                else:
                    self.log_test("User Login", False, f"Login failed: {data}")
            else:
                self.log_test("User Login", False, f"Status: {response.status_code}, Response: {response.text}")
                
        except Exception as e:
            self.log_test("Authentication Flow", False, f"Error: {str(e)}")

    def test_4_authenticated_api_calls(self):
        """Test 4: Authenticated API Calls"""
        print("=" * 60)
        print("TEST 4: Authenticated API Calls")
        print("=" * 60)
        
        if not self.auth_token:
            self.log_test("Authenticated API Calls", False, "No authentication token available")
            return
        
        headers = {
            'Authorization': f'Token {self.auth_token}',
            'Content-Type': 'application/json'
        }
        
        try:
            # Test blockchain info
            response = requests.get(f"{self.base_url}/blockchain/info/", headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Get Blockchain Info", True, f"Retrieved blockchain info", data.get('data'))
            else:
                self.log_test("Get Blockchain Info", False, f"Status: {response.status_code}")
            
            # Test UUID generation
            response = requests.post(f"{self.base_url}/blockchain/generate-uuid/", headers=headers)
            if response.status_code == 201:
                data = response.json()
                if data.get('success'):
                    uuid_value = data['data']['uuid_value']
                    self.log_test("Generate UUID", True, f"Generated UUID: {uuid_value}", data['data'])
                    
                    # Test UUID verification
                    verify_data = {'uuid_value': uuid_value}
                    response = requests.post(f"{self.base_url}/blockchain/verify-uuid/", 
                                           headers=headers, json=verify_data)
                    if response.status_code == 200:
                        verify_result = response.json()
                        self.log_test("Verify UUID", True, "UUID verification successful", verify_result.get('data'))
                    else:
                        self.log_test("Verify UUID", False, f"Status: {response.status_code}")
                else:
                    self.log_test("Generate UUID", False, f"Generation failed: {data}")
            else:
                self.log_test("Generate UUID", False, f"Status: {response.status_code}")
            
            # Test get user UUIDs
            response = requests.get(f"{self.base_url}/blockchain/user-uuids/", headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Get User UUIDs", True, f"Retrieved {len(data.get('data', []))} UUIDs", data.get('data'))
            else:
                self.log_test("Get User UUIDs", False, f"Status: {response.status_code}")
            
            # Test get latest UUID
            response = requests.get(f"{self.base_url}/blockchain/latest-uuid/", headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Get Latest UUID", True, "Retrieved latest UUID", data.get('data'))
            else:
                self.log_test("Get Latest UUID", False, f"Status: {response.status_code}")
                
        except Exception as e:
            self.log_test("Authenticated API Calls", False, f"Error: {str(e)}")

    def test_5_flutter_integration_simulation(self):
        """Test 5: Flutter Integration Simulation"""
        print("=" * 60)
        print("TEST 5: Flutter Integration Simulation")
        print("=" * 60)
        
        if not self.auth_token:
            self.log_test("Flutter Integration", False, "No authentication token available")
            return
        
        headers = {
            'Authorization': f'Token {self.auth_token}',
            'Content-Type': 'application/json'
        }
        
        try:
            # Simulate Flutter app flow
            print("Simulating Flutter app user journey...")
            
            # 1. User opens app and gets latest UUID
            response = requests.get(f"{self.base_url}/blockchain/latest-uuid/", headers=headers)
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    uuid_value = data['data']['uuid_value']
                    self.log_test("Flutter: Get Latest UUID", True, f"App loaded with UUID: {uuid_value}")
                    
                    # 2. User generates new UUID
                    response = requests.post(f"{self.base_url}/blockchain/generate-uuid/", headers=headers)
                    if response.status_code == 201:
                        new_data = response.json()
                        if new_data.get('success'):
                            new_uuid = new_data['data']['uuid_value']
                            self.log_test("Flutter: Generate New UUID", True, f"Generated new UUID: {new_uuid}")
                            
                            # 3. User verifies the new UUID
                            verify_data = {'uuid_value': new_uuid}
                            response = requests.post(f"{self.base_url}/blockchain/verify-uuid/", 
                                                   headers=headers, json=verify_data)
                            if response.status_code == 200:
                                verify_result = response.json()
                                self.log_test("Flutter: Verify UUID", True, "UUID verification successful")
                                
                                # 4. User gets all their UUIDs
                                response = requests.get(f"{self.base_url}/blockchain/user-uuids/", headers=headers)
                                if response.status_code == 200:
                                    all_uuids = response.json()
                                    self.log_test("Flutter: Get All UUIDs", True, 
                                                f"Retrieved {len(all_uuids.get('data', []))} UUIDs")
                                else:
                                    self.log_test("Flutter: Get All UUIDs", False, f"Status: {response.status_code}")
                            else:
                                self.log_test("Flutter: Verify UUID", False, f"Status: {response.status_code}")
                        else:
                            self.log_test("Flutter: Generate New UUID", False, f"Generation failed: {new_data}")
                    else:
                        self.log_test("Flutter: Generate New UUID", False, f"Status: {response.status_code}")
                else:
                    self.log_test("Flutter: Get Latest UUID", False, f"Failed: {data}")
            else:
                self.log_test("Flutter: Get Latest UUID", False, f"Status: {response.status_code}")
                
        except Exception as e:
            self.log_test("Flutter Integration", False, f"Error: {str(e)}")

    def test_6_database_integrity(self):
        """Test 6: Database Integrity and Blockchain Structure"""
        print("=" * 60)
        print("TEST 6: Database Integrity and Blockchain Structure")
        print("=" * 60)
        
        try:
            # Check blockchain structure
            blockchain = Blockchain.objects.first()
            if blockchain:
                blocks = Block.objects.filter(blockchain=blockchain).order_by('index')
                self.log_test("Blockchain Structure", True, f"Found {blocks.count()} blocks in blockchain")
                
                # Verify block chaining
                previous_hash = None
                for i, block in enumerate(blocks):
                    if i == 0:
                        # First block should have empty previous_hash
                        if block.previous_hash == "":
                            self.log_test(f"Block {i} Previous Hash", True, "First block has empty previous hash")
                        else:
                            self.log_test(f"Block {i} Previous Hash", False, f"Expected empty, got: {block.previous_hash}")
                    else:
                        # Subsequent blocks should have previous block's hash
                        if block.previous_hash == previous_hash:
                            self.log_test(f"Block {i} Previous Hash", True, "Block correctly chained")
                        else:
                            self.log_test(f"Block {i} Previous Hash", False, 
                                        f"Expected: {previous_hash}, Got: {block.previous_hash}")
                    
                    # Verify block hash
                    calculated_hash = block.calculate_hash()
                    if block.hash == calculated_hash:
                        self.log_test(f"Block {i} Hash Integrity", True, "Block hash is valid")
                    else:
                        self.log_test(f"Block {i} Hash Integrity", False, 
                                    f"Hash mismatch: {block.hash} vs {calculated_hash}")
                    
                    previous_hash = block.hash
                
                # Check UUID distribution
                total_uuids = UserUUID.objects.count()
                active_uuids = UserUUID.objects.filter(is_active=True).count()
                self.log_test("UUID Statistics", True, 
                            f"Total UUIDs: {total_uuids}, Active: {active_uuids}")
                
                # Check user-UUID relationships
                user_uuid_count = UserUUID.objects.filter(user=self.test_user).count()
                self.log_test("User-UUID Relationship", True, 
                            f"Test user has {user_uuid_count} UUIDs")
                
            else:
                self.log_test("Blockchain Structure", False, "No blockchain found in database")
                
        except Exception as e:
            self.log_test("Database Integrity", False, f"Error: {str(e)}")

    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting Comprehensive Blockchain UUID System Test")
        print("=" * 80)
        print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 80)
        
        self.test_1_django_models()
        self.test_2_api_endpoints()
        self.test_3_authentication_flow()
        self.test_4_authenticated_api_calls()
        self.test_5_flutter_integration_simulation()
        self.test_6_database_integrity()
        
        # Summary
        print("=" * 80)
        print("TEST SUMMARY")
        print("=" * 80)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result['success'])
        failed_tests = total_tests - passed_tests
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests} ✅")
        print(f"Failed: {failed_tests} ❌")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        if failed_tests > 0:
            print("\nFailed Tests:")
            for result in self.test_results:
                if not result['success']:
                    print(f"  ❌ {result['test']}: {result['message']}")
        
        print(f"\nTest completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        return passed_tests == total_tests

def main():
    """Main test function"""
    tester = BlockchainTester()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎉 All tests passed! The blockchain system is working correctly.")
        return 0
    else:
        print("\n⚠️  Some tests failed. Please check the output above for details.")
        return 1

if __name__ == "__main__":
    exit(main())
