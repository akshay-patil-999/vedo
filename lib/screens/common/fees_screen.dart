import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tuition_model.dart';
import '../../providers/auth_provider.dart';

class FeesScreen extends StatelessWidget {
  final String userRole;
  const FeesScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    final isDark = auth.isDarkMode;

    final query = userRole == 'teacher'
        ? FirebaseFirestore.instance.collection('tuitions').where('teacherId', isEqualTo: uid)
        : FirebaseFirestore.instance.collection('tuitions').where('studentIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
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

          final tuitions = docs.map((doc) => TuitionModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id})).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tuitions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tuition = tuitions[index];
              final feeValue = (docs[index].data() as Map<String, dynamic>)['fee'] ?? (docs[index].data() as Map<String, dynamic>)['fees'] ?? 0;
              final feeType = (docs[index].data() as Map<String, dynamic>)['feeType'] ?? 'month';
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tuition.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 6),
                    Text(tuition.subject, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        const Icon(Icons.currency_rupee, color: AppTheme.secondaryColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Fee: ₹$feeValue / $feeType', style: const TextStyle(fontWeight: FontWeight.w700))),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text('Status: Pending confirmation', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Teacher: ${tuition.teacherName.isEmpty ? 'Assigned soon' : tuition.teacherName}', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 12.5)),
                  ]),
                ),
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
          Icon(Icons.account_balance_wallet_outlined, size: 72, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No fee details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Fee information will appear here once your institute adds it.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ]),
      ),
    );
  }
}
