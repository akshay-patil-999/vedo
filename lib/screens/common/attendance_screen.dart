import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tuition_model.dart';
import '../../providers/auth_provider.dart';

class AttendanceScreen extends StatelessWidget {
  final String userRole;
  const AttendanceScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    final isDark = auth.isDarkMode;

    final query = userRole == 'teacher'
        ? FirebaseFirestore.instance.collection('tuitions').where('teacherId', isEqualTo: uid)
        : FirebaseFirestore.instance.collection('tuitions').where('studentIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return FutureBuilder<List<_AttendanceSummary>>(
            future: Future.wait(docs.map((doc) async {
              final tuition = TuitionModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
              final attendanceSnapshot = await FirebaseFirestore.instance.collection('attendance').where('tuitionId', isEqualTo: tuition.id).orderBy('date', descending: true).limit(5).get();
              final sessions = attendanceSnapshot.docs.map((attendanceDoc) {
                final data = attendanceDoc.data();
                final presentIds = List<String>.from(data['presentStudentIds'] ?? []);
                return _AttendanceSession(date: data['date']?.toString() ?? '—', presentCount: presentIds.length);
              }).toList();
              return _AttendanceSummary(tuition: tuition, sessions: sessions);
            })),
            builder: (context, futureSnapshot) {
              if (!futureSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final summaries = futureSnapshot.data!;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: summaries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  final latest = summary.sessions.isNotEmpty ? summary.sessions.first : null;
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(summary.tuition.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(height: 6),
                        Text(summary.tuition.subject, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: latest != null ? Colors.green.withValues(alpha: 0.08) : AppTheme.secondaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Icon(latest != null ? Icons.check_circle_outline : Icons.info_outline, color: latest != null ? Colors.green : AppTheme.secondaryColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                latest != null
                                    ? 'Latest session: ${latest.date} • ${latest.presentCount} present'
                                    : 'No attendance recorded yet.',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Text('Timing: ${summary.tuition.timing.isEmpty ? 'To be announced' : summary.tuition.timing}', style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                      ]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.fact_check_outlined, size: 72, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No classes to show', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Attendance will appear here after your classes are connected.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

class _AttendanceSummary {
  final TuitionModel tuition;
  final List<_AttendanceSession> sessions;

  _AttendanceSummary({required this.tuition, required this.sessions});
}

class _AttendanceSession {
  final String date;
  final int presentCount;

  _AttendanceSession({required this.date, required this.presentCount});
}
