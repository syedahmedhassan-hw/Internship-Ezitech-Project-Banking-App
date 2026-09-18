import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumerCtrl = TextEditingController();

  String _category = 'Electricity';
  String _provider = 'K-Electric';
  bool _fetched = false;
  bool _loading = false;
  bool _paying = false;

  // Fetched bill details
  String? _billName;
  double? _billAmount;
  String? _dueDate;
  bool _isPaid = false;

  final Map<String, List<String>> _providers = {
    'Electricity': ['K-Electric', 'LESCO', 'IESCO', 'FESCO'],
    'Gas': ['SSGC', 'SNGPL'],
    'Water': ['KWSB', 'WASA Lahore', 'WASA Rawalpindi'],
    'Internet': ['PTCL Broadband', 'StormFiber', 'Nayatel'],
  };

  void _onCategoryChanged(String? val) {
    if (val == null) return;
    setState(() {
      _category = val;
      _provider = _providers[val]!.first;
      _fetched = false;
    });
  }

  Future<void> _fetchBill() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _fetched = false;
    });

    final billDocId = '${_provider}_${_consumerCtrl.text.trim()}';
    final billRef = FirebaseFirestore.instance.collection('bills').doc(billDocId);

    try {
      final docSnap = await billRef.get();

      if (docSnap.exists) {
        final data = docSnap.data()!;
        setState(() {
          _billName = data['accountTitle'] ?? 'Consumer Account';
          _billAmount = (data['amount'] ?? 0).toDouble();
          _dueDate = data['dueDate'] ?? '15th August 2026';
          _isPaid = data['status'] == 'Paid';
          _fetched = true;
          _loading = false;
        });
      } else {
        // If not found, automatically seed one in Firestore for testing
        final random = Random();
        final double mockAmount = (random.nextInt(3500) + 1500).toDouble();
        final seedData = {
          'provider': _provider,
          'category': _category,
          'consumerNumber': _consumerCtrl.text.trim(),
          'amount': mockAmount,
          'dueDate': '15th August 2026',
          'status': 'Unpaid',
          'accountTitle': 'Consumer Account: ${_consumerCtrl.text.trim()}',
        };

        await billRef.set(seedData);

        setState(() {
          _billName = seedData['accountTitle'] as String;
          _billAmount = seedData['amount'] as double;
          _dueDate = seedData['dueDate'] as String;
          _isPaid = false;
          _fetched = true;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching bill: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _payBill() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _billAmount == null) return;

    setState(() => _paying = true);
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final billDocId = '${_provider}_${_consumerCtrl.text.trim()}';
    final billRef = FirebaseFirestore.instance.collection('bills').doc(billDocId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final billSnap = await tx.get(billRef);

        final currentBalance = (userSnap.data()?['balance'] ?? 0).toDouble();
        final billStatus = billSnap.data()?['status'] ?? 'Unpaid';

        if (billStatus == 'Paid') {
          throw Exception('This bill has already been paid.');
        }

        if (currentBalance < _billAmount!) {
          throw Exception('Insufficient balance');
        }

        // Deduct balance from user
        tx.update(userRef, {'balance': currentBalance - _billAmount!});

        // Set bill status to Paid
        tx.update(billRef, {'status': 'Paid'});

        // Add to user transactions
        tx.set(userRef.collection('transactions').doc(), {
          'type': 'bill_payment',
          'category': _category,
          'provider': _provider,
          'consumerNumber': _consumerCtrl.text.trim(),
          'amount': _billAmount!,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Paid',
        });
      });

      setState(() {
        _isPaid = true;
        _paying = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paid Rs. ${_billAmount!.toStringAsFixed(2)} to $_provider successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdowns inside a premium card container
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Bill Category',
                          prefixIcon: Icon(Icons.category),
                          border: InputBorder.none,
                        ),
                        items: _providers.keys.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: _onCategoryChanged,
                      ),
                      const Divider(),
                      DropdownButtonFormField<String>(
                        value: _provider,
                        decoration: const InputDecoration(
                          labelText: 'Service Provider',
                          prefixIcon: Icon(Icons.business),
                          border: InputBorder.none,
                        ),
                        items: _providers[_category]!.map((prov) {
                          return DropdownMenuItem(value: prov, child: Text(prov));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _provider = val;
                              _fetched = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Consumer number input
              TextFormField(
                controller: _consumerCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Consumer Number / Reference ID',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter consumer number';
                  if (v.length < 6) return 'Must be at least 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Fetch Button
              ElevatedButton(
                onPressed: _loading ? null : _fetchBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6AEB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Fetch Bill Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // Bill Info Display
              if (_fetched) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _provider.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isPaid ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isPaid ? 'PAID' : 'UNPAID',
                                style: TextStyle(
                                  color: _isPaid ? Colors.green.shade800 : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _billName ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount Due', style: TextStyle(color: Colors.grey)),
                            Text(
                              'Rs. ${_billAmount!.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Due Date', style: TextStyle(color: Colors.grey)),
                            Text(_dueDate ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!_isPaid)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _paying ? null : _payBill,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _paying
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
