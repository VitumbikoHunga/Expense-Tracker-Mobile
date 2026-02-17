import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/quotation.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().fetchQuotations();
  }

  void _showCreateQuotationDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateQuotationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Quotations'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateQuotationDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.fetchQuotations();
            },
            child: expenseProvider.quotations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No quotations yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Create your first quotation to get started'),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showCreateQuotationDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Quotation'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenseProvider.quotations.length,
                    itemBuilder: (context, index) {
                      final quotation = expenseProvider.quotations[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.request_quote, color: AppTheme.primaryColor),
                          ),
                          title: Text(quotation.quotationNumber),
                          subtitle: Text('${quotation.clientName} • ${quotation.status}'),
                          trailing: Text(
                            'MK ${quotation.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
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

class CreateQuotationDialog extends StatefulWidget {
  const CreateQuotationDialog({super.key});

  @override
  State<CreateQuotationDialog> createState() => _CreateQuotationDialogState();
}

class _CreateQuotationDialogState extends State<CreateQuotationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<QuotationItemRow> _items = [];
  bool _isCapturingLocation = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  void _addItem() {
    setState(() {
      _items.add(QuotationItemRow(
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Quotation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_clientNameController, 'Client Name *', required: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_clientEmailController, 'Client Email')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_descriptionController, 'Description', maxLines: 3),
                      const SizedBox(height: 16),
                      Text('Location (Optional)', style: Theme.of(context).textTheme.bodySmall),
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
                              : const Icon(Icons.location_on, size: 18),
                            label: const Text('Capture'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add Item')),
                        ],
                      ),
                      ..._items,
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: MK ${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_notesController, 'Additional notes', maxLines: 3),
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
                              child: const Text('Create Quotation', style: TextStyle(color: Colors.white)),
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

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      
      final quotation = Quotation(
        id: 'qt_${DateTime.now().millisecondsSinceEpoch}',
        quotationNumber: 'QT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        clientName: _clientNameController.text,
        clientEmail: _clientEmailController.text,
        description: _descriptionController.text,
        amount: _totalAmount,
        status: 'draft',
        validUntil: DateTime.now().add(const Duration(days: 30)),
        items: _items.map((e) => e.toItem()).toList(),
        location: _locationController.text,
        notes: _notesController.text,
        userId: authProvider.user?.id ?? 'unknown',
        createdAt: DateTime.now(),
      );

      final success = await expenseProvider.createQuotation(quotation);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation created successfully')));
        }
      }
    }
  }
}

class QuotationItemRow extends StatelessWidget {
  final VoidCallback onChanged;
  final Function(QuotationItemRow) onRemove;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController unitPriceController = TextEditingController(text: '0');

  QuotationItemRow({super.key, required this.onChanged, required this.onRemove}) {
    quantityController.addListener(onChanged);
    unitPriceController.addListener(onChanged);
  }

  double get total {
    final qty = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0;
    return qty * price;
  }

  QuotationItem toItem() {
    return QuotationItem(
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
              decoration: const InputDecoration(hintText: 'Description', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: unitPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Text('MK${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          IconButton(onPressed: () => onRemove(this), icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20)),
        ],
      ),
    );
  }
}
