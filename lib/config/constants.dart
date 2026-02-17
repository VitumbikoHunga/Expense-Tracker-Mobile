import 'dart:io';

class AppConstants {
  // Platform-aware base URL - Android emulator uses 10.0.2.2 for host localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // For iOS simulator or physical devices, use actual IP: http://YOUR_MACHINE_IP:3000/api

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

  // Budgets
  static const String budgetsEndpoint = '/budgets';
  static const String createBudgetEndpoint = '/budgets/create';

  // Quotations
  static const String quotationsEndpoint = '/quotations';
  static const String createQuotationEndpoint = '/quotations/create';

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
