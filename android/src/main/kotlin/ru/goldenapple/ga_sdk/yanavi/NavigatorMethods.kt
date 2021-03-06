package ru.goldenapple.ga_sdk.yanavi

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Base64
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.EncodedKeySpec
import java.security.spec.PKCS8EncodedKeySpec

private enum class MapType { google, googleGo, amap, baidu, waze, yandexNavi, yandexMaps, citymapper, mapswithme, osmand, doubleGis }

private class MapModel(val mapType: MapType, val mapName: String, val packageName: String) {
    fun toMap(): Map<String, String> {
        return mapOf("mapType" to mapType.name, "mapName" to mapName, "packageName" to packageName)
    }
}

class NavigatorMethods(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAMESPACE: String = "NavigatorMethods"
    }

    private val maps = listOf(
            MapModel(MapType.google, "Google Maps", "com.google.android.apps.maps"),
            MapModel(MapType.googleGo, "Google Maps Go", "com.google.android.apps.mapslite"),
            MapModel(MapType.amap, "Amap", "com.autonavi.minimap"),
            MapModel(MapType.baidu, "Baidu Maps", "com.baidu.BaiduMap"),
            MapModel(MapType.waze, "Waze", "com.waze"),
            MapModel(MapType.yandexNavi, "Yandex Navigator", "ru.yandex.yandexnavi"),
            MapModel(MapType.yandexMaps, "Yandex Maps", "ru.yandex.yandexmaps"),
            MapModel(MapType.citymapper, "Citymapper", "com.citymapper.app.release"),
            MapModel(MapType.mapswithme, "MAPS.ME", "com.mapswithme.maps.pro"),
            MapModel(MapType.osmand, "OsmAnd", "net.osmand"),
            MapModel(MapType.doubleGis, "2GIS", "ru.dublgis.dgismobile")
    )

    private fun getInstalledMaps(): List<MapModel> {
        val installedApps = context?.packageManager?.getInstalledApplications(0) ?: return listOf()
        return maps.filter { map -> installedApps.any { app -> app.packageName == map.packageName } }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledMaps" -> {
                val installedMaps = getInstalledMaps()
                result.success(installedMaps.map { map -> map.toMap() })
            }
            "showMarker", "showDirections", "launchMap" -> {
                val args = call.arguments as Map<*, *>

                if (!isMapAvailable(args["mapType"] as String)) {
                    result.error("MAP_NOT_AVAILABLE", "Map is not installed on a device", null)
                    return
                }

                val mapType = MapType.valueOf(args["mapType"] as String)
                val url = args["url"] as String

                launchMap(mapType, url, result)
            }
            "isMapAvailable" -> {
                val args = call.arguments as Map<*, *>
                result.success(isMapAvailable(args["mapType"] as String))
            }
            "getYandexNaviSignature" -> {
                val args = call.arguments as Map<*, *>
                result.success(getYandexNaviSignature(args["url"] as String, args["privateKey"] as String))
            }
            else -> result.notImplemented()
        }
    }

    private fun getYandexNaviSignature(url: String, key: String): String {
        val trimmedKey: String = key.replace(Regex("""\s*[-].*\sPRIVATE KEY\s*[-]+\s*"""), "").replace("\\s", "");
        try {
            val result = Base64.decode(trimmedKey, Base64.DEFAULT).asList();
            val factory: KeyFactory = KeyFactory.getInstance("RSA");
            val keySpec: EncodedKeySpec = PKCS8EncodedKeySpec(result.toByteArray());
            val signature = Signature.getInstance("SHA256withRSA");
            signature.initSign(factory.generatePrivate(keySpec));
            signature.update(url.toByteArray());

            val encrypted = signature.sign();
            return Base64.encodeToString(encrypted, Base64.NO_WRAP);
        } catch (e: Exception) {
            throw SecurityException("Error calculating cipher data. SIC!");
        }
    }


    private fun isMapAvailable(type: String): Boolean {
        val installedMaps = getInstalledMaps()
        return installedMaps.any { map -> map.mapType.name == type }
    }

    private fun launchGoogleMaps(url: String) {
        context?.let {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(it.packageManager) != null) {
                it.startActivity(intent)
            }
        }
    }


    private fun launchMap(mapType: MapType, url: String, result: MethodChannel.Result) {
        context?.let {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val foundMap = maps.find { map -> map.mapType == mapType }
            if (foundMap != null) {
                intent.setPackage(foundMap.packageName)
            }
            it.startActivity(intent)
        }
        result.success(null)
    }

}