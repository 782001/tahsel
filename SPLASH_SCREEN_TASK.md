# Android 12+ Splash Screen Implementation Guide

This document provides a technical reference for implementing a seamless, branded splash screen on Android 12 (API 31) and higher, while maintaining a smooth transition to the Flutter application.

## Task Overview
The goal was to replace the default Android system splash (which often defaults to black) with a branded experience that matches the app's primary color and logo. This involves using the **AndroidX Splash Screen library** to control the native splash screen behavior, specifically for Android 12 and 13.

## File Modifications

| File Path | Description |
| :--- | :--- |
| `android/app/build.gradle.kts` | Added the Core Splashscreen dependency. |
| `android/app/src/main/res/values/styles.xml` | Updated `LaunchTheme` to inherit from `Theme.SplashScreen`. |
| `android/app/src/main/res/values-v31/styles.xml` | Provided specific attributes for API 31+. |
| `android/app/src/main/res/values-night/styles.xml` | Configured dark mode support for the splash screen. |
| `android/app/src/main/res/values-night-v31/styles.xml` | Configured dark mode support for API 31+. |
| `android/app/src/main/kotlin/com/awadi/tahsel/MainActivity.kt` | Initialized the Splash Screen API in the activity lifecycle. |

## New Files Added

| File Path | Description |
| :--- | :--- |
| `android/app/src/main/res/drawable/splash_icon.xml` | A wrapper drawable providing internal padding for the logo. |

---

## Step-by-Step Changes

### 1. Adding Dependencies
In `android/app/build.gradle.kts`, added the following dependency to support the modern Splash Screen API:
```kotlin
dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
}
```

### 2. Creating a Padded Icon (Zoom-Out Effect)
To prevent the icon from appearing too large or "zoomed" on Android 12+, we created a layer-list drawable in `android/app/src/main/res/drawable/splash_icon.xml` with defined padding:
```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:drawable="@drawable/ic_launcher_foreground"
        android:gravity="center"
        android:top="32dp"
        android:bottom="32dp"
        android:left="32dp"
        android:right="32dp" />
</layer-list>
```

### 3. Updating Application Themes
Modified the `LaunchTheme` in all `styles.xml` files. The theme must now inherit from `Theme.SplashScreen`:
```xml
<style name="LaunchTheme" parent="Theme.SplashScreen">
    <!-- The background color of the splash screen -->
    <item name="windowSplashScreenBackground">#1E56A0</item>
    
    <!-- The icon to display in the center -->
    <item name="windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
    
    <!-- Theme to transition to after the splash screen is dismissed -->
    <item name="postSplashScreenTheme">@style/NormalTheme</item>
    
    <!-- Retain existing Flutter configurations -->
    <item name="android:windowFullscreen">false</item>
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
</style>
```

### 4. Native Initialization
In `MainActivity.kt`, called `installSplashScreen()` before `super.onCreate()`. This ensures the native splash screen hands off correctly to the Flutter engine:
```kotlin
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen() // Must be called before super.onCreate()
        super.onCreate(savedInstanceState)
    }
}
```

---

## Usage Guide

### AndroidManifest.xml
Ensure your main activity is using the `LaunchTheme` in `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name=".MainActivity"
    android:theme="@style/LaunchTheme" ... >
```

### Key Attributes Explained
*   **`windowSplashScreenBackground`**: The solid color background shown initially.
*   **`windowSplashScreenAnimatedIcon`**: The icon resource. On Android 12+, this is clipped to a circle. Using a foreground-only icon (without a white square background) is recommended.
*   **`postSplashScreenTheme`**: Crucial for stability; this is the theme the activity "switches" to once the app has loaded.

### Troubleshooting
*   **Zoomed Icon**: If the icon touches the circle edges, increase the padding in `splash_icon.xml`.
*   **Black Screen**: Ensure `styles.xml` in `values-v31` is correctly updated, as Android 12+ prioritizes that directory.
