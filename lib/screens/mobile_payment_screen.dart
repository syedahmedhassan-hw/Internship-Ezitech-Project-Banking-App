import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MobilePaymentScreen extends StatefulWidget {
  const MobilePaymentScreen({super.key});

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _operator = 'Jazz';
  bool _loading = false;
  int _selectedTab = 0; // 0: Easyload, 1: Bundles

  final List<String> _operators = ['Jazz', 'Telenor', 'Zong', 'Ufone'];

  // List of mock bundles
  final List<Map<String, dynamic>> _bundles = [
    {
      'title': 'Weekly Hybrid Plus',
      'volume': '10 GB Data + 3000 Net Mins',
      'price': 350.0,
    },
    {
      'title': 'Monthly Super Max',
      'volume': '30 GB Data + 5000 Net Mins',
      'price': 899.0,
    },
    {
      'title': 'Daily Social Pack',
      'volume': '2 GB WhatsApp & Facebook',
      'price': 50.0,
    },
    {
      'title': 'Monthly Extreme Data',
      'volume': '100 GB Data (Ultra Fast)',
      'price': 1200.0,
    },
  ];

  Future<void> _processRecharge(double amount, String description) async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final currentBalance = (snap.data()?['balance'] ?? 0).toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        tx.update(userRef, {'balance': currentBalance - amount});
        tx.set(userRef.collection('transactions').doc(), {
          'type': 'mobile_payment',
          'operator': _operator,
          'phoneNumber': _phoneCtrl.text.trim(),
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Completed',
        });
      });

      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded Rs. ${amount.toStringAsFixed(2)} to $_operator: ${_phoneCtrl.text}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recharge Failed: ${e.toString().replaceAll('Exception: ', '')}'),
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
        title: const Text('Mobile Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operator Selection Slider/Dropdown
              const Text(
                'Select Operator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _operators.map((op) {
                  final selected = _operator == op;
                  return InkWell(
                    onTap: () => setState(() => _operator = op),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1B6AEB) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? const Color(0xFF1B6AEB) : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        op,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'e.g. 03XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter mobile number';
                  if (v.length < 10) return 'Invalid phone number format';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tabs switcher
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 0 ? const Color(0xFF1B6AEB) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Easyload',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0 ? const Color(0xFF1B6AEB) : Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 1 ? const Color(0xFF1B6AEB) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Bundles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1 ? const Color(0xFF1B6AEB) : Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tab contents
              if (_selectedTab == 0) ...[
                // Easyload Content
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Load Amount (Rs.)',
                    prefixIcon: Icon(Icons.currency_lira), // fallback currency representation
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  validator: (v) {
                    if (_selectedTab == 0) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      final amt = double.tryParse(v);
                      if (amt == null || amt < 100) return 'Minimum recharge is Rs. 100';
                      return null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
                          _processRecharge(amount, 'Easyload Top-up');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Recharge Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                // Bundles Content
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bundles.length,
                  itemBuilder: (context, idx) {
                    final b = _bundles[idx];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(b['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(b['volume'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              'Rs. ${b['price']}',
                              style: const TextStyle(color: Color(0xFF1B6AEB), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () => _processRecharge(b['price'], 'Bundle Sub: ${b['title']}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Subscribe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
