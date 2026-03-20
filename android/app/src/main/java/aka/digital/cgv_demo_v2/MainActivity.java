package akademo.aka_appsflyer_flutter_v1;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

// Các import CleverTap đã được comment lại
// import com.clevertap.android.sdk.CleverTapAPI;
// ... (các import khác)

import com.google.android.gms.ads.identifier.AdvertisingIdClient;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

// Xóa bỏ "implements DisplayUnitListener" vì interface này thuộc CleverTap
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "deeplink_channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Logic CleverTap đã được comment toàn bộ để tránh lỗi build
        /*
        CleverTapAPI cleverTapAPI = CleverTapAPI.getDefaultInstance(getApplicationContext());
        if (cleverTapAPI != null) {
            Log.d("[CleverTap]", "CleverTap instance initialized");
            // ... (Geofence và DisplayUnit logic)
        }
        */

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

        // Tạo Notification Channel khi khởi tạo engine
        createCustomNotificationChannel();
    }

    @Override
    public void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);

        if (intent.getExtras() != null) {
            // CleverTapAPI.getDefaultInstance(this).pushNotificationClickedEvent(intent.getExtras());

            // Xử lý deeplink từ Notification nếu có
            String deeplink = intent.getExtras().getString("wzrk_dl");
            if (deeplink != null) {
                Log.d("[Deeplink]", "Received wzrk_dl: " + deeplink);

                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                        .invokeMethod("onDeeplinkReceived", deeplink);
            }
        }
        setIntent(intent);
    }

    // Các phương thức Override của CleverTap DisplayUnit đã được xóa/comment để tránh lỗi build

    private void createCustomNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelId = "Custom_Channel";
            String channelName = "Custom_Channel";
            String channelDescription = "Custom_Channel";

            // Đảm bảo bạn có file lmao.mp3 trong thư mục res/raw/
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