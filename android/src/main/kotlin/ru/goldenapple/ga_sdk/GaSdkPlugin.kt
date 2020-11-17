package ru.goldenapple.ga_sdk

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import io.flutter.app.FlutterActivityEvents
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.reactivex.Observable
import io.reactivex.subjects.AsyncSubject
import io.reactivex.subjects.Subject
import ru.goldenapple.ga_sdk.dto.BluetoothDeviceDto
import ru.goldenapple.ga_sdk.streamHandlers.BluetoothStreamHandler

const val TAG: String = "ga_sdk";

/** GaSdkPlugin */
class GaSdkPlugin : FlutterPlugin, MethodCallHandler, FlutterActivity() {
    val namespace = "ga_sdk"

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    var observableDisposed: Subject<Boolean> =  AsyncSubject.create();

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun onAttachedToEngine(@NonNull fpb: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = fpb;
        bluetoothManager = flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager;
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "$namespace/state_stream");
        eventChannel.setStreamHandler(BluetoothStreamHandler(bluetoothManager, this))
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "$namespace/method")
        channel.setMethodCallHandler(this)
        
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getBtBoundedDevices" -> result.success(getBtBoundedDevices());
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        };
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        observableDisposed.onNext(true);
        channel.setMethodCallHandler(null)
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    fun getBtBoundedDevices(): String? {
        return Gson().toJson(
                bluetoothManager.adapter.bondedDevices.map {
                    BluetoothDeviceDto(
                            name = it.name,
                            address = it.address,
                            bondState = it.bondState,
                            type = it.type,
                            deviceClass = it.bluetoothClass.deviceClass,
                            majorDeviceClass = it.bluetoothClass.majorDeviceClass
                    )
                }
        );
    }


    override fun onDestroy() {
        observableDisposed.onNext(true);

        super.onDestroy();
    }


    override fun onUserLeaveHint() {
        observableDisposed.onNext(true);
    }

}
