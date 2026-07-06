import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuickActionsScreen extends StatelessWidget {
  final String userRole;
  const QuickActionsScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = _buildActions(userRole);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.backgroundColor,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: action.color.withValues(alpha: 0.12), child: Icon(action.icon, color: action.color)),
              title: Text(action.title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              subtitle: Text(action.description, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: action.onTap,
            ),
          );
        },
      ),
    );
  }

  List<_QuickAction> _buildActions(String role) {
    switch (role) {
      case 'teacher':
        return [
          _QuickAction(title: 'Create class', description: 'Set up a new classroom or batch.', icon: Icons.add_circle_outline, color: AppTheme.primaryColor, onTap: () {}),
          _QuickAction(title: 'Send reminder', description: 'Notify students about class timing or homework.', icon: Icons.notifications_active_outlined, color: AppTheme.secondaryColor, onTap: () {}),
          _QuickAction(title: 'Review doubts', description: 'Open the doubt queue and respond quickly.', icon: Icons.help_outline, color: Colors.teal, onTap: () {}),
        ];
      case 'parent':
        return [
          _QuickAction(title: 'View child progress', description: 'Check attendance, fees, and recent activity.', icon: Icons.insights_outlined, color: AppTheme.primaryColor, onTap: () {}),
          _QuickAction(title: 'Pay fee reminder', description: 'Keep fee updates and follow-up in one place.', icon: Icons.account_balance_wallet_outlined, color: Colors.deepPurple, onTap: () {}),
          _QuickAction(title: 'Message teacher', description: 'Raise a concern or ask for support.', icon: Icons.chat_bubble_outline, color: AppTheme.secondaryColor, onTap: () {}),
        ];
      case 'owner':
        return [
          _QuickAction(title: 'Manage standards', description: 'Add or review batches and standards.', icon: Icons.school_outlined, color: AppTheme.primaryColor, onTap: () {}),
          _QuickAction(title: 'Review enrollments', description: 'Approve or reject student enrollments.', icon: Icons.people_outline, color: Colors.green, onTap: () {}),
          _QuickAction(title: 'Track revenue', description: 'Keep an eye on class and institute revenue.', icon: Icons.currency_rupee, color: AppTheme.secondaryColor, onTap: () {}),
        ];
      default:
        return [
          _QuickAction(title: 'Join class', description: 'Use a code to join a new classroom.', icon: Icons.group_add_outlined, color: AppTheme.primaryColor, onTap: () {}),
          _QuickAction(title: 'Open study tools', description: 'Jump into the study timer and homework view.', icon: Icons.timer_outlined, color: AppTheme.secondaryColor, onTap: () {}),
          _QuickAction(title: 'Raise a doubt', description: 'Ask your teacher for help quickly.', icon: Icons.help_outline, color: Colors.teal, onTap: () {}),
        ];
    }
  }
}

class _QuickAction {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.title, required this.description, required this.icon, required this.color, required this.onTap});
}
