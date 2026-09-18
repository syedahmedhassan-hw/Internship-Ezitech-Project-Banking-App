import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payee.dart';

class AddPayeeScreen extends StatefulWidget {
  const AddPayeeScreen({super.key});

  @override
  State<AddPayeeScreen> createState() => _AddPayeeScreenState();
}

class _AddPayeeScreenState extends State<AddPayeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _savePayee() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    final payee = Payee(
      id: '',
      name: _nameCtrl.text.trim(),
      accountNumber: _accCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payees')
        .add(payee.toMap());

    setState(() => _saving = false);
    if (mounted) {
      // Return to funds transfer screen with the new payee's data
      Navigator.pop(context, payee);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Payee')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payee Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number (10 Digits)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.trim().length != 10) return 'Account Number must be exactly 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _savePayee,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save Payee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
