# tahsel

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

# Abdullah Alawadi's Standard Reference Repo

This project serves as a **standard repository for Abdullah Alawadi’s personal coding style**. It is a reusable base for future development, demonstrating a clean, maintainable, and scalable approach to building Flutter applications.

- Localization (translations)
- SharedPreferences management
- Dio setup for APIs
- Navigation without context
- App-wide constants
- Centralized theme-aware colors (AppColors)
- flutter_launcher_icons
- Security device checks (Root/Jailbreak)
- Secure token storage (VaultKit)
- Safe logging management
- Data obfuscation
- Global error handling
- Theme management (Dark/Light)
  It’s modular and can be copied into any Flutter project.

---

## 🎯 Project Purpose

This repository is designed to be:

- **A Standard Reference**: A reflection of Abdullah Alawadi’s approach to writing high-quality Flutter code.
- **Reusable Base**: A modular boilerplate that can be integrated into any new project to jumpstart development with best practices.
- **Clean Architecture Showcase**: A real-world demonstration of how Clean Architecture is implemented to separate concerns and ensure maintainability.

---

## 🚀 Latest Changes (March 17, 2026)

### 1. Secure Storage Migration (`vault_kit`)

- **Refactor**: Replaced `flutter_secure_storage` with `vault_kit: ^1.0.5`.
- **Reasoning**: Switched to a lighter and more efficient native encryption solution (AES-256-GCM on Android, Keychain on iOS) with improved read/write performance for authentication tokens.
- **Implementation**: Updated `SecureStorageHelper` and Dependency Injection to use the new engine while maintaining the existing abstraction layer.

### 2. Clean Architecture Implementation (Category Module)

- **Feature**: Added a new `Category` feature following strict Clean Architecture principles.
- **Components**:
  - **Data Layer**: Remote Data Source and Repository implementation.
  - **Domain Layer**: Entities and Use Cases (`GetCategories`, `GetCategoryById`).
  - **Presentation Layer**: BLoC/Cubit for state management.
- **Purpose**: Serves as a live example of how to scale the project with new features using the established architectural patterns.

### 3. API Infrastructure Improvements

- Updated `Endpoint` management to include dynamic category routing.
- Enhanced `injection_container.dart` with modular dependency registration.

---

**Usage anywhere:**

```dart
final cashHelper = sl<CashHelper>();
final secureStorage = sl<SecureStorageHelper>();
final dio = sl<DioClient>();
final navigator = sl<NavigatorService>();

------------Navigation--------
  nav().pushNamed(Routes.authWelcomeScreen);

------------Translation----------
AppStrings.login.tr()

------------Logging--------------
AppLogger.printMessage("Log message only in debug mode");

------------Security-------------
// make sure that SecurityService.isEnabled = true;
// in main.dart
SecurityService.isEnabled = true;
await SecurityService.checkSecurity(); // Navigates if insecure
String safeData = SecurityService.obfuscateData("sensitive@info.com");

context.read<ThemeCubit>().toggleTheme();

------------AppColors------------
// Automatically switches based on current theme
Color background = AppColors.scafoldBackGround;
Color text = AppColors.textColor;
```

## 1️⃣ NavigatorService

✅✅A singleton service to handle **navigation from anywhere** in the app, without needing `BuildContext`.
it added to getIt in injectionContainer.dart

```dart
import 'package:flutter/material.dart';
NavigatorService nav() => sl<NavigatorService>();
class NavigatorService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext get context => navigatorKey.currentContext!;
}

final navigator = NavigatorService();
```

**Usage:**

```dart
  nav().pushNamed(Routes.authWelcomeScreen);

// Or use helper for context
navigator.navigatorKey.currentState!.pushNamed(Routes.authWelcomeScreen);
// Or use helper for context
navigator.context;
```

---

## 2️⃣ CashHelper (SharedPreferences)

✅✅ it added to getIt in injectionContainer.dart
Wrapper around SharedPreferences for easy access and consistent use.

