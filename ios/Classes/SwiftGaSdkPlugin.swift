import Flutter
import UIKit
import MapKit
import CoreBluetooth
import ExternalAccessory
import CryptoKit
import CommonCrypto

private enum MapType: String {
  case apple
  case google
  case amap
  case baidu
  case waze
  case yandexNavi
  case yandexMaps
  case citymapper
  case mapswithme
  case osmand
  case doubleGis

  func type() -> String {
    return self.rawValue
  }
}

private class Device : Codable {
    let name: String;
    let address: String;
    let type: Int;
    let bondState: Int;
    let deviceClass: Int;
    let majorDeviceClass: Int;

    init(name: String, address: String, type: Int, deviceClass: Int, majorDeviceClass: Int) {
        self.name = name;
        self.type = type;
        self.address = address;
        self.bondState = 1;
        self.deviceClass = deviceClass;
        self.majorDeviceClass = majorDeviceClass;
    }
}

private class Map {
  let mapName: String;
  let mapType: MapType;
  let urlPrefix: String?;

    init(mapName: String, mapType: MapType, urlPrefix: String?) {
        self.mapName = mapName
        self.mapType = mapType
        self.urlPrefix = urlPrefix
    }

    func toMap() -> [String:String] {
    return [
      "mapName": mapName,
      "mapType": mapType.type(),
    ]
  }
}

private let maps: [Map] = [
    Map(mapName: "Apple Maps", mapType: MapType.apple, urlPrefix: ""),
    Map(mapName: "Google Maps", mapType: MapType.google, urlPrefix: "comgooglemaps://"),
    Map(mapName: "Amap", mapType: MapType.amap, urlPrefix: "iosamap://"),
    Map(mapName: "Baidu Maps", mapType: MapType.baidu, urlPrefix: "baidumap://"),
    Map(mapName: "Waze", mapType: MapType.waze, urlPrefix: "waze://"),
    Map(mapName: "Yandex Navigator", mapType: MapType.yandexNavi, urlPrefix: "yandexnavi://"),
    Map(mapName: "Yandex Maps", mapType: MapType.yandexMaps, urlPrefix: "yandexmaps://"),
    Map(mapName: "Citymapper", mapType: MapType.citymapper, urlPrefix: "citymapper://"),
    Map(mapName: "MAPS.ME", mapType: MapType.mapswithme, urlPrefix: "mapswithme://"),
    Map(mapName: "OsmAnd", mapType: MapType.osmand, urlPrefix: "osmandmaps://"),
    Map(mapName: "2GIS", mapType: MapType.doubleGis, urlPrefix: "dgis://")
]

private func getMapByRawMapType(type: String) -> Map {
    return maps.first(where: { $0.mapType.type() == type })!
}

private func getMapItem(latitude: String, longitude: String) -> MKMapItem {
    let coordinate = CLLocationCoordinate2DMake(Double(latitude)!, Double(longitude)!)
    let destinationPlacemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)

    return MKMapItem(placemark: destinationPlacemark);
}

private func showMarker(mapType: MapType, url: String, title: String, latitude: String, longitude: String) {
    switch mapType {
    case MapType.apple:
        let coordinate = CLLocationCoordinate2DMake(Double(latitude)!, Double(longitude)!)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.02))
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)]
        mapItem.name = title
        mapItem.openInMaps(launchOptions: options)
    default:
        UIApplication.shared.openURL(URL(string:url)!)

    }
}

private func getDirectionsMode(directionsMode: String?) -> String {
    switch directionsMode {
    case "driving":
        return MKLaunchOptionsDirectionsModeDriving
    case "walking":
        return MKLaunchOptionsDirectionsModeWalking
    case "transit":
        if #available(iOS 9.0, *) {
            return MKLaunchOptionsDirectionsModeTransit
        } else {
            return MKLaunchOptionsDirectionsModeDriving
        }
    default:
        if #available(iOS 10.0, *) {
            return MKLaunchOptionsDirectionsModeDefault
        } else {
            return MKLaunchOptionsDirectionsModeDriving
        }
    }
}

private func showDirections(mapType: MapType, url: String, destinationTitle: String?, destinationLatitude: String, destinationLongitude: String, originTitle: String?, originLatitude: String?, originLongitude: String?, directionsMode: String?) {
    switch mapType {
    case MapType.apple:

        let destinationMapItem = getMapItem(latitude: destinationLatitude, longitude: destinationLongitude);
        destinationMapItem.name = destinationTitle ?? "Destination"

        let hasOrigin = originLatitude != nil && originLatitude != nil
        var originMapItem: MKMapItem {
            if !hasOrigin {
                return MKMapItem.forCurrentLocation()
            }
            let origin = getMapItem(latitude: originLatitude!, longitude: originLongitude!)
            origin.name = originTitle ?? "Origin"
            return origin
        }


        MKMapItem.openMaps(
            with: [originMapItem, destinationMapItem],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: getDirectionsMode(directionsMode: directionsMode)]
        )
    default:
        UIApplication.shared.openURL(URL(string:url)!)

    }
}

