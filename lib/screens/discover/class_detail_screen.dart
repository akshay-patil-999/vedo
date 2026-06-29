import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ClassDetailScreen extends StatelessWidget {
  final String classId;
  final Map<String, dynamic> data;
  const ClassDetailScreen({super.key, required this.classId, required this.data});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.userRole;
    final actionLabel = role == 'teacher'
        ? 'Book Appointment'
        : role == 'parent'
            ? 'Request Meet'
            : 'Request Enrollment';

    final instituteName = data['name'] ?? data['instituteName'] ?? 'Class Detail';
    final standardName = data['standardName'] ?? 'Standard';
    final description = data['description'] ?? 'No description available.';
    final fee = data['fee'] ?? 0;
    final feeType = data['feeType'] ?? 'month';
    final medium = data['medium'] ?? 'Medium not set';
    final subjects = (data['subjects'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final instituteId = data['instituteId'] as String? ?? '';

    void handleAction() {
      final message = role == 'teacher'
          ? 'Appointment request sent to the institute.'
          : role == 'parent'
              ? 'Meeting request sent to the institute.'
              : 'Enrollment request sent to the institute.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    return Scaffold(
      appBar: AppBar(title: Text('$standardName • $instituteName')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: instituteId.isNotEmpty ? FirebaseFirestore.instance.collection('institutes').doc(instituteId).snapshots() : const Stream.empty(),
        builder: (context, instituteSnapshot) {
          final instituteData = instituteSnapshot.data?.data() as Map<String, dynamic>?;
          final instituteContact = instituteData?['contact'] ?? data['contact'] ?? 'Not available';
          final instituteAddress = '${instituteData?['location'] ?? data['location'] ?? 'Unknown location'}, ${instituteData?['city'] ?? data['city'] ?? 'Unknown city'}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF5BA3F5)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$standardName · $instituteName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('$medium • ₹$fee/$feeType', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(instituteAddress, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Batch Overview'),
              _detailTile('Institute', instituteName),
              _detailTile('Standard', standardName),
              _detailTile('Medium', medium),
              _detailTile('Location', instituteAddress),
              _detailTile('Contact', instituteContact),
              const SizedBox(height: 16),
              _sectionTitle('Description'),
              Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 16),
              _sectionTitle('Subjects'),
              if (subjects.isEmpty)
                const Text('No subjects listed yet.', style: TextStyle(color: Colors.black54))
              else
                ...subjects.map((subject) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(subject['name'] ?? 'Subject'),
                    subtitle: Text('Faculty: ${subject['faculty'] ?? 'Not specified'}'),
                  );
                }),
              const SizedBox(height: 16),
              _sectionTitle('Institute Standards'),
              StreamBuilder<QuerySnapshot>(
                stream: instituteId.isNotEmpty
                    ? FirebaseFirestore.instance.collection('institutes').doc(instituteId).collection('standards').orderBy('createdAt', descending: false).snapshots()
                    : const Stream.empty(),
                builder: (context, standardSnapshot) {
                  if (standardSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (standardSnapshot.hasError) {
                    return Text('Failed to load standards: ${standardSnapshot.error}');
                  }
                  final standardDocs = standardSnapshot.data?.docs ?? [];
                  if (standardDocs.isEmpty) {
                    return const Text('No standard list available.');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: standardDocs.map((stdDoc) {
                      final stdData = stdDoc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• ${stdData['name'] ?? 'Standard'} (${stdData['medium'] ?? 'Medium'})'),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: handleAction, child: Text(actionLabel)),
            ]),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
      ]),
    );
  }
}
