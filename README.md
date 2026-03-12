# cgv_demo_flutter_firebase

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

android: 
    - Basic Integration (done)
    - Events & user properties (done)
    - Mobile Push (done)
    - In App  (done)
    - Rich Push
    - Push Impression (done)
    - MSG-PUSH (done)
    - Pull Notification
    - Native Display
    - App Inbox  (done)
    - Push Primer  (done)
    - Push Template (done)
    - Geofence  (done)
    - App Uninstall(Android): Cần upgrade firebase console lên Blaze plan để tracking real-time uninstall.
    Command: firebase deploy --only functions
    Error: Your project clevertap-android-c74c1 must be on the Blaze (pay-as-you-go) plan to complete this command. Required API artifactregistry.googleapis.com can't be enabled until the upgrade is complete. To upgrade, visit the following URL:  https://console.firebase.google.com/project/clevertap-android-c74c1/usage/details

    Đã xong native display ở tầng android -> render UI ở test_page.dart