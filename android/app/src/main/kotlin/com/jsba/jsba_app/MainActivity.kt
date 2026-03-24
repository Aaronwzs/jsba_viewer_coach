package com.jsba.jsba_app

import android.os.StrictMode
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        StrictMode.setThreadPolicy(
            StrictMode.ThreadPolicy.Builder()
                .permitNetwork()
                .permitDiskReads()
                .permitDiskWrites()
                .build()
        )
        super.onCreate(savedInstanceState)
    }
}
