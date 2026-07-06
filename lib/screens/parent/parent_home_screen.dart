import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/explore_institute_section.dart';
import '../auth/login_screen.dart';
import '../common/feature_hub_screen.dart';
import '../common/quick_actions_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = auth.isDarkMode;
    final tabs = [
      _buildOverview(auth, isDark),
      _buildProgress(auth, isDark),
      _buildAttendance(auth, isDark),
      _buildFees(auth, isDark),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.family_restroom, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('VEDO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => auth.toggleDarkMode(),
          ),
        ],
      ),
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.backgroundColor,
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isDark ? AppTheme.primaryDark : AppTheme.primaryColor,
        unselectedItemColor: isDark ? Colors.grey : Colors.grey.shade500,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today_rounded), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Fees'),
        ],
      ),
    );
  }

  Widget _buildOverview(AuthProvider auth, bool isDark) {
    final uid = auth.currentUser?.uid;

    if (Firebase.apps.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello, ${auth.currentUser?.name ?? 'Parent'}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your parent overview is ready to load with the full institute experience.', style: TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Overview ready', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('The dashboard is using the same polished layout and navigation as the web experience.'),
              ]),
            ),
          ),
        ]),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final childId = data?['linkedStudentId'];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello, ${auth.currentUser?.name ?? 'Parent'}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Stay on top of your child’s learning, attendance, fees, and updates.', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _metricCard('Child Progress', 'Excellent', Icons.trending_up_rounded, AppTheme.primaryColor, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('Upcoming', '2 classes', Icons.event_available_rounded, AppTheme.secondaryColor, isDark)),
            ]),
            const SizedBox(height: 16),
            if (childId == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('No child linked', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Link your child from the profile section to unlock milestone updates.'),
                  ]),
                ),
              )
            else
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(childId).snapshots(),
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) return const SizedBox();
                  final child = s.data?.data() as Map<String, dynamic>?;
                  if (child == null) return const SizedBox();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(child['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Class: ${child['standard'] ?? '-'}'),
                        const SizedBox(height: 4),
                        Text('Institute: ${child['instituteName'] ?? '-'}'),
                      ]),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.apps_outlined, color: AppTheme.primaryColor),
                title: const Text('Open all features'),
                subtitle: const Text('Alerts, timetable, attendance, fees and doubt support.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeatureHubScreen(userRole: 'parent')));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.flash_on_outlined, color: AppTheme.secondaryColor),
                title: const Text('Quick actions'),
                subtitle: const Text('Jump to the most useful parent actions.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickActionsScreen(userRole: 'parent')));
                },
              ),
            ),
            const SizedBox(height: 24),
            const ExploreInstituteSection(title: 'Explore Institutes'),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await auth.signOut();
                if (!mounted) return;
                navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Sign Out'),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildProgress(AuthProvider auth, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Performance Overview', 'Your child’s recent growth'),
        const SizedBox(height: 12),
        _infoTile('Math', 'Strong improvement this month', Icons.calculate_outlined, isDark),
        _infoTile('Science', 'Completed project review', Icons.science_outlined, isDark),
        _infoTile('Reading', 'Reading streak is active', Icons.menu_book_outlined, isDark),
      ]),
    );
  }

  Widget _buildAttendance(AuthProvider auth, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Attendance', 'Current attendance snapshot'),
        const SizedBox(height: 12),
        _infoTile('Present', '94% this month', Icons.check_circle_outline_rounded, isDark),
        _infoTile('Late', '2 sessions', Icons.access_time_rounded, isDark),
        _infoTile('Pending', '1 leave request', Icons.pending_actions_rounded, isDark),
      ]),
    );
  }

  Widget _buildFees(AuthProvider auth, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Fee Status', 'Updated today'),
        const SizedBox(height: 12),
        _infoTile('Paid', 'Tuition fee is up to date', Icons.payment_outlined, isDark),
        _infoTile('Next Due', 'July 20', Icons.event_note_outlined, isDark),
        _infoTile('Support', 'Payment receipts available', Icons.support_agent_outlined, isDark),
      ]),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: Colors.grey)),
    ]);
  }

  Widget _infoTile(String title, String subtitle, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ])),
      ]),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}
