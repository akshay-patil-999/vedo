import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class InstituteSetupScreen extends StatefulWidget {
  final String? instituteId;
  const InstituteSetupScreen({super.key, this.instituteId});

  @override
  State<InstituteSetupScreen> createState() => _InstituteSetupScreenState();
}

class _InstituteSetupScreenState extends State<InstituteSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _city = TextEditingController();
  final _contact = TextEditingController();
  final _year = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.instituteId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance.collection('institutes').doc(widget.instituteId).get();
    if (!doc.exists) return;
    final data = doc.data();
    if (data == null) return;
    _name.text = data['name'] ?? '';
    _location.text = data['location'] ?? '';
    _city.text = data['city'] ?? '';
    _contact.text = data['contact'] ?? '';
    _year.text = (data['yearEstablished']?.toString() ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final data = {
      'ownerId': uid,
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'city': _city.text.trim(),
      'contact': _contact.text.trim(),
      'yearEstablished': int.tryParse(_year.text.trim()) ?? FieldValue.serverTimestamp(),
      'isPublic': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final instituteRef = widget.instituteId != null
          ? FirebaseFirestore.instance.collection('institutes').doc(widget.instituteId)
          : FirebaseFirestore.instance.collection('institutes').doc(uid);

      await instituteRef.set(data, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'instituteId': instituteRef.id,
        'instituteName': _name.text.trim(),
        'location': _location.text.trim(),
        'city': _city.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Setup'), backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Institute Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location / Address'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact Number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: _year, decoration: const InputDecoration(labelText: 'Year Established'), keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _isSaving ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _save, child: const Text('Save')),
            ]),
          ),
        ),
      ),
    );
  }
}
