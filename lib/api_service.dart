import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      // IMPORTANT: Replace with your computer's IP address.
      // 'localhost' or '127.0.0.1' will NOT work from the Android emulator/iOS simulator.
      baseUrl: 'http://127.0.0.1:8000/', // Example: 'http://192.168.1.10:8000/'
    ),
  );

  void setAuthToken(String token, {String? scheme}) {
    String headerScheme = scheme ?? _inferSchemeFromToken(token);
    _dio.options.headers['Authorization'] = '$headerScheme $token';
  }

  String _inferSchemeFromToken(String token) {
    // Heuristic: JWTs have 3 segments separated by dots
    final isLikelyJwt = token.split('.').length == 3;
    return isLikelyJwt ? 'Bearer' : 'Token';
  }

  Future<void> postIncident(Map<String, dynamic> incidentDetails) async {
    try {
      // Debug: log what we're sending
      print('Sending incident payload: $incidentDetails');
      final payload = {'details': incidentDetails};
      print('Final API payload: $payload');
      // Post to the incidents endpoint (requires auth)
      await _dio.post(
        'api/incidents/',
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    try {
      final response = await _dio.get('api/incidents/');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  // Blockchain UUID methods
  Future<Map<String, dynamic>> generateUUID() async {
    try {
      final response = await _dio.post('blockchain/generate-uuid/');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  Future<Map<String, dynamic>> getUserUUIDs() async {
    try {
      final response = await _dio.get('blockchain/user-uuids/');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  Future<Map<String, dynamic>> getLatestUUID() async {
    try {
      final response = await _dio.get('blockchain/latest-uuid/');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  Future<Map<String, dynamic>> verifyUUID(String uuidValue) async {
    try {
      final response = await _dio.post(
        'blockchain/verify-uuid/',
        data: {'uuid_value': uuidValue},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  Future<Map<String, dynamic>> getBlockchainInfo() async {
    try {
      final response = await _dio.get('blockchain/info/');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'auth/login/', // This is appended to the baseUrl
        data: {'username': username, 'password': password},
      );
      // Normalize common Django/DRF auth responses to a single shape
      final data = response.data;
      // If server already returns { success, token, user }
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data;
      }
      // DRF SimpleJWT style: { access, refresh, (optional) user }
      if (data is Map<String, dynamic> &&
          (data.containsKey('access') || data.containsKey('token'))) {
        final token = data['token'] ?? data['access'];
        final user = data['user'] ?? {'username': data['username'] ?? username};
        final scheme = data.containsKey('access') ? 'Bearer' : 'Token';
        return {
          'success': true,
          'token': token,
          'user': user,
          'authScheme': scheme,
        };
      }
      // DRF error style: { detail: "..." }
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return {'success': false, 'error': data['detail']};
      }
      // Fallback: try to infer token key
      if (data is Map<String, dynamic>) {
        final candidateToken = data['token'] ?? data['access'] ?? data['key'];
        if (candidateToken is String && candidateToken.isNotEmpty) {
          final scheme = candidateToken.split('.').length == 3
              ? 'Bearer'
              : 'Token';
          return {
            'success': true,
            'token': candidateToken,
            'user': {'username': data['username'] ?? username},
            'authScheme': scheme,
          };
        }
        return {
          'success': false,
          'error': data['error'] ?? 'Unexpected response from server',
        };
      }
      return {'success': false, 'error': 'Unexpected response from server'};
    } on DioException catch (e) {
      // Handle errors returned by the server (like 401 Unauthorized)
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': false,
            'error': data['detail'] ?? data['error'] ?? 'Login failed',
          };
        }
        return {'success': false, 'error': 'Login failed'};
      }
      // Handle other errors (network issues, etc.)
      throw Exception('Failed to connect to the server');
    }
  }

  Future<Map<String, dynamic>> verifyBlock(int blockId) async {
    try {
      final response = await _dio.post(
        'blockchain/verify-block/',
        data: {'block_id': blockId},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Backend error response: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Failed to connect to the server');
    }
  }
}
