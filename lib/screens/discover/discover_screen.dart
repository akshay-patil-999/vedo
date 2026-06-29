import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'all_classes_screen.dart';
import 'all_institutes_screen.dart';
import 'class_detail_screen.dart';
import 'institute_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Institutes & Classes'), backgroundColor: AppTheme.primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Featured Institutes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('institutes').where('isPublic', isEqualTo: true).limit(4).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Unable to load institutes: ${snap.error}'));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No institutes available yet.'));
              return Column(children: docs.map((doc) => _instituteCard(doc.id, doc.data() as Map<String, dynamic>)).toList());
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllInstitutesScreen())),
              child: const Text('Explore more institutes'),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Public Classes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').where('isPublic', isEqualTo: true).orderBy('createdAt', descending: true).limit(8).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Unable to load classes: ${snap.error}'));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No classes available yet.'));
              return Column(children: docs.map((doc) => _classCard(doc.id, doc.data() as Map<String, dynamic>)).toList());
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllClassesScreen())),
              child: const Text('Explore more classes'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _instituteCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Institute';
    final location = '${data['location'] ?? ''}, ${data['city'] ?? ''}';
    final established = data['yearEstablished']?.toString() ?? '';
    final contact = data['contact'] ?? '';
    final description = data['description'] ?? 'Quality education available.';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(location, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Contact: $contact', style: const TextStyle(fontSize: 13)),
          ],
          if (established.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Est. $established', style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InstituteDetailScreen(instituteId: id, data: data))),
            child: const Text('View institute details'),
          ),
        ]),
      ),
    );
  }

  Widget _classCard(String id, Map<String, dynamic> data) {
    final instituteName = data['instituteName'] ?? 'Institute';
    final standardName = data['standardName'] ?? 'Class';
    final location = '${data['location'] ?? ''}, ${data['city'] ?? ''}';
    final fee = data['fee'] ?? 0;
    final feeType = data['feeType'] ?? '';
    final medium = data['medium'] ?? '';
    final subject = (data['subjects'] as List<dynamic>?)?.firstWhere((sub) => sub is Map<String, dynamic>, orElse: () => null) as Map<String, dynamic>?;
    final teacher = subject != null ? subject['faculty'] ?? '' : '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(instituteName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$standardName • $medium', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(location, style: const TextStyle(color: Colors.grey)),
          if (teacher.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Teacher: $teacher', style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 6),
          Text('₹$fee/${feeType.isNotEmpty ? feeType : 'month'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClassDetailScreen(classId: id, data: data))),
            child: const Text('View class details'),
          ),
        ]),
      ),
    );
  }
}
