import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebtMappingScreen extends StatefulWidget {
  const DebtMappingScreen({super.key});

  @override
  State<DebtMappingScreen> createState() => _DebtMappingScreenState();
}

class _DebtMappingScreenState extends State<DebtMappingScreen> {
  Future<void> _updatePoints(int addPoints) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final pointsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('points');
    final doc = await pointsRef.get();
    int current = doc.data()?['total'] ?? 0;
    int newTotal = current + addPoints;
    String badgeTier = 'Bronze Achiever';
    if (newTotal >= 10000) {
      badgeTier = 'Diamond Achiever';
    } else if (newTotal >= 5000) {
      badgeTier = 'Platinum Achiever';
    } else if (newTotal >= 2500) {
      badgeTier = 'Gold Achiever';
    } else if (newTotal >= 1000) {
      badgeTier = 'Silver Achiever';
    }
    await pointsRef.set({
      'total': newTotal,
      'badge': badgeTier,
    }, SetOptions(merge: true));
  }

  final _debtAmountController = TextEditingController();
  final _debtTypeController = TextEditingController();
  final _installmentController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _addDebt() async {
    if (_debtAmountController.text.isEmpty ||
        _debtTypeController.text.isEmpty ||
        _installmentController.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final debtData = {
        'amount': double.parse(_debtAmountController.text),
        'type': _debtTypeController.text,
        'installment': double.parse(_installmentController.text),
        'createdAt': FieldValue.serverTimestamp(),
        'clearedAmount': 0.0,
        'lastPaidMonth': null,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('financial_profile')
          .doc('debt_tracker')
          .collection('debts')
          .add(debtData);
      setState(() {
        _error = null;
        _loading = false;
      });
      _debtAmountController.clear();
      _debtTypeController.clear();
      _installmentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Debt Mapping & Repayment Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Debt',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _debtAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Debt Amount',
                              prefixIcon: Icon(Icons.money_off),
                              border: InputBorder.none,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _debtTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Debt Type (e.g. Loan, Credit Card)',
                              prefixIcon: Icon(Icons.category),
                              border: InputBorder.none,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _installmentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Repayment',
                              prefixIcon: Icon(Icons.payments),
                              border: InputBorder.none,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _addDebt,
                            child: const Text('Add Debt'),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Your Debts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (user != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('financial_profile')
                          .doc('debt_tracker')
                          .collection('debts')
                          .orderBy('createdAt', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Card(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No debts added yet.'),
                            ),
                          );
                        }
                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final debt = doc.data() as Map<String, dynamic>;
                            final debtId = doc.id;
                            return Card(
                              color: theme.colorScheme.surface.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${debt['type'] ?? ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Amount: ₹${debt['amount'] ?? ''}',
                                          ),
                                          Text(
                                            'Monthly Repayment: ₹${debt['installment'] ?? ''}',
                                          ),
                                          Text(
                                            'Cleared: ₹${debt['clearedAmount'] ?? 0.0}',
                                          ),
                                          LinearProgressIndicator(
                                            value: (debt['amount'] ?? 1) > 0
                                                ? ((debt['clearedAmount'] ??
                                                              0.0) /
                                                          (debt['amount'] ?? 1))
                                                      .clamp(0.0, 1.0)
                                                : 0.0,
                                            minHeight: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete Debt',
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('financial_profile')
                                            .doc('debt_tracker')
                                            .collection('debts')
                                            .doc(debtId)
                                            .delete();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.surface,
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed:
                                          (debt['lastPaidMonth'] ==
                                              '${DateTime.now().year}-${DateTime.now().month}')
                                          ? null
                                          : () async {
                                              final now = DateTime.now();
                                              final currentMonth =
                                                  '${now.year}-${now.month}';
                                              double cleared =
                                                  (debt['clearedAmount'] ??
                                                      0.0) +
                                                  (debt['installment'] ?? 0.0);
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .collection(
                                                    'financial_profile',
                                                  )
                                                  .doc('debt_tracker')
                                                  .collection('debts')
                                                  .doc(debtId)
                                                  .set({
                                                    'lastPaidMonth':
                                                        currentMonth,
                                                    'clearedAmount': cleared,
                                                  }, SetOptions(merge: true));
                                              await _updatePoints(
                                                50,
                                              ); // Award points for repayment
                                            },
                                      child:
                                          (debt['lastPaidMonth'] ==
                                              '${DateTime.now().year}-${DateTime.now().month}')
                                          ? const Text('Paid for this month')
                                          : const Text(
                                              'Month Installment Paid',
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
