# Dependencies Overview

## pubspec.yaml

This file contains all the main dependencies for the Expense Tracker Flutter app. Here's what each one does:

## Core Flutter Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Flutter framework - core UI toolkit |
| `cupertino_icons` | 1.0.2 | iOS-style icons |

## State Management

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | 6.0.0 | State management solution, makes it easy to manage app state |
| `flutter_bloc` | 8.1.0 | Business Logic Component pattern (optional, for complex scenarios) |
| `equatable` | 2.0.0 | Simplifies equality comparisons for BLoC/models |

## Networking & API

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | 1.1.0 | HTTP client for making API requests |
| `dio` | 5.3.0 | Advanced HTTP client with interceptors and caching |

## Local Storage

| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | 2.2.0 | Simple key-value storage for app preferences |
| `sqflite` | 2.3.0 | SQLite database for local data persistence |
| `flutter_secure_storage` | 9.0.0 | Secure storage for tokens and sensitive data |

## Navigation

| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | 12.0.0 | Modern routing and navigation management |

## UI & Styling

| Package | Version | Purpose |
|---------|---------|---------|
| `google_fonts` | 6.1.0 | Google Fonts typography support |
| `cached_network_image` | 3.3.0 | Load and cache images from the network |
| `intl` | 0.19.0 | Internationalization and localization |

## Data Visualization

| Package | Version | Purpose |
|---------|---------|---------|
| `fl_chart` | 0.64.0 | Beautiful charts and graphs for reports |

## Date & Time

| Package | Version | Purpose |
|---------|---------|---------|
| `table_calendar` | 3.1.0 | Calendar widget for date selection |

## Camera & Location

| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | 1.0.0 | Pick images from camera or gallery |
| `camera` | 0.10.0 | Access device camera |
| `geolocator` | 9.0.0 | Get device GPS location |

## PDF & Documents

| Package | Version | Purpose |
|---------|---------|---------|
| `pdf` | 3.10.0 | Generate PDF documents |
| `printing` | 5.11.0 | Print and preview PDFs |

## Security & Authentication

| Package | Version | Purpose |
|---------|---------|---------|
| `jwt_decoder` | 2.0.0 | Decode JWT tokens from backend |

## Notifications

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_local_notifications` | 16.0.0 | Local push notifications |

## Development Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_test` | Testing framework |
| `flutter_linter` | Code linting |
| `build_runner` | Code generation |

## How to Add More Dependencies

### Example: Add Firebase Analytics

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.24.0
     firebase_analytics: ^10.7.0
   ```

2. Get the package:
   ```bash
   flutter pub get
   ```

3. Use in code:
   ```dart
   import 'package:firebase_analytics/firebase_analytics.dart';
   
   final analytics = FirebaseAnalytics.instance;
   analytics.logEvent(name: 'receipt_created');
   ```

## Dependency Management

### Check for Updates
```bash
flutter pub outdated
```

### Upgrade All Dependencies
```bash
flutter pub upgrade
```

### Upgrade Specific Package
```bash
flutter pub upgrade package_name
```

### Remove Unused Dependencies
```bash
flutter pub remove package_name
```

## Common Issues with Dependencies

### Issue: Version Conflict
**Solution**: Check `pubspec.lock` and run:
```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: Package Not Found
**Solution**: Ensure you've added it to `pubspec.yaml` and run:
```bash
flutter pub get
```

### Issue: Build Failure Due to Dependency
**Solution**: 
```bash
flutter clean
flutter pub get
flutter run
```

## Platform-Specific Configuration

### Android (android/app/build.gradle)
- Minimum SDK version is set based on dependencies
- Some packages require specific Android versions

### iOS (ios/Podfile)
- iOS deployment target is set automatically
- Some packages use Cocoapods

## Upgrading Dependency Strategy

### For Production Apps:
- Update only critical security patches
- Test thoroughly before major version upgrades
- Use compatible versions

### Development:
- Keep dependencies relatively up-to-date
- Monitor breaking changes
- Subscribe to package changelogs

## Optional Dependencies (Not Used Yet)

These can be added as your app grows:

```yaml
# For offline-first functionality
realm: ^0.11.0

# For advanced video handling
video_player: ^2.8.0

# For QR code scanning
mobile_scanner: ^3.5.0

# For local authentication
local_auth: ^2.1.0

# For push notifications (FCM)
firebase_cloud_messaging: ^14.7.0

# For analytics
firebase_analytics: ^10.7.0

# For remote configuration
firebase_remote_config: ^4.4.0
```

## Performance Notes

- **Provider**: Lightweight, minimal boilerplate
- **http vs Dio**: http is lighter, Dio has more features
- **SQLite vs SharedPreferences**: SQLite for complex data, SharedPreferences for simple key-value

## Security Considerations

- ✅ `flutter_secure_storage`: For tokens
- ✅ `jwt_decoder`: Validate tokens before use
- ✅ Always use HTTPS in production
- ✅ Don't log sensitive data

## License Information

All dependencies have open-source licenses. Check individual package pages on pub.dev for specific licenses.

## Useful Commands

```bash
# See all dependencies
flutter pub deps

# Check for dependency issues
flutter doctor

# Analyze package dependencies
flutter pub pub outdated

# Cache dependencies
flutter pub global activate

# View dependency tree
flutter pub deps --compact
```

## Resources

- **Pub.dev**: https://pub.dev (Official Dart package repository)
- **Flutter Packages**: https://flutter.dev/packages
- **Dart Documentation**: https://dart.dev/guides/packages

---

Happy developing! 🎉
