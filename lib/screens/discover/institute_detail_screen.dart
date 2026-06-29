import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'class_detail_screen.dart';

class InstituteDetailScreen extends StatelessWidget {
  final String instituteId;
  final Map<String, dynamic> data;

  const InstituteDetailScreen({super.key, required this.instituteId, required this.data});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.userRole;
    final instituteName = data['name'] ?? 'Institute Details';
    final address = '${data['location'] ?? 'Location not set'}, ${data['city'] ?? 'City not set'}';
    final contact = data['contact'] ?? 'Not available';
    final established = data['yearEstablished']?.toString() ?? 'Unknown';
    final description = data['description'] ?? 'This institute provides quality programs and classes.';

    return Scaffold(
      appBar: AppBar(title: Text(instituteName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFEDF2FF)),
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(instituteName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 14),
              _detailTile('Address', address),
              const SizedBox(height: 8),
              _detailTile('Contact', contact),
              const SizedBox(height: 8),
              _detailTile('Established', established),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Available Batches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').where('instituteId', isEqualTo: instituteId).orderBy('createdAt', descending: true).snapshots(),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (classSnapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Failed to load batches: ${classSnapshot.error}'),
                );
              }

              final classDocs = classSnapshot.data?.docs ?? [];
              if (classDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No batches or classes are published yet for this institute.'),
                );
              }

              return Column(
                children: classDocs.map((classDoc) {
                  final classData = classDoc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(classData['standardName'] ?? 'Batch', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${classData['medium'] ?? 'Medium not set'} • ${classData['location'] ?? data['location'] ?? ''}, ${classData['city'] ?? data['city'] ?? ''}'),
                        const SizedBox(height: 6),
                        Text('₹${classData['fee'] ?? 0} / ${classData['feeType'] ?? 'month'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(classData['description'] ?? 'No batch description available.'),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClassDetailScreen(classId: classDoc.id, data: classData))),
                            child: const Text('View class details'),
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (role != 'owner') ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showEnrollmentDialog(context, auth, data),
              child: const Text('Request enrollment to this institute'),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _detailTile(String title, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
    ]);
  }

  Future<void> _showEnrollmentDialog(BuildContext context, AuthProvider auth, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: auth.currentUser?.name ?? '');
    final emailController = TextEditingController(text: auth.currentUser?.email ?? '');
    final phoneController = TextEditingController();
    final infoController = TextEditingController();
    final role = auth.userRole;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(role == 'teacher' ? 'Apply for teaching role' : 'Request enrollment'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: infoController, decoration: InputDecoration(labelText: role == 'teacher' ? 'Experience / skills' : 'Study goals'), maxLines: 3),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final requestData = {
                  'instituteId': instituteId,
                  'instituteName': data['name'] ?? '',
                  'ownerId': data['ownerId'] ?? '',
                  'userId': auth.currentUser?.uid ?? '',
                  'userName': nameController.text.trim(),
                  'userEmail': emailController.text.trim(),
                  'userRole': role,
                  'phone': phoneController.text.trim(),
                  'message': infoController.text.trim(),
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                };
                await FirebaseFirestore.instance.collection('enrollment_requests').add(requestData);
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your request has been sent to the institute.')));
                }
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }
}
