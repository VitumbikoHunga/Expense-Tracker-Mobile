import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../models/invoice.dart';
import '../models/quotation.dart';

class ExpenseProvider extends ChangeNotifier {
  
  List<Receipt> _receipts = [];
  List<Invoice> _invoices = [];
  List<Quotation> _quotations = [];
  bool _isLoading = false;
  String? _error;

  List<Receipt> get receipts => _receipts;
  List<Invoice> get invoices => _invoices;
  List<Quotation> get quotations => _quotations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculated totals for easy access across pages
  double get totalReceiptsAmount => _receipts.fold(0.0, (sum, r) => sum + r.amount);
  double get totalInvoicesPaidAmount => _invoices.where((i) => i.status == 'paid').fold(0.0, (sum, i) => sum + i.amount);
  double get totalQuotationsAmount => _quotations.fold(0.0, (sum, q) => sum + q.amount);

  Future<void> fetchReceipts() async {
    _isLoading = true;
    _error = null;

    try {
      // Mock data for demo purposes
      await Future.delayed(const Duration(milliseconds: 500));
      
      _receipts = [
        Receipt(
          id: '1',
          vendor: 'Grocery Store',
          amount: 45.99,
          category: 'Food',
          date: DateTime.now().subtract(const Duration(days: 2)),
          notes: 'Weekly groceries',
          userId: 'user_123',
        ),
        Receipt(
          id: '2',
          vendor: 'Gas Station',
          amount: 52.00,
          category: 'Transport',
          date: DateTime.now().subtract(const Duration(days: 1)),
          notes: 'Fuel',
          userId: 'user_123',
        ),
        Receipt(
          id: '3',
          vendor: 'Coffee Shop',
          amount: 5.50,
          category: 'Food',
          date: DateTime.now(),
          notes: 'Morning coffee',
          userId: 'user_123',
        ),
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReceipt(Receipt receipt) async {
    try {
      _receipts.insert(0, receipt);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchInvoices() async {
    _isLoading = true;
    _error = null;

    try {
      // Mock data for demo purposes
      await Future.delayed(const Duration(milliseconds: 500));
      
      _invoices = [
        Invoice(
          id: '1',
          invoiceNumber: 'INV-001',
          clientName: 'ABC Corp',
          amount: 1500.00,
          status: 'pending',
          invoiceDate: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().add(const Duration(days: 25)),
          description: 'Services rendered',
          userId: 'user_123',
        ),
        Invoice(
          id: '2',
          invoiceNumber: 'INV-002',
          clientName: 'XYZ Ltd',
          amount: 2500.00,
          status: 'paid',
          invoiceDate: DateTime.now().subtract(const Duration(days: 10)),
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          description: 'Project delivery',
          userId: 'user_123',
        ),
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createInvoice(Invoice invoice) async {
    try {
      // In a real app, this would be an API call
      _invoices.insert(0, invoice);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchQuotations() async {
    _isLoading = true;
    _error = null;

    try {
      // Mock data for demo purposes
      await Future.delayed(const Duration(milliseconds: 500));
      
      _quotations = [
        Quotation(
          id: '1',
          quotationNumber: 'QT-001',
          clientName: 'New Client',
          amount: 3000.00,
          status: 'draft',
          validUntil: DateTime.now().add(const Duration(days: 30)),
          description: 'Project estimation',
          userId: 'user_123',
        ),
        Quotation(
          id: '2',
          quotationNumber: 'QT-002',
          clientName: 'Potential Customer',
          amount: 5000.00,
          status: 'sent',
          validUntil: DateTime.now().add(const Duration(days: 15)),
          description: 'Website development',
          userId: 'user_123',
        ),
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuotation(Quotation quotation) async {
    try {
      _quotations.insert(0, quotation);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