```dart
import 'package:shared_preferences/shared_preferences.dart';

class CashHelper {
  final SharedPreferences sharedPreferences;

  CashHelper(this.sharedPreferences);

  dynamic getData({required String key}) => sharedPreferences.get(key);
  bool? getBoolData({required String key}) => sharedPreferences.getBool(key);
  Future<bool> saveData({required String key, required dynamic value}) async {
 if (value is String) {

      return await sharedPreferences.setString(key, value);
    }    if (value is int) return sharedPreferences.setInt(key, value);
    if (value is bool) return sharedPreferences.setBool(key, value);
    if (value is double) return sharedPreferences.setDouble(key, value);
    throw UnsupportedError('Unsupported type');
  }

  Future<bool> removeData({required String key}) => sharedPreferences.remove(key);
  Future<bool> clearAll() => sharedPreferences.clear();
}
```

**Usage:**

```dart
final AppStrings.locale = sl<CashHelper>().getData(key: "locale");
await sl<CashHelper>().saveData(key: 'locale', value: 'abc123');
```

---

## 3️⃣ Dio Setup

Centralized network client for API requests.

```dart
import 'package:dio/dio.dart';

class DioClient {
  DioClient(this._dio) {
    _dio
      ..options.baseUrl = Endpoint.apiBaseUrl
      ..options.connectTimeout = Endpoint.connectionTimeout
      ..options.receiveTimeout = Endpoint.receiveTimeout
      ..options.responseType = ResponseType.json;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers[ApiKeys.contentType] = 'application/json';
          options.headers[ApiKeys.accept] = 'application/json';
          كمان بتبعت اللغه & التوكين تلقائي مع الريكويست
          يعني مش محتاج ابعتهم مع  الريكويست كل مره
     final lang =
              sl<CashHelper>().getData(key: AppStrings.locale) ??
              AppStrings.currentLang;
          options.headers[ApiKeys.acceptLanguage] = lang;

           // Fetch token securely
          final token = await sl<SecureStorageHelper>().getData(key: 'token');
          if (token != null) {
            options.headers[ApiKeys.authorization] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
    // 🐛 Logger
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
  }
}




```

**Usage1:**

```dart
 Directly from GetIt
final dio = sl<DioClient>();
final response = await dio.get('/users');
```

**Usage2:**

او ممكن نخلي الكونستراكتور ياخدها لما نستدعي الريموت داتا سورس جوه الinjection_container.dart

Passing Dio to Remote Data Source via Injection Container

```dart
class AddToCartRemoteDataSource extends AddToCartBaseRemoteDataSource {
  final DioClient dio;


  AddToCartRemoteDataSource(this.dio);


  Future<void> addItem(Map<String, dynamic> data) async {
    final response = await dio.post('/cart/add', data: data);
    // handle response
  }
}


// In injection_container.dart
sl.registerLazySingleton(() => AddToCartRemoteDataSource(sl<DioClient>()));

✅ Now every request automatically includes the user's language and token headers without manually setting them each time.

```

---

## 4️⃣ GetIt Dependency Injection

All services are registered with **GetIt** for easy access anywhere.

```dart
final sl = GetIt.instance;

Future<void> init() async {
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  sl.registerLazySingleton<CashHelper>(
    () => CashHelper(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<DioClient>(() => DioClient(Dio()));
  sl.registerLazySingleton(() => NavigatorService());
}
```

---

## ✅ Advantages

- Centralized navigation, storage, API, and translation
- Shortcut methods for cleaner code
- Reusable in any Flutter project
- Hot Restart Friendly
- Easy to maintain constants in `AppStrings`

---

## 6️⃣ Recommended Folder Structure

```
lang/
   ├─ ar.json
   ├─ en.json
lib/
├─ core/
│  ├─ dio_client/
│  │  ├─ dio_client.dart
│  ├─ storage/
│  │  ├─ cashhelper.dart
│  ├─ services/
│  │  ├─ injection_container.dart
│  │  ├─ navigator_service.dart
├─ config/
│  ├─ services/
│  │  ├─ injection_container.dart
│  │  ├─ navigator_service.dart

```