private func isMapAvailable(map: Map) -> Bool {
    if map.mapType == MapType.apple {
        return true
    }
    return UIApplication.shared.canOpenURL(URL(string:map.urlPrefix!)!)
}

func loadCert() -> SecKey {
  let certificateData = NSData(
    contentsOf:Bundle.main.url(forResource: "yanavigator", withExtension: "der")!
  )

  let options: [String: Any] =
    [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
    kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
    kSecAttrKeySizeInBits as String: 512]

  let key = SecKeyCreateWithData(certificateData!,
    options as CFDictionary,
    nil)

  return key!
}

func signString(string: String, key: SecKey) -> String {

    let messageData = string.data(using:String.Encoding.utf8)!
    var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
    
     _ = hash.withUnsafeMutableBytes {digestBytes in
      messageData.withUnsafeBytes {messageBytes in
        CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
      }
    }

    let signature = SecKeyCreateSignature(key,
      SecKeyAlgorithm.rsaSignatureDigestPKCS1v15SHA256,
      hash as CFData,
      nil) as Data?

    return (signature?.base64EncodedString())!
}

func getPlatformVersion() -> String {
    return "";
}

internal class IboxProFlutterDelegate: NSObject, PaymentControllerDelegate {
  private let methodChannel: FlutterMethodChannel
  private let paymentController: PaymentController
  
  public var foundDevices : String

    public required init(methodChannel: FlutterMethodChannel, paymentController: PaymentController, foundDevices :String) {
    self.methodChannel = methodChannel
    self.foundDevices = ""
    self.paymentController = paymentController
  }

  public func disable() {
    self.paymentController.disable()
  }

  public func paymentControllerStartTransaction(_ transactionId: String!) {
    let arguments: [String:String] = [
      "id": transactionId
    ]

    methodChannel.invokeMethod("onPaymentStart", arguments: arguments)
  }

  public func paymentControllerDone(_ transactionData: TransactionData!) {
    let arguments: [String:Any] = [
      "requiredSignature": transactionData.requiredSignature,
      "transaction": SwiftGaSdkPlugin.formatTransactionItem(transactionData.transaction!)
    ]

    disable()

    methodChannel.invokeMethod("onPaymentComplete", arguments: arguments)
  }

  public func paymentControllerError(_ error: PaymentControllerErrorType, message: String?) {
    let arguments: [String:Any] = [
      "nativeErrorType": Int(error.rawValue),
      "errorMessage": message != nil ? message! : ""
    ]

    disable()

    methodChannel.invokeMethod("onPaymentError", arguments: arguments)
  }

  public func paymentControllerReaderEvent(_ event: PaymentControllerReaderEventType) {
    let arguments: [String:Int] = [
      "nativeReaderEventType": Int(event.rawValue)
    ]

    methodChannel.invokeMethod("onReaderEvent", arguments: arguments)
  }

  public func paymentControllerRequestBTDevice(_ devices: [Any]!) {
    if(SwiftGaSdkPlugin.deviceName.isEmpty){
        let foundDevices = devices as! [BTDevice]
        if(foundDevices.count > 0) {
            var data : [Device] = []
            for d in foundDevices {
                data.append(Device(name: d.name(), address: d.uuid(), type: 0, deviceClass: 0, majorDeviceClass: 0))
            }
            
            do {
                let jsonEncoder = JSONEncoder()
                let obj = try jsonEncoder.encode(data)
                self.foundDevices = String(data: obj, encoding: .utf8)!
            } catch {
            }
        }
    }else{
        let device = (devices as! [BTDevice]).first(where: { $0.name() == SwiftGaSdkPlugin.deviceName })

        if (device != nil) {
          self.paymentController.setBTDevice(device)
          self.paymentController.save(device)
          self.paymentController.stopSearch4BTReaders()

          methodChannel.invokeMethod("onReaderSetBTDevice", arguments: nil)
        }
    }
  }

  public func paymentControllerRequestCardApplication(_ applications: [Any]!) {}
  public func paymentControllerScheduleStepsStart() {}
  public func paymentControllerScheduleStepsCreated(_ scheduleSteps: [Any]!) {}
}

