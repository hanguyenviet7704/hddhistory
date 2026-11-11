import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('AppInterceptor refresh-token detection', () {
    test('detects concrete refresh token request path', () {
      expect(isRefreshTokenRequestPath('/api/v1/users/user-1/refresh-token'), isTrue);
    });

    test('does not detect regular user request path as refresh token', () {
      expect(isRefreshTokenRequestPath('/api/v1/users/me'), isFalse);
    });

    test('does not attach stale authorization header to refresh token request path', () {
      final shouldAttach = shouldAttachAuthorizationHeaderToPath(
        '/api/v1/users/user-1/refresh-token',
        hasAuthorizationHeader: false,
        hasAccessToken: true,
      );

      expect(shouldAttach, isFalse);
    });

    test('attaches authorization header to regular request path when access token exists', () {
      final shouldAttach = shouldAttachAuthorizationHeaderToPath(
        '/api/v1/categories',
        hasAuthorizationHeader: false,
        hasAccessToken: true,
      );

      expect(shouldAttach, isTrue);
    });
  });
}
