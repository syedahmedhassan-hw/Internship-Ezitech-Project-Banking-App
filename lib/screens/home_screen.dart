import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/app_drawer.dart';
import '../controllers/theme_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyBank',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = (snapshot.hasData && snapshot.data?.data() != null)
                    ? snapshot.data!.data() as Map<String, dynamic>
                    : <String, dynamic>{
                        'name': 'Bank Customer',
                        'accountNumber': '1048291034',
                        'balance': 50000.0,
                        'cardNumberLast4': '9194',
                        'cardExpiry': '10/29',
                      };

                final name = data['name'] ?? 'Bank Customer';
                final accNumber = data['accountNumber'] ?? '1048291034';
                final double balance = (data['balance'] ?? 50000.0).toDouble();
                final cardLast4 = data['cardNumberLast4'] ?? '9194';
                final cardExpiry = data['cardExpiry'] ?? '10/29';

                // Safely update balance if it's zero to allow testing
                if (balance == 0) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'balance': 50000.0});
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('transactions')
                      .snapshots(),
                  builder: (context, txSnapshot) {
                    double totalRevenue = balance; // base is current balance
                    double monthlyExpense = 0;
                    List<double> dailySpending = List.filled(14, 0.0);

                    if (txSnapshot.hasData) {
                      for (var doc in txSnapshot.data!.docs) {
                        final txData = doc.data() as Map<String, dynamic>? ?? {};
                        final double amt = (txData['amount'] ?? 0).toDouble();
                        final type = txData['type'] ?? '';

                        if (type == 'deposit') {
                          totalRevenue += amt;
                        } else if (type == 'transfer' ||
                            type == 'bill_payment' ||
                            type == 'mobile_payment') {
                          monthlyExpense += amt;

                          final timestamp = txData['timestamp'] as Timestamp?;
                          if (timestamp != null) {
                            final daysAgo = DateTime.now()
                                .difference(timestamp.toDate())
                                .inDays;
                            if (daysAgo >= 0 && daysAgo < 14) {
                              dailySpending[13 - daysAgo] += amt;
                            }
                          }
                        }
                      }
                    }

                    // Normalize chart heights
                    double maxSpend = dailySpending.reduce((curr, next) => curr > next ? curr : next);
                    if (maxSpend == 0.0) maxSpend = 1.0;

                    final heights = List.generate(14, (index) {
                      final spend = dailySpending[index];
                      if (maxSpend == 1.0) {
                        final mockHeights = [
                          0.3, 0.45, 0.2, 0.6, 0.75, 0.5, 0.9,
                          0.4, 0.65, 0.35, 0.8, 0.55, 0.7, 0.85
                        ];
                        return mockHeights[index];
                      }
                      return 0.15 + (spend / maxSpend) * 0.85;
                    });

                    final isFrozen = data['status'] == 'frozen';

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFrozen) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.ac_unit, color: Colors.red, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Account Temporarily Frozen',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                              fontSize: 14),
                                        ),
                                        Text(
                                          'Transfers & payments are restricted by Bank Administration.',
                                          style: TextStyle(color: Colors.redAccent, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // User Welcome Profile Header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.indigo.shade100,
                                child: const Text(
                                  'S', // Default avatar
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome Back,',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Premium Blue Gradient Card
                          _availableFundsCard(balance, cardLast4, cardExpiry),
                          const SizedBox(height: 18),

                          // Send and Request Buttons
                          _sendRequestButtons(context, accNumber),
                          const SizedBox(height: 28),

                          // Overview section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Overview',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/statement'),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Total Revenue / Monthly Expense Cards
                          Row(
                            children: [
                              Expanded(
                                child: _overviewMetricCard(
                                  title: 'Total Revenue',
                                  amount: 'Rs. ${totalRevenue.toStringAsFixed(2)}',
                                  percentage: '+45%',
                                  isPositive: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _overviewMetricCard(
                                  title: 'Monthly Expense',
                                  amount: 'Rs. ${monthlyExpense.toStringAsFixed(2)}',
                                  percentage: '-11%',
                                  isPositive: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Performance Card / Custom Chart
                          _salesPerformanceCard(heights),
                          const SizedBox(height: 28),

                          // Quick Actions Section
                          const Text(
                            'Quick Services',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 14),
                          _quickActionsGrid(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // Styled available funds card matching Screen 1
  Widget _availableFundsCard(double balance, String last4, String expiry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FA5F9), // Light sky blue
            Color(0xFF1B6AEB), // Mid blue
            Color(0xFF0F4FC3), // Royal blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6AEB).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Funds',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  _balanceHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => setState(() => _balanceHidden = !_balanceHidden),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _balanceHidden ? '••••••' : 'Rs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Number',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '•••• •••• •••• $last4',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Expired Date',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Send and Request pills below the card
  Widget _sendRequestButtons(BuildContext context, String accNumber) {
    return Row(
      children: [
        // Send Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/fundsTransfer'),
            icon: const Icon(Icons.arrow_outward, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B), // Dark slate
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Request Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Show QR code for request
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Request Funds', textAlign: TextAlign.center),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Scan this QR code to transfer money to this account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      QrImageView(
                        data: accNumber,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Account #: $accNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Request'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Revenue / Expense Metric Card (Dark styling)
  Widget _overviewMetricCard({
    required String title,
    required String amount,
    required String percentage,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark panel matching Screen 1
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                percentage,
                style: TextStyle(
                  color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom Chart Visual representation of Sales Performance / Conversion
  Widget _salesPerformanceCard(List<double> barHeights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Performance',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Today\'s sales are \$319 higher than last month',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '73%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Sales conversion',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dynamic styled bar representation
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(14, (index) {
                final isOrange = index == 4 || index == 10;
                return Container(
                  width: 14,
                  height: 60 * barHeights[index],
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isOrange
                          ? [const Color(0xFFF97316), const Color(0xFFFDBA74)]
                          : [const Color(0xFF1B6AEB), const Color(0xFF93C5FD)],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Grid updated styling
  Widget _quickActionsGrid(BuildContext context) {
    final items = [
      ('Funds Transfer', Icons.send, '/fundsTransfer', const Color(0xFFEEF2F6)),
      ('Bill Payment', Icons.receipt_long, '/billPayment', const Color(0xFFEEF2F6)),
      ('Mobile Payment', Icons.phone_android, '/mobilePayment', const Color(0xFFEEF2F6)),
      ('Statement', Icons.article, '/statement', const Color(0xFFEEF2F6)),
      ('Cards', Icons.credit_card, '/cards', const Color(0xFFEEF2F6)),
      ('Services', Icons.miscellaneous_services, '/services', const Color(0xFFEEF2F6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, i) {
        final (label, icon, route, bgColor) = items[i];
        return InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
