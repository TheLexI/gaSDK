import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ga_sdk/IBox/PaymentResult.dart';
import 'package:meta/meta.dart';

import 'package:ga_sdk/IBox/PaymentRequest.dart';
import 'package:ga_sdk/ga_sdk.dart';

class IBox {
  final MethodChannel _channel = const MethodChannel('${GaSdk.NAMESPACE}/IBox/methods');

  Function _onError = (int code, String name, String message) {};
  Function _onEvent = (int code, String name, String message) {};
  Function _onSuccess = (PaymentResult result) {};

  IBox() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onError":
          _onError(call.arguments['code'], call.arguments['name'], call.arguments['data']);
          break;
        case "onEvent":
          _onEvent(call.arguments['code'], call.arguments['name'], call.arguments['data']);
          break;
        case "onSuccess":
          _onSuccess(PaymentResult.fromJson(jsonDecode(call.arguments.toString())));
          break;
      }
    });
  }

  Future<void> pay(
      {@required String device,
      @required String login,
      @required String password,
      @required double amount,
      @required String description,
      String email,
      String phone,
      Function onError,
      Function onEvent,
      Function onSuccess}) async {
    _onError = onError;
    _onEvent = onEvent;
    _onSuccess = onSuccess;

    await _channel.invokeMapMethod(
        'pay', PaymentRequest(amount: amount, description: description, device: device, login: login, password: password, email: email, phone: phone).toMap());
  }

  Future<void> cancel() async {
    await _channel.invokeMapMethod('cancel');
  }
}
