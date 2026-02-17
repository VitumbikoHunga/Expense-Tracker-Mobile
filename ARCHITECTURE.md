# Flutter App Architecture & Customization Guide

## Architecture Overview

This Flutter app uses a **Provider-based architecture** with clean separation of concerns:

```
┌─────────────────────────────────────────┐
│           UI Layer (Screens)             │
│  • LoginScreen, DashboardScreen, etc.   │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│      State Management (Providers)        │
│  • AuthProvider, ExpenseProvider, etc.  │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│      Business Logic (Services)           │
│  • ApiService, LocalStorageService      │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│         Data Layer (Models)              │
│  • User, Receipt, Invoice, Budget       │
└─────────────────────────────────────────┘
```

## Layer Breakdown

### 1. **UI Layer (Screens & Widgets)**

Located in `lib/screens/` and `lib/widgets/`

**Responsibility**: Display data and collect user input

**Example**:
```dart
class DashboardScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          // UI code
        );
      },
    );
  }
}
```

### 2. **State Management Layer (Providers)**

Located in `lib/providers/`

**Responsibility**: Manage app state and business logic

**Architecture**:
```dart
class ExpenseProvider extends ChangeNotifier {
  // State
  List<Receipt> _receipts = [];
  
  // Getters
  List<Receipt> get receipts => _receipts;
  
  // Methods that modify state
  Future<void> fetchReceipts() async {
    _receipts = /* fetched data */;
    notifyListeners(); // Notify UI to rebuild
  }
}
```

**Usage in Widget**:
```dart
Consumer<ExpenseProvider>(
  builder: (context, expenseProvider, _) {
    return ListView(
      children: expenseProvider.receipts.map((r) => Text(r.vendor)).toList(),
    );
  },
)
```

### 3. **Service Layer (API & Business Logic)**

Located in `lib/services/`

**Responsibility**: Handle HTTP requests and external services

**Example ApiService**:
```dart
class ApiService {
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }
}
```

### 4. **Data Layer (Models)**

Located in `lib/models/`

**Responsibility**: Data structures and serialization

**Example Model**:
```dart
class Receipt {
  final String vendor;
  final double amount;
  
  Receipt.fromJson(Map<String, dynamic> json)
    : vendor = json['vendor'],
      amount = json['amount'].toDouble();
  
  Map<String, dynamic> toJson() => {
    'vendor': vendor,
    'amount': amount,
  };
}
```

## Data Flow Example

When user taps "Fetch Receipts":

```
User Action (Button Tap)
         ↓
    UI Layer (Widget)
         ↓
 Provider Method (fetchReceipts)
         ↓
 Service Layer (ApiService.get())
         ↓
   HTTP Request
         ↓
 Backend API Response
         ↓
 Parse JSON → Model
         ↓
Update Provider State
         ↓
Widget Rebuilds
         ↓
 User Sees Updated UI
```

## How to Extend the App

### Adding a New Feature

#### 1. Create a New Model

Create `lib/models/expense_category.dart`:
```dart
class ExpenseCategory {
  final String id;
  final String name;
  final int color;
  
  ExpenseCategory({
    required this.id,
    required this.name,
    required this.color,
  });
  
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      color: json['color'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color,
  };
}
```

#### 2. Create/Update Provider

Update `lib/providers/expense_provider.dart`:
```dart
class ExpenseProvider extends ChangeNotifier {
  List<ExpenseCategory> _categories = [];
  
  List<ExpenseCategory> get categories => _categories;
  
  Future<void> fetchCategories() async {
    try {
      final response = await _apiService.get('/categories');
      _categories = List<ExpenseCategory>.from(
        (response['data'] as List).map((x) => ExpenseCategory.fromJson(x)),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
```

#### 3. Create Screen