---

## to handle app icon

run in terminal
=> dart run flutter_launcher_icons

---

## 7️⃣ SecurityService

✅✅ A service to protect the application by checking for insecure device environments (rooted/jailbroken or developer mode).

```dart
class SecurityService {
  /// Configuration to enable or disable the security service
  static bool isEnabled = true;

  /// Check if the device is jailbroken or rooted
  static Future<bool> isJailbroken();

  /// Check if developer mode / ADB is enabled (Android only)
  static Future<bool> isDeveloperModeEnabled();

  /// Main security check logic - navigates to warning screen if insecure
  static Future<void> checkSecurity();
}
```

**Usage in SplashScreen:**

```dart
void _navigateToNext() async {
  await SecurityService.checkSecurity();
  // continue navigation...
}
```

**Features:**

- Responsive warning screen using `ScreenUtil`.
- Automatic navigation to `SecurityWarningScreen` if conditions are met.
- Follows the app's standard design system and typography.

---

## 8️⃣ AppLogger (printMessage)

✅✅ A utility to manage logging safely, ensuring logs only appear during development.

```dart
import 'package:tahsel/core/utils/app_logger.dart';

// Use this anywhere in the app
AppLogger.printMessage("User logged in with ID: 123");
```

- **Debug Mode**: Logs are printed to the console.
- **Release Mode**: Logs are completely silenced, preventing sensitive information leaks.

---

## 9️⃣ Secure Data Handling & Obfuscation

✅✅ Guidelines and tools for protecting sensitive information.

### Secure Storage (Tokens)

The project uses **VaultKit** for secure storage. VaultKit is a lightweight, efficient, and native solution (AES-256-GCM on Android, Keychain on iOS) designed for high performance and a clean API.

**Why VaultKit?**

- **Lighter & Efficient**: Minimal overhead compared to other solutions.
- **Improved Performance**: Faster read/write operations for quick token access.
- **Native Security**: Uses OS-level encryption (Android Keystore / iOS Keychain).

Always use `SecureStorageHelper` for sensitive data like authentication tokens instead of `SharedPreferences`.

```dart
final secureStorage = sl<SecureStorageHelper>();
await secureStorage.saveData(key: 'token', value: 'my_secret_token');
```

### Data Obfuscation

The `SecurityService` provides a toggle to obfuscate sensitive data in the UI or logs.

```dart
// Enable/Disable globally
SecurityService.isObfuscationEnabled = true;

// Usage
String sensitiveEmail = "user@example.com";
String safeEmail = SecurityService.obfuscateData(sensitiveEmail); // us****om
```

---

## 🔟 API Key Management (.env)

✅✅ Manage sensitive environment variables using `.env` files properly.

1.  **Create a `.env` file** in the root directory:
    ```env
    API_BASE_URL=https://api.example.com
    API_KEY=your_secret_api_key_here
    ```
2.  **Add it to `.gitignore`** to prevent leaking keys:
    ```
    .env*
    ```
3.  **Access variables** in code:

    ```dart
    import 'package:flutter_dotenv/flutter_dotenv.dart';

    String baseUrl = dotenv.env['API_BASE_URL'] ?? 'fallback_url';
    ```

---

## 1️⃣1️⃣ Global Error Handling (ErrorScreen)

✅✅ Captures all Flutter framework and building errors, showing a user-friendly UI instead of a red screen or terminal logs.

- **Responsive**: Adapts to all screen sizes.
- **Informative**: Shows error details in a scrollable, selectable container.
- **Themed**: Matches the app's primary colors and typography.
- **Production Ready**: Prevents users from seeing raw code crashes.

---

## 1️⃣2️⃣ Theme Management (Dark/Light Mode)

