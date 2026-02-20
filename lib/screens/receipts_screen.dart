import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../models/invoice.dart';
import '../models/receipt.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().fetchReceipts();
    // fetch supporting lists
    context.read<BudgetProvider>().fetchBudgets();
    context.read<ExpenseProvider>().fetchInvoices();
  }

  void _showAddReceiptDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddReceiptDialog(),
    );
  }

  Future<Uint8List> _buildPdfForReceipts(List<Receipt> list) async {
    final doc = pw.Document();
    for (final r in list) {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('Receipt',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(7),
                  },
                  children: [
                    _pdfTableRow('Vendor', r.title ?? r.vendor),
                    _pdfTableRow('Amount', 'MK ${r.amount.toStringAsFixed(2)}'),
                    _pdfTableRow('Category', r.category),
                    _pdfTableRow(
                        'Date', DateFormat('MMM dd, yyyy').format(r.date)),
                    if (r.notes != null && r.notes!.isNotEmpty)
                      _pdfTableRow('Notes', r.notes!),
                  ],
                ),
                pw.Spacer(),
                pw.Text(
                  'Generated on ${DateFormat('MMM dd, yyyy – kk:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            ),
          );
        },
      ));
    }
    return doc.save();
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(value)),
    ]);
  }

  Future<void> _downloadAllReceipts() async {
    final expenseProvider = context.read<ExpenseProvider>();
    if (expenseProvider.receipts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No receipts to download')));
      return;
    }
    final bytes = await _buildPdfForReceipts(expenseProvider.receipts);
    await Printing.sharePdf(
        bytes: bytes, filename: 'all_receipts_${DateTime.now()}.pdf');
  }

  Future<void> _viewReceipt(Receipt r) async {
    final bytes = await _buildPdfForReceipts([r]);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }

  Future<void> _downloadReceipt(Receipt r) async {
    final bytes = await _buildPdfForReceipts([r]);
    await Printing.sharePdf(
        bytes: bytes, filename: 'receipt_${r.id ?? ''}.pdf');
  }

  Future<void> _deleteReceipt(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Receipt'),
            content:
                const Text('Are you sure you want to delete this receipt?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final result = await expenseProvider.deleteReceipt(id);
    if (!mounted) return;
    final success = result['success'] as bool? ?? false;
    final deletedAmount = result['amount'] as double? ?? 0;
    final budgetId = result['budgetId'] as String?;
    if (success && budgetId != null && budgetId.isNotEmpty) {
      budgetProvider.removeFromBudget(budgetId, deletedAmount);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Receipt deleted'
            : 'Failed to delete receipt: ${expenseProvider.error}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Receipts'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download all receipts',
            onPressed: _downloadAllReceipts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReceiptDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.fetchReceipts();
            },
            child: Column(
              children: [
                if (expenseProvider.error != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      'Error: ${expenseProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: expenseProvider.receipts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No receipts found',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: expenseProvider.receipts.length,
                          itemBuilder: (context, index) {
                            final receipt = expenseProvider.receipts[index];
                            return Card(
                              child: ListTile(
                                onTap: () => _viewReceipt(receipt),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                title: Text(receipt.title ?? receipt.vendor),
                                subtitle: Text(
                                    '${receipt.category} • ${DateFormat('MMM dd, yyyy').format(receipt.date)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'MK ${receipt.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        switch (value) {
                                          case 'view':
                                            await _viewReceipt(receipt);
                                            break;
                                          case 'download':
                                            await _downloadReceipt(receipt);
                                            break;
                                          case 'delete':
                                            await _deleteReceipt(
                                                receipt.id ?? '');
                                            break;
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Text('View'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'download',
                                          child: Text('Download'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ), // end Expanded
              ], // end Column children
            ), // end Column
          ); // end RefreshIndicator
        },
      ),
    );
  }
}

class AddReceiptDialog extends StatefulWidget {
  const AddReceiptDialog({super.key});

  @override
  State<AddReceiptDialog> createState() => _AddReceiptDialogState();
}

class _AddReceiptDialogState extends State<AddReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _linkType; // 'Budget' or 'Invoice'
  String? _selectedBudgetName;
  String? _selectedInvoiceNumber;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  File? _receiptPhoto;
  bool _isCapturingLocation = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _receiptPhoto = File(pickedFile.path));
    }
  }

  // Open the device camera explicitly and prefer rear camera where available
  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (pickedFile != null) {
      setState(() => _receiptPhoto = File(pickedFile.path));
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error capturing location: $e')));
      }
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  // simple helper row that wraps on small width
  Widget _responsiveRow(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 500) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children
              .map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: w,
                  ))
              .toList(),
        );
      }
      final spaced = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        spaced.add(Expanded(child: children[i]));
        if (i < children.length - 1) spaced.add(const SizedBox(width: 16));
      }
      return Row(children: spaced);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Receipt',
                      style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt Photo',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _buildPhotoArea(),
                      const SizedBox(height: 24),
                      _buildTextField(_titleController, 'Title *',
                          required: true, hint: 'e.g., Lunch at restaurant'),
                      const SizedBox(height: 16),
                      _responsiveRow([
                        _buildTextField(_amountController, 'Amount *',
                            required: true, keyboardType: TextInputType.number),
                        _buildDropdownField(
                          'Link Type',
                          ['None', 'Budget', 'Invoice'],
                          _linkType,
                          (val) => setState(() => _linkType = val),
                        ),
                      ]),
                      if (_linkType == 'Budget')
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: _buildDropdownField(
                            'Budget',
                            context
                                .watch<BudgetProvider>()
                                .budgets
                                .where((b) => b.spent < b.limit)
                                .map((b) => b.category)
                                .toList(),
                            _selectedBudgetName,
                            (val) => setState(() => _selectedBudgetName = val),
                          ),
                        ),
                      if (_linkType == 'Invoice')
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: _buildDropdownField(
                            'Invoice',
                            context
                                .watch<ExpenseProvider>()
                                .invoices
                                .where((i) => i.status.toLowerCase() != 'paid')
                                .map((i) => i.invoiceNumber)
                                .toList(),
                            _selectedInvoiceNumber,
                            (val) =>
                                setState(() => _selectedInvoiceNumber = val),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _responsiveRow([
                        _buildDatePicker('Date *', _selectedDate, (date) {
                          setState(() => _selectedDate = date);
                        }),
                        _buildTimePicker('Time', _selectedTime, (time) {
                          setState(() => _selectedTime = time);
                        }),
                      ]),
                      const SizedBox(height: 16),
                      // budget/invoice association handled above via link type
                      Text('Location',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      _responsiveRow([
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Main Street, City',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _isCapturingLocation ? null : _captureLocation,
                          icon: _isCapturingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 18),
                          label: const Text('Capture'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildTextField(_notesController, 'Notes',
                          maxLines: 3, hint: 'Additional notes...'),
                      const SizedBox(height: 24),
                      _responsiveRow([
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A5F)),
                          onPressed: _submit,
                          child: const Text('Save Receipt',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (_receiptPhoto != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(_receiptPhoto!, height: 150, fit: BoxFit.cover),
                  IconButton(
                    onPressed: () => setState(() => _receiptPhoto = null),
                    icon: const CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child:
                            Icon(Icons.close, size: 16, color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('Upload a photo or capture with camera',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.upload),
                label: const Text('Upload'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false,
      TextInputType? keyboardType,
      int maxLines = 1,
      String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: required
              ? (val) => val == null || val.isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? value,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        options.isEmpty
            ? Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('No options available',
                    style: TextStyle(color: Colors.grey[600])),
              )
            : DropdownButtonFormField<String>(
                initialValue: value,
                items: options
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, DateTime selectedDate, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) onPicked(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MM/dd/yyyy').format(selectedDate)),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
      String label, TimeOfDay selectedTime, Function(TimeOfDay) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
                context: context, initialTime: selectedTime);
            if (time != null) onPicked(time);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedTime.format(context)),
                const Icon(Icons.access_time, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // ensure link selections are made if required
      if (_linkType == 'Budget' && _selectedBudgetName == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a budget to associate')));
        return;
      }
      if (_linkType == 'Invoice' && _selectedInvoiceNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select an invoice to associate')));
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      final receipt = Receipt(
        id: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        vendor: _titleController
            .text, // Using title as vendor for backward compatibility
        title: _titleController.text,
        amount: double.tryParse(_amountController.text) ?? 0,
        category: _linkType == 'Budget'
            ? (_selectedBudgetName ?? 'Budget')
            : _linkType == 'Invoice'
                ? (_selectedInvoiceNumber ?? 'Invoice')
                : 'Other',
        date: _selectedDate,
        time: _selectedTime.format(context),
        budgetId: _linkType == 'Budget'
            ? context
                .read<BudgetProvider>()
                .budgets
                .firstWhere((b) => b.category == _selectedBudgetName,
                    orElse: () => Budget(
                        id: '',
                        category: '',
                        limit: 0,
                        spent: 0,
                        period: '',
                        startDate: DateTime.now(),
                        endDate: DateTime.now(),
                        userId: ''))
                .id
            : null,
        invoiceId: _linkType == 'Invoice'
            ? context
                .read<ExpenseProvider>()
                .invoices
                .firstWhere((i) => i.invoiceNumber == _selectedInvoiceNumber,
                    orElse: () => Invoice(
                        id: '',
                        invoiceNumber: '',
                        clientName: '',
                        amount: 0,
                        status: '',
                        invoiceDate: DateTime.now(),
                        dueDate: DateTime.now(),
                        userId: ''))
                .id
            : null,
        notes: _notesController.text,
        location: _locationController.text,
        imageUrl: _receiptPhoto?.path,
        userId: authProvider.user?.id ?? 'unknown',
        createdAt: DateTime.now(),
      );

      // before attempting to create a receipt, ensure budget still has room
      if (receipt.budgetId != null && receipt.budgetId!.isNotEmpty) {
        final budgetProvider = context.read<BudgetProvider>();
        final bool full = budgetProvider.budgets
            .any((b) => b.id == receipt.budgetId && b.spent >= b.limit);
        if (full) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Budget is fully used; cannot add more receipts')));
          return;
        }
      }

      // if this receipt is linked to an invoice we must ensure the invoice
      // is not already paid and that the amount doesn't exceed the remaining
      if (receipt.invoiceId != null && receipt.invoiceId!.isNotEmpty) {
        final expProv = context.read<ExpenseProvider>();
        final inv = expProv.invoices.firstWhere(
            (i) => i.id == receipt.invoiceId,
            orElse: () => Invoice(
                id: '',
                invoiceNumber: '',
                clientName: '',
                amount: 0,
                status: '',
                invoiceDate: DateTime.now(),
                dueDate: DateTime.now(),
                userId: ''));
        if (inv.id!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to locate linked invoice')));
          return;
        }
        if (inv.status.toLowerCase() == 'paid') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Invoice already paid; cannot add receipt')));
          return;
        }
        final paid = expProv.amountPaidForInvoice(inv.id);
        final remaining = inv.amount - paid;
        if (receipt.amount > remaining) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Receipt exceeds remaining balance (MK ${remaining.toStringAsFixed(2)})')));
          return;
        }
      }

      final success = await expenseProvider.createReceipt(receipt);

      if (!mounted) return;
      
      final budgetProvider = context.read<BudgetProvider>();

      if (success) {
        // update budget totals if linked
        if (receipt.budgetId != null && receipt.budgetId!.isNotEmpty) {
          budgetProvider.addToBudget(receipt.budgetId!, receipt.amount);
        }
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt saved successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(expenseProvider.error ?? 'Failed to save receipt')));
        }
      }
    }
  }
}
