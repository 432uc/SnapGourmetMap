# Snap GourmetLog

## Setup Instructions

Since the automatic project creation failed (Flutter command not found), please run the following commands in this directory (`c:/Users/yuc/Desktop/SnapGourmetMap`):

1. **Initialize Flutter Project**:
   ```bash
   flutter create .
   ```
   This will generate the necessary Android and iOS project files (`android/`, `ios/`, etc.).

2. **Add Dependencies**:
   ```bash
   flutter pub get
   ```

## Adding Google Maps API Key

To enable Google Maps, you must add your API key to the `android/app/src/main/AndroidManifest.xml` file (which will be created after running `flutter create .`).

Open `android/app/src/main/AndroidManifest.xml` and add the following inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

Also, add the following permissions if you plan to use location features:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## Running the App

Run the app with:

```bash
flutter run
```
