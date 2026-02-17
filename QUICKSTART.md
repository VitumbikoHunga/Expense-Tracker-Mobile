# Quick Start Guide - 5 Minutes to Running the App

## Prerequisites Checklist

- [ ] Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- [ ] Android Studio OR Xcode installed
- [ ] Android Emulator/iOS Simulator running OR physical device connected
- [ ] Your backend API running (localhost:3000)

## Quick Setup (Copy & Paste)

### 1. Navigate to Project
```bash
cd c:\Users\RI DESIGN\Desktop\123\expense_tracker_mobile
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Update API URL
**Windows:**
```bash
# Open lib/config/constants.dart in your editor
# Change line 5 from:
# static const String baseUrl = 'http://localhost:3000/api';
# To your backend URL:
# For Android Emulator: http://10.0.2.2:3000/api
# For Physical Device: http://192.168.1.YOUR_IP:3000/api
```

### 4. Run the App

**For Android:**
```bash
flutter run
```

**For iOS (Mac only):**
```bash
flutter run -d iPhone
```

## Test Login

After the app starts, use these credentials:
- **Email**: (Use an account from your backend)
- **Password**: (Your password)

> If you don't have a test account, create one by clicking "Sign Up"

## What You'll See

1. **Login Screen** - Enter credentials
2. **Dashboard** - Overview of expenses and budgets
3. **Navigation Drawer** - Access all features:
   - 📊 Dashboard
   - 🧾 Receipts
   - 📋 Invoices
   - 💼 Quotations
   - 💰 Budgets
   - 📈 Reports
   - ⚙️ Settings

## Common Commands

| Command | What it does |
|---------|-------------|
| `flutter run` | Run the app |
| `r` | Hot reload (during development) |
| `R` | Full app restart |
| `q` | Quit the app |
| `flutter devices` | List connected devices |
| `flutter logs` | View app logs |
| `flutter clean` | Reset build files |

## Troubleshooting Quick Fixes

### "No devices found"
```bash
# Start Android Emulator
flutter emulators --launch <emulator_name>

# Or start iOS Simulator
open -a Simulator
```

### "Connection refused" - Can't reach backend
1. Check backend is running: `localhost:3000`
2. Update API URL in `lib/config/constants.dart`
3. For emulator, use `10.0.2.2` instead of `localhost`

### "Build failed"
```bash
flutter clean
flutter pub get
flutter run
```

## Next Steps

- [ ] Test login/logout
- [ ] Test creating a receipt (tap + button)
- [ ] Check dashboard stats
- [ ] Review code in `lib/screens/`
- [ ] Read [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup
- [ ] Read [ARCHITECTURE.md](ARCHITECTURE.md) to learn how to extend

## File Structure Quick Reference

```
lib/
├── main.dart              ← App starting point
├── screens/               ← All app pages
├── providers/             ← State management
├── models/                ← Data structures
├── services/              ← API calls
└── config/constants.dart  ← API settings
```

## Making Your First Change

### Change the app color:
1. Open `lib/theme/app_theme.dart`
2. Change `primaryColor = Color(0xFF6366F1)` to your color
3. Save and press `r` in terminal for hot reload

## Useful VS Code Extensions

- **Flutter** - Official Flutter support
- **Dart** - Dart language support
- **Awesome Flutter Snippets** - Code snippets

## Need Help?

1. **Setup issues?** → Read [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. **How to add features?** → Read [ARCHITECTURE.md](ARCHITECTURE.md)
3. **Dependencies?** → Read [DEPENDENCIES.md](DEPENDENCIES.md)
4. **Project overview?** → Read [README.md](README.md)

---

**You're ready!** 🚀 Run `flutter run` and enjoy!
