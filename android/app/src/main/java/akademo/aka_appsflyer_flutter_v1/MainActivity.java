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
        }
    }

    @Override
    public void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);  

        // 1. Lấy link từ payload của Firebase (thường nằm trong extras)
        // String afPushLink = null;
        // if (intent.getExtras() != null) {
        //     afPushLink = intent.getExtras().getString("af_push_link");
        //     Log.d("MainActivity", "🔗 [AppsFlyer Log] afPushLink: " + afPushLink);
        // }

        // 2. NẾU tìm thấy link, hãy "ép" nó vào Data của Intent
        // if (afPushLink != null && !afPushLink.isEmpty()) {
        //     intent.setData(android.net.Uri.parse(afPushLink));
        //     Log.d("MainActivity", "🔗 [AppsFlyer Log] Đã ép link vào Intent Data: " + afPushLink);
        // }

        // intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        // intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        // intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
    }
}