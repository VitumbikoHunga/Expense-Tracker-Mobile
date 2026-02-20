import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import '../models/receipt.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) {
        return InstallmentDetailDialog(invoice: invoice);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Installments'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expProv, _) {
          final invoices = expProv.installmentInvoices;
          if (expProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (invoices.isEmpty) {
            return const Center(
              child: Text(
                'No installments invoices at the moment.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              final paid = expProv.amountPaidForInvoice(inv.id);
              final remaining = inv.amount - paid;
              return Card(
                child: ListTile(
                  title: Text(inv.invoiceNumber),
                  subtitle: Text(
                      'Client: ${inv.clientName}\nPaid: MK ${paid.toStringAsFixed(2)}\nRemaining: MK ${remaining.toStringAsFixed(2)}'),
                  isThreeLine: true,
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showInvoiceDetails(inv),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Dialog showing details for a single invoice under installments
class InstallmentDetailDialog extends StatelessWidget {
  final Invoice invoice;
  const InstallmentDetailDialog({required this.invoice, super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8, maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Invoice ${invoice.invoiceNumber}',
                    style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            Consumer<ExpenseProvider>(
              builder: (context, expProv, _) {
                final receipts = expProv.receiptsForInvoice(invoice.id!);
                final paid = expProv.amountPaidForInvoice(invoice.id);
                final remaining = invoice.amount - paid;
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Total: MK ${invoice.amount.toStringAsFixed(2)}'),
                      Text('Paid: MK ${paid.toStringAsFixed(2)}'),
                      Text('Remaining: MK ${remaining.toStringAsFixed(2)}'),
                      const SizedBox(height: 16),
                      const Text('Payments',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (receipts.isEmpty)
                        const Text('No payments recorded yet')
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: receipts.length,
                            itemBuilder: (context, i) {
                              final r = receipts[i];
                              return ListTile(
                                title: Text(r.vendor),
                                subtitle: Text(
                                    'MK ${r.amount.toStringAsFixed(2)} • ${DateFormat('MMM dd, yyyy').format(r.date)}'),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: remaining <= 0
                            ? null
                            : () => _showAddPaymentDialog(context, remaining),
                        child: const Text('Add Payment'),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, double maxAmount) {
    final _vendorController = TextEditingController();
    final _amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Add Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _vendorController,
                    decoration: const InputDecoration(labelText: 'Vendor'),
                  ),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText:
                            'Amount (max MK ${maxAmount.toStringAsFixed(2)})'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100));
                        if (date != null) selectedDate = date;
                      },
                      child: const Text('Select Date')),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (amount <= 0 || amount > maxAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Amount must be between 0 and ${maxAmount.toStringAsFixed(2)}')));
                      return;
                    }
                    final authProv = context.read<AuthProvider>();
                    final receipt = Receipt(
                      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                      vendor: _vendorController.text,
                      amount: amount,
                      category: invoice.invoiceNumber,
                      date: selectedDate,
                      userId: authProv.user?.id ?? 'unknown',
                      invoiceId: invoice.id,
                    );
                    final success = await context
                        .read<ExpenseProvider>()
                        .createReceipt(receipt);
                    if (success) {
                      Navigator.pop(ctx); // close add dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment recorded')));
                      // after saving we may need to dismiss the detail window if invoice is complete
                      final expProv = context.read<ExpenseProvider>();
                      final paid = expProv.amountPaidForInvoice(invoice.id);
                      if (paid >= invoice.amount) {
                        // pop the surrounding dialog
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Invoice completed and moved to Invoices page')));
                      }
                      // detail dialog listens via Consumer so it will refresh if still open
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(context.read<ExpenseProvider>().error ??
                              'Failed to save payment')));
                    }
                  },
                  child: const Text('Save'))
            ],
          );
        });
  }
}
