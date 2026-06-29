import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'add_standard_screen.dart';

class StandardsListScreen extends StatefulWidget {
  final bool initialOpenAdd;
  const StandardsListScreen({super.key, this.initialOpenAdd = false});

  @override
  State<StandardsListScreen> createState() => _StandardsListScreenState();
}

class _StandardsListScreenState extends State<StandardsListScreen> {
  String? _instituteId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid != null && _instituteId == null) {
      FirebaseFirestore.instance.collection('users').doc(uid).get().then((doc) {
        final id = doc.data()?['instituteId'] as String?;
        if (id != null && mounted) setState(() => _instituteId = id);
      }).catchError((_) {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOpenAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAdd());
    }
  }

  void _openAdd() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddStandardScreen()));

  Future<void> _showStandardDetail(String standardId, Map<String, dynamic> data) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(data['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Medium: ${data['medium'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Fee: ₹${data['fee'] ?? 0} / ${data['feeType'] ?? ''}'),
              const SizedBox(height: 12),
              const Text('Subjects:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((data['subjects'] as List<dynamic>?) ?? []).map((s) => ListTile(title: Text(s['name'] ?? ''), subtitle: Text(s['faculty'] ?? ''))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddStandardScreen())); }, child: const Text('Edit'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _deleteStandard(standardId), child: const Text('Delete'))),
              ])
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteStandard(String standardId) async {
    if (_instituteId == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Standard'),
            content: const Text('Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ).then((v) => v ?? false);
    if (!confirmed) return;
    try {
      final stdDocRef = FirebaseFirestore.instance.collection('institutes').doc(_instituteId).collection('standards').doc(standardId);
      List<QueryDocumentSnapshot> classesToDelete = [];
      final classesQuery = await FirebaseFirestore.instance.collection('classes').where('instituteId', isEqualTo: _instituteId).where('standardId', isEqualTo: standardId).get();
      classesToDelete = classesQuery.docs;

      final batch = FirebaseFirestore.instance.batch();
      batch.delete(stdDocRef);
      for (var c in classesToDelete) {
        batch.delete(FirebaseFirestore.instance.collection('classes').doc(c.id));
      }
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Standard deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Standards & Batches')),
      body: _instituteId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('institutes').doc(_instituteId).collection('standards').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No standards added yet. Add your first standard!'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? 'Standard'),
                      subtitle: Text('${data['medium'] ?? ''} • ₹${data['fee'] ?? 0}'),
                      trailing: Text('${(data['subjects'] as List<dynamic>?)?.length ?? 0} subjects'),
                      onTap: () => _showStandardDetail(doc.id, data),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _openAdd, child: const Icon(Icons.add)),
    );
  }
}
