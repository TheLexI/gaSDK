package ru.goldenapple.ga_sdk

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine


class MainActivity : FlutterActivity() {
    // You can keep this empty class or remove it. Plugins on the new embedding
    // now automatically registers plugins.
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(GaSdkPlugin());
    }
}