package com.shadow.blackhole

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private var sharedText: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.shadow.blackhole/sharedTextChannel")
                .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                    if (call.method == "getSharedText") {
                        result.success(sharedText)
                    }
                    if (call.method == "clearSharedText") {
                        sharedText = null
                        result.success(0)
                    }
                }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.shadow.blackhole/registerMedia")
                .setMethodCallHandler { call: MethodCall, _: MethodChannel.Result? ->
                    if (call.method == "registerFile") {
                        val argument = call.argument<String>("file")
                        val file = File(argument)
                        sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(file)))
                    }
                }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.shadow.blackhole/intentChannel")
                .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                    if (call.method == "openAudio") {
                        val audioPath = call.argument<String>("audioPath")
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(audioPath))
                        intent.setDataAndType(Uri.parse(audioPath), "audio/*")
                        startActivity(intent)
                        result.success(0)
                    }
                }
    }

    override fun onNewIntent(intent: Intent) {
        var newIntent = intent
        super.onNewIntent(newIntent)
        setIntent(newIntent)
        newIntent = getIntent()
        val action = newIntent.action
        val type = newIntent.type
        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type) {
                sharedText = newIntent.getStringExtra(Intent.EXTRA_TEXT)
            }
        }
    }
}