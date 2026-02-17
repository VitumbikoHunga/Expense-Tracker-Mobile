# Expense Tracker Mobile - Setup Guide

## Step-by-Step Setup Instructions

### Phase 1: Initial Setup

#### Step 1: Install Flutter SDK

1. **Download Flutter**
   - Go to https://flutter.dev/docs/get-started/install
   - Download the appropriate version for your OS (Windows, Mac, or Linux)

2. **Extract Flutter**
   - Extract the downloaded zip file to a location like `C:\flutter` (Windows) or `~/flutter` (Mac/Linux)

3. **Add Flutter to PATH**
   - **Windows**: Add `C:\flutter\bin` to your system PATH
   - **Mac/Linux**: Run `export PATH="$PATH:~/flutter/bin"` in terminal

4. **Verify Installation**
   ```bash
   flutter --version
   flutter doctor
   ```

#### Step 2: Setup Android Development (for Android app)

1. **Install Android Studio**
   - Download from https://developer.android.com/studio

2. **Install Android Emulator**
   - Open Android Studio → SDK Manager
   - Install SDK Platform (API 33 or higher)
   - Create a Virtual Device (AVD)

3. **Set up environment variables** (if needed)
   - `ANDROID_SDK_ROOT` = Path to Android SDK

#### Step 3: Setup iOS Development (for iOS app - Mac only)

1. **Install Xcode**
   ```bash
   xcode-select --install
   ```

2. **Install Cocoapods**
   ```bash
   sudo gem install cocoapods
   ```

3. **Setup iOS Simulator**
   - Xcode → Preferences → Locations
   - Set Command Line Tools to your Xcode version

### Phase 2: Project Setup

#### Step 4: Prepare the Flutter Project

1. **Navigate to project**
   ```bash
   cd expense_tracker_mobile
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Update constants with your API**
   - Open `lib/config/constants.dart`
   - Change `baseUrl` to your backend URL:
     ```dart
     // For local development on Android Emulator
     static const String baseUrl = 'http://10.0.2.2:3000/api';
     
     // For local development on iOS Simulator
     // static const String baseUrl = 'http://localhost:3000/api';
     
     // For physical device
     // static const String baseUrl = 'http://YOUR-IP-ADDRESS:3000/api';
     ```

#### Step 5: Run the App

**For Android:**
```bash
# Start Android Emulator first
flutter run
```

**For iOS (Mac only):**
```bash
# Start iOS Simulator
open -a Simulator

# Run the app
flutter run
```

### Phase 3: Testing & Development

#### Step 6: Verify Backend Connection

1. Ensure your Next.js backend is running

2. Check API connectivity:
   ```bash
   # Test from your app
   # Try logging in with test credentials
   ```

3. Monitor backend logs for API calls

#### Step 7: Run in Debug Mode

```bash
flutter run -v  # Verbose mode for debugging
```

### Phase 4: Building for Production

#### Step 8: Build APK (Android)

```bash
# Release APK
flutter build apk --release

# App Bundle (for Google Play Store)
flutter build appbundle --release
```

Output location: `build/app/outputs/`

#### Step 9: Build IPA (iOS - Mac only)

```bash
flutter build ios --release
# Then open in Xcode for signing and distribution
open ios/Runner.xcworkspace
```

## Making Changes to the App

### To Add a New Feature:

1. **Create new screen**
   ```bash
   # Create new file in lib/screens/
   lib/screens/new_feature_screen.dart
   ```

2. **Add route** in `lib/routes/app_router.dart`
   ```dart
   GoRoute(
     path: '/feature',
     name: 'feature',
     builder: (context, state) => const NewFeatureScreen(),
   ),
   ```

3. **Add navigation** from drawer or other screens

### To Connect Backend API:

1. **Add provider method** in appropriate provider (`auth_provider.dart`, etc.)

2. **API call example**:
   ```dart
   Future<void> fetchData() async {
     try {
       final response = await _apiService.get('/endpoint');
       // Process response
     } catch (e) {
       _error = e.toString();
     }
     notifyListeners();
   }
   ```

3. **Use in widget**:
   ```dart
   Consumer<YourProvider>(
     builder: (context, provider, _) {
       return provider.data == null 
           ? LoadingWidget() 
           : DataWidget(data: provider.data);
     },
   )
   ```

## Environment Configuration

### Local Development

**API Configuration for Different Scenarios:**

| Scenario | BaseURL |
|----------|---------|
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator | `http://localhost:3000/api` |
| Physical Android Device | `http://192.168.x.x:3000/api` |
| Physical iOS Device | `http://192.168.x.x:3000/api` |

### Production

- Update `baseUrl` to your production API endpoint
- Enable certificate pinning for security
- Update app version in `pubspec.yaml`

## Troubleshooting Common Issues

### Issue: "Flutter command not found"
**Solution**: Add Flutter to PATH and restart terminal/IDE

### Issue: "Error: PlatformException: Bad state: No HostAvailabilityListener"
**Solution**: Restart Android Emulator or iOS Simulator

### Issue: "Connection refused" on API calls
**Solution**: 
- Verify backend is running
- Check correct IP/URL in constants.dart
- Check firewall settings

### Issue: "Insufficient storage on emulator"
**Solution**: Delete and recreate Android Virtual Device

### Issue: Build errors with dependencies
**Solution**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## Performance Tips

1. **Use DevTools for debugging**:
   ```bash
   flutter pub global activate devtools
   devtools
   ```

2. **Monitor performance**:
   - Use Android Studio Profiler
   - Monitor API response times
   - Check memory usage

3. **Optimize images**:
   - Use appropriate image sizes
   - Consider image compression

## Security Best Practices

- ✅ Tokens stored securely with `flutter_secure_storage`
- ✅ HTTPS only for production
- ✅ Validate user input
- ✅ Never log sensitive data
- ✅ Use proper error handling without exposing internals

## Next Steps After Setup

1. **Test Authentication**
   - Test login/register with your backend
   - Verify token storage

2. **Test Data Sync**
   - Create test data in web app
   - Verify it appears in mobile app
   - Create data in mobile app, verify in web app

3. **Customize Branding** (Optional)
   - Update app name in `pubspec.yaml`
   - Update colors in `lib/theme/app_theme.dart`
   - Update app icon

4. **Add Features**
   - Camera integration for receipts
   - PDF export
   - Notifications

## Support & Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **Provider Documentation**: https://pub.dev/packages/provider
- **GoRouter Documentation**: https://pub.dev/packages/go_router

---

**You're all set!** 🎉 Start building with your Expense Tracker Flutter app!
