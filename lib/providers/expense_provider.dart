import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt.dart';
import '../models/invoice.dart';
import '../models/quotation.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

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
  double get totalReceiptsAmount =>
      _receipts.fold(0.0, (sum, r) => sum + r.amount);
  double get totalInvoicesPaidAmount => _invoices
      .where((i) => i.status == 'paid')
      .fold(0.0, (sum, i) => sum + i.amount);
  double get totalQuotationsAmount =>
      _quotations.fold(0.0, (sum, q) => sum + q.amount);

  /// Returns the total amount paid against a specific invoice using linked receipts.
  double amountPaidForInvoice(String? invoiceId) {
    if (invoiceId == null) return 0.0;
    return _receipts
        .where((r) => r.invoiceId == invoiceId)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  /// Returns receipts that are linked to a particular invoice.
  List<Receipt> receiptsForInvoice(String invoiceId) {
    return _receipts.where((r) => r.invoiceId == invoiceId).toList();
  }

  /// Invoice list filtered to only those currently being paid via installments.
  List<Invoice> get installmentInvoices =>
      _invoices.where((i) => i.status.toLowerCase() == 'installments').toList();

  // helper for parsing lists returned by API
  List<T> _parseList<T>(
      dynamic res, T Function(Map<String, dynamic>) fromJson) {
    if (res is List) {
      return res.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> fetchReceipts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (AppConstants.useMockApi) {
      // provide a little delay so spinner is visible
      await Future.delayed(const Duration(milliseconds: 200));
      _receipts = await _loadMockReceipts();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService().get(AppConstants.receiptsEndpoint);
      _receipts = _parseList<Receipt>(response, (x) => Receipt.fromJson(x));
    } catch (e) {
      // if API fails just leave receipts as-is and report error
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReceipt(Receipt receipt) async {
    // Helper used to update invoice status when linked
    void _maybeUpdateInvoiceStatus(String? invoiceId) {
      if (invoiceId == null) return;
      final idx = _invoices.indexWhere((i) => i.id == invoiceId);
      if (idx == -1) return;
      final invoice = _invoices[idx];
      final paidSoFar = _receipts
          .where((r) => r.invoiceId == invoiceId)
          .fold(0.0, (sum, r) => sum + r.amount);
      // if the receipt being added isn't yet in the list (mock path), include its amount
      // this method is sometimes called before insertion for mock but we'll recompute after anyway
      if (paidSoFar >= invoice.amount && invoice.status != 'paid') {
        _invoices[idx] = Invoice(
          id: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          clientName: invoice.clientName,
          clientEmail: invoice.clientEmail,
          budgetId: invoice.budgetId,
          amount: invoice.amount,
          status: 'paid',
          invoiceDate: invoice.invoiceDate,
          dueDate: invoice.dueDate,
          description: invoice.description,
          items: invoice.items,
          imageUrl: invoice.imageUrl,
          location: invoice.location,
          notes: invoice.notes,
          userId: invoice.userId,
          createdAt: invoice.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }

    if (AppConstants.useMockApi) {
      // simply prepend a fake id and add to list; ensure all fields are preserved so
      // budget/invoice links work when running with mock data.
      final created = Receipt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vendor: receipt.vendor,
        title: receipt.title,
        amount: receipt.amount,
        category: receipt.category,
        date: receipt.date,
        time: receipt.time,
        budgetId: receipt.budgetId,
        invoiceId: receipt.invoiceId,
        installments: receipt.installments,
        notes: receipt.notes,
        imageUrl: receipt.imageUrl,
        location: receipt.location,
        paymentMethod: receipt.paymentMethod,
        userId: receipt.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _receipts.insert(0, created);
      _maybeUpdateInvoiceStatus(created.invoiceId);
      await _saveMockReceipts();
      notifyListeners();
      return true;
    }

    try {
      final data = receipt.toJson();
      data.remove('id');

      final response = await ApiService().post(
        AppConstants.createReceiptEndpoint,
        data: data,
      );
      // try to convert returned object
      final created = Receipt.fromJson(response as Map<String, dynamic>);
      _receipts.insert(0, created);
      _maybeUpdateInvoiceStatus(created.invoiceId);
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
    notifyListeners();

    if (AppConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      _invoices = await _loadMockInvoices();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService().get(AppConstants.invoicesEndpoint);
      _invoices = _parseList<Invoice>(response, (x) => Invoice.fromJson(x));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createInvoice(Invoice invoice) async {
    if (AppConstants.useMockApi) {
      final created = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceNumber: invoice.invoiceNumber,
        clientName: invoice.clientName,
        amount: invoice.amount,
        status: invoice.status,
        invoiceDate: invoice.invoiceDate,
        dueDate: invoice.dueDate,
        userId: invoice.userId,
      );
      _invoices.insert(0, created);
      await _saveMockInvoices();
      notifyListeners();
      return true;
    }

    try {
      final data = invoice.toJson();
      data.remove('id');
      final response = await ApiService().post(
        AppConstants.createInvoiceEndpoint,
        data: data,
      );
      final created = Invoice.fromJson(response as Map<String, dynamic>);
      _invoices.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sends the generated receipt for an invoice to the client's email.
  /// Only invoices already marked as paid should invoke this.
  Future<bool> sendInvoiceReceipt(String invoiceId) async {
    if (AppConstants.useMockApi) {
      // in mock mode just pretend it worked after a small delay
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    }

    try {
      await ApiService().post(
        '${AppConstants.invoicesEndpoint}/$invoiceId/send-receipt',
        data: {},
      );
      // ignore response body for now
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
    notifyListeners();

    if (AppConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      _quotations = [
        Quotation(
          id: 'q1',
          quotationNumber: 'QUO-001',
          clientName: 'Mock Client',
          amount: 150.0,
          status: 'pending',
          validUntil: DateTime.now().add(const Duration(days: 30)),
          userId: '1',
        )
      ];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService().get(AppConstants.quotationsEndpoint);
      _quotations =
          _parseList<Quotation>(response, (x) => Quotation.fromJson(x));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createQuotation(Quotation quotation) async {
    if (AppConstants.useMockApi) {
      final created = Quotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quotationNumber: quotation.quotationNumber,
        clientName: quotation.clientName,
        amount: quotation.amount,
        status: quotation.status,
        validUntil: quotation.validUntil,
        userId: quotation.userId,
      );
      _quotations.insert(0, created);
      notifyListeners();
      return true;
    }

    try {
      final data = quotation.toJson();
      data.remove('id');
      final response = await ApiService().post(
        AppConstants.createQuotationEndpoint,
        data: data,
      );
      final created = Quotation.fromJson(response as Map<String, dynamic>);
      _quotations.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Deletes a receipt. Returns a map containing success flag and
  /// the amount of the deleted receipt (0 if not found).
  Future<Map<String, dynamic>> deleteReceipt(String id) async {
    double deletedAmount = 0;
    String? budgetId;

    // find existing receipt
    final existing = _receipts.firstWhere((r) => r.id == id,
        orElse: () => Receipt(
            vendor: '',
            amount: 0,
            category: '',
            date: DateTime.now(),
            userId: ''));
    if (existing.id != null) {
      deletedAmount = existing.amount;
      budgetId = existing.budgetId;
    }

    if (AppConstants.useMockApi) {
      _receipts.removeWhere((r) => r.id == id);
      await _saveMockReceipts();
      notifyListeners();
      return {'success': true, 'amount': deletedAmount, 'budgetId': budgetId};
    }

    try {
      await ApiService().delete('${AppConstants.receiptsEndpoint}/$id');
      _receipts.removeWhere((r) => r.id == id);
      notifyListeners();
      return {'success': true, 'amount': deletedAmount, 'budgetId': budgetId};
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'amount': deletedAmount, 'budgetId': budgetId};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Return receipts matching the given budget ID.
  List<Receipt> receiptsForBudget(String budgetId) {
    return _receipts.where((r) => r.budgetId == budgetId).toList();
  }

  // --- mock persistence helpers --------------------------------------------------
  static const _receiptsKey = 'mock_receipts';
  static const _invoicesKey = 'mock_invoices';

  Future<List<Receipt>> _loadMockReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_receiptsKey);
    if (jsonString == null) {
      return [
        Receipt(
          id: 'r1',
          vendor: 'Mock Store',
          amount: 25.0,
          category: 'Food',
          date: DateTime.now(),
          userId: '1',
        )
      ];
    }
    final List decoded = json.decode(jsonString) as List;
    return decoded
        .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveMockReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_receipts.map((r) => r.toJson()).toList());
    await prefs.setString(_receiptsKey, jsonString);
  }

  Future<List<Invoice>> _loadMockInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_invoicesKey);
    if (jsonString == null) {
      return [
        Invoice(
          id: 'i1',
          invoiceNumber: 'INV-001',
          clientName: 'Mock Client',
          amount: 100.0,
          status: 'paid',
          invoiceDate: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().add(const Duration(days: 25)),
          userId: '1',
        )
      ];
    }
    final List decoded = json.decode(jsonString) as List;
    return decoded
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveMockInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_invoices.map((i) => i.toJson()).toList());
    await prefs.setString(_invoicesKey, jsonString);
  }
}
