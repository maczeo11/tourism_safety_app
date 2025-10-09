# Blockchain UUID Generator API

This Django app provides a simple blockchain-based UUID generation system for users. Each UUID is stored in a blockchain structure, ensuring immutability and traceability.

## Features

- **Blockchain Storage**: UUIDs are stored in blocks with cryptographic hashing
- **User Linking**: Each UUID is linked to a specific user
- **Verification**: Verify UUID integrity and authenticity
- **Immutable Records**: Once created, UUIDs cannot be modified
- **Traceability**: Track when and where each UUID was generated

## API Endpoints

### Authentication Required
All endpoints require authentication using Django's Token Authentication.

### 1. Generate UUID
**POST** `/blockchain/generate-uuid/`

Generates a new UUID for the authenticated user.

**Response:**
```json
{
    "success": true,
    "message": "UUID generated successfully",
    "data": {
        "id": 1,
        "uuid_value": "550e8400-e29b-41d4-a716-446655440000",
        "user_username": "testuser",
        "user_email": "test@example.com",
        "block_index": 0,
        "block_hash": "abc123...",
        "created_at": "2025-09-24T23:08:19Z",
        "is_active": true
    }
}
```

### 2. Get User UUIDs
**GET** `/blockchain/user-uuids/`

Retrieves all UUIDs for the authenticated user.

**Response:**
```json
{
    "success": true,
    "message": "Found 2 UUIDs for user",
    "data": [
        {
            "id": 1,
            "uuid_value": "550e8400-e29b-41d4-a716-446655440000",
            "user_username": "testuser",
            "user_email": "test@example.com",
            "block_index": 0,
            "block_hash": "abc123...",
            "created_at": "2025-09-24T23:08:19Z",
            "is_active": true
        }
    ]
}
```

### 3. Get Latest UUID
**GET** `/blockchain/latest-uuid/`

Retrieves the most recent UUID for the authenticated user.

### 4. Verify UUID
**POST** `/blockchain/verify-uuid/`

Verifies if a UUID exists in the blockchain and is valid.

**Request Body:**
```json
{
    "uuid_value": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:**
```json
{
    "success": true,
    "message": "UUID is valid and found in blockchain",
    "data": {
        "valid": true,
        "user": "testuser",
        "created_at": "2025-09-24T23:08:19Z",
        "block_index": 0,
        "block_hash": "abc123..."
    }
}
```

### 5. Get Blockchain Info
**GET** `/blockchain/info/`

Retrieves general information about the blockchain.

**Response:**
```json
{
    "success": true,
    "message": "Blockchain information retrieved successfully",
    "data": {
        "blockchain_name": "TouristSafetyUUID",
        "total_blocks": 5,
        "latest_block_index": 4,
        "total_uuids": 10,
        "created_at": "2025-09-24T23:08:19Z"
    }
}
```

### 6. Get Blockchain Details
**GET** `/blockchain/details/`

Retrieves detailed blockchain information including all blocks and UUIDs.

## Usage Examples

### Using curl

1. **Generate UUID:**
```bash
curl -X POST http://localhost:8000/blockchain/generate-uuid/ \
  -H "Authorization: Token YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

2. **Verify UUID:**
```bash
curl -X POST http://localhost:8000/blockchain/verify-uuid/ \
  -H "Authorization: Token YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"uuid_value": "550e8400-e29b-41d4-a716-446655440000"}'
```

### Using Python requests

```python
import requests

# Set up authentication
headers = {
    'Authorization': 'Token YOUR_TOKEN_HERE',
    'Content-Type': 'application/json'
}

# Generate UUID
response = requests.post(
    'http://localhost:8000/blockchain/generate-uuid/',
    headers=headers
)
print(response.json())

# Verify UUID
verify_data = {
    'uuid_value': '550e8400-e29b-41d4-a716-446655440000'
}
response = requests.post(
    'http://localhost:8000/blockchain/verify-uuid/',
    headers=headers,
    json=verify_data
)
print(response.json())
```

## Database Models

### Blockchain
- `name`: Name of the blockchain
- `created_at`: Creation timestamp
- `is_active`: Whether the blockchain is active

### Block
- `blockchain`: Foreign key to Blockchain
- `index`: Block index in the chain
- `timestamp`: Block creation timestamp
- `previous_hash`: Hash of the previous block
- `hash`: Hash of this block
- `nonce`: Nonce for mining (currently 0)

### UserUUID
- `user`: Foreign key to User
- `uuid_value`: The actual UUID
- `block`: Foreign key to Block where this UUID is stored
- `created_at`: Creation timestamp
- `is_active`: Whether the UUID is active

## Security Features

1. **Cryptographic Hashing**: Each block is hashed using SHA-256
2. **Immutable Records**: Once created, records cannot be modified
3. **User Authentication**: All operations require valid user authentication
4. **Data Integrity**: Block hashes ensure data hasn't been tampered with

## Management Commands

### Initialize Blockchain
```bash
python manage.py init_blockchain
```

This command initializes the blockchain system and creates the main blockchain instance.
