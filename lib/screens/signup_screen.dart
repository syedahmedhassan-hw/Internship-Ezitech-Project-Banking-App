import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  String _generateAccountNumber() {
    final rng = Random();
    // Generates a clean 10-digit number starting with '10'
    final randomDigits = List.generate(8, (_) => rng.nextInt(10)).join();
    return '10$randomDigits';
  }

  String _generateCardNumber() {
    final rng = Random();
    final group1 = List.generate(4, (_) => rng.nextInt(10)).join();
    final group2 = List.generate(4, (_) => rng.nextInt(10)).join();
    final group3 = List.generate(4, (_) => rng.nextInt(10)).join();
    return '4221 $group1 $group2 $group3';
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final fullCardNumber = _generateCardNumber();
      final last4 = fullCardNumber.substring(fullCardNumber.length - 4);
      final accountNumber = _generateAccountNumber();

      // Check if this is the designated admin email
      final role = _emailCtrl.text.trim().toLowerCase() == 'admin@mybank.com' ? 'admin' : 'user';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'cnic': _cnicCtrl.text.trim(),
        'cardNumber': fullCardNumber,
        'cardNumberLast4': last4,
        'cardExpiry': '10/29',
        'cardCvv': '382',
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'balance': 50000.0, // Starting balance Rs. 50,000 for realistic dynamic testing
        'accountNumber': accountNumber, // Exactly 10 digits
        'role': role,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Customer Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join MyBank Today',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your unique 10-digit Account Number and Card details will be generated automatically.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _field(
                  _nameCtrl,
                  'Full Name',
                  Icons.person,
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                ),
                _field(
                  _cnicCtrl,
                  'CNIC Number (13 digits)',
                  Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter CNIC';
                    if (v.length < 13) return 'CNIC must be at least 13 digits';
                    return null;
                  },
                ),
                _field(
                  _phoneCtrl,
                  'Phone Number (e.g. 03001234567)',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
                ),
                _field(
                  _emailCtrl,
                  'Email Address',
                  Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                _field(
                  _passCtrl,
                  'Password (min 6 chars)',
                  Icons.lock,
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Password must be 6+ characters' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Register & Open Account', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
