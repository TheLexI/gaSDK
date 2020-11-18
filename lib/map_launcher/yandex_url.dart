import 'dart:developer';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:flutter/material.dart';
import 'package:ga_sdk/map_launcher/models.dart';
import 'package:ga_sdk/map_launcher/utils.dart';

Future<String> getYaNavDirectionsUrl(
    {@required MapType mapType,
    @required Coords destination,
    @required String destinationTitle,
    @required Coords origin,
    @required String originTitle,
    @required DirectionsMode directionsMode,
    @required List<Coords> waypoints,
    String client,
    String privateKey}) async {
  var url =  Utils.buildUrl(
    url: 'yandexnavi://build_route_on_map',
    queryParams: {
      'lat_to': '${destination.latitude}',
      'lon_to': '${destination.longitude}',
      'lat_from': Utils.nullOrValue(origin, '${origin?.latitude}'),
      'lon_from': Utils.nullOrValue(origin, '${origin?.longitude}'),
      'client': '$client'
    },
  );

  final privateKey_ = await parseKeyFromFile(privateKey);
  final signer = Signer(RSASigner(RSASignDigest.SHA256, privateKey: privateKey_));
  final signature =  Uri.encodeFull(signer.sign(url).base64);

  print(signature);

  url = Uri.encodeFull(url) +'&signature=${Uri.encodeComponent(signature)}';

  return url;
}
