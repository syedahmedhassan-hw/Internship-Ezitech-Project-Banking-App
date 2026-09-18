import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  bool _isCardNumberHidden = true;
  bool _isCardFrozen = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings & Plans',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting && !userSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = (userSnap.hasData && userSnap.data?.data() != null)
                    ? userSnap.data!.data() as Map<String, dynamic>
                    : <String, dynamic>{'cardNumberLast4': '9194'};
                final cardLast4 = userData['cardNumberLast4'] ?? '9194';

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('transactions')
                      .snapshots(),
                  builder: (context, txSnap) {
                    double spentThisMonth = 0.0;

                    if (txSnap.hasData) {
                      final now = DateTime.now();
                      for (var doc in txSnap.data!.docs) {
                        final tx = doc.data() as Map<String, dynamic>? ?? {};
                        final type = tx['type'] ?? '';
                        final double amount = (tx['amount'] ?? 0).toDouble();
                        final timestamp = tx['timestamp'] as Timestamp?;

                        if (type != 'deposit' && timestamp != null) {
                          final txDate = timestamp.toDate();
                          if (txDate.year == now.year && txDate.month == now.month) {
                            spentThisMonth += amount;
                          }
                        }
                      }
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan Allocation Card
                          _planAllocationCard(cardLast4),
                          const SizedBox(height: 24),

                          // Freeze Card Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.indigo,
                            title: const Text(
                              'Freeze Card',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: const Text(
                              'Temporarily disable your card for all transactions',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            value: _isCardFrozen,
                            onChanged: (val) {
                              setState(() {
                                _isCardFrozen = val;
                              });
                            },
                          ),
                          const SizedBox(height: 28),

                          // Spending Benchmark section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Spending Benchmark',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'View all',
                                  style: TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Benchmark Details
                          _spendingBenchmarkDetails(spentThisMonth),
                          const SizedBox(height: 24),

                          // Spending Progress Bars
                          _spendingProgressBars(spentThisMonth),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _planAllocationCard(String cardLast4) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Premium dark slate card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Allocation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your monthly contribution is automatically allocated across the selected financial products.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Rs. 5,999',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '/ month',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Next payment will be charged on 25th March',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),

          // Visa info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Small mock Visa Logo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VISA',
                          style: TextStyle(
                            color: Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isCardNumberHidden 
                                ? '•••• •••• •••• $cardLast4'
                                : '4221 4567 8901 $cardLast4',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Green "Show" button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCardNumberHidden = !_isCardNumberHidden;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2), // Light green opaque
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _isCardNumberHidden ? 'Show' : 'Hide',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Edit Annual Plan Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              label: const Text(
                'Edit annual plan',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spendingBenchmarkDetails(double spentThisMonth) {
    // Show total spent formatted
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Rs. ${spentThisMonth.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 12),
                SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '45% higher than similar businesses',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _spendingProgressBars(double spentThisMonth) {
    // We assume a budget limit of Rs. 50,000 for standard accounts
    const double userBudget = 50000.0;
    final double userProgress = (spentThisMonth / userBudget).clamp(0.0, 1.0);

    // Hardcode average benchmark at Rs. 24,000 (0.48 ratio)
    const double averageBenchmark = 24000.0;
    final double averageProgress = (averageBenchmark / userBudget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Your spent progress bar
          _customProgressBar(
            label: 'Your spent',
            amount: 'Rs. ${(spentThisMonth / 1000).toStringAsFixed(1)}k',
            progress: userProgress,
          ),
          const SizedBox(height: 20),
          // Average progress bar
          _customProgressBar(
            label: 'Average',
            amount: 'Rs. ${(averageBenchmark / 1000).toStringAsFixed(1)}k',
            progress: averageProgress,
          ),
        ],
      ),
    );
  }

  Widget _customProgressBar({
    required String label,
    required String amount,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress fill
            FractionallySizedBox(
              widthFactor: progress == 0 ? 0.01 : progress, // show tiny bar if 0
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF60A5FA),
                      Color(0xFF2563EB),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
