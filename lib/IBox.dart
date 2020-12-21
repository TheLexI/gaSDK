import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ga_sdk/IBox/PaymentResult.dart';
import 'package:ga_sdk/IBox/types.dart';
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
      @required String extId,
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

    return await _channel.invokeMapMethod(
        'pay', PaymentRequest(amount: amount, description: description, device: device, extId: extId, login: login, password: password, email: email, phone: phone).toMap());
  }

  Future<void> reverse({
    @required String transactionID,
    @required String extID,
    @required String description,
    @required String device,
    @required String login,
    @required String password,
    @required double returnAmount,
    Function onError,
    Function onEvent,
    Function onSuccess
  }) async {

    _onError = onError;
    _onEvent = onEvent;
    _onSuccess = onSuccess;

    return await _channel.invokeMethod('reverse', {
      'transactionID': transactionID,
      'extID': extID,
      'device': device,
      'login': login,
      'password': password,
      'returnAmount': returnAmount
    });
  }

  Future<void> setBlue({@required String device, @required String login, @required String password}) async {
    await _channel.invokeMapMethod('setBlue', {"device": device, "login": login, "password": password});
  }

  Future<void> cancel() async {
    await _channel.invokeMapMethod('cancel');
  }

  String errorConvert(int paymentError) {
    if (Platform.isAndroid)
      return androidErrorConvert(paymentError);
    else if (Platform.isIOS) return iosErrorConvert(paymentError);
  }

  String androidErrorConvert(int paymentError) {
    String msg = ''; //paymentError.message ?? '';
    switch (paymentError) {
    //case AndroidErrorType.ServerError:
    //  return paymentError.message;
      case AndroidErrorType.ConnectionError:
        return "Сервер не отвечает";
      case AndroidErrorType.EMVCardNotSupported:
        return "Чиповые транзакции не разрешены";
      case AndroidErrorType.NFCNotAllowed:
        return "NFC транзакции не разрешены";
      case AndroidErrorType.EMVCancel:
        return "Транзакция отменена";
      case AndroidErrorType.EMVDeclined:
        return "Транзакция отклонена";
      case AndroidErrorType.EMVTerminated:
        return "Транзакция прервана";
      case AndroidErrorType.EMVCardError:
        return "Ошибка карты";
      case AndroidErrorType.EMVDeviceError:
        return "Ошибка ридера";
      case AndroidErrorType.EMVCardBlocked:
        return "Карта заблокирована";
      case AndroidErrorType.EMVCardNotSupported:
        return "Карта не поддерживается";
      case AndroidErrorType.NoSuchTransaction:
        return "Транзакция не найдена";
      case AndroidErrorType.TransactionNullOrEmpty:
        return "Ошибка создания транзакции";
      case AndroidErrorType.InvalidInputType:
        return "Неправильный тип ввода";
      case AndroidErrorType.InvalidAmount:
        return "Неправильная сумма";
      case AndroidErrorType.TtkFailed:
        return "Ошибка устройства ($msg)";
      case AndroidErrorType.ExtAppFailed:
        return "Ошибка приложения ($msg)";
      case AndroidErrorType.NFCLimitExceeded:
        return "Превышен лимит на бесконтактную карту";
      default:
        return "Ошибка EMV ($msg)";
    }
  }



  String eventConvert(int paymentEvent) {
    if (Platform.isAndroid) return androidEventConvert(paymentEvent);
    else if (Platform.isIOS) return IosEventConvert(paymentEvent);
  }

  String androidEventConvert(int paymentEvent) {
    switch (paymentEvent) {
      case AndroidReaderEventType.StartInit:
      case AndroidReaderEventType.Connected:
        return "Инициализация ридера";
      case AndroidReaderEventType.Disconnected:
        return "Ридер не подключен";
      case AndroidReaderEventType.InitSuccessfully:
        return "Подождите...";
      case AndroidReaderEventType.InitFailed:
        return "Ошибка инициализации";
      case AndroidReaderEventType.SwipeCard:
      case AndroidReaderEventType.EmvTransactionStarted:
      case AndroidReaderEventType.NfcTransactionStarted:
        return "Оплата";
      case AndroidReaderEventType.WaitingForCard:
        return "Предъявите карту";
      case AndroidReaderEventType.PaymentCanceled:
        return "Платеж отменен";
      case AndroidReaderEventType.EjectCardTimeout:
      case AndroidReaderEventType.EjectCard:
        return "Извлеките карту";
      case AndroidReaderEventType.BadSwipe:
        return "Ошибка при считывании магнитной полосы";
      case AndroidReaderEventType.LowBattery:
        return "Ридер почти разряжен";
      case AndroidReaderEventType.CardTimeout:
        return "Таймаут ожидания карты";
      case AndroidReaderEventType.PinTimeout:
        return "Таймаут ожидания ввода ПИН";
      default:
        return "";
    }
  }

  String IosEventConvert(int paymentEvent) {
    switch (paymentEvent) {
      case IosReaderEventType.Initialized:
        return "Предъявите карту";
      case IosReaderEventType.Connected:
        return "Инициализация ридера";
      case IosReaderEventType.Disconnected:
        return "Ридер не подключен";
      case IosReaderEventType.CardInserted:
        return "Карта прочитана";
      case IosReaderEventType.CardSwiped:
        return "Карта прочитана";
      case IosReaderEventType.EMVStarted:
        return "Подождите...";
      default:
        return "";
    }
  }

  String iosErrorConvert(int paymentError) {
    String msg = ''; // paymentError.message ?? '';
    switch (paymentError) {
      case IosErrorType.ReaderTimeout:
        return "Время ожидания карты истекло";
      case IosErrorType.ReaderDisconnected:
        return "Ридер отключен";
      case IosErrorType.EMVCardNotSupported:
        return "Чиповые транзакции не разрешены";
      case IosErrorType.EMVCancel:
        return "Транзакция отменена";
      case IosErrorType.EMVDeclined:
        return "Транзакция отклонена";
      case IosErrorType.EMVTerminated:
        return "Транзакция прервана";
      case IosErrorType.CardInsertedWrong:
      case IosErrorType.EMVCardError:
        return "Ошибка карты";
      case IosErrorType.EMVDeviceError:
        return "Ошибка ридера";
      case IosErrorType.EMVCardBlocked:
        return "Карта заблокирована";
      case IosErrorType.EMVCardNotSupported:
        return "Карта не поддерживается";
      case IosErrorType.ZeroAmount:
        return "Неправильная сумма";
      case IosErrorType.Submit:
      case IosErrorType.SubmitCash:
      case IosErrorType.SubmitPrepaid:
      case IosErrorType.SubmitCredit:
      case IosErrorType.SubmitOuterCard:
      case IosErrorType.SubmitLink:
      case IosErrorType.Swipe:
      case IosErrorType.OnlineProcess:
      case IosErrorType.ScheduleSteps:
        return "Произошла ошибка";
      case IosErrorType.Reverse:
      case IosErrorType.ReverseCash:
      case IosErrorType.ReversePrepaid:
      case IosErrorType.ReverseCredit:
      case IosErrorType.ReverseOuterCard:
      case IosErrorType.ReverseLink:
      case IosErrorType.ReverseCNP:
      case IosErrorType.ReverseCAuto:
        return "Ошибка проведения отмены платежа";
      default:
        return "Ошибка EMV ($msg)";
    }
  }
}
