package akademo.aka_appsflyer_flutter_v1;

import android.os.Bundle;
import android.Manifest;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.AudioAttributes;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

// import com.clevertap.android.sdk.CleverTapAPI;
// import com.clevertap.android.sdk.pushnotification.NotificationInfo;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
// import com.clevertap.android.sdk.pushnotification.fcm.CTFcmMessageHandler;

import java.util.Map;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "MyFCMService";
    private static final String CHANNEL_ID = "Flutter Test 1";

    @Override
    public void onNewToken(@NonNull String token) {
        Log.d(TAG, "FCM Token: " + token);
        // CleverTapAPI ct = CleverTapAPI.getDefaultInstance(getApplicationContext());
        // if (ct != null) ct.pushFcmRegistrationId(token, true);
    }

    @Override
    public void onMessageReceived(@NonNull RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        Map<String, String> data = remoteMessage.getData();
        Log.d(TAG, "Push data payload: " + data);

        // if (handleCleverTapPush(remoteMessage)) {
        //     Log.i(TAG, "[PUSH] Đây là push từ CleverTap – đã xử lý bằng SDK");
        //     return; 
        // }
        // Log.i(TAG, "[PUSH] Không phải từ CleverTap – sẽ hiển thị theo custom");
        showCustomNotification(remoteMessage);
    }

    // private boolean handleCleverTapPush(RemoteMessage remoteMessage) {
    //     Map<String, String> data = remoteMessage.getData();
    //     if (data == null || data.isEmpty()) return false;

    //     Bundle extras = new Bundle();
    //         for (Map.Entry<String, String> entry : data.entrySet()) {
    //             extras.putString(entry.getKey(), entry.getValue());
    //         }

    //     NotificationInfo info = CleverTapAPI.getNotificationInfo(extras);
    //     Log.d(TAG, "NotificationInfo: fromCleverTap = " + info.fromCleverTap);

    //     if (!info.fromCleverTap) return false;

    //     new CTFcmMessageHandler().createNotification(getApplicationContext(), remoteMessage);
    //     return true;
    // }

    private void showCustomNotification(RemoteMessage message) {
        createChannelIfNeeded();

        Map<String, String> data = message.getData();
        String title = data.getOrDefault("title", message.getNotification() != null ? message.getNotification().getTitle() : "Thông báo");
        String body = data.getOrDefault("body", message.getNotification() != null ? message.getNotification().getBody() : "Nội dung");
        String deeplink = data.get("wzrk_dl"); 

        PendingIntent pendingIntent = null;
        if (deeplink != null) {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(deeplink));
            intent.setPackage(getPackageName());
            pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        }

        Bitmap largeIcon = BitmapFactory.decodeResource(getResources(), R.drawable.aka_logo); 

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.aka_logo) 
                .setLargeIcon(largeIcon)
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true)
                .setColor(Color.parseColor("#6200EE")) 
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setStyle(new NotificationCompat.BigPictureStyle()
                        .bigPicture(largeIcon)
                        .bigLargeIcon((Bitmap)null));

        if (pendingIntent != null) builder.setContentIntent(pendingIntent);

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                        == PackageManager.PERMISSION_GRANTED) {
            int notificationId;
            try {
                notificationId = Integer.parseInt(data.get("id"));
            } catch (Exception e) {
                notificationId = title.hashCode();
            }
            NotificationManagerCompat.from(this).notify(notificationId, builder.build());
        } else {
            Log.w(TAG, "Chưa có quyền POST_NOTIFICATIONS");
        }
    }

    private void createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;

        NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return;

        Uri soundUri = Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + getPackageName() + "/raw/sound2");
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "CHANNEL_ID",
                NotificationManager.IMPORTANCE_HIGH);
        channel.setSound(soundUri, new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build());
        channel.enableLights(true);
        channel.enableVibration(true);
        nm.createNotificationChannel(channel);
    }
}