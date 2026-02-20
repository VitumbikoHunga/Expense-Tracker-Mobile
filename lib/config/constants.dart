import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // Platform-aware base URL. When running on the web the browser can reach the
  // backend via localhost; on an Android emulator we need to hit 10.0.2.2.
  // Physical devices or iOS simulators should use your machine's IP or `localhost`
  // as appropriate. You can adjust this getter or override in your own build
  // configuration.
  static String get baseUrl {
    if (kIsWeb) {
      // web builds run in a browser which sees your dev server as localhost
      return 'http://localhost:3000/api';
    }
    // default to Android emulator address; change manually if you run on device
    return 'http://10.0.2.2:3000/api';
  }

  // When you don't have a backend available yet you can run entirely against
  // mocked data. Flip to `false` once your API is up and running.
  static const bool useMockApi = true;

  // API Endpoints
  static const String loginEndpoint = '/users/login';
  static const String registerEndpoint = '/users/register';
  static const String getUserEndpoint = '/users/profile';

  // Receipts
  static const String receiptsEndpoint = '/receipts';
  static const String createReceiptEndpoint = '/receipts/create';
  static const String uploadReceiptEndpoint = '/receipts/upload';

  // Invoices
  static const String invoicesEndpoint = '/invoices';
  static const String createInvoiceEndpoint = '/invoices/create';
  static const String sendInvoiceReceiptEndpoint =
      '/invoices'; // base used with /{id}/send-receipt

  // Budgets
  static const String budgetsEndpoint = '/budgets';
  static const String createBudgetEndpoint = '/budgets/create';

  // Quotations
  static const String quotationsEndpoint = '/quotations';
  static const String createQuotationEndpoint = '/quotations/create';

  // Categories
  static const String categoriesEndpoint = '/categories';
  // (additional category endpoints such as create/delete may be derived from this)

  // System
  static const String systemLogsEndpoint = '/system-logs';
  static const String testDbEndpoint = '/test-db';

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
}
