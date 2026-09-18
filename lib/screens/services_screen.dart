import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // Currency Converter State
  final _amountCtrl = TextEditingController(text: '100');
  String _selectedCurrency = 'USD';

  final Map<String, double> _exchangeRates = {
    'USD': 278.50,
    'EUR': 302.20,
    'GBP': 355.80,
    'AED': 75.80,
    'SAR': 74.25,
  };

  void _showEditProfileDialog(BuildContext parentContext, Map<String, dynamic> userData) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final nameCtrl = TextEditingController(text: userData['name'] ?? '');
    final phoneCtrl = TextEditingController(text: userData['phone'] ?? '');
    final addressCtrl = TextEditingController(text: userData['address'] ?? 'Karachi, Pakistan');

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Residential Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(parentContext);
              final nav = Navigator.of(ctx);
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              });
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyConverterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
          final rate = _exchangeRates[_selectedCurrency] ?? 278.50;
          final pkrResult = amt * rate;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.currency_exchange, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Live Currency Converter',style:TextStyle(fontSize: 14,fontWeight: FontWeight.w500)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Foreign Amount',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _exchangeRates.keys
                            .map((curr) => DropdownMenuItem(value: curr, child: Text(curr)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Equivalent Value in PKR', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${pkrResult.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      Text('1 $_selectedCurrency = Rs. $rate PKR', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banking Services Hub', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? 'Customer';
                final phone = userData['phone'] ?? 'N/A';
                final isFrozen = userData['status'] == 'frozen';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.indigo.shade100,
                              child: const Icon(Icons.person, size: 32, color: Colors.indigo),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phone: $phone',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _showEditProfileDialog(context, userData),
                              tooltip: 'Edit Profile',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Services & Features',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),

                      // Services Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.9,
                        children: [
                          _serviceTile(
                            context,
                            title: 'Online Cheque',
                            subtitle: 'Book request & cheque deposit',
                            icon: Icons.assignment_outlined,
                            color: Colors.teal,
                            onTap: () => Navigator.pushNamed(context, '/chequeServices'),
                          ),
                          _serviceTile(
                            context,
                            title: 'Edit Profile',
                            subtitle: 'Update address & contact',
                            icon: Icons.manage_accounts_outlined,
                            color: Colors.indigo,
                            onTap: () => _showEditProfileDialog(context, userData),
                          ),
                          _serviceTile(
                            context,
                            title: 'Cards Control',
                            subtitle: isFrozen ? 'Card Frozen' : 'Manage limits & freeze',
                            icon: Icons.credit_card,
                            color: isFrozen ? Colors.red : Colors.orange,
                            onTap: () => Navigator.pushNamed(context, '/cards'),
                          ),
                          _serviceTile(
                            context,
                            title: 'Currency Rate',
                            subtitle: 'Live exchange calculator',
                            icon: Icons.currency_exchange,
                            color: Colors.purple,
                            onTap: () => _showCurrencyConverterDialog(context),
                          ),
                          _serviceTile(
                            context,
                            title: 'Bill Payment',
                            subtitle: 'Utilities & bills',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, '/billPayment'),
                          ),
                          _serviceTile(
                            context,
                            title: 'Mobile Load',
                            subtitle: 'Top-up & bundles',
                            icon: Icons.phone_android,
                            color: Colors.green,
                            onTap: () => Navigator.pushNamed(context, '/mobilePayment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _serviceTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