internal class BlueStatusDelegate: NSObject, FlutterStreamHandler, CBCentralManagerDelegate {
    
    var manager: CBCentralManager!
    var bltStatus: Bool
    
    override init() {
        self.bltStatus = false
        super.init()
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
          print("power is off")
          bltStatus = false
      } else {
         print("power is on")
         bltStatus = true
      }
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        
        let state: Int = self.bltStatus ? 12 : 10
        eventSink(state)
        return nil
    }
}

public class SwiftGaSdkPlugin: NSObject, FlutterPlugin  {

    private static let apiError = -1
    private let methodChannelBlue: FlutterMethodChannel
    private let methodChannelCards: FlutterMethodChannel
    private let methodChannelPayment: FlutterMethodChannel
    private let paymentControllerDelegate: IboxProFlutterDelegate
    private let paymentController: PaymentController
    public static var deviceName = ""
    
    public required init(_ channelBlue: FlutterMethodChannel,channelCards: FlutterMethodChannel,channelPayment: FlutterMethodChannel) {
        self.methodChannelBlue = channelBlue
        self.methodChannelCards = channelCards
        self.methodChannelPayment = channelPayment
        self.paymentController = PaymentController.instance()!
        self.paymentControllerDelegate = IboxProFlutterDelegate(
          methodChannel: channelPayment,
          paymentController: self.paymentController,
          foundDevices: ""
        )
        
        self.paymentController.setDelegate(paymentControllerDelegate)
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channelBlue = FlutterMethodChannel(name: "ga_sdk/method", binaryMessenger: registrar.messenger())
        let channelBlue = FlutterMethodChannel(name: "ga_sdk/method", binaryMessenger: registrar.messenger())
        let channelBlue = FlutterMethodChannel(name: "ga_sdk/method", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "ga_sdk/state_stream", binaryMessenger:registrar.messenger())
        eventChannel.setStreamHandler(BlueStatusDelegate())
        let instance = SwiftGaSdkPlugin(channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func adjustPayment(_ call: FlutterMethodCall) {
       let params = call.arguments as! [String: Any]

       DispatchQueue.global(qos: .background).async {
         let res = self.paymentController.adjust(
           withTrId: (params["id"] as! String),
           signature: (params["signature"] as! FlutterStandardTypedData).data,
           receiptEmail: params["receiptEmail"] as? String,
           receiptPhone: params["receiptPhone"] as? String
         )
        
         let arguments = self.checkResult(res)
         self.methodChannel.invokeMethod("onPaymentAdjust", arguments: arguments)
       }
    }

    public func adjustReversePayment(_ call: FlutterMethodCall) {
       let params = call.arguments as! [String: Any]

       DispatchQueue.global(qos: .background).async {
         let res = self.paymentController.reverseAdjust(
           withTrId: (params["id"] as! String),
           signature: (params["signature"] as! FlutterStandardTypedData).data,
           receiptEmail: params["receiptEmail"] as? String,
           receiptPhone: params["receiptPhone"] as? String
         )
         let arguments = self.checkResult(res)

         self.methodChannel.invokeMethod("onReversePaymentAdjust", arguments: arguments)
       }
    }

    public func cancel() {
       self.paymentController.disable()
    }

    public func info(_ call: FlutterMethodCall) {
       let params = call.arguments as! [String: Any]

       DispatchQueue.global(qos: .background).async {
         let res = self.paymentController.history(withTransactionID: (params["id"] as! String))
         var arguments = self.checkResult(res)

         if (arguments["errorCode"] as! Int == 0 && !res!.transactions()!.isEmpty) {
           let transactionItem = res!.transactions().first as! TransactionItem
           let formattedData = SwiftGaSdkPlugin.formatTransactionItem(transactionItem)

           arguments["transaction"] = formattedData
         }

         self.methodChannel.invokeMethod("onInfo", arguments: arguments)
       }
    }
    
    public func pay(_ call: FlutterMethodCall) {
        let params = call.arguments as! [String: Any]
        DispatchQueue.global(qos: .background).async {
            self.paymentController.setEmail((params["login"] as! String), password: (params["password"] as! String))
            self.paymentController.authentication()
            
            SwiftGaSdkPlugin.deviceName = params["device"] as! String
            
            let readerType = PaymentControllerReaderType_P17
            self.paymentController.search4BTReaders(with: readerType)
            self.paymentController.setReaderType(readerType)
            let amount = (params["amount"] as! NSNumber).doubleValue
            let description = params["description"] as! String
            let email = params["receiptEmail"] as? String
            let phone = params["receiptPhone"] as? String
            let singleStepAuth = params["singleStepAuth"] as! Bool
            
            let ctx = PaymentContext.init()
           
            let inputType = TransactionInputType(
             rawValue: TransactionInputType.RawValue(params["inputType"] as! Int)
            )
            ctx.inputType = inputType
            ctx.currency = CurrencyType_RUB
            ctx.amount = amount
            ctx.description = description
            ctx.receiptMail = email
            ctx.receiptPhone = phone

            self.paymentController.setPaymentContext(ctx)
            self.paymentController.enable()
            self.paymentController.setSingleStepAuthentication(singleStepAuth)
        }
    }

    public func login(_ call: FlutterMethodCall) {
       let params = call.arguments as! [String: Any]

       DispatchQueue.global(qos: .background).async {
         self.paymentController.setEmail((params["email"] as! String), password: (params["password"] as! String))
         let res = self.paymentController.authentication()
         let arguments = self.checkResult(res)

         self.methodChannel.invokeMethod("onLogin", arguments: arguments)
       }
    }

    public func startPayment(_ call: FlutterMethodCall) {
       let params = call.arguments as! [String: Any]
       let inputType = TransactionInputType(
         rawValue: TransactionInputType.RawValue(params["inputType"] as! Int)
       )
       let amount = (params["amount"] as! NSNumber).doubleValue
       let description = params["description"] as! String
       let email = params["receiptEmail"] as? String
       let phone = params["receiptPhone"] as? String
       let singleStepAuth = params["singleStepAuth"] as! Bool
       let ctx = PaymentContext.init()

       ctx.inputType = inputType
       ctx.currency = CurrencyType_RUB
       ctx.amount = amount
       ctx.description = description
       ctx.receiptMail = email
       ctx.receiptPhone = phone

       paymentController.setPaymentContext(ctx)
       paymentController.enable()
       paymentController.setSingleStepAuthentication(singleStepAuth)
    }

    public func startReversePayment(_ call: FlutterMethodCall) {
       let params = call.arguments as! [String: Any]
       let amount = (params["amount"] as! NSNumber).doubleValue
       let email = params["receiptEmail"] as? String
       let phone = params["receiptPhone"] as? String
       let singleStepAuth = params["singleStepAuth"] as! Bool

       DispatchQueue.global(qos: .background).async {
         let res = self.paymentController.history(withTransactionID: (params["id"] as! String))
         let arguments = self.checkResult(res)

         if (arguments["errorCode"] as! Int == 0 && !res!.transactions()!.isEmpty) {
           let transactionItem = (res!.transactions().first as! TransactionItem)

           if (
             transactionItem.reverseMode() == TransactionReverseMode_NONE ||
             transactionItem.reverseMode() == TransactionReverseMode_AUTO_REVERSE
           ) {
             self.methodChannel.invokeMethod("onReverseReject", arguments: arguments)
             return
           }

           let ctx = ReversePaymentContext.init()
           ctx.currency = CurrencyType_RUB
           ctx.amountReverse = amount
           ctx.receiptMail = email
           ctx.receiptPhone = phone
           ctx.transaction = transactionItem

           self.paymentController.setPaymentContext(ctx)
           self.paymentController.enable()
           self.paymentController.setSingleStepAuthentication(singleStepAuth)
         } else {
           self.methodChannel.invokeMethod("onHistoryError", arguments: arguments)
         }
       }
        
    }

    public func startSearchBTDevice(_ call: FlutterMethodCall) {
       let readerType = PaymentControllerReaderType_P17
       self.paymentController.search4BTReaders(with: readerType)
       self.paymentController.setReaderType(readerType)
    }

    public func stopSearchBTDevice() {
       self.paymentController.stopSearch4BTReaders()
    }
    
    private func checkResult(_ res: APIResult?) -> [String:Any?] {
        var arguments = [
          "errorMessage": nil
        ] as [String:Any?]

        if (res != nil && res!.valid()) {
          arguments["errorCode"] = Int(res!.errorCode())
        } else {
          arguments["errorCode"] = SwiftGaSdkPlugin.apiError
        }

        return arguments
    }

    public static func formatTransactionItem(_ transactionItem: TransactionItem) -> [String:Any] {
        let card = transactionItem.card()

        return [
          "id": transactionItem.id(),
          "rrn": transactionItem.rrn(),
          "emvData": transactionItem.emvData(),
          "date": transactionItem.date(),
          "currencyID": transactionItem.currencyID(),
          "descriptionOfTransaction": transactionItem.descriptionOfTransaction(),
          "stateDisplay": transactionItem.stateDisplay(),
          "invoice": transactionItem.invoice(),
          "approvalCode": transactionItem.approvalCode(),
          "operation": transactionItem.operation(),
          "cardholderName": transactionItem.cardholderName(),
          "terminalName": transactionItem.terminalName(),
          "amount": transactionItem.amount(),
          "amountNetto": transactionItem.amountNetto(),
          "feeTotal": transactionItem.feeTotal(),
          "latitude": transactionItem.latitude(),
          "longitude": transactionItem.longitude(),
          "state": transactionItem.state(),
          "subState": transactionItem.subState(),
          "inputType": Int(transactionItem.inputType().rawValue),
          "displayMode": Int(transactionItem.displayMode().rawValue),
          "acquirerID": transactionItem.acquirerID(),
          "card": [
            "iin": card?.iin(),
            "expiration": card?.expiration(),
            "panMasked": card?.panMasked(),
            "panEnding": card?.panEnding(),
            "binID": card?.binID()
          ]
        ]
        
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "adjustPayment":
          adjustPayment(call)
          return result(nil)
        case "adjustReversePayment":
          adjustReversePayment(call)
          return result(nil)
        case "pay":
            pay(call)
          return result(nil)
        case "cancel":
          cancel()
          return result(nil)
        case "info":
          info(call)
          return result(nil)
        case "login":
          login(call)
          return result(nil)
        case "startPayment":
          startPayment(call)
          return result(nil)
        case "startReversePayment":
          startReversePayment(call)
          return result(nil)
        case "startSearchBTDevice":
          startSearchBTDevice(call)
          return result(nil)
        case "stopSearchBTDevice":
          stopSearchBTDevice()
          return result(nil)
        case "getBtBoundedDevices":
            print("Search BT Devices started")
            
            let readerType = PaymentControllerReaderType_P17
            self.paymentController.search4BTReaders(with: readerType)
            
            let seconds = 3.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                
                print("Search BT Devices finished")
                
                if(!self.paymentControllerDelegate.foundDevices.isEmpty){
                    print("Device found " + self.paymentControllerDelegate.foundDevices)
                    result(self.paymentControllerDelegate.foundDevices)
                }else{
                    print("Device not found sry man")
                    result("[]")
                }
                self.paymentController.stopSearch4BTReaders()
            }
           
            return;
        case "getInstalledMaps":
            result(maps.filter({ isMapAvailable(map: $0) }).map({ $0.toMap() }))

        case "showMarker":
            let args = call.arguments as! NSDictionary
            let mapType = args["mapType"] as! String
            let url = args["url"] as! String
            let title = args["title"] as! String
            let latitude = args["latitude"] as! String
            let longitude = args["longitude"] as! String

            let map = getMapByRawMapType(type: mapType)
            if (!isMapAvailable(map: map)) {
            result(FlutterError(code: "MAP_NOT_AVAILABLE", message: "Map is not installed on a device", details: nil))
            return;
            }

            showMarker(mapType: MapType(rawValue: mapType)!, url: url, title: title, latitude: latitude, longitude: longitude)

        case "showDirections":
            let args = call.arguments as! NSDictionary
            let mapType = args["mapType"] as! String
            let url = args["url"] as! String

            let destinationTitle = args["destinationTitle"] as? String
            let destinationLatitude = args["destinationLatitude"] as! String
            let destinationLongitude = args["destinationLongitude"] as! String

            let originTitle = args["originTitle"] as? String
            let originLatitude = args["originLatitude"] as? String
            let originLongitude = args["originLongitude"] as? String

            let directionsMode = args["directionsMode"] as? String

            let map = getMapByRawMapType(type: mapType)
            if (!isMapAvailable(map: map)) {
            result(FlutterError(code: "MAP_NOT_AVAILABLE", message: "Map is not installed on a device", details: nil))
                return;
            }

            showDirections(
                mapType: MapType(rawValue: mapType)!,
                url: url,
                destinationTitle: destinationTitle,
                destinationLatitude: destinationLatitude,
                destinationLongitude: destinationLongitude,
                originTitle: originTitle,
                originLatitude: originLatitude,
                originLongitude: originLongitude,
                directionsMode: directionsMode
            )

        case "isMapAvailable":
            let args = call.arguments as! NSDictionary
            let mapType = args["mapType"] as! String
            let map = getMapByRawMapType(type: mapType)
            result(isMapAvailable(map: map))

        case "getYandexNaviSignature":
            let args = call.arguments as! NSDictionary
            let url = args["url"] as! String
            let signature = signString(string: url, key: loadCert())
            result(signature)
            return;

        default:
          print("method does not exist")
    }
  }
}
