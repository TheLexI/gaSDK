import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ga_sdk/ga_sdk.dart';
import 'package:ga_sdk/map_launcher/directions_url.dart';
import 'package:ga_sdk/map_launcher/marker_url.dart';
import 'package:ga_sdk/map_launcher/models.dart';
import 'package:ga_sdk/map_launcher/utils.dart';
import 'package:ga_sdk/map_launcher/yandex_url.dart';

class MapLauncherClass {
  final MethodChannel _channel = const MethodChannel('${GaSdk.NAMESPACE}/$NAMESPACE');

  static const NAMESPACE = "NavigatorMethods";
  MapLauncherClass();

  Future<List<AvailableMap>> get installedMaps async {
    final maps = await _channel.invokeMethod('getInstalledMaps');
    return List<AvailableMap>.from(
      maps.map((map) => AvailableMap.fromJson(map)),
    );
  }

  Future<dynamic> showMarker({
    @required MapType mapType,
    @required Coords coords,
    @required String title,
    String description,
    int zoom,
  }) async {
    final url = getMapMarkerUrl(
      mapType: mapType,
      coords: coords,
      title: title,
      description: description,
      zoom: zoom,
    );

    final Map<String, String> args = {
      'mapType': Utils.enumToString(mapType),
      'url': Uri.encodeFull(url),
      'title': title,
      'description': description,
      'latitude': coords.latitude.toString(),
      'longitude': coords.longitude.toString(),
    };
    return _channel.invokeMethod('showMarker', args);
  }

  Future<dynamic> showDirections(
      {@required MapType mapType,
      @required Coords destination,
      String destinationTitle,
      Coords origin,
      String originTitle,
      List<Coords> waypoints,
      DirectionsMode directionsMode = DirectionsMode.driving,
      String privateKey,
      String clientId}) async {
    String url;

    if (MapType.yandexNavi == mapType) {
      url = await getYaNavDirectionsUrl(
          mapType: mapType,
          destination: destination,
          destinationTitle: destinationTitle,
          origin: origin,
          originTitle: originTitle,
          waypoints: waypoints,
          directionsMode: directionsMode,
          client: clientId,
          privateKey: privateKey);
    } else {
      url = Uri.encodeFull(getMapDirectionsUrl(
        mapType: mapType,
        destination: destination,
        destinationTitle: destinationTitle,
        origin: origin,
        originTitle: originTitle,
        waypoints: waypoints,
        directionsMode: directionsMode,
      ));
    }
    final Map<String, String> args = {
      'mapType': Utils.enumToString(mapType),
      'url': url,
      'destinationTitle': destinationTitle,
      'destinationLatitude': destination.latitude.toString(),
      'destinationLongitude': destination.longitude.toString(),
      'destinationtitle': destinationTitle,
      'originLatitude': origin?.latitude?.toString(),
      'originLongitude': origin?.longitude?.toString(),
      'origintitle': originTitle,
      'directionsMode': Utils.enumToString(directionsMode),
    };
    return _channel.invokeMethod('showDirections', args);
  }

  Future<bool> isMapAvailable(MapType mapType) async {
    return _channel.invokeMethod(
      'isMapAvailable',
      {'mapType': Utils.enumToString(mapType)},
    );
  }
}
