package com.sep.sep490_mobile;

import com.learntoflutter.flutter_embed_unity_android.unity.FakeUnityPlayerActivity;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import com.learntoflutter.flutter_embed_unity_android.UnityBridge;

public class MainActivity extends FlutterActivity {

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Khởi tạo UnityBridge với BinaryMessenger của engine
        UnityBridge.init(flutterEngine.getDartExecutor().getBinaryMessenger());
    }
}

