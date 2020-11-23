package ru.goldenapple.ga_sdk.bluetooth

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
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import ru.goldenapple.ga_sdk.TAG
import java.lang.Exception

class BluetoothStreamHandler(
        val namespace: String,
        val bluetoothManager: BluetoothManager,
        val context: Context
){

    private val bluetoothStateStreamHandler: EventChannel.StreamHandler = object : EventChannel.StreamHandler {

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
            context.registerReceiver(mReceiver, filter)
        }

        override fun onCancel(arguments: Any?) {
            Log.d("$TAG: Bluetooth", "onCancel")
            try {
                context.unregisterReceiver(mReceiver)
            } catch (ex: Exception) {
                Log.d(namespace, ex.toString())
            }
        }
    }

    fun getHandler(): EventChannel.StreamHandler {
        return bluetoothStateStreamHandler;
    }
}