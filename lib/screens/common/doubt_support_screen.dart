import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class DoubtSupportScreen extends StatefulWidget {
  final String userRole;
  const DoubtSupportScreen({super.key, required this.userRole});

  @override
  State<DoubtSupportScreen> createState() => _DoubtSupportScreenState();
}

class _DoubtSupportScreenState extends State<DoubtSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitDoubt() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a subject and your question.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('doubt_requests').add({
        'userRole': widget.userRole,
        'userId': uid,
        'userName': auth.currentUser?.name ?? 'User',
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your doubt has been raised.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send doubt: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    final isDark = auth.isDarkMode;

    final query = uid.isEmpty
        ? null
        : FirebaseFirestore.instance
            .collection('doubt_requests')
            .where(widget.userRole == 'teacher' ? 'teacherId' : 'userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Doubt Support')),
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ask your doubt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject')), 
                const SizedBox(height: 12),
                TextField(controller: _messageController, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe your doubt')), 
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitDoubt, child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit doubt'))),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text('Recent doubts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 10),
          if (query == null)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Sign in to view your doubt history.')))
          else
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('No doubts raised yet.')));
                }
                return Column(children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(data['subject'] ?? 'Untitled'),
                      subtitle: Text(data['message'] ?? ''),
                      trailing: Chip(label: Text((data['status'] ?? 'open').toString().toUpperCase())),
                    ),
                  );
                }).toList());
              },
            ),
        ]),
      ),
    );
  }
}
