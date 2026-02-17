import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/invoice.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().fetchInvoices();
  }

  void _showGenerateInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => const GenerateInvoiceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Invoices'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGenerateInvoiceDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.fetchInvoices();
            },
            child: expenseProvider.invoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenseProvider.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = expenseProvider.invoices[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              invoice.clientName.isNotEmpty
                                  ? invoice.clientName.substring(0, 1)
                                  : '?',
                              style:
                                  const TextStyle(color: AppTheme.primaryColor),
                            ),
                          ),
                          title: Text(invoice.invoiceNumber),
                          subtitle:
                              Text('${invoice.clientName} • ${invoice.status}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'MK ${invoice.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(invoice.dueDate),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class GenerateInvoiceDialog extends StatefulWidget {
  const GenerateInvoiceDialog({super.key});

  @override
  State<GenerateInvoiceDialog> createState() => _GenerateInvoiceDialogState();
}

class _GenerateInvoiceDialogState extends State<GenerateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController(
      text: 'INV-${DateFormat('HHmmss').format(DateTime.now())}');
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _budgetIdController = TextEditingController();
  final _notesController = TextEditingController();

  String _status = 'Draft';
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  final List<InvoiceItemRow> _items = [];
  File? _attachment;
  String? _location;
  bool _isCapturingLocation = false;

  @override
  void initState() {
    super.initState();
    _addItem(); // Start with one empty item
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItemRow(
        onChanged: () => setState(() {}),
        onRemove: (item) {
          if (_items.length > 1) {
            setState(() => _items.remove(item));
          }
        },
      ));
    });
  }

  double get _totalAmount {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _attachment = File(pickedFile.path));
    }
  }

  // Open the device camera explicitly and prefer rear camera where available
  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (pickedFile != null) {
      setState(() => _attachment = File(pickedFile.path));
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _location =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _isCapturingLocation = false);
    }
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
                  Text('Generate Invoice',
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                                _invoiceNumberController, 'Invoice Number'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                                'Status', ['Draft', 'Pending', 'Paid'], _status,
                                (val) {
                              setState(() => _status = val!);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(
                                  _clientNameController, 'Client Name *',
                                  required: true)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextField(
                                  _clientEmailController, 'Client Email')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _budgetIdController, 'Budget ID (optional)'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                                'Invoice Date *', _invoiceDate, (date) {
                              setState(() => _invoiceDate = date);
                            }),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                _buildDatePicker('Due Date', _dueDate, (date) {
                              setState(() => _dueDate = date);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Line Items',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      ..._items,
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: MK ${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Invoice Attachment (Photo)',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _buildAttachmentArea(),
                      const SizedBox(height: 24),
                      Text('Location',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed:
                            _isCapturingLocation ? null : _captureLocation,
                        icon: _isCapturingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.location_on_outlined),
                        label: Text(_location ?? 'Capture Location'),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_notesController, 'Notes', maxLines: 3),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Generate Invoice'),
                        ),
                      ),
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

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: label.replaceAll(' *', ''),
          ),
          validator: required
              ? (val) => val == null || val.isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? selectedDate, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) onPicked(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedDate != null
                    ? DateFormat('MM/dd/yyyy').format(selectedDate)
                    : 'mm/dd/yyyy'),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentArea() {
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
          if (_attachment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(_attachment!, height: 100, fit: BoxFit.cover),
                  IconButton(
                    onPressed: () => setState(() => _attachment = null),
                    icon: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      final invoice = Invoice(
        id: 'invoice_${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: _invoiceNumberController.text,
        clientName: _clientNameController.text,
        clientEmail: _clientEmailController.text,
        budgetId: _budgetIdController.text,
        amount: _totalAmount,
        status: _status.toLowerCase(),
        invoiceDate: _invoiceDate,
        dueDate: _dueDate ?? _invoiceDate.add(const Duration(days: 30)),
        items: _items.map((e) => e.toItem()).toList(),
        imageUrl: _attachment?.path,
        location: _location,
        notes: _notesController.text,
        userId: authProvider.user?.id ?? 'unknown',
        createdAt: DateTime.now(),
      );

      final success = await expenseProvider.createInvoice(invoice);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice generated successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(expenseProvider.error ?? 'Failed to create invoice')));
        }
      }
    }
  }
}

class InvoiceItemRow extends StatelessWidget {
  final VoidCallback onChanged;
  final Function(InvoiceItemRow) onRemove;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController unitPriceController =
      TextEditingController(text: '0');

  InvoiceItemRow({super.key, required this.onChanged, required this.onRemove}) {
    quantityController.addListener(onChanged);
    unitPriceController.addListener(onChanged);
  }

  double get total {
    final qty = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0;
    return qty * price;
  }

  InvoiceItem toItem() {
    return InvoiceItem(
      description: descriptionController.text,
      quantity: double.tryParse(quantityController.text) ?? 0,
      unitPrice: double.tryParse(unitPriceController.text) ?? 0,
      total: total,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                  hintText: 'Description',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: unitPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Text('MK${total.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          IconButton(
              onPressed: () => onRemove(this),
              icon: const Icon(Icons.delete_outline,
                  color: Colors.grey, size: 20)),
        ],
      ),
    );
  }
}
