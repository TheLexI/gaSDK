package ru.goldenapple.ga_sdk


import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import ru.goldenapple.ga_sdk.bluetooth.BluetoothHandler
import ru.goldenapple.ga_sdk.bluetooth.BluetoothStreamHandler
import ru.goldenapple.ga_sdk.ibox.IBox
import ru.goldenapple.ga_sdk.yanavi.NavigatorMethods


const val TAG: String = "ga_sdk";

/** GaSdkPlugin */
class GaSdkPlugin() : FlutterPlugin, ActivityAware {
    val namespace = "ga_sdk"

    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    lateinit var binding: ActivityPluginBinding
    private lateinit var applicationContext: Context

    private var bluetoothChannel: MethodChannel? = null
    private var bluetoothEventChannel: EventChannel? = null

    private var navigatorChannel: MethodChannel? = null

    private var  paymentChannel: MethodChannel? = null;

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun onAttachedToEngine(@NonNull fpb: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = fpb.applicationContext
        flutterPluginBinding = fpb;
    }

    //region unused
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) { }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }
    //endregion

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding

        initializeBluetooth()
        initializeNavigatorLaugh()
        initializePayment()
    }

    override fun onDetachedFromActivity() {
        destroyBluetooth()
        destroyNavigator()
        destroyPayment()
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private fun initializeBluetooth(){
        bluetoothManager = flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager;

        val streamHandler = BluetoothStreamHandler(namespace, bluetoothManager, binding.activity).getHandler()
        bluetoothEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "$namespace/state_stream");
        bluetoothEventChannel!!.setStreamHandler(streamHandler);

        val handler  = BluetoothHandler(bluetoothManager)
        bluetoothChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "$namespace/method")
        bluetoothChannel?.setMethodCallHandler(handler)
    }

    private fun destroyBluetooth(){
        bluetoothEventChannel!!.setStreamHandler(null);
        bluetoothChannel?.setMethodCallHandler(null);
        bluetoothEventChannel = null
        bluetoothChannel = null;
    }


    private fun initializeNavigatorLaugh(){
        navigatorChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "$namespace/${NavigatorMethods.NAMESPACE}");
        navigatorChannel?.setMethodCallHandler(NavigatorMethods(applicationContext));
    }

    private fun destroyNavigator(){
        navigatorChannel?.setMethodCallHandler(null);
        navigatorChannel = null;
    }


    private fun initializePayment(){
        paymentChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "ga_sdk/IBox/methods")
        paymentChannel?.setMethodCallHandler(IBox(binding.activity, paymentChannel))
    }

    private fun destroyPayment(){
        paymentChannel?.setMethodCallHandler(null)
        paymentChannel = null
    }
}
