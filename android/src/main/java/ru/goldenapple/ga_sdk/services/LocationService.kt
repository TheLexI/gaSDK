package ru.goldenapple.ga_sdk.services

import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import androidx.annotation.RequiresApi
import androidx.core.app.JobIntentService
import androidx.work.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Duration

class GetLocationWorker(appContext: Context, workerParameters: WorkerParameters): Worker(appContext, workerParameters){
    override fun doWork(): Result {

        return Result.success();
    }
}

class LocationService : MethodChannel.MethodCallHandler, JobIntentService() {
    val WORKER_NAME: String  = "location_request_worker";

    var _locationManager: LocationManager? = null;
    var _workRequest : PeriodicWorkRequest? = null;

    override fun onBind(intent: Intent): IBinder {
        TODO("Return the communication channel to the service.")
    }

    override fun onHandleWork(intent: Intent) {
        TODO("Not yet implemented")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate() {
        super.onCreate()
        if(null == _locationManager) _locationManager = applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager;
        if(null == _workRequest) {
            _workRequest = PeriodicWorkRequestBuilder<GetLocationWorker>(Duration.ofSeconds(60))
                    .addTag(WORKER_NAME)
                    .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                    .build();
        };
    }

    fun startLocation(){
        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(WORKER_NAME, ExistingPeriodicWorkPolicy.KEEP , _workRequest!!);
    }

    fun stopLocation(){
        WorkManager.getInstance(applicationContext).cancelAllWorkByTag(WORKER_NAME);
    }

    override fun onDestroy() {
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        TODO("Not yet implemented")
    }
}