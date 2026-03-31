package akademo.aka_appsflyer_flutter_v1;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import com.google.android.gms.ads.identifier.AdvertisingIdClient;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import com.appsflyer.AppsFlyerLib;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "aka.digital/appsflyer_bridge";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new Thread(() -> {
            try {
                AdvertisingIdClient.Info adInfo = AdvertisingIdClient.getAdvertisingIdInfo(getApplicationContext());
                Log.d("GAID_DEBUG", "Advertising ID: " + adInfo.getId());
            } catch (Exception e) {
                Log.e("GAID_DEBUG", "Error getting GAID: " + e.getMessage());
            }
        }).start();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        Intent intent = getIntent();
        if (intent != null) {
            setIntent(intent);
            // AppsFlyerLib.getInstance().sendPushNotificationData(this);
            // Log.d("🔗 [AppsFlyer Log]", "onCreate: Sent Push Data to AppsFlyer");
        }
    }

    @Override
    public void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);  

        // if (intent.getData() != null) {
        //     Log.d("🔗 [AppsFlyer Log]", "[onNewIntent] Link nhận được tại Native: " + intent.getData().toString());
        // }

        //     AppsFlyerLib.getInstance().sendPushNotificationData(this);
        //     AppsFlyerLib.getInstance().performOnDeepLinking(intent, this);
        //     AppsFlyerLib.getInstance().start(this);

        // new Handler(Looper.getMainLooper()).postDelayed(() -> {
        //     new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), "aka.digital/appsflyer_bridge")
        //         .invokeMethod("onNativePushClick", "intent_updated");
        // }, 500);

        // Log.d("🔗 [AppsFlyer Log]", "[onNewIntent] Native gửi intent_updated về Flutter (sau start)" );

    }
}