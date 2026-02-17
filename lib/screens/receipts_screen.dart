import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
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
    context.read<CategoryProvider>().fetchCategories();
  }

  void _showAddReceiptDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddReceiptDialog(),
    );
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
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                          ),
                          title: Text(receipt.title ?? receipt.vendor),
                          subtitle: Text('${receipt.category} • ${DateFormat('MMM dd, yyyy').format(receipt.date)}'),
                          trailing: Text(
                            'MK ${receipt.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
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

class AddReceiptDialog extends StatefulWidget {
  const AddReceiptDialog({super.key});

  @override
  State<AddReceiptDialog> createState() => _AddReceiptDialogState();
}

class _AddReceiptDialogState extends State<AddReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _budgetIdController = TextEditingController();
  final _invoiceIdController = TextEditingController();
  final _installmentsController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
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
    final pickedFile = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
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
        _locationController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error capturing location: $e')));
      }
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Receipt', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
                      Text('Receipt Photo', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _buildPhotoArea(),
                      const SizedBox(height: 24),
                      _buildTextField(_titleController, 'Title *', required: true, hint: 'e.g., Lunch at restaurant'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_amountController, 'Amount *', required: true, keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              'Category',
                              categories.map((e) => e.name).toList(),
                              _selectedCategory,
                              (val) => setState(() => _selectedCategory = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker('Date *', _selectedDate, (date) {
                              setState(() => _selectedDate = date);
                            }),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimePicker('Time', _selectedTime, (time) {
                              setState(() => _selectedTime = time);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_budgetIdController, 'Budget ID (optional)', hint: 'MongoDB ID')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_invoiceIdController, 'Invoice ID (optional)', hint: 'MongoDB ID')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_installmentsController, 'Installments', keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      Text('Location', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Main Street, City',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isCapturingLocation ? null : _captureLocation,
                            icon: _isCapturingLocation 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 18),
                            label: const Text('Capture'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_notesController, 'Notes', maxLines: 3, hint: 'Additional notes...'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
                              onPressed: _submit,
                              child: const Text('Save Receipt', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
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

  Widget _buildPhotoArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
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
                    icon: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('Upload a photo or capture with camera', style: TextStyle(fontSize: 12)),
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

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, TextInputType? keyboardType, int maxLines = 1, String? hint}) {
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime selectedDate, Function(DateTime) onPicked) {
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
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
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

  Widget _buildTimePicker(String label, TimeOfDay selectedTime, Function(TimeOfDay) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(context: context, initialTime: selectedTime);
            if (time != null) onPicked(time);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
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
      final authProvider = context.read<AuthProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      
      final receipt = Receipt(
        id: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        vendor: _titleController.text, // Using title as vendor for backward compatibility
        title: _titleController.text,
        amount: double.tryParse(_amountController.text) ?? 0,
        category: _selectedCategory ?? 'Other',
        date: _selectedDate,
        time: _selectedTime.format(context),
        budgetId: _budgetIdController.text,
        invoiceId: _invoiceIdController.text,
        installments: int.tryParse(_installmentsController.text),
        notes: _notesController.text,
        location: _locationController.text,
        imageUrl: _receiptPhoto?.path,
        userId: authProvider.user?.id ?? 'unknown',
        createdAt: DateTime.now(),
      );

      final success = await expenseProvider.createReceipt(receipt);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt saved successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(expenseProvider.error ?? 'Failed to save receipt')));
        }
      }
    }
  }
}
