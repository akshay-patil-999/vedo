import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentRequestsScreen extends StatelessWidget {
  const EnrollmentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enrollment Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('enrollment_requests').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load requests: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final requestId = docs[index].id;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['instituteName'] ?? 'Institute', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Applicant: ${data['userName'] ?? data['userEmail'] ?? ''}'),
                    Text('Role: ${data['userRole'] ?? 'student'}'),
                    if ((data['message'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text('Message: ${data['message']}'),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('enrollment_requests').doc(requestId).update({'status': 'approved', 'respondedAt': FieldValue.serverTimestamp()});
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
                            await FirebaseFirestore.instance.collection('enrollment_requests').doc(requestId).update({'status': 'rejected', 'respondedAt': FieldValue.serverTimestamp()});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
                            }
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
