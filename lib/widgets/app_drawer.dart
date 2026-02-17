import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        authProvider.user?.name.isNotEmpty ?? false
                            ? authProvider.user!.name.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.user?.name ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      authProvider.user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.receipt,
            title: 'Receipts',
            onTap: () {
              context.go('/receipts');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.description,
            title: 'Invoices',
            onTap: () {
              context.go('/invoices');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.description,
            title: 'Quotations',
            onTap: () {
              context.go('/quotations');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Budgets',
            onTap: () {
              context.go('/budgets');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category,
            title: 'Categories',
            onTap: () {
              context.go('/categories');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () {
              context.go('/reports');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              context.go('/settings');
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
