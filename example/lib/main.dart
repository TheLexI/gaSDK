import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:ga_sdk/ga_sdk.dart';
import 'package:ga_sdk/dto/BluetoothDeviceDto.dart';
import 'package:ga_sdk/map_launcher/models.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String device = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await GaSdk.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      device = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: StreamBuilder<dynamic>(
      stream: GaSdk.bluetoothAdapterState,
      initialData: '...',
      builder: (context, data) => Scaffold(
          appBar: AppBar(title: Text(data.data.toString())),
          body: FutureBuilder<List<BluetoothDeviceDto>>(
              future: GaSdk.getBoundedDevices(),
              initialData: [],
              builder: (context, AsyncSnapshot<List<BluetoothDeviceDto>> a) => ListView(
                  children: a.data
                      .map((e) => ListTile(
                          title: Text(e.name),
                          selectedTileColor: Colors.green,
                          selected: device == e.address,
                          onTap: () {
                            setState(() {
                              device = e.address;
                            });
                          }))
                      .toList())),
          floatingActionButton: MaterialButton(
            child: Icon(Icons.map),
            onPressed: () async {
              /*await GaSdk.iBox.pay(

                  device,

              );*/
              /*GaSdk.MapLauncher.showDirections(
                  mapType: MapType.yandexNavi,
                  destination: Coords(55.358821, 86.162360),
                  clientId: '293',
                  privateKey: await rootBundle.loadString('assets/key/293_private_key.pem'));*/
            },
          )),
    ));
  }
}
