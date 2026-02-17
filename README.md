# Expense Tracker Mobile App - Flutter

A cross-platform mobile application built with Flutter that mirrors the functionality of the Expense Tracker web application. This app connects to your existing Next.js backend API.

## Features

- ✅ User Authentication (Login & Register)
- ✅ Dashboard with expense overview
- ✅ Receipt Management
- ✅ Invoice Tracking
- ✅ Budget Management with progress visualization
- ✅ Quotation Management
- ✅ Reports & Analytics
- ✅ Settings & User Profile
- ✅ Responsive UI Design
- ✅ Offline Support (Planned)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── constants.dart       # API endpoints and constants
├── models/                  # Data models
│   ├── user.dart
│   ├── receipt.dart
│   ├── invoice.dart
│   ├── budget.dart
│   └── quotation.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── expense_provider.dart
│   └── budget_provider.dart
├── services/                # API & Business logic
│   └── api_service.dart
├── screens/                 # UI Screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── receipts_screen.dart
│   ├── invoices_screen.dart
│   ├── budgets_screen.dart
│   ├── quotations_screen.dart
│   ├── reports_screen.dart
│   └── settings_screen.dart
├── widgets/                 # Reusable widgets
│   ├── app_drawer.dart
│   └── dashboard_stats.dart
├── routes/
│   └── app_router.dart     # Navigation configuration
└── theme/
    └── app_theme.dart      # Theme configuration
```

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio or Xcode (for iOS development)
- Your Expense Tracker Next.js backend running

## Installation

### 1. Install Flutter

Follow the official Flutter installation guide: https://flutter.dev/docs/get-started/install

### 2. Clone or Create the Project

```bash
cd expense_tracker_mobile
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure API Base URL

Edit `lib/config/constants.dart` and update the `baseUrl` to your backend API:

```dart
static const String baseUrl = 'http://YOUR-API-URL:3000/api';
```

For local development:
- **Android**: Use `http://10.0.2.2:3000/api` (Android Emulator)
- **iOS**: Use `http://localhost:3000/api` (iOS Simulator)
- **Physical Device**: Use your machine's IP address `http://192.168.x.x:3000/api`

### 5. Run the App

```bash
# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run with specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## Development Features

### Hot Reload
During development, use hot reload for faster iteration:
```bash
r - Hot reload
R - Hot restart
q - Quit
```

### Debug Mode
The app includes built-in debugging features:
- Network request logging
- Error handling with user feedback
- Secure token storage

## API Integration

The app connects to these endpoints:

### Authentication
- `POST /users/login` - User login
- `POST /users/register` - User registration
- `GET /users/profile` - Get user profile

### Receipts
- `GET /receipts` - Fetch all receipts
- `POST /receipts/create` - Create receipt
- `POST /receipts/upload` - Upload receipt image

### Invoices
- `GET /invoices` - Fetch all invoices
- `POST /invoices/create` - Create invoice

### Budgets
- `GET /budgets` - Fetch all budgets
- `POST /budgets/create` - Create budget
- `PUT /budgets/:id` - Update budget
- `DELETE /budgets/:id` - Delete budget

### Quotations
- `GET /quotations` - Fetch all quotations
- `POST /quotations/create` - Create quotation

### Reports
- `GET /system-logs` - Get system logs

## State Management

The app uses **Provider** for state management:

- **AuthProvider**: Manages user authentication
- **ExpenseProvider**: Manages receipts, invoices, and quotations
- **BudgetProvider**: Manages budgets and calculations

## Storage

- **Secure Storage**: Authentication tokens are stored securely using `flutter_secure_storage`
- **SharedPreferences**: Local app preferences
- **SQLite**: For offline functionality (coming soon)

## Building for Production

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Then open in Xcode for final setup and signing
```

## Troubleshooting

### Connection refused errors
- Ensure your Next.js backend is running
- Check that the API base URL in `constants.dart` is correct
- For emulator: Use `10.0.2.2` instead of `localhost`

### Authentication errors
- Verify email and password are correct
- Check that your backend is properly returning the auth token
- Clear secure storage if needed: Delete and reinstall the app

### Build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Upcoming Features

- [ ] Offline mode with data sync
- [ ] Camera integration for receipt capture
- [ ] PDF export for invoices
- [ ] Push notifications
- [ ] Advanced analytics and charts
- [ ] Multi-currency support
- [ ] Dark theme
- [ ] Biometric authentication

## Dependencies

Key packages used:
- **go_router** - Navigation
- **provider** - State management
- **http** - HTTP requests
- **flutter_secure_storage** - Secure token storage
- **shared_preferences** - Local storage
- **fl_chart** - Charts and graphs
- **image_picker** - Camera and file access
- **intl** - Internationalization

## Contributing

To contribute to this project:
1. Create a new branch for your feature
2. Make your changes
3. Test thoroughly on both platforms
4. Submit a pull request

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review the API endpoint configurations
3. Check backend logs for API errors
4. Review Flutter and Dart documentation

## License

This project is part of the Expense Tracker application.

## Notes for Web App Integration

Since this Flutter app shares the same backend API as your web app:
- User accounts and data are synchronized
- Login credentials are the same across platforms
- All data changes sync in real-time
- Both apps can be used interchangeably

Enjoy using Expense Tracker Mobile! 🚀
