import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardStats extends StatelessWidget {
  final double totalExpenses;
  final double totalBudget;
  final double budgetSpent;

  const DashboardStats({
    super.key,
    required this.totalExpenses,
    required this.totalBudget,
    required this.budgetSpent,
  });

  @override
  Widget build(BuildContext context) {
    final budgetRemaining = totalBudget - budgetSpent;
    final percentageUsed = totalBudget > 0 ? (budgetSpent / totalBudget) * 100 : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Expenses',
                amount: totalExpenses,
                icon: Icons.trending_down,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Budget Limit',
                amount: totalBudget,
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Budget Spent',
                amount: budgetSpent,
                icon: Icons.money_off,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Remaining',
                amount: budgetRemaining,
                icon: Icons.savings,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Budget Progress
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Usage',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${percentageUsed.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentageUsed / 100,
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentageUsed > 100 ? AppTheme.errorColor : AppTheme.primaryColor,
                    ),
                    backgroundColor: AppTheme.borderColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'MK ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
