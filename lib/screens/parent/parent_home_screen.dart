import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/explore_institute_section.dart';
import '../auth/login_screen.dart';

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
    final tabs = [_buildHome(auth, isDark), _buildProgress(auth, isDark), _buildAttendance(auth, isDark), _buildFees(auth, isDark)];

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.family_restroom, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Text('VEDO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
        actions: [IconButton(icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined), onPressed: () => auth.toggleDarkMode())],
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today_rounded), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Fees'),
        ],
      ),
    );
  }

  Widget _buildHome(AuthProvider auth, bool isDark) {
    final uid = auth.currentUser?.uid;
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
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Color(0xFFFFB74D)]), borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello, ${auth.currentUser?.name ?? 'Parent'}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Viewing: ${data?['childName'] ?? 'No child linked'}', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 16),
            if (childId == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('No child linked'),
                    SizedBox(height: 8),
                    Text('Link your child by editing your profile'),
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
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(child['name'] ?? ''),
                        const SizedBox(height: 4),
                        Text('Class: ${child['standard'] ?? '-'}'),
                        const SizedBox(height: 4),
                        Text('Institute: ${child['instituteName'] ?? '-'}'),
                      ]),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            const ExploreInstituteSection(title: 'Explore Institutes'),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await auth.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Sign Out'),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildProgress(AuthProvider auth, bool isDark) {
    return Center(child: Text('Progress (read-only view)'));
  }

  Widget _buildAttendance(AuthProvider auth, bool isDark) {
    return Center(child: Text('Attendance'));
  }

  Widget _buildFees(AuthProvider auth, bool isDark) {
    return Center(child: Text('Fees'));
  }
}
