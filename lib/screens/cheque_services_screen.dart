import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChequeServicesScreen extends StatefulWidget {
  const ChequeServicesScreen({super.key});

  @override
  State<ChequeServicesScreen> createState() => _ChequeServicesScreenState();
}

class _ChequeServicesScreenState extends State<ChequeServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cheque Book Request Form
  int _selectedLeaves = 25;
  final _addressCtrl = TextEditingController();
  bool _requestLoading = false;

  // Online Cheque Deposit Form
  final _chequeNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _frontPhotoUploaded = false;
  bool _backPhotoUploaded = false;
  bool _depositLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressCtrl.dispose();
    _chequeNoCtrl.dispose();
    _bankNameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitChequeBookRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address.')),
      );
      return;
    }

    setState(() => _requestLoading = true);
    try {
      final fee = _selectedLeaves == 10
          ? 150.0
          : _selectedLeaves == 25
              ? 300.0
              : 500.0;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cheque_requests')
          .add({
        'leaves': _selectedLeaves,
        'fee': fee,
        'deliveryAddress': _addressCtrl.text.trim(),
        'status': 'Pending Delivery',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _addressCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque book request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _tabController.animateTo(2); // Switch to Activity tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requestLoading = false);
    }
  }

  Future<void> _submitChequeDeposit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_chequeNoCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cheque number must be 6 digits.')),
      );
      return;
    }
    if (_bankNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter issuing bank name.')),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount.')),
      );
      return;
    }
    if (!_frontPhotoUploaded || !_backPhotoUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back photos of the cheque.')),
      );
      return;
    }

    setState(() => _depositLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cheque_deposits')
          .add({
        'chequeNumber': _chequeNoCtrl.text.trim(),
        'issuingBank': _bankNameCtrl.text.trim(),
        'amount': amount,
        'status': 'Under Verification',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _chequeNoCtrl.clear();
        _bankNameCtrl.clear();
        _amountCtrl.clear();
        setState(() {
          _frontPhotoUploaded = false;
          _backPhotoUploaded = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Online Cheque Deposit submitted for processing!'),
            backgroundColor: Colors.green,
          ),
        );
        _tabController.animateTo(2); // Switch to Activity tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit cheque deposit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _depositLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Cheque Services', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Request Book'),
            Tab(icon: Icon(Icons.document_scanner), text: 'Deposit Cheque'),
            Tab(icon: Icon(Icons.history), text: 'Activity Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _requestChequeBookTab(),
          _depositChequeTab(),
          _activityLogTab(),
        ],
      ),
    );
  }

  Widget _requestChequeBookTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.indigo, size: 28),
                      SizedBox(width: 7),
                      Text(
                        'Request New Cheque Book',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Order a personalized cheque book delivered straight to your registered mailing address.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Number of Leaves:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [10, 25, ].map((leaves) {
                      final isSelected = _selectedLeaves == leaves;
                      final fee = leaves == 10 ? 150 : (leaves == 25 ? 300 : 500);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLeaves = leaves),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected ? Colors.indigo : Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$leaves Leaves',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. $fee',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white70 : Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mailing Delivery Address',
                      hintText: 'Enter complete home or office address...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestLoading ? null : _submitChequeBookRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _requestLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Request', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _depositChequeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.indigo, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Online Cheque Deposit',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deposit physical cheques electronically by entering cheque details and capturing front/back photos.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _chequeNoCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number (6 digits)',
                      hintText: 'e.g. 849201',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bankNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Issuing Bank Name',
                      hintText: 'e.g. Meezan Bank, HBL, Allied Bank',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cheque Amount (Rs.)',
                      prefixText: 'Rs. ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Upload Cheque Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _frontPhotoUploaded = !_frontPhotoUploaded);
                          },
                          icon: Icon(
                            _frontPhotoUploaded ? Icons.check_circle : Icons.camera_alt,
                            color: _frontPhotoUploaded ? Colors.green : Colors.indigo,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_frontPhotoUploaded ? 'Front Captured' : 'Front Image'),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: _frontPhotoUploaded ? Colors.green : Colors.indigo),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _backPhotoUploaded = !_backPhotoUploaded);
                          },
                          icon: Icon(
                            _backPhotoUploaded ? Icons.check_circle : Icons.camera_alt,
                            color: _backPhotoUploaded ? Colors.green : Colors.indigo,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_backPhotoUploaded ? 'Back Captured' : 'Back Image'),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: _backPhotoUploaded ? Colors.green : Colors.indigo),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _depositLoading ? null : _submitChequeDeposit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _depositLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Cheque for Verification',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityLogTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cheque_requests')
          .snapshots(),
      builder: (context, reqSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('cheque_deposits')
              .snapshots(),
          builder: (context, depSnap) {
            final reqDocs = reqSnap.hasData ? reqSnap.data!.docs : [];
            final depDocs = depSnap.hasData ? depSnap.data!.docs : [];

            if (reqDocs.isEmpty && depDocs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No cheque requests or deposits found.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (reqDocs.isNotEmpty) ...[
                  const Text('Cheque Book Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...reqDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final leaves = data['leaves'] ?? 0;
                    final fee = data['fee'] ?? 0;
                    final status = data['status'] ?? 'Pending';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigoAccent,
                          child: Icon(Icons.menu_book, color: Colors.white, size: 20),
                        ),
                        title: Text('Cheque Book ($leaves Leaves)'),
                        subtitle: Text('Fee: Rs. $fee | Status: $status'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                if (depDocs.isNotEmpty) ...[
                  const Text('Cheque Deposits History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...depDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final chequeNo = data['chequeNumber'] ?? '------';
                    final bank = data['issuingBank'] ?? 'Bank';
                    final amount = (data['amount'] ?? 0).toDouble();
                    final status = data['status'] ?? 'Under Verification';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.history_edu, color: Colors.white, size: 20),
                        ),
                        title: Text('Cheque #$chequeNo ($bank)'),
                        subtitle: Text('Amount: Rs. ${amount.toStringAsFixed(2)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
