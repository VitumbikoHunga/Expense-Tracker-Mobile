import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPeriod = 'Last 6 months';

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
      expenses[receipt.category] = (expenses[receipt.category] ?? 0) + receipt.amount;
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

                  // Summary Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSummaryCard(
                          'Total Expenses',
                          'MK${totalExpenses.toStringAsFixed(2)}',
                          Icons.trending_down,
                          Colors.red,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          'Total Earnings',
                          'MK${totalEarnings.toStringAsFixed(2)}',
                          Icons.trending_up,
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          'Net Balance',
                          '${netBalance >= 0 ? '+' : ''}MK${netBalance.toStringAsFixed(2)}',
                          netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                          netBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Monthly Comparison Chart
                  const Text(
                    'Monthly Comparison',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlyComparisonChart(expenseProvider),

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
            setState(() => _selectedPeriod = newValue!);
          },
          items: <String>['Last 3 months', 'Last 6 months', 'Last year']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
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

  Widget _buildMonthlyComparisonChart(ExpenseProvider provider) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5000, // Mock max for visual consistency
          barGroups: [
            _makeGroupData(0, 1500, 2000), // Sep
            _makeGroupData(1, 2200, 1800), // Oct
            _makeGroupData(2, 1200, 2500), // Nov
            _makeGroupData(3, 3500, 4000), // Dec
            _makeGroupData(4, 2800, 3200), // Jan
            _makeGroupData(5, 1000, 1500), // Feb
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(titles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('MK${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
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
                Text('No expense data available', style: TextStyle(color: Colors.grey)),
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
                          title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
                          Container(width: 12, height: 12, color: _getCategoryColor(e.key)),
                          const SizedBox(width: 8),
                          Text(e.key),
                          const Spacer(),
                          Text('MK${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return const Color(0xFF63BE7B);
      case 'transport': return const Color(0xFFFFA500);
      case 'entertainment': return const Color(0xFF8E7CC3);
      case 'utilities': return const Color(0xFFFF6B6B);
      case 'office': return const Color(0xFF4ECDC4);
      case 'healthcare': return const Color(0xFF45B7D1);
      default: return const Color(0xFF1E3A5F);
    }
  }
}
