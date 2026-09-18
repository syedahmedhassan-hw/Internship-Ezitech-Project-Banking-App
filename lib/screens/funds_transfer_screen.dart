import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payee.dart';

class FundsTransferScreen extends StatefulWidget {
  const FundsTransferScreen({super.key});

  @override
  State<FundsTransferScreen> createState() => _FundsTransferScreenState();
}

class _FundsTransferScreenState extends State<FundsTransferScreen> {
  final _amountCtrl = TextEditingController();
  final _directAccCtrl = TextEditingController();
  final _directNameCtrl = TextEditingController();

  Payee? _selectedPayee;
  bool _isDirect = false;
  String _selectedBank = 'MyBank';
  bool _sending = false;

  final List<String> _banks = ['MyBank', 'HBL', 'Alfalah', 'Meezan', 'Standard Chartered'];

  Future<void> _openAddPayee() async {
    final result = await Navigator.pushNamed(context, '/addPayee');
    if (result is Payee) {
      setState(() {
        _selectedPayee = result;
        _isDirect = false;
      });
    }
  }

  Future<void> _sendMoney() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    String destAccount;
    String destName;
    String destBank;

    if (_isDirect) {
      destAccount = _directAccCtrl.text.trim();
      destName = _directNameCtrl.text.trim();
      destBank = _selectedBank;
      if (destAccount.isEmpty || destName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all direct transfer details'), backgroundColor: Colors.red),
        );
        return;
      }
      if (destAccount.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account number must be exactly 10 digits'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      if (_selectedPayee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payee'), backgroundColor: Colors.red),
        );
        return;
      }
      destAccount = _selectedPayee!.accountNumber;
      destName = _selectedPayee!.name;
      destBank = _selectedPayee!.bankName;
    }

    setState(() => _sending = true);
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final status = snap.data()?['status'] ?? 'active';
        if (status == 'frozen') {
          throw Exception('Your account is currently FROZEN by bank administration. Transfers are disabled.');
        }

        final currentBalance = (snap.data()?['balance'] ?? 0).toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Deduct from sender
        tx.update(userRef, {'balance': currentBalance - amount});

        // Add to sender's transactions
        tx.set(userRef.collection('transactions').doc(), {
          'type': 'transfer',
          'to': destAccount,
          'toName': destName,
          'bankName': destBank,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Completed',
        });

        // If transferring within MyBank, try to credit the recipient
        if (destBank == 'MyBank') {
          // Check if recipient's account exists
          final destUsersSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('accountNumber', isEqualTo: destAccount)
              .limit(1)
              .get();

          if (destUsersSnap.docs.isNotEmpty) {
            final destUserDoc = destUsersSnap.docs.first;
            final destUserRef = destUserDoc.reference;
            final destUserBalance = (destUserDoc.data()['balance'] ?? 0).toDouble();

            // Credit recipient balance
            tx.update(destUserRef, {'balance': destUserBalance + amount});

            // Log recipient transaction
            tx.set(destUserRef.collection('transactions').doc(), {
              'type': 'deposit',
              'from': snap.data()?['accountNumber'] ?? 'Sender',
              'fromName': snap.data()?['name'] ?? 'User',
              'amount': amount,
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'Completed',
            });
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transferred Rs. ${amount.toStringAsFixed(2)} to $destName!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Funds Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Select Mode: Saved Payees vs Direct Transfer
                  Row(
                    children: [
                      Expanded(
                        child: _tabButton('Saved Payees', !_isDirect, () {
                          setState(() => _isDirect = false);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _tabButton('Direct Transfer', _isDirect, () {
                          setState(() => _isDirect = true);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mode content
                  if (!_isDirect) ...[
                    // Payees listing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Saved Payee',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        TextButton.icon(
                          onPressed: _openAddPayee,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Payee'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('payees')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return _noPayeesCard();
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final payee = Payee.fromMap(docs[i].id,
                                  docs[i].data() as Map<String, dynamic>);
                              final isSelected = _selectedPayee?.id == payee.id;

                              return InkWell(
                                onTap: () => setState(() => _selectedPayee = payee),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1B6AEB) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1B6AEB) : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isSelected ? Colors.white24 : Colors.grey.shade100,
                                        child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.black54),
                                      ),
                                      const Spacer(),
                                      Text(
                                        payee.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        payee.bankName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        payee.accountNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected ? Colors.white54 : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Direct transfer fields
                    const Text(
                      'Beneficiary Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedBank,
                              decoration: const InputDecoration(
                                labelText: 'Destination Bank',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                              items: _banks.map((b) {
                                return DropdownMenuItem(value: b, child: Text(b));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedBank = val);
                                }
                              },
                            ),
                            const Divider(),
                            TextFormField(
                              controller: _directAccCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Account Number / IBAN',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.numbers),
                              ),
                            ),
                            const Divider(),
                            TextFormField(
                              controller: _directNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Account Title / Name',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Amount and Send Button section
                  if (_isDirect || _selectedPayee != null) ...[
                    const Text(
                      'Transfer Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (Rs.)',
                        prefixIcon: Icon(Icons.currency_lira),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _sending ? null : _sendMoney,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _sending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _tabButton(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1B6AEB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF1B6AEB) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _noPayeesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.grey.shade300, size: 40),
          const SizedBox(height: 8),
          const Text('No saved payees found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 4),
          const Text('Click "Add Payee" or use "Direct Transfer".', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
