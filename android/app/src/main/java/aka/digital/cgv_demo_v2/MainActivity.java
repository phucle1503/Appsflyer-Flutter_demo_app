package com.af_flutter_sample;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import android.location.Location;

import com.clevertap.android.sdk.CleverTapAPI;
import com.clevertap.android.sdk.InAppNotificationButtonListener;
import com.clevertap.android.sdk.InAppNotificationListener;
import com.clevertap.android.geofence.CTGeofenceAPI;
import com.clevertap.android.geofence.interfaces.CTGeofenceEventsListener;
import com.clevertap.android.geofence.interfaces.CTLocationUpdatesListener;
import com.clevertap.android.geofence.CTGeofenceSettings;
import com.clevertap.android.sdk.displayunits.DisplayUnitListener;
import com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit;
import com.google.android.gms.ads.identifier.AdvertisingIdClient;

import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList; // [Native Display]


import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import org.json.JSONObject;

public class MainActivity extends FlutterActivity implements DisplayUnitListener {
    private static final String CHANNEL = "deeplink_channel";
    private static final String NATIVE_DISPLAY_CHANNEL = "native_display_channel"; // [Native Display]

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        CleverTapAPI cleverTapAPI = CleverTapAPI.getDefaultInstance(getApplicationContext());
        if (cleverTapAPI != null) {
            Log.d("[CleverTap]", "CleverTap instance initialized");

            CTGeofenceSettings ctGeofenceSettings = new CTGeofenceSettings.Builder()
                    .enableBackgroundLocationUpdates(true)
                    .setLogLevel(3)  // Verbose
                    .setLocationAccuracy((byte) 1)  // HIGH
                    .setLocationFetchMode((byte) 1) // CONTINUOUS
                    .setGeofenceMonitoringCount(20)
                    .setInterval(60 * 60 * 1000) // 1 giờ
                    .setFastestInterval(30 * 60 * 1000) // 30 phút
                    .setSmallestDisplacement(200.0f) // 200 mét
                    .setGeofenceNotificationResponsiveness(30000) // 30 giây
                    .build();

            CTGeofenceAPI.getInstance(getApplicationContext()).init(ctGeofenceSettings, cleverTapAPI);

            CTGeofenceAPI.getInstance(getApplicationContext())
                    .setOnGeofenceApiInitializedListener(() -> {
                        Log.d("[Geofence]", "CTGeofenceAPI initialized ✅");
                    });

            CTGeofenceAPI.getInstance(getApplicationContext())
                    .setCtGeofenceEventsListener(new CTGeofenceEventsListener() {
                        @Override
                        public void onGeofenceEnteredEvent(JSONObject jsonObject) {
                            Log.d("[Geofence]", "📍 Entered: " + jsonObject.toString());
                        }

                        @Override
                        public void onGeofenceExitedEvent(JSONObject jsonObject) {
                            Log.d("[Geofence]", "📍 Exited: " + jsonObject.toString());
                        }
                    });

            CTGeofenceAPI.getInstance(getApplicationContext())
                    .setCtLocationUpdatesListener(new CTLocationUpdatesListener() {
                        @Override
                        public void onLocationUpdates(Location location) {
                            Log.d("[Geofence]", "📡 Location update: " + location.getLatitude() + ", " + location.getLongitude());
                        }
                    });

            try {
                CTGeofenceAPI.getInstance(getApplicationContext()).triggerLocation();
            } catch (IllegalStateException e) {
                Log.e("[Geofence]", "Geofence SDK chưa được init đúng cách ❌", e);
            }

            cleverTapAPI.setDisplayUnitListener(this); // Lắng nghe native display
            HashMap<String, Object> eventProps = new HashMap<>();
            eventProps.put("source", "flutter");
            cleverTapAPI.pushEvent("native display", eventProps);
            cleverTapAPI.getAllDisplayUnits();            // Kích hoạt lấy dữ liệu native display
        }

        // ===== GAID DEBUG =====
        new Thread(() -> {
            try {
                AdvertisingIdClient.Info adInfo =
                        AdvertisingIdClient.getAdvertisingIdInfo(getApplicationContext());

                String gaid = adInfo.getId();
                boolean isLimitAdTrackingEnabled = adInfo.isLimitAdTrackingEnabled();

                Log.d("GAID_DEBUG", "Advertising ID: " + gaid);
                Log.d("GAID_DEBUG", "Limit Ad Tracking: " + isLimitAdTrackingEnabled);

            } catch (Exception e) {
                Log.e("GAID_DEBUG", "Error getting GAID: " + e.getMessage());
            }
        }).start();
    }


    @Override
    public void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);

        if (intent.getExtras() != null) {
            CleverTapAPI.getDefaultInstance(this).pushNotificationClickedEvent(intent.getExtras());

            String deeplink = intent.getExtras().getString("wzrk_dl");
            if (deeplink != null) {
                Log.d("[Deeplink]", "Received wzrk_dl: " + deeplink);

                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                        .invokeMethod("onDeeplinkReceived", deeplink);
            }
        }
        setIntent(intent);
    }

    @Override
    public void onDisplayUnitsLoaded(ArrayList<CleverTapDisplayUnit> displayUnits) {
        if (displayUnits != null && !displayUnits.isEmpty()) {
            CleverTapDisplayUnit adUnit = displayUnits.get(0);

            String title = adUnit.getContents().get(0).getTitle();
            String message = adUnit.getContents().get(0).getMessage();

            new android.app.AlertDialog.Builder(this)
                    .setTitle(title)
                    .setMessage(message)
                    .setPositiveButton("OK", (dialog, which) -> {
                        CleverTapAPI.getDefaultInstance(this).pushDisplayUnitClickedEventForID(adUnit.getUnitID());
                    })
                    .show();

            CleverTapAPI.getDefaultInstance(this).pushDisplayUnitViewedEventForID(adUnit.getUnitID());
            CleverTapAPI.getDefaultInstance(getApplicationContext()).pushDisplayUnitClickedEventForID(adUnit.getUnitID());


        }
    }

    private void createCustomNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelId = "Custom_Channel";
            String channelName = "Custom_Channel";
            String channelDescription = "Custom_Channel";

            Uri soundUri = Uri.parse("android.resource://" + getPackageName() + "/raw/lmao");

            AudioAttributes audioAttributes = new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build();

            NotificationChannel channel = new NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription(channelDescription);
            channel.enableLights(true);
            channel.enableVibration(true);
            channel.setSound(soundUri, audioAttributes);

            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
                Log.d("[NotificationChannel]", "Custom_Channel with sound created");
            }
        }
    }
}

