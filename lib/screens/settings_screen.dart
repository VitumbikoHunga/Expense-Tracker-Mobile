import 'package:flutter/material.dart';
// removed unused import
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  // Profile Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();

  // Notification states
  bool _receiptAlerts = true;
  bool _invoiceReminders = true;
  bool _budgetAlerts = true;

  // Activity Log Filter
  String _selectedActivity = 'All Activities';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _fullNameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1E3A5F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A5F),
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Notifications'),
            Tab(text: 'Activity Logs'),
            Tab(text: 'Team'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildNotificationsTab(),
          _buildActivityLogsTab(),
          _buildTeamTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Manage your account and system settings',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Profile Information',
            icon: Icons.person_outline,
            children: [
              _buildLabelTextField(
                  'Full Name', _fullNameController, 'Your full name'),
              const SizedBox(height: 16),
              _buildLabelTextField(
                  'Email Address', _emailController, 'your@email.com'),
              const SizedBox(height: 16),
              _buildLabelTextField(
                  'Organization', _orgController, 'Your organization name'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F)),
                child: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Security',
            icon: Icons.shield_outlined,
            children: [
              OutlinedButton(
                onPressed: () {},
                child: const Text('Change Password'),
              ),
              const SizedBox(height: 8),
              const Text('Last password change: Never',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Notification Preferences',
            icon: Icons.notifications_none,
            children: [
              _buildSwitchTile(
                  'Receipt Alerts',
                  'Get notified when a new receipt is added',
                  _receiptAlerts,
                  (val) => setState(() => _receiptAlerts = val)),
              const Divider(),
              _buildSwitchTile(
                  'Invoice Reminders',
                  'Get notified about upcoming invoice due dates',
                  _invoiceReminders,
                  (val) => setState(() => _invoiceReminders = val)),
              const Divider(),
              _buildSwitchTile(
                  'Budget Alerts',
                  'Get notified when spending exceeds budget',
                  _budgetAlerts,
                  (val) => setState(() => _budgetAlerts = val)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F)),
                child: const Text('Save Preferences',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'System Activity Logs',
            icon: Icons.analytics_outlined,
            subtitle: 'View all modifications and changes to your data',
            children: [
              Container(
                width: 200,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivity,
                    isExpanded: true,
                    onChanged: (val) =>
                        setState(() => _selectedActivity = val!),
                    items: [
                      'All Activities',
                      'Receipt Created',
                      'Receipt Deleted',
                      'Invoice Status Updated',
                      'Emails Sent',
                      'Budget Updated',
                      'Quotation Created'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Details')),
                    DataColumn(label: Text('Resource ID')),
                    DataColumn(label: Text('Timestamp')),
                  ],
                  rows: [
                    _buildDataRow('Receipt Created', 'Created new receipt',
                        'Receipt: receipts...', 'Feb 12, 2026 01:13'),
                    _buildDataRow('budget_created', '', '-Budget: budgets_...',
                        'Feb 12, 2026 01:21'),
                    _buildDataRow('budget_deleted', '', '-Budget: budgets_...',
                        'Feb 12, 2026 01:24'),
                    _buildDataRow('budget_created', '', '-Budget: budgets_...',
                        'Feb 12, 2026 01:24'),
                    _buildDataRow('Receipt Created', 'Created new receipt',
                        'Receipt: receipts...', 'Feb 12, 2026 01:26'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Invite Team Members',
            icon: Icons.group_add_outlined,
            children: [
              _buildLabelTextField(
                  'Email Address', TextEditingController(), 'team@example.com'),
              const SizedBox(height: 16),
              const Text('Role',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'User',
                    isExpanded: true,
                    onChanged: (val) {},
                    items: ['User', 'Admin']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F)),
                child: const Text('Send Invitation',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'About Team Access',
            icon: Icons.info_outline,
            children: const [
              Text(
                  'User Role: Can view reports and manage receipts, invoices, and budgets',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 8),
              Text(
                  'Admin Role: Full access including notifications, activity logs, and team management',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      String? subtitle,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelTextField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF1E3A5F),
    );
  }

  DataRow _buildDataRow(
      String type, String details, String resource, String time) {
    return DataRow(cells: [
      DataCell(Text(type, style: const TextStyle(fontSize: 13))),
      DataCell(Text(details, style: const TextStyle(fontSize: 13))),
      DataCell(Text(resource,
          style: const TextStyle(fontSize: 13, color: Colors.grey))),
      DataCell(Text(time, style: const TextStyle(fontSize: 13))),
    ]);
  }
}
