package akademo.aka_appsflyer_flutter_v1;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.appsflyer.AppsFlyerLib;
import java.util.Map;
import android.net.Uri;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "MyFCMService";
    private static final String CHANNEL_ID = "fcm_default_channel"; 

    @Override
    public void onNewToken(@NonNull String token) {
        super.onNewToken(token);
        AppsFlyerLib.getInstance().updateServerUninstallToken(getApplicationContext(), token);
    }

    @Override
    public void onMessageReceived(@NonNull RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);

        if (remoteMessage.getData().containsKey("af-uinstall-tracking")) {
            Log.d(TAG, "[MyFirebaseMessagingService] AppsFlyer uninstall tracking silent push received.");
            return;
        }
        showCustomNotification(remoteMessage);
    }

    private void showCustomNotification(RemoteMessage message) {
        createChannelIfNeeded();

        Map<String, String> data = message.getData();
        String title = data.getOrDefault("title", (message.getNotification() != null) ? message.getNotification().getTitle() : "Thông báo");
        String body = data.getOrDefault("body", (message.getNotification() != null) ? message.getNotification().getBody() : "Nội dung mới");
        String imageUrl = data.get("image");
        String afLink = data.get("af_push_link");

        Intent intent = new Intent(this, MainActivity.class);
        intent.setAction("FLUTTER_NOTIFICATION_CLICK");
        if (afLink != null) {
            intent.setData(Uri.parse(afLink)); 
        }

        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);

        Bundle bundle = new Bundle();
        for (Map.Entry<String, String> entry : data.entrySet()) {
            bundle.putString(entry.getKey(), entry.getValue());
        }
        
        if (message.getMessageId() != null) {
            bundle.putString("google.message_id", message.getMessageId());
        }
        if (message.getSentTime() > 0) {
            bundle.putString("google.sent_time", String.valueOf(message.getSentTime()));
        }
        if (data.containsKey("af_push_link")) {
            bundle.putString("af_push_link", data.get("af_push_link"));
        }
        intent.putExtras(bundle);

        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, (int) System.currentTimeMillis(), intent, 
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent);

        if (imageUrl != null && !imageUrl.isEmpty()) {
            Bitmap bitmap = getBitmapFromUrl(imageUrl);
            if (bitmap != null) {
                builder.setStyle(new NotificationCompat.BigPictureStyle()
                        .bigPicture(bitmap)
                        .bigLargeIcon((Bitmap) null));
                builder.setLargeIcon(bitmap);
            }
        } 

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
        try {
            notificationManager.notify((int) System.currentTimeMillis(), builder.build());
        } catch (SecurityException e) {
            Log.e(TAG, "[MyFirebaseMessagingService] Lỗi quyền thông báo: " + e.getMessage());
        }
        // NotificationManagerCompat.from(this).notify((int) System.currentTimeMillis(), builder.build());
    }

    private Bitmap getBitmapFromUrl(String imageUrl) {
        try {
            URL url = new URL(imageUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setDoInput(true);
            connection.connect();
            InputStream input = connection.getInputStream();
            return BitmapFactory.decodeStream(input);
        } catch (Exception e) {
            Log.e(TAG, "[MyFirebaseMessagingService] Lỗi tải ảnh Push: " + e.getMessage());
            return null;
        }
    }

    private void createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null && nm.getNotificationChannel(CHANNEL_ID) == null) {
                NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Default", NotificationManager.IMPORTANCE_HIGH);
                channel.setDescription("Kênh thông báo mặc định của ứng dụng");
                channel.enableLights(true);
                channel.enableVibration(true);
                nm.createNotificationChannel(channel);
            }
        }
    }
}