package com.learntoflutter.flutter_embed_unity_android;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

public class UnityBridge {

    private static final String CHANNEL_NAME = "flutter_unity_bridge";

    private static MethodChannel channel;
    private static final Handler mainHandler = new Handler(Looper.getMainLooper());

    public static void init(@NonNull BinaryMessenger messenger) {
        channel = new MethodChannel(messenger, CHANNEL_NAME);
    }

    private static MethodChannel getChannel() {
        return channel;
    }

    public static void onUnityMessage(final String message) {
        final MethodChannel ch = getChannel();
        if (ch == null) return;

        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                ch.invokeMethod("onUnityMessage", message);
            }
        });
    }

    public static void onUnitySceneLoaded(
            final String name,
            final int buildIndex,
            final boolean isLoaded,
            final boolean isValid
    ) {
        final MethodChannel ch = getChannel();
        if (ch == null) return;

        final Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("buildIndex", buildIndex);
        payload.put("isLoaded", isLoaded);
        payload.put("isValid", isValid);

        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                ch.invokeMethod("onUnitySceneLoaded", payload);
            }
        });
    }
}
