"use strict";

/**
 * Cloud Function gửi sự kiện "App Uninstalled" lên CleverTap
 * khi người dùng gỡ cài đặt app (app_remove)
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const request = require("requestretry");

admin.initializeApp();

/**
 * Gửi sự kiện gỡ cài đặt ứng dụng lên CleverTap khi Firebase ghi nhận app_remove
 */
exports.sendAndroidUninstallToCleverTap = functions.analytics
  .event("app_remove")
  .onLog((event) => {
    function myRetryStrategy(err, response) {
      return !!err || response.statusCode === 503;
    }

    const clevertapId = event.user.userProperties.ct_objectId.value;

    const data = JSON.stringify({
      d: [
        {
          objectId: clevertapId,
          type: "event",
          evtName: "App Uninstalled",
          evtData: {},
        },
      ],
    });

    return request(
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CleverTap-Account-Id": "485-766-KW7Z",
          "X-CleverTap-Passcode": "2abfe30afb194a359fde255345130ed4",
        },
        body: data,
        url: "https://sg1.api.clevertap.com/firebase/upload",
        maxAttempts: 5,
        retryDelay: 2000,
        retryStrategy: myRetryStrategy,
      },
      (err, response, body) => {
        if (response && response.statusCode === 200) {
          console.log("✅ Sent uninstall event to CleverTap:", body);
        } else {
          console.error(
            "❌ Failed to send uninstall:",
            err || response.statusCode,
            body,
          );
        }
      },
    );
  });
