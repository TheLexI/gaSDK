import 'package:flutter/services.dart';
import 'package:ga_sdk/ga_sdk.dart';

class MapLauncherClass {
  static const NAMESPACE = "NavigatorMethods";

  static const MethodChannel _channel = const MethodChannel('${GaSdk.NAMESPACE}/$NAMESPACE');

}