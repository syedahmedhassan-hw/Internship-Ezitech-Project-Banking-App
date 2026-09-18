import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatementScreen extends StatelessWidget {
  const StatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Account Statement', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner showing dynamic total spending
                _statementOverviewBanner(uid),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Transaction History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),

                // Transactions List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('transactions')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return _emptyState();
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final data = docs[idx].data() as Map<String, dynamic>;
                          return _transactionTile(data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Display summary banner with spending calculation
  Widget _statementOverviewBanner(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0;
        int count = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          count = docs.length;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final double amount = (data['amount'] ?? 0).toDouble();
            // Since we currently have only debit transactions (transfers, bills, loads)
            totalSpent += amount;
          }
        }

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF1E293B), // Dark slate
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Outflow', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${totalSpent.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Transactions', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No transactions recorded yet.',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make transfers or pay bills to see statements.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final amount = (data['amount'] ?? 0).toDouble();
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
        : 'Pending';

    IconData icon;
    String title;
    String subtitle;
    Color iconBg;

    switch (type) {
      case 'transfer':
        icon = Icons.swap_horiz;
        iconBg = const Color(0xFFEFF6FF);
        title = 'Funds Transfer';
        subtitle = 'To: ${data['toName'] ?? 'Account'} (${data['to'] ?? ''})';
        break;
      case 'bill_payment':
        icon = Icons.receipt;
        iconBg = const Color(0xFFFEF2F2);
        title = 'Bill Paid';
        subtitle = '${data['provider'] ?? 'Utility'} • ${data['consumerNumber'] ?? ''}';
        break;
      case 'mobile_payment':
        icon = Icons.phone_android;
        iconBg = const Color(0xFFECFDF5);
        title = 'Mobile Load';
        subtitle = '${data['operator'] ?? 'Network'} • ${data['phoneNumber'] ?? ''}';
        break;
      default:
        icon = Icons.payment;
        iconBg = const Color(0xFFF1F5F9);
        title = 'Transaction';
        subtitle = data['description'] ?? 'Debit Transaction';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1E293B)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: Text(
          '-Rs. ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
