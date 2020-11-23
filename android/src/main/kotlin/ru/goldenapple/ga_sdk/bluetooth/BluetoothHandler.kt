package ru.goldenapple.ga_sdk.bluetooth

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import ru.goldenapple.ga_sdk.TAG

class BluetoothHandler(private val bluetoothManager: BluetoothManager) : MethodChannel.MethodCallHandler {

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getBtBoundedDevices" -> result.success(getBtBoundedDevices());
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        };
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    fun getBtBoundedDevices(): String? {
        Log.d(TAG, "getBtBoundedDevices - start");
        val dev: Set<BluetoothDevice> = bluetoothManager.adapter?.bondedDevices ?: setOf();
        Log.d(TAG, dev.size.toString());
        dev.forEach {
            Log.d(TAG, it.name)
        }
        if (dev.count() == 0) return "[]"

        val json = JSONArray(dev.map {
            JSONObject()
                    .put("name", it.name)
                    .put("address", it.address)
                    .put("type", it.type)
                    .put("bondState", it.bondState)
                    .put("deviceClass", it.bluetoothClass.deviceClass)
                    .put("majorDeviceClass", it.bluetoothClass.majorDeviceClass)
        }).toString()

        Log.d(TAG, json);
        Log.d(TAG, "getBtBoundedDevices - end");
        return json
    }

}