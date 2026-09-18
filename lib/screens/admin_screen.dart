import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/theme_controller.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _useLocalFallback = false; // Streams real created customer accounts from Firestore

  // Local fallback demo customers list if Firestore security rules block cloud access
  final List<Map<String, dynamic>> _localCustomers = [
    {
      'id': 'demo_1',
      'name': 'Ali Khan',
      'email': 'ali.khan@example.com',
      'phone': '03001234567',
      'accountNumber': '1048291034',
      'balance': 75000.0,
      'role': 'user',
      'status': 'active',
      'cardNumberLast4': '9194',
    },
    {
      'id': 'demo_2',
      'name': 'Fatima Ahmed',
      'email': 'fatima.a@example.com',
      'phone': '03219876543',
      'accountNumber': '1082910482',
      'balance': 120000.0,
      'role': 'user',
      'status': 'active',
      'cardNumberLast4': '4506',
    },
    {
      'id': 'demo_3',
      'name': 'Zubair Raza',
      'email': 'zubair.raza@example.com',
      'phone': '03335554433',
      'accountNumber': '1099201823',
      'balance': 3500.0,
      'role': 'user',
      'status': 'frozen',
      'cardNumberLast4': '1122',
    },
    {
      'id': 'demo_4',
      'name': 'Bank Admin User',
      'email': 'admin@mybank.com',
      'phone': '03000800123',
      'accountNumber': '1000000001',
      'balance': 500000.0,
      'role': 'admin',
      'status': 'active',
      'cardNumberLast4': '0001',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _seedDemoCustomers() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final users = [
        {
          'name': 'Ali Khan',
          'email': 'ali.khan@example.com',
          'phone': '03001234567',
          'accountNumber': '1048291034',
          'balance': 75000.0,
          'role': 'user',
          'status': 'active',
          'cardNumberLast4': '9194',
          'cardExpiry': '10/29',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fatima Ahmed',
          'email': 'fatima.a@example.com',
          'phone': '03219876543',
          'accountNumber': '1082910482',
          'balance': 120000.0,
          'role': 'user',
          'status': 'active',
          'cardNumberLast4': '4506',
          'cardExpiry': '08/28',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Zubair Raza',
          'email': 'zubair.raza@example.com',
          'phone': '03335554433',
          'accountNumber': '1099201823',
          'balance': 3500.0,
          'role': 'user',
          'status': 'frozen',
          'cardNumberLast4': '1122',
          'cardExpiry': '12/27',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var u in users) {
        final docRef = firestore.collection('users').doc();
        batch.set(docRef, u);
      }

      await batch.commit();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Successfully created sample customer accounts in Firestore!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // If Cloud Firestore permission fails, switch to Local Demo Mode automatically
      setState(() {
        _useLocalFallback = true;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Switched to Local Demo Admin Mode (Firebase Rules Restricted)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showAdjustBalanceDialog(BuildContext context, String uid, String name, double currentBalance) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Admin Balance Adjustment');
    bool isCredit = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Adjust Balance: $name'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Balance: Rs. ${currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Credit (+)'),
                          selected: isCredit,
                          onSelected: (val) => setDialogState(() => isCredit = true),
                          selectedColor: Colors.green.shade100,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Debit (-)'),
                          selected: !isCredit,
                          onSelected: (val) => setDialogState(() => isCredit = false),
                          selectedColor: Colors.red.shade100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs.)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid positive amount.')),
                    );
                    return;
                  }

                  final newBalance = isCredit ? currentBalance + amount : currentBalance - amount;
                  if (newBalance < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Balance cannot drop below zero.')),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);

                  if (_useLocalFallback) {
                    setState(() {
                      final idx = _localCustomers.indexWhere((c) => c['id'] == uid);
                      if (idx != -1) {
                        _localCustomers[idx]['balance'] = newBalance;
                      }
                    });
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Updated balance for $name (Local Mode)')),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'balance': newBalance,
                    });

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('transactions')
                        .add({
                      'title': isCredit ? 'Admin Credit Deposit' : 'Admin Debit Adjustment',
                      'amount': amount,
                      'type': isCredit ? 'deposit' : 'transfer',
                      'note': noteCtrl.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Successfully updated balance for $name!')),
                    );
                  } catch (e) {
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Firestore Error: $e. Switched to Local Mode.')),
                    );
                    setState(() => _useLocalFallback = true);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleAccountStatus(String uid, String name, bool currentIsFrozen) async {
    final messenger = ScaffoldMessenger.of(context);
    final newStatus = currentIsFrozen ? 'active' : 'frozen';

    if (_useLocalFallback) {
      setState(() {
        final idx = _localCustomers.indexWhere((c) => c['id'] == uid);
        if (idx != -1) {
          _localCustomers[idx]['status'] = newStatus;
        }
      });
      messenger.showSnackBar(
        SnackBar(content: Text('$name\'s account is now ${newStatus.toUpperCase()} (Local Mode)')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': newStatus,
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            currentIsFrozen
                ? '$name\'s account is now ACTIVE'
                : '$name\'s account is now FROZEN',
          ),
        ),
      );
    } catch (e) {
      setState(() => _useLocalFallback = true);
      messenger.showSnackBar(
        SnackBar(content: Text('Switched to Local Mode ($e)')),
      );
    }
  }

  void _editUserProfile(BuildContext parentContext, String uid, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final roleCtrl = TextEditingController(text: data['role'] ?? 'user');

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(
                labelText: 'Role (user / admin)',
                border: OutlineInputBorder(),
                helperText: 'Type "admin" to grant admin privileges',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(parentContext);
              final nav = Navigator.of(ctx);

              if (_useLocalFallback) {
                setState(() {
                  final idx = _localCustomers.indexWhere((c) => c['id'] == uid);
                  if (idx != -1) {
                    _localCustomers[idx]['name'] = nameCtrl.text.trim();
                    _localCustomers[idx]['phone'] = phoneCtrl.text.trim();
                    _localCustomers[idx]['role'] = roleCtrl.text.trim().toLowerCase();
                  }
                });
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Profile updated (Local Mode)!')));
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': roleCtrl.text.trim().toLowerCase(),
                });
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Customer profile updated!')));
              } catch (e) {
                nav.pop();
                setState(() => _useLocalFallback = true);
                messenger.showSnackBar(SnackBar(content: Text('Switched to Local Mode ($e)')));
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_useLocalFallback ? Icons.cloud_off : Icons.cloud_done),
            tooltip: _useLocalFallback ? 'Using Local Demo Mode' : 'Using Firestore Cloud',
            color: _useLocalFallback ? Colors.orange : Colors.green,
            onPressed: () {
              setState(() {
                _useLocalFallback = !_useLocalFallback;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _useLocalFallback ? 'Switched to Local Demo Mode' : 'Switched to Cloud Firestore Mode',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Seed Sample Customers',
            onPressed: _seedDemoCustomers,
          ),
          IconButton(
            icon: Icon(
              ThemeController.instance.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              setState(() {
                ThemeController.instance.toggleTheme();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final nav = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              nav.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _useLocalFallback ? _buildLocalAdminView() : _buildFirestoreAdminView(),
    );
  }

  Widget _buildLocalAdminView() {
    final filtered = _localCustomers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final acc = (c['accountNumber'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || acc.contains(q) || email.contains(q);
    }).toList();

    double totalDeposits = 0;
    int activeCount = 0;
    int frozenCount = 0;

    for (var c in _localCustomers) {
      totalDeposits += (c['balance'] ?? 0).toDouble();
      if (c['status'] == 'frozen') {
        frozenCount++;
      } else {
        activeCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bank Administration Portal | Real-time Account & Customer Management',
                    style: TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _useLocalFallback = !_useLocalFallback),
                  icon: const Icon(Icons.sync, size: 14),
                  label: const Text('Cloud Sync', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          _buildOverviewCards(totalDeposits, _localCustomers.length, activeCount, frozenCount),
          const SizedBox(height: 20),

          _buildSearchBar(),
          const SizedBox(height: 20),

          const Text('Customer Accounts (Local Demo Mode)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final c = filtered[index];
              return _customerCard(
                uid: c['id'],
                name: c['name'],
                email: c['email'],
                accNo: c['accountNumber'],
                balance: (c['balance'] ?? 0).toDouble(),
                isFrozen: c['status'] == 'frozen',
                role: c['role'] ?? 'user',
                rawDocData: c,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreAdminView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lock_person, color: Colors.orange, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Permission Action Required',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cloud Firestore is blocking real user queries due to security rules in your Firebase Console.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To see real created customer accounts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 8),
                      Text('1. Open Firebase Console -> Firestore Database -> Rules'),
                      Text('2. Change rules to: allow read, write: if true;'),
                      Text('3. Click Publish.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _useLocalFallback = true),
                      icon: const Icon(Icons.developer_mode),
                      label: const Text('View Sample Accounts'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to Bank Database...'),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Customer Accounts Found in Firestore',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap below to seed demo customer accounts, or switch to Local Demo Mode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _seedDemoCustomers,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Seed Firestore Demo Accounts'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _useLocalFallback = true),
                        icon: const Icon(Icons.developer_mode),
                        label: const Text('Use Local Mode'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        double totalBankDeposits = 0;
        int totalCustomers = docs.length;
        int activeCount = 0;
        int frozenCount = 0;

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          totalBankDeposits += (d['balance'] ?? 0).toDouble();
          final isFrozen = d['status'] == 'frozen';
          if (isFrozen) {
            frozenCount++;
          } else {
            activeCount++;
          }
        }

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final acc = (data['accountNumber'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final q = _searchQuery.toLowerCase();
          return name.contains(q) || acc.contains(q) || email.contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(totalBankDeposits, totalCustomers, activeCount, frozenCount),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              const Text('Customer Accounts Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final uid = doc.id;
                  final d = doc.data() as Map<String, dynamic>;
                  return _customerCard(
                    uid: uid,
                    name: d['name'] ?? 'Unnamed Customer',
                    email: d['email'] ?? 'No email',
                    accNo: d['accountNumber'] ?? 'N/A',
                    balance: (d['balance'] ?? 0).toDouble(),
                    isFrozen: d['status'] == 'frozen',
                    role: d['role'] ?? 'user',
                    rawDocData: d,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(double deposits, int customers, int active, int frozen) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard('Total Deposits', 'Rs. ${deposits.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard('Total Customers', '$customers Accounts', Icons.people, Colors.teal),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard('Active Accounts', '$active Active', Icons.check_circle, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard('Frozen Accounts', '$frozen Frozen', Icons.ac_unit, Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Search customer by name, account #, or email...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim();
        });
      },
    );
  }

  Widget _customerCard({
    required String uid,
    required String name,
    required String email,
    required String accNo,
    required double balance,
    required bool isFrozen,
    required String role,
    required Map<String, dynamic> rawDocData,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (role == 'admin') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ADMIN',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Acc #: $accNo | $email',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFrozen ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFrozen ? 'FROZEN' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFrozen ? Colors.red.shade800 : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rs. ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.indigo),
                      tooltip: 'Adjust Balance',
                      onPressed: () => _showAdjustBalanceDialog(context, uid, name, balance),
                    ),
                    IconButton(
                      icon: Icon(
                        isFrozen ? Icons.lock_open : Icons.lock,
                        color: isFrozen ? Colors.green : Colors.orange,
                      ),
                      tooltip: isFrozen ? 'Unfreeze Account' : 'Freeze Account',
                      onPressed: () => _toggleAccountStatus(uid, name, isFrozen),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.grey),
                      tooltip: 'Edit Profile',
                      onPressed: () => _editUserProfile(context, uid, rawDocData),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
