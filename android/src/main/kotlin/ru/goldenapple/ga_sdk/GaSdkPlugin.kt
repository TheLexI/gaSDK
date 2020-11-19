package ru.goldenapple.ga_sdk


import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonArray
import com.google.gson.JsonObject
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import ru.goldenapple.ga_sdk.dto.BluetoothDeviceDto
import ru.goldenapple.ga_sdk.dto.BluetoothDeviceDtoSerializer
import ru.goldenapple.ga_sdk.yanavi.NavigatorMethods
import java.lang.Exception


const val TAG: String = "ga_sdk";

/** GaSdkPlugin */
class GaSdkPlugin() : FlutterPlugin, MethodCallHandler, ActivityAware {
    val namespace = "ga_sdk"

    lateinit var binding: ActivityPluginBinding
    private var channel: MethodChannel? = null
    private var navigatorChannel: MethodChannel? = null
    private lateinit var eventChannel: EventChannel
    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun onAttachedToEngine(@NonNull fpb: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = fpb;
        bluetoothManager = flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager;
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "$namespace/state_stream");

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "$namespace/method")
        channel?.setMethodCallHandler(this)

        navigatorChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "$namespace/${NavigatorMethods.NAMESPACE}");
        navigatorChannel?.setMethodCallHandler(NavigatorMethods(fpb.applicationContext));
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
        channel?.setMethodCallHandler(null)
        channel = null
        navigatorChannel?.setMethodCallHandler(null)
        navigatorChannel = null;
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

        val devices = dev.map {
            BluetoothDeviceDto(
                    name = it.name,
                    address = it.address,
                    type = it.type,
                    bondState = it.bondState,
                    deviceClass = it.bluetoothClass?.deviceClass ?: 0,
                    majorDeviceClass=it.bluetoothClass?.majorDeviceClass ?: 0
            )
        }

        val json = GsonBuilder().registerTypeAdapter(BluetoothDeviceDto::class.java, BluetoothDeviceDtoSerializer()).create().toJson(devices);


        Log.d(TAG, json);
        Log.d(TAG, "getBtBoundedDevices - end");
        return json
    }

    private val bluetoothStateStreamHandler: StreamHandler = object : StreamHandler {

        var events: EventChannel.EventSink? = null

        private val mReceiver: BroadcastReceiver = object : BroadcastReceiver() {
            @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
            override fun onReceive(context: Context?, intent: Intent) {
                val action = intent.action
                val state = bluetoothManager.adapter?.state ?: 0
                Log.i("${TAG}: Bluetooth", "got action $action($state)")
                events?.success(state)
            }
        }

        @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            Log.d("${TAG}: Bluetooth", "onListen")
            this.events = events;
            events?.success(bluetoothManager.adapter?.state ?: 0);

            val filter = IntentFilter()
            filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            binding.activity.registerReceiver(mReceiver, filter)
        }

        override fun onCancel(arguments: Any?) {
            Log.d("$TAG: Bluetooth", "onCancel")
            try {
                binding.activity.unregisterReceiver(mReceiver);
            } catch (ex: Exception) {
            }
        }

    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding;
        eventChannel.setStreamHandler(bluetoothStateStreamHandler);
    }

    override fun onDetachedFromActivityForConfigChanges() {
        bluetoothStateStreamHandler.onCancel("");
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
        bluetoothStateStreamHandler.onCancel("");
    }

}
