import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    // IMPORTANT: Replace with your computer's IP address.
    // 'localhost' or '127.0.0.1' will NOT work from the Android emulator/iOS simulator.
    baseUrl: 'http://172.22.70.122:8000/auth/', // Example: 'http://192.168.1.10:8000/auth/'
  ));

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'login/', // This is appended to the baseUrl
        data: {
          'username': username,
          'password': password,
        },
      );
      // Based on your LoginView, a successful response contains user data
      return response.data;
    } on DioException catch (e) {
      // Handle errors returned by the server (like 401 Unauthorized)
      if (e.response != null) {
        return e.response!.data;
      }
      // Handle other errors (network issues, etc.)
      throw Exception('Failed to connect to the server');
    }
  }
}