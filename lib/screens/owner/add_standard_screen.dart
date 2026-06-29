import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AddStandardScreen extends StatefulWidget {
  const AddStandardScreen({super.key});

  @override
  State<AddStandardScreen> createState() => _AddStandardScreenState();
}

class _AddStandardScreenState extends State<AddStandardScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  String? _standard;
  String _medium = 'English';
  final List<Map<String, String>> _subjects = [];
  final _subjectName = TextEditingController();
  final _facultyName = TextEditingController();
  final _feeController = TextEditingController();
  String _feeType = 'Monthly';
  bool _isSaving = false;

  final List<String> _standards = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11 (Science)',
    'Class 11 (Commerce)',
    'Class 11 (Arts)',
    'Class 12 (Science)',
    'Class 12 (Commerce)',
    'Class 12 (Arts)',
  ];

  final List<String> _mediums = ['English', 'Semi-English', 'Marathi', 'Hindi', 'Other'];

  @override
  void dispose() {
    _subjectName.dispose();
    _facultyName.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _addSubject() {
    if (_subjectName.text.trim().isEmpty) return;
    setState(() {
      _subjects.add({'name': _subjectName.text.trim(), 'faculty': _facultyName.text.trim()});
      _subjectName.clear();
      _facultyName.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one subject.')));
      return;
    }

    final standardName = _standard?.trim() ?? '';
    if (standardName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a standard.')));
      return;
    }

    setState(() => _isSaving = true);
    final ownerId = context.read<AuthProvider>().currentUser?.uid;
    if (ownerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to locate owner.')));
      }
      setState(() => _isSaving = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
      String? instituteId = userDoc.data()?['instituteId'] as String?;
      if (instituteId == null || instituteId.isEmpty) {
        final q = await FirebaseFirestore.instance.collection('institutes').where('ownerId', isEqualTo: ownerId).limit(1).get();
        if (q.docs.isEmpty) {
          throw 'Institute not set up yet.';
        }
        instituteId = q.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(ownerId).set({'instituteId': instituteId}, SetOptions(merge: true));
      }

      final instituteDoc = await FirebaseFirestore.instance.collection('institutes').doc(instituteId).get();
      final instituteData = instituteDoc.data() ?? {};

      final standardData = {
        'name': standardName,
        'medium': _medium,
        'subjects': _subjects,
        'fee': int.tryParse(_feeController.text.trim()) ?? 0,
        'feeType': _feeType,
        'discount': 0,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final standardRef = await FirebaseFirestore.instance.collection('institutes').doc(instituteId).collection('standards').add(standardData);
      await standardRef.update({'id': standardRef.id});

      final classData = {
        'instituteId': instituteId,
        'instituteName': instituteData['name'] ?? '',
        'location': instituteData['location'] ?? '',
        'city': instituteData['city'] ?? '',
        'ownerId': ownerId,
        'standardId': standardRef.id,
        'standardName': standardName,
        'medium': _medium,
        'subjects': _subjects,
        'fee': int.tryParse(_feeController.text.trim()) ?? 0,
        'feeType': _feeType,
        'description': '$standardName batch at ${instituteData['name'] ?? ''}',
        'isPublic': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final classRef = await FirebaseFirestore.instance.collection('classes').add(classData);
      await classRef.update({'id': classRef.id});

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Standard Added! ✅'),
          content: Text('$standardName saved with ${_subjects.length} subjects and fee ₹${_feeController.text}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Add Another')),
            ElevatedButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Go to Dashboard')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Standard'), backgroundColor: AppTheme.primaryColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_step == 0) _buildStep1() else if (_step == 1) _buildStep2() else _buildStep3(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Standard Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _standard,
        decoration: const InputDecoration(labelText: 'Standard'),
        items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (value) => setState(() => _standard = value),
        validator: (value) => value == null ? 'Select standard' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _medium,
        decoration: const InputDecoration(labelText: 'Medium'),
        items: _mediums.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (value) => setState(() => _medium = value ?? 'English'),
        validator: (value) => value == null ? 'Select medium' : null,
      ),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () => setState(() => _step = 1), child: const Text('Next')),
    ]);
  }

  Widget _buildStep2() {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              return ListTile(
                title: Text(subject['name'] ?? ''),
                subtitle: Text(subject['faculty'] ?? ''),
                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _subjects.removeAt(index))),
              );
            },
          ),
        ),
        TextFormField(controller: _subjectName, decoration: const InputDecoration(labelText: 'Subject Name')),
        const SizedBox(height: 8),
        TextFormField(controller: _facultyName, decoration: const InputDecoration(labelText: 'Faculty Name')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: _addSubject, child: const Text('Add Subject'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: _subjects.isNotEmpty ? () => setState(() => _step = 2) : null, child: const Text('Next'))),
        ]),
      ]),
    );
  }

  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Fee Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextFormField(
        controller: _feeController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Fee Amount (₹)'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter fee amount';
          }
          if (int.tryParse(value.trim()) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _feeType,
        decoration: const InputDecoration(labelText: 'Fee Type'),
        items: ['Monthly', 'Quarterly', 'Yearly'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
        onChanged: (value) => setState(() => _feeType = value ?? 'Monthly'),
      ),
      const SizedBox(height: 20),
      _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(onPressed: _save, child: const Text('Save')),
    ]);
  }
}
