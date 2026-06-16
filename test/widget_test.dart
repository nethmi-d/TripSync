import 'package:flutter_test/flutter_test.dart';
import 'package:tripsyc/core/utils/validators.dart';

void main() {
  test('validates required signup fields', () {
    expect(
      Validators.requiredName('', fieldName: 'Full name'),
      'Full name is required.',
    );
    expect(Validators.email('traveler@example.com'), isNull);
    expect(Validators.password('secret123'), isNull);
    expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
  });
}
