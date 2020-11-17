import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ga_sdk/ga_sdk.dart';
import 'package:ga_sdk/dto/BluetoothDeviceDto.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

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
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<dynamic>(
            stream: GaSdk.state,
            initialData: '...',
            builder: (context, data) {
              return Text(data.data.toString());
            },
          ),
        ),
        body: FutureBuilder<List<BluetoothDeviceDto>>(
          future: GaSdk.getBoundedDevices(),
          initialData: [],
          builder: (context, AsyncSnapshot<List<BluetoothDeviceDto>> a) {
            return ListView(
            children: a.data.map((e) => ListTile(title: Text(e.name))).toList()
        );
          },
        )
      ),
    );
  }
}
