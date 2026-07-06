import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'enrollment_requests_screen.dart';
import 'institute_setup_screen.dart';
import 'add_standard_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  String? _instituteId;

  Stream<QuerySnapshot> get _ownerInstituteStream {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return FirebaseFirestore.instance.collection('institutes').where('ownerId', isEqualTo: auth.currentUser?.uid).limit(1).snapshots();
  }

  void _refreshInstituteId(String? instituteId) {
    if (instituteId == null) return;
    if (_instituteId != instituteId) {
      setState(() => _instituteId = instituteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = auth.isDarkMode;

    final tabs = [
      _buildHomeTab(auth, isDark),
      _buildClassesTab(auth, isDark),
      _buildStudentsTab(auth, isDark),
      _buildProfileTab(auth, isDark),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.business, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Text('VEDO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
        actions: [IconButton(icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined), onPressed: () => auth.toggleDarkMode()), const SizedBox(width: 8)],
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
          BottomNavigationBarItem(icon: Icon(Icons.class_outlined), activeIcon: Icon(Icons.class_rounded), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people_rounded), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_instituteId == null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InstituteSetupScreen()));
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddStandardScreen()));
              },
              label: const Text('+ Add Standard'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHomeTab(AuthProvider auth, bool isDark) {
    final user = auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _ownerInstituteStream,
      builder: (context, instituteSnapshot) {
        final instituteDoc = instituteSnapshot.data?.docs.isNotEmpty == true ? instituteSnapshot.data!.docs.first : null;
        final instituteId = instituteDoc?.id;
        if (instituteId != null) {
          _refreshInstituteId(instituteId);
        }
        final instituteData = instituteDoc?.data() as Map<String, dynamic>?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF5BA3F5)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(user?.name ?? 'Owner', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30)), child: const Text('Role: Institute Owner', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                ])),
                Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: instituteId == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance.collection('institutes').doc(instituteId).collection('standards').snapshots(),
              builder: (context, standardSnapshot) {
                final standardCount = standardSnapshot.data?.docs.length ?? 0;
                return StreamBuilder<QuerySnapshot>(
                  stream: instituteId == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').where('instituteId', isEqualTo: instituteId).snapshots(),
                  builder: (context, studentSnapshot) {
                    final studentCount = studentSnapshot.data?.docs.length ?? 0;
                    return StreamBuilder<QuerySnapshot>(
                      stream: instituteId == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance.collection('classes').where('instituteId', isEqualTo: instituteId).snapshots(),
                      builder: (context, classSnapshot) {
                        final batchCount = classSnapshot.data?.docs.length ?? 0;
                        final totalRevenue = (classSnapshot.data?.docs ?? []).fold<int>(0, (current, doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          final fee = data?['fee'];
                          return current + (fee is int ? fee : int.tryParse(fee?.toString() ?? '0') ?? 0);
                        });
                        return Column(children: [
                          Row(children: [
                            Expanded(child: _buildStatCard('Total Standards', '$standardCount', Icons.menu_book, AppTheme.primaryColor, isDark)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildStatCard('Total Students', '$studentCount', Icons.people, AppTheme.secondaryColor, isDark)),
                          ]),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: _buildStatCard('Total Batches', '$batchCount', Icons.workspaces, AppTheme.secondaryColor, isDark)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildStatCard('Revenue', '₹$totalRevenue', Icons.currency_rupee, AppTheme.primaryDark, isDark)),
                          ]),
                        ]);
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _buildStatCard('Institute Overview', 'Live', Icons.dashboard_outlined, AppTheme.primaryColor, isDark)),
              const SizedBox(width: 14),
              Expanded(child: _buildStatCard('Pending Requests', 'Review now', Icons.notifications_active_outlined, AppTheme.secondaryColor, isDark)),
            ]),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.apps_outlined, color: AppTheme.primaryColor),
                title: const Text('All institute features'),
                subtitle: const Text('Manage standards, batches, enrollments, attendance, and fees.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollmentRequestsScreen()));
                },
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: auth.currentUser?.uid == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection('enrollment_requests')
                      .where('ownerId', isEqualTo: auth.currentUser?.uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
              builder: (context, requestSnapshot) {
                if (requestSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (requestSnapshot.hasError) {
                  return Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load requests: ${requestSnapshot.error}'),
                    ),
                  );
                }
                final pendingDocs = requestSnapshot.data?.docs ?? [];
                if (pendingDocs.isEmpty) {
                  return Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Enrollment Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('No pending requests.'),
                      ]),
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Enrollment Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${pendingDocs.length} pending request(s)'),
                      const SizedBox(height: 12),
                      ...pendingDocs.take(2).map((doc) {
                        final request = doc.data() as Map<String, dynamic>;
                        final applicant = request['userName'] ?? request['userEmail'] ?? 'Applicant';
                        final roleLabel = request['userRole'] ?? 'student';
                        final message = request['message'] ?? '';
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(applicant, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Role: $roleLabel'),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Message: $message'),
                          ],
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('enrollment_requests').doc(doc.id).update({'status': 'approved', 'respondedAt': FieldValue.serverTimestamp()});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved.')));
                                  }
                                },
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('enrollment_requests').doc(doc.id).update({'status': 'rejected', 'respondedAt': FieldValue.serverTimestamp()});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
                                  }
                                },
                                child: const Text('Reject'),
                              ),
                            ),
                          ]),
                          if (doc != pendingDocs.take(2).last) const Divider(height: 28),
                        ]);
                      }),
                      if (pendingDocs.length > 2) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollmentRequestsScreen())),
                            child: const Text('View all requests'),
                          ),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('My Institute', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  instituteData == null
                      ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('No institute set up yet'),
                          ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InstituteSetupScreen())), child: const Text('Setup your institute →')),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(instituteData['name'] ?? ''),
                          const SizedBox(height: 4),
                          Text('${instituteData['location'] ?? ''}, ${instituteData['city'] ?? ''}'),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InstituteSetupScreen(instituteId: instituteId))), child: const Text('Edit')),
                        ]),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }

  Widget _buildClassesTab(AuthProvider auth, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ownerInstituteStream,
      builder: (context, instituteSnapshot) {
        final instituteDoc = instituteSnapshot.data?.docs.isNotEmpty == true ? instituteSnapshot.data!.docs.first : null;
        final instituteId = instituteDoc?.id;
        if (instituteId == null) {
          return const Center(child: Text('No institute set up yet. Tap Setup to create one.'));
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('institutes').doc(instituteId).collection('standards').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Center(child: Text('No standards added yet'));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(data['standardName'] ?? ''),
                    subtitle: Text('${(data['subjects'] as List<dynamic>?)?.length ?? 0} subjects • ${data['medium'] ?? ''}'),
                    trailing: Text('₹${data['fee'] ?? '-'}'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddStandardScreen())),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: docs.length,
            );
          },
        );
      },
    );
  }

  Widget _buildStudentsTab(AuthProvider auth, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ownerInstituteStream,
      builder: (context, instituteSnapshot) {
        final instituteDoc = instituteSnapshot.data?.docs.isNotEmpty == true ? instituteSnapshot.data!.docs.first : null;
        final instituteId = instituteDoc?.id;
        if (instituteId == null) return const Center(child: Text('No institute set up yet'));
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').where('instituteId', isEqualTo: instituteId).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Center(child: Text('No students enrolled yet'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return Card(child: ListTile(title: Text(data['name'] ?? ''), subtitle: Text(data['email'] ?? '')));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab(AuthProvider auth, bool isDark) {
    final user = auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _ownerInstituteStream,
      builder: (context, instituteSnapshot) {
        final instituteDoc = instituteSnapshot.data?.docs.isNotEmpty == true ? instituteSnapshot.data!.docs.first : null;
        final instituteData = instituteDoc?.data() as Map<String, dynamic>?;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user?.name ?? ''), const SizedBox(height: 8), Text(user?.email ?? '')]))),
            const SizedBox(height: 12),
            if (instituteData != null)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(instituteData['name'] ?? ''),
                    const SizedBox(height: 4),
                    Text('${instituteData['location'] ?? ''}, ${instituteData['city'] ?? ''}'),
                  ]),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                await auth.signOut();
                if (!mounted) return;
                navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ]),
        );
      },
    );
  }
}
