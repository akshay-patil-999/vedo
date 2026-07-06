import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'attendance_screen.dart';
import 'doubt_support_screen.dart';
import 'fees_screen.dart';
import 'notifications_center.dart';
import 'quick_actions_screen.dart';
import 'timetable_screen.dart';

class FeatureHubScreen extends StatelessWidget {
  final String userRole;

  const FeatureHubScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleLabel = switch (userRole) {
      'teacher' => 'Teacher Console',
      'owner' => 'Institute Owner',
      'parent' => 'Parent View',
      _ => 'Student View',
    };
    final items = [
      _FeatureCard(
        title: 'Alerts & Reminders',
        subtitle: 'See homework alerts, announcements and study reminders.',
        icon: Icons.notifications_active_outlined,
        color: AppTheme.secondaryColor,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsCenter())),
      ),
      _FeatureCard(
        title: 'Timetable',
        subtitle: 'Check your class slots, timings, and upcoming sessions.',
        icon: Icons.schedule_outlined,
        color: AppTheme.primaryColor,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimetableScreen(userRole: userRole))),
      ),
      _FeatureCard(
        title: 'Attendance',
        subtitle: 'Review attendance records for every joined class.',
        icon: Icons.fact_check_outlined,
        color: Colors.green,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceScreen(userRole: userRole))),
      ),
      _FeatureCard(
        title: 'Fees',
        subtitle: 'Track fee details and payment status in one place.',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.deepPurple,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeesScreen(userRole: userRole))),
      ),
      _FeatureCard(
        title: 'Doubt Support',
        subtitle: 'Raise a doubt and follow up with your teacher quickly.',
        icon: Icons.help_outline,
        color: Colors.teal,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DoubtSupportScreen(userRole: userRole))),
      ),
      _FeatureCard(
        title: 'Quick Actions',
        subtitle: 'Jump into the most useful daily actions for your role.',
        icon: Icons.flash_on_outlined,
        color: Colors.indigo,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuickActionsScreen(userRole: userRole))),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All Features')),
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Everything in one place', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Reminders, timetable, attendance, fees, and doubt support are now connected to your $roleLabel dashboard.', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                  child: Text('Role: $roleLabel', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: item)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ]),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
