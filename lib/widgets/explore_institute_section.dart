import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ExploreInstituteSection extends StatelessWidget {
  final String title;

  const ExploreInstituteSection({super.key, this.title = 'Explore Institutes'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('institutes')
              .where('isPublic', isEqualTo: true)
              .limit(4)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Unable to load institutes: ${snapshot.error}'),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No institutes available yet. Check again soon!'),
              );
            }

            return Column(
              children: [
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildInstituteCard(data, context);
                }),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/discover'),
                    child: const Text('Explore more'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstituteCard(Map<String, dynamic> data, BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.userRole;
    final instituteName = data['name'] ?? 'Institute';
    final location = '${data['location'] ?? ''}, ${data['city'] ?? ''}';
    final contact = data['contact'] ?? '';
    final established = data['yearEstablished']?.toString() ?? '';
    final owner = data['ownerName'] ?? data['ownerId'] ?? 'Institute Owner';
    final description = data['description'] ?? 'A quality learning institute.';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(instituteName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), const Icon(Icons.business, color: Colors.blueGrey, size: 18), const SizedBox(width: 4), Text(owner, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 8),
          Text(location, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Contact: $contact', style: const TextStyle(fontSize: 13)),
          ],
          if (established.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Est. $established', style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 12),
          if (role != 'owner')
            ElevatedButton(
              onPressed: () => _showEnrollmentDialog(context, data, role),
              child: Text(role == 'teacher' ? 'Apply as Teacher' : 'Request Enrollment'),
            ),
        ]),
      ),
    );
  }

  Future<void> _showEnrollmentDialog(BuildContext context, Map<String, dynamic> data, String role) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nameController = TextEditingController(text: auth.currentUser?.name ?? '');
    final emailController = TextEditingController(text: auth.currentUser?.email ?? '');
    final phoneController = TextEditingController();
    final infoController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(role == 'teacher' ? 'Apply for teaching role' : 'Request enrollment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                TextField(controller: infoController, decoration: InputDecoration(labelText: role == 'teacher' ? 'Experience / skills' : 'Study goals'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final requestData = {
                  'instituteId': data['id'] ?? data['instituteId'] ?? '',
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
