import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    
    expenseProvider.fetchReceipts();
    expenseProvider.fetchInvoices();
    budgetProvider.fetchBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Consumer2<ExpenseProvider, BudgetProvider>(
        builder: (context, expenseProvider, budgetProvider, _) {
            final totalExpenses = expenseProvider.totalReceiptsAmount;
            final totalEarnings = expenseProvider.totalInvoicesPaidAmount;

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Logo(size: 48, initials: 'ET'),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Track your expenses and earnings', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Top Stats Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard('Total Expenses', 'MK${totalExpenses.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.red),
                          _buildStatCard('Total Earnings', 'MK${totalEarnings.toStringAsFixed(2)}', Icons.trending_up, Colors.green),
                          _buildStatCard('Receipts', '${expenseProvider.receipts.length}', Icons.receipt_long, Colors.blue),
                          _buildStatCard('Invoices', '${expenseProvider.invoices.length}', Icons.description, Colors.orange),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Overview Chart
                      Expanded(
                        flex: 2,
                        child: _buildSectionCard(
                          title: 'Monthly Overview',
                          child: SizedBox(
                            height: 300,
                            child: _buildLineChart(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Budget and Activity Column (Sidebar style for larger screens)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildSectionCard(
                              title: 'Budget Tracking',
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  const Text('Set budgets to track your spending', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => context.go('/budgets'),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
                                    child: const Text('Set Budgets', style: TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionCard(
                              title: 'Recent Activity',
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  const Text('No recent transactions', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
                if (value.toInt() < titles.length) {
                  return Text(titles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('MK${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [const FlSpot(0, 0), const FlSpot(1, 0), const FlSpot(2, 0), const FlSpot(3, 0), const FlSpot(4, 0), const FlSpot(5, 0)],
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}
