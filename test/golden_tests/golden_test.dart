@Skip("Goldens")

import 'package:flutter_test/flutter_test.dart';

import '../test_data.dart';
import 'test.dart';

void main() {
  // Test each HTML element
  group('golden tests', () {
    testData.forEach((key, value) {
      testHtml(key, value);
    });
  });
}
