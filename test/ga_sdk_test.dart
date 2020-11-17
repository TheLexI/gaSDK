import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_sdk/ga_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('ga_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await GaSdk.platformVersion, '42');
  });
}
