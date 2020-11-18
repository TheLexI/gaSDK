import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ga_sdk/dto/BluetoothDeviceDto.dart';
import 'package:ga_sdk/map_launcher.dart';

class GaSdk {
  static const NAMESPACE = "ga_sdk";
  static const MethodChannel _channel = const MethodChannel('${NAMESPACE}/method');
  static final _state_stream = const EventChannel('${NAMESPACE}/state_stream');

  static Stream<dynamic> get state => _state_stream.receiveBroadcastStream();

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static MapLauncherClass MapLauncher = MapLauncherClass();

  static Future<List<BluetoothDeviceDto>> getBoundedDevices() async {
    var data = jsonDecode(await _channel.invokeMethod('getBtBoundedDevices') ?? "[]") as List<dynamic>;
    return data
        .map((e) => BluetoothDeviceDto(
            name: e['name'], type: e['type'], address: e['address'], bondState: e['bondState'], deviceClass: e['deviceClass'], majorDeviceClass: e['majorDeviceClass']))
        .toList();
  }
}
