import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

// simple helper class for report buckets (day or month)
class _Bucket {
  final String label;
  final DateTime start;
  final DateTime end;
  _Bucket(this.label, this.start, this.end);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPeriod = 'Last 6 months';
  DateTime? _specificDate;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().fetchReceipts();
    context.read<ExpenseProvider>().fetchInvoices();
    context.read<BudgetProvider>().fetchBudgets();
  }

  Map<String, double> _buildCategoryExpenses(ExpenseProvider provider) {
    final expenses = <String, double>{};
    for (var receipt in provider.receipts) {
      expenses[receipt.category] =
          (expenses[receipt.category] ?? 0) + receipt.amount;
    }
    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          _buildPeriodDropdown(),
        ],
      ),
      body: Consumer2<ExpenseProvider, BudgetProvider>(
        builder: (context, expenseProvider, budgetProvider, _) {
          final categoryExpenses = _buildCategoryExpenses(expenseProvider);
          final totalExpenses = expenseProvider.totalReceiptsAmount;
          final totalEarnings = expenseProvider.totalInvoicesPaidAmount;
          final netBalance = totalEarnings - totalExpenses;

          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.fetchReceipts();
              await expenseProvider.fetchInvoices();
              await budgetProvider.fetchBudgets();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Analyze your spending and earnings patterns',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards (wrap instead of scrolling)
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildSummaryCard(
                        'Total Expenses',
                        'MK${totalExpenses.toStringAsFixed(2)}',
                        Icons.trending_down,
                        Colors.red,
                      ),
                      _buildSummaryCard(
                        'Total Earnings',
                        'MK${totalEarnings.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildSummaryCard(
                        'Net Balance',
                        '${netBalance >= 0 ? '+' : ''}MK${netBalance.toStringAsFixed(2)}',
                        netBalance >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        netBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Comparison Chart
                  Text(
                    '${_selectedPeriod} Comparison',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPeriodControls(),
                  const SizedBox(height: 16),
                  _buildPeriodComparisonChart(expenseProvider),

                  const SizedBox(height: 32),
                  // Expenses by Category
                  const Text(
                    'Expenses by Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(categoryExpenses, totalExpenses),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: const Icon(Icons.calendar_today, size: 16),
          style: const TextStyle(color: Colors.black, fontSize: 13),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPeriod = newValue!;
              // reset custom dates when period changes
              if (_selectedPeriod == 'Daily') {
                _specificDate = DateTime.now();
                _fromDate = null;
                _toDate = null;
              } else if (_selectedPeriod == 'Weekly') {
                _fromDate = DateTime.now().subtract(const Duration(days: 6));
                _toDate = DateTime.now();
                _specificDate = null;
              } else if (_selectedPeriod == 'Custom range') {
                _fromDate = DateTime.now().subtract(const Duration(days: 30));
                _toDate = DateTime.now();
                _specificDate = null;
              } else {
                _specificDate = null;
                _fromDate = null;
                _toDate = null;
              }
            });
          },
          items: <String>[
            'Daily',
            'Weekly',
            'Last 1 month',
            'Last 3 months',
            'Last 6 months',
            'Last year',
            'Custom range'
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // controls shown below the period dropdown when additional date input is required
  Widget _buildPeriodControls() {
    if (_selectedPeriod == 'Daily') {
      return _buildDateField('Select date', _specificDate ?? DateTime.now(),
          (date) => setState(() => _specificDate = date));
    }
    if (_selectedPeriod == 'Weekly' || _selectedPeriod == 'Custom range') {
      return Row(
        children: [
          Expanded(
              child: _buildDateField('From', _fromDate ?? DateTime.now(),
                  (date) => setState(() => _fromDate = date))),
          const SizedBox(width: 16),
          Expanded(
              child: _buildDateField('To', _toDate ?? DateTime.now(),
                  (date) => setState(() => _toDate = date))),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDateField(
      String label, DateTime initial, ValueChanged<DateTime> onSelected) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label: ${DateFormat('yyyy-MM-dd').format(initial)}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  List<_Bucket> _computeBuckets() {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;
    String periodType = 'month';

    if (_selectedPeriod == 'Daily') {
      start = _specificDate ?? now;
      end = start.add(const Duration(days: 1));
      periodType = 'day';
    } else if (_selectedPeriod == 'Weekly') {
      start = _fromDate ?? now.subtract(const Duration(days: 6));
      end = (_toDate ?? now).add(const Duration(days: 1));
      periodType = 'day';
    } else if (_selectedPeriod == 'Custom range') {
      start = _fromDate ?? now.subtract(const Duration(days: 30));
      end = (_toDate ?? now).add(const Duration(days: 1));
      final diff = end.difference(start).inDays;
      periodType = diff <= 31 ? 'day' : 'month';
    } else if (_selectedPeriod.startsWith('Last')) {
      if (_selectedPeriod.contains('1 month')) {
        start = DateTime(now.year, now.month - 1, now.day);
      } else if (_selectedPeriod.contains('3 months')) {
        start = DateTime(now.year, now.month - 3, now.day);
      } else if (_selectedPeriod.contains('6 months')) {
        start = DateTime(now.year, now.month - 6, now.day);
      } else if (_selectedPeriod.contains('year')) {
        start = DateTime(now.year - 1, now.month, now.day);
      } else {
        start = now.subtract(const Duration(days: 180));
      }
      end = now.add(const Duration(days: 1));
      periodType = 'month';
    } else {
      start = now.subtract(const Duration(days: 180));
      end = now.add(const Duration(days: 1));
      periodType = 'month';
    }

    List<_Bucket> buckets = [];
    if (periodType == 'day') {
      DateTime cursor = DateTime(start.year, start.month, start.day);
      while (cursor.isBefore(end)) {
        final label = DateFormat('MM/dd').format(cursor);
        buckets
            .add(_Bucket(label, cursor, cursor.add(const Duration(days: 1))));
        cursor = cursor.add(const Duration(days: 1));
      }
    } else {
      DateTime cursor = DateTime(start.year, start.month);
      while (cursor.isBefore(end)) {
        final label = DateFormat('MMM yy').format(cursor);
        buckets.add(
            _Bucket(label, cursor, DateTime(cursor.year, cursor.month + 1)));
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
    }
    return buckets;
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: Colors.red.shade300, width: 8),
        BarChartRodData(toY: y2, color: Colors.green.shade300, width: 8),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodComparisonChart(ExpenseProvider provider) {
    final buckets = _computeBuckets();
    final expenses = buckets.map((b) {
      return provider.receipts
          .where((r) => !r.date.isBefore(b.start) && r.date.isBefore(b.end))
          .fold(0.0, (sum, r) => sum + r.amount);
    }).toList();
    final earnings = buckets.map((b) {
      return provider.invoices
          .where((i) =>
              !i.invoiceDate.isBefore(b.start) && i.invoiceDate.isBefore(b.end))
          .fold(0.0, (sum, i) => sum + i.amount);
    }).toList();

    double maxValue = 0;
    for (var v in [...expenses, ...earnings]) {
      if (v > maxValue) maxValue = v;
    }
    if (maxValue < 1) maxValue = 1;

    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue * 1.1,
          barGroups: List.generate(buckets.length, (i) {
            return _makeGroupData(i, expenses[i], earnings[i]);
          }),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= buckets.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(buckets[idx].label,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('MK${value.toInt()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> expenses, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: expenses.isEmpty
          ? const Column(
              children: [
                Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No expense data available',
                    style: TextStyle(color: Colors.grey)),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: expenses.entries.map((e) {
                        return PieChartSectionData(
                          color: _getCategoryColor(e.key),
                          value: e.value,
                          title:
                              '${(e.value / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...expenses.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              color: _getCategoryColor(e.key)),
                          const SizedBox(width: 8),
                          Text(e.key),
                          const Spacer(),
                          Text('MK${e.value.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFF63BE7B);
      case 'transport':
        return const Color(0xFFFFA500);
      case 'entertainment':
        return const Color(0xFF8E7CC3);
      case 'utilities':
        return const Color(0xFFFF6B6B);
      case 'office':
        return const Color(0xFF4ECDC4);
      case 'healthcare':
        return const Color(0xFF45B7D1);
      default:
        return const Color(0xFF1E3A5F);
    }
  }
}