A Cubit-based theme management system that persists the user's choice using `CashHelper`.

### Implementation

- **ThemeCubit**: Handles state transitions between `ThemeMode.light` and `ThemeMode.dark`.
- **Persistence**: Automatically saves the selected theme to `SharedPreferences`.
- **Integration**: Wrapped in `main.dart`'s `MaterialApp` via `BlocBuilder`.

### Usage

Toggle theme from any widget or using global helpers:

```dart
import 'package:tahsel/features/theme/presentation/cubit/theme_cubit.dart';

// Option 1: Global shortcut (anywhere)
theme().toggleTheme();

// Option 2: BuildContext extension (inside widgets)
context.theme.toggleTheme();

// Option 3: Standard Bloc access
context.read<ThemeCubit>().toggleTheme();

// Switch to specific modes
theme().toDarkMode();
theme().toLightMode();
```

### Pre-built Widgets

We provide two ready-to-use widgets for theme switching:

1. **ThemeToggleButton**: A simple icon button for AppBars.

   ```dart
   appBar: AppBar(
     actions: [ThemeToggleButton()],
   )
   ```

2. **ThemeSwitchListTile**: A ListTile with a switch, perfect for settings screens.
   ```dart
   ListView(
     children: [
       ThemeSwitchListTile(
         title: "Dark Mode",
         leadingIcon: Icons.dark_mode,
       ),
     ],
   )
   ```

---

## 1️⃣3️⃣ Centralized Theme-Aware Colors (AppColors)

✅✅ A centralized system for managing colors that automatically adapt to the current theme (Light or Dark).

### Core Features:

- **Dynamic Getters**: `AppColors` properties are getters that evaluate the current theme state dynamically.
- **Theme Awareness**: Uses `NavigatorService` to check the current `Brightness` or directly interfaces with `ThemeCubit`.
- **Consistency**: Ensures all UI components (TextStyles, CustomButtons, Containers) use the same semantic colors.

### Usage:

Instead of reaching into `Theme.of(context)` manually, use `AppColors` anywhere:

```dart
Container(
  color: AppColors.scafoldBackGround, // Changes automatically
  child: Text(
    "Hello World",
    style: TextStyle(color: AppColors.textColor),
  ),
)
```

---

## 1️⃣4️⃣ Vital Android Configuration

> [!IMPORTANT]
> The following Android configuration details are **CRITICAL** and must be included in every project to ensure correct module resolution, secure signing, and consistent builds across different environments.

### 1. Root `build.gradle.kts` (Namespace Fix)

Add the following `subprojects` block to your `android/build.gradle.kts`. This is essential for fixing namespace issues in older plugins (like `flutter_jailbreak_detection`) and ensuring proper evaluation order.

```kotlin
subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")

        afterEvaluate {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespace.invoke(androidExt)
                    if (currentNamespace == null) {
                        val manifestFile = project.file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val content = manifestFile.readText()
                            val matcher = java.util.regex.Pattern.compile("""package="([^"]+)"""").matcher(content)
                            if (matcher.find()) {
                                val packageName = matcher.group(1)
                                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                                setNamespace.invoke(androidExt, packageName)
                            }
                        } else if (project.name == "flutter_jailbreak_detection") {
                            val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExt, "com.rioapp.demo.flutter_jailbreak_detection")
                        }
                    }
                } catch (e: Exception) {
                    // Ignore reflection exceptions if methods don't exist
                }
            }
        }
    }
}
```

### 2. App Signing & `key.properties`

To maintain secure and consistent release builds, use a `key.properties` file in the `android/` directory.

**File Structure (`android/key.properties`):**

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=your_alias
storeFile=path/to/your/upload-keystore.jks
```

**Implementation in `android/app/build.gradle.kts`:**
Ensure your app-level build file loads these properties:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Then, use `keystoreProperties.getProperty("...")` within your `signingConfigs`.

---

This setup allows you to copy the folder structure and utilities into any Flutter project and get started immediately.

---