Create `lib/screens/categories_screen.dart`:
```dart
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return ListTile(
                title: Text(category.name),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### 4. Add Route

Update `lib/routes/app_router.dart`:
```dart
GoRoute(
  path: '/categories',
  name: 'categories',
  builder: (context, state) => const CategoriesScreen(),
),
```

#### 5. Add Navigation

Update `lib/widgets/app_drawer.dart`:
```dart
_buildDrawerItem(
  context,
  icon: Icons.category,
  title: 'Categories',
  onTap: () {
    context.go('/categories');
    Navigator.pop(context);
  },
),
```

## Customization Guide

### Changing Colors

Edit `lib/theme/app_theme.dart`:
```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1); // Change this
  static const Color secondaryColor = Color(0xFF10B981); // Change this
  // ... other colors
}
```

### Changing API Endpoints

Edit `lib/config/constants.dart`:
```dart
static const String baseUrl = 'YOUR_NEW_API_URL';
static const String receiptsEndpoint = '/custom-receipts';
```

### Adding Error Handling

In any provider method:
```dart
Future<void> fetchData() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // Do work
  } on UnauthorizedException {
    _error = 'Unauthorized';
    // Redirect to login
    AuthProvider().logout();
  } on NotFoundException {
    _error = 'Resource not found';
  } catch (e) {
    _error = 'Unexpected error: $e';
  }
  
  _isLoading = false;
  notifyListeners();
}
```

### Adding Form Validation

```dart
class _AddReceiptFormState extends State<AddReceiptForm> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'This field is required';
              }
              if (value!.length < 3) {
                return 'Must be at least 3 characters';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Process form
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

### 1. **State Management**
- ✅ Use providers for global state
- ✅ Use local setState for UI-only state
- ✅ Always call `notifyListeners()` after state change
- ❌ Don't modify state directly without notifying

### 2. **API Calls**
- ✅ Handle loading, error, and success states
- ✅ Use try-catch for error handling
- ✅ Show user feedback for long operations
- ❌ Don't block UI with synchronous operations

### 3. **Widget Design**
- ✅ Keep widgets focused and reusable
- ✅ Extract complex widgets into separate files
- ✅ Use Consumer for state consumption
- ❌ Don't pass too many parameters

### 4. **Code Organization**
- ✅ Keep files in appropriate directories
- ✅ Use meaningful naming conventions
- ✅ Comment complex logic
- ❌ Don't mix concerns in one file

## Testing

### Unit Tests Example

Create `test/models/receipt_test.dart`:
```dart
void main() {
  test('Receipt.fromJson parses JSON correctly', () {
    final json = {
      '_id': '123',
      'vendor': 'Store',
      'amount': 50.0,
      'category': 'Food',
      'date': '2024-01-15T00:00:00.000Z',
    };
    
    final receipt = Receipt.fromJson(json);
    
    expect(receipt.id, '123');
    expect(receipt.vendor, 'Store');
    expect(receipt.amount, 50.0);
  });
}
```

## Performance Optimization

1. **Use `const` constructors**:
   ```dart
   const Text('Hello') // Better than Text('Hello')
   ```

2. **Cache API responses**:
   ```dart
   List<Receipt>? _cachedReceipts;
   ```

3. **Use `RepaintBoundary` for expensive widgets**:
   ```dart
   RepaintBoundary(
     child: ExpensiveWidget(),
   )
   ```

4. **Lazy load lists**:
   ```dart
   ListView.builder() // Instead of ListView()
   ```

## Common Patterns

### Pattern 1: Loading State
```dart
if (provider.isLoading) {
  return const CircularProgressIndicator();
} else if (provider.error != null) {
  return ErrorWidget(message: provider.error!);
} else {
  return DataWidget(data: provider.data);
}
```

### Pattern 2: Refresh Pattern
```dart
RefreshIndicator(
  onRefresh: () async {
    await provider.fetchData();
  },
  child: ListView(...),
)
```

### Pattern 3: Multi-Provider
```dart
Consumer2<AuthProvider, ExpenseProvider>(
  builder: (context, authProvider, expenseProvider, _) {
    // Use both providers
  },
)
```

## Deployment Checklist

- [ ] Update app version in `pubspec.yaml`
- [ ] Update API baseUrl to production
- [ ] Test all features on real device
- [ ] Run `flutter analyze` for code quality
- [ ] Check performance with DevTools
- [ ] Update README with setup instructions
- [ ] Generate app signing keys
- [ ] Build release APK/IPA
- [ ] Test on multiple devices/Android versions

---

**Happy coding!** 🚀
