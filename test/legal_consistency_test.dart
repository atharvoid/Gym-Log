import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/config/legal_links.dart';

void main() {
  test('Legal URLs are valid and secure HTTPS links', () {
    expect(kPrivacyPolicyUrl, startsWith('https://'));
    expect(kTermsOfServiceUrl, startsWith('https://'));
    expect(kPrivacyPolicyUrl, contains('privacy-policy'));
    expect(kTermsOfServiceUrl, contains('terms-of-service'));
  });
}
