package com.af_flutter_sample;

import android.app.Application;
import com.clevertap.android.sdk.ActivityLifecycleCallback;
import com.clevertap.android.sdk.CleverTapAPI;
// import com.clevertap.android.sdk.pushnotification.NotificationHandler;
// import com.clevertap.pushtemplates.PushTemplateNotificationHandler;

public class MyApplication extends Application    {

    @Override
    public void onCreate() {

        ActivityLifecycleCallback.register(this);
        super.onCreate();

    }
}
