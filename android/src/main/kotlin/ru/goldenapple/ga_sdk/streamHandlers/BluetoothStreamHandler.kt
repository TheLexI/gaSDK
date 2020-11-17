package ru.goldenapple.ga_sdk.streamHandlers


import android.bluetooth.BluetoothManager
import android.media.MediaCas
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.Disposable
import io.reactivex.disposables.SerialDisposable
import ru.goldenapple.ga_sdk.GaSdkPlugin
import ru.goldenapple.ga_sdk.TAG
import java.util.concurrent.TimeUnit


class BluetoothStreamHandler(private  val bluetoothManager: BluetoothManager, private  val plugin: GaSdkPlugin) : EventChannel.StreamHandler {
    companion object {
        private const val delayListenBleStatus = 500L
    }

    private val subscriptionDisposable = SerialDisposable()


    override fun onListen(arguments: Any?, events: EventSink?) {
        Log.d(TAG, "stateStreamHandler, current action: ${events.toString()}")
        subscriptionDisposable.set(events?.let(::listenToBleStatus))
    }

    override fun onCancel(arguments: Any?) {
        subscriptionDisposable.set(null)
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private fun listenToBleStatus(eventSink: EventSink): Disposable =
            Observable.interval(delayListenBleStatus, TimeUnit.MILLISECONDS)
                    .takeUntil(plugin.observableDisposed)
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe({ next ->
                        val bleStatus = bluetoothManager.adapter?.state
                        Log.d(TAG, bleStatus.toString())
                        eventSink.success(bleStatus.toString())
                    }, { throwable ->
                        eventSink.error("ObserveBleStatusFailure", throwable.message, throwable.stackTrace)
                    })
}

