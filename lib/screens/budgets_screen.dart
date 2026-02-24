import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
// removed unused import
import '../widgets/app_drawer.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController _categoryController;
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _limitController = TextEditingController();
    // ensure both budgets and receipts are loaded so that budget items
    // can show related receipts and remaining amounts update correctly
    context.read<BudgetProvider>().fetchBudgets();
    context.read<ExpenseProvider>().fetchReceipts();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    _categoryController.clear();
    _limitController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Food, Transport',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _limitController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit (MK)',
                  hintText: 'e.g., 500000',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_categoryController.text.isEmpty ||
                  _limitController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final success = await context.read<BudgetProvider>().createBudget(
                    _categoryController.text,
                    double.parse(_limitController.text),
                  );

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget set successfully')),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Budgets'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Template download mock
            },
            child:
                const Text('Download Template', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Set Budget'),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await budgetProvider.fetchBudgets();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budgets',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards (wrap to next line on narrow screens)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSummaryCard(
                        context,
                        'Total Budget',
                        'MK${budgetProvider.totalBudgetLimit.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      _buildSummaryCard(
                        context,
                        'Total Spent',
                        'MK${budgetProvider.totalSpent.toStringAsFixed(2)}',
                        Icons.trending_down,
                        Colors.red,
                      ),
                      _buildSummaryCard(
                        context,
                        'Remaining',
                        'MK${budgetProvider.remainingBudget.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (budgetProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'Error: ${budgetProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (budgetProvider.budgets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No budgets set for this month'),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(builder: (ctx, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final columns = screenWidth > 600 ? 3 : 2;
                      final spacing = 12.0;
                      // calculate a width per item taking into account spacing
                      final itemWidth =
                          (screenWidth - (columns + 1) * spacing) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: budgetProvider.budgets.map((budget) {
                          return SizedBox(
                            width: itemWidth,
                            child: _buildBudgetItem(context, budget),
                          );
                        }).toList(),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String amount,
      IconData icon, Color color) {
    // simple card that can shrink on narrow screens
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(amount,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: title == 'Total Spent'
                              ? Colors.red
                              : (title == 'Remaining'
                                  ? Colors.green
                                  : Colors.black)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(BuildContext context, dynamic budget) {
    // listen to receipts so we can display linked ones under this budget
    final receipts =
        context.watch<ExpenseProvider>().receiptsForBudget(budget.id);
    final double percentage =
        budget.limit > 0 ? (budget.spent / budget.limit) : 0;
    final bool isComplete = budget.spent >= budget.limit;
    final bool isExceeded = budget.spent > budget.limit;
    final double remaining = budget.limit - budget.spent;
    final String statusText =
        isComplete ? 'Done' : (isExceeded ? 'Over Budget' : 'On Track');
    final Color statusColor =
        isComplete ? Colors.red : (isExceeded ? Colors.red : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text('Monthly Budget',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined, size: 20)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      (isComplete || isExceeded)
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 14,
                      color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Spent',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Flexible(
                  child: Text('MK${budget.spent.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage > 1 ? 1 : percentage,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? Colors.red : Colors.grey[400]!),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Budget',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Flexible(
                  child: Text('MK${budget.limit.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'MK${remaining.toStringAsFixed(2)} ${remaining >= 0 ? 'remaining' : 'over budget'}',
              style: TextStyle(
                color: remaining >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: receipts.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No receipts linked to this budget.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              ]
            : receipts
                .map((r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.vendor ?? r.title ?? 'Receipt'),
                      subtitle: Text(
                          'MK${r.amount.toStringAsFixed(2)}  •  ${DateFormat.yMMMd().format(r.date)}'),
                    ))
                .toList(),
      ),
    );
  }
}
