import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/core/base/base.dart';
import 'package:meup/src/auth/data/datasources/apis/apis.dart';
import 'package:meup/src/auth/data/models/models.dart';
import 'package:meup/src/auth/data/repositories/repositories.dart';
import 'package:meup/src/auth/domain/repositories/repositories.dart';
import 'package:meup/src/auth/domain/usecases/usecases.dart';

void main() {
  late LoginUsecase loginUsecase;
  late IAuthRepository authRepository;
  late AuthApi authApi;
  late Dio dio;

  setUp(() {
    // Set up a real Dio instance with appropriate configuration
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://pdbvqixndzlhbwwizqvf.supabase.co', // Replace with your actual API base URL
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'apikey':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkYnZxaXhuZHpsaGJ3d2l6cXZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY2Njk1NzAsImV4cCI6MjA2MjI0NTU3MH0.0PxndSf1xpQ3GfbA4mP_3ebHZpJmW4R-VhbSBxfFQCs',
        },
      ),
    );

    // Add logging interceptor for better debugging during tests
    dio.interceptors.add(LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));

    // Initialize the real AuthApi with the configured Dio
    authApi = AuthApi(dio);

    // Create the real repository instance
    authRepository = AuthRepository(authApi);

    // Initialize the use case with the real repository
    loginUsecase = LoginUsecase(authRepository);
  });

  group('LoginUsecase with real API', () {
    // Test data - you need real credentials that work with your API
    final Map<String, dynamic> validCredentials = {
      'email': 'kjbhvgc@firain.com', // Use real test credentials
      'password': '123456789', // Use real test password
    };

    // Test with valid credentials - this will make a real API call
    test('should return Auth model when login with valid credentials', () async {
      // Act - This will call the real API
      final result = await loginUsecase(validCredentials).run();

      // Assert
      result.fold(
        (failure) {
          // This will run if the API call fails
          fail('Login should succeed but got failure: $failure');
        },
        (auth) {
          // This will run if the API call succeeds
          debugPrint('auth: ${auth.toJson()}');
          expect(auth, isA<Auth>());
          expect(auth.accessToken, isNotEmpty);
          expect(auth.user, isNotEmpty);
          // Add more specific assertions based on your API response
        },
      );
    });

    // Test with invalid credentials - should return a server failure
    test('should return ServerFailure when login with invalid credentials', () async {
      // Invalid credentials
      final Map<String, dynamic> invalidCredentials = {'email': 'wrong@example.com', 'password': 'wrongpassword'};

      // Act - This will call the real API
      final result = await loginUsecase(invalidCredentials).run();

      // Assert
      expect(result.isLeft(), isTrue); // Should be a Left (failure)

      result.fold(
        (failure) {
          // This will run if the API call fails (expected)
          expect(failure, isA<AppException>()); // Check it's a failure type
        },
        (auth) {
          // This should not run
          fail('Expected failure but got success with auth: $auth');
        },
      );
    });
  }, skip: false); // Set to true if you want to skip these tests during regular test runs
}
