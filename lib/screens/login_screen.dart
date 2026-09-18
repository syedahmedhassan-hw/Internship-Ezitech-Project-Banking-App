import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../widgets/app_drawer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(); // email or username
  final _passCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _localAuth = LocalAuthentication();
  bool _loading = false;
  String? _error;

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _userCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // Check role in Firestore
      final uid = cred.user?.uid;
      if (uid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();

        if (mounted) {
          if (role == 'admin' || _userCtrl.text.trim().toLowerCase() == 'admin@mybank.com') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithFingerprint() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        setState(() => _error = 'Biometrics not available on this device.');
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to log in',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok && mounted) {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
          if (mounted) {
            if (role == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin');
              return;
            }
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      setState(() => _error = 'Fingerprint auth failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer & Admin Login')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.account_balance, size: 72, color: Colors.indigo),
                const SizedBox(height: 16),
                Text('Welcome Back to MyBank',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 8),
                const Text(
                  'Log in to access your digital banking account or admin portal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _userCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter email address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter password' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _loginWithPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Login to Account', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loginWithFingerprint,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Login with Biometrics'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("Don't have an account? Sign up"),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/helpline'),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('24/7 Helpline & Support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
