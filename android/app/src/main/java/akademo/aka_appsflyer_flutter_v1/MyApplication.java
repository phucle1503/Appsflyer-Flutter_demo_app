package akademo.aka_appsflyer_flutter_v1;
import com.clevertap.android.sdk.ActivityLifecycleCallback;
import android.app.Application;

public class MyApplication extends Application    {

    @Override
    public void onCreate() {
        ActivityLifecycleCallback.register(this);
        super.onCreate();
    }
}
