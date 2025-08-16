import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
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

  // Notification state
  String? _notification;
  static const double lowBalanceThreshold = 100.0;
  static const double largeTransactionThreshold = 5000.0;
  double _balance = 0.0;
  bool _loading = true;
  List<Map<String, dynamic>> _transactions = [];
  double get _totalAdded => _transactions
      .where((tx) => tx['type'] == 'add')
      .fold(0.0, (sum, tx) => sum + (tx['amount'] as num).toDouble());
  double get _totalSpent => _transactions
      .where((tx) => tx['type'] == 'spend')
      .fold(0.0, (sum, tx) => sum + (tx['amount'] as num).toDouble());

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final walletDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .get();
    final txSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main')
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();
    setState(() {
      _balance = walletDoc.data()?['balance']?.toDouble() ?? 0.0;
      _transactions = txSnap.docs.map((d) => d.data()).toList();
      _loading = false;
      _notification = null;
      // Low balance notification
      if (_balance < lowBalanceThreshold) {
        _notification = '⚠️ Your wallet balance is low!';
      } else if (_transactions.isNotEmpty &&
          (_transactions.first['amount'] as num).toDouble() >=
              largeTransactionThreshold) {
        _notification =
            '🔔 Large transaction detected: ₹${(_transactions.first['amount'] as num).toString()}';
      }
    });
  }

  Future<void> _addTransaction({required bool isAdd}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    double? amount;
    String? category;
    String? note;
    await showDialog(
      context: context,
      builder: (context) {
        final amountController = TextEditingController();
        final categoryController = TextEditingController();
        final noteController = TextEditingController();
        return AlertDialog(
          title: Text(isAdd ? 'Add Money' : 'Spend Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                amount = double.tryParse(amountController.text);
                category = categoryController.text;
                note = noteController.text;
                if (amount != null &&
                    category != null &&
                    category!.isNotEmpty) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (amount == null || category == null || (category?.isEmpty ?? true))
      return;
    final now = DateTime.now();
    final txData = {
      'amount': amount,
      'category': category,
      'note': note ?? '',
      'date': now,
      'type': isAdd ? 'add' : 'spend',
    };
    final walletRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('main');
    await walletRef.set({
      'balance': isAdd ? _balance + amount! : _balance - amount!,
    }, SetOptions(merge: true));
    await walletRef.collection('transactions').add(txData);
    if (isAdd && amount != null && amount! >= 1000) {
      int pointsToAdd = (amount! ~/ 1000) * 20;
      if (pointsToAdd > 0) {
        await _updatePoints(pointsToAdd); // Award points for saving money
      }
    }
    await _loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FB),
      appBar: AppBar(
        title: const Text(
          'Virtual Wallet',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_notification != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8,
                    ),
                    child: Card(
                      color: Colors.red.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _notification!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.amber,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Wallet Balance',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '₹${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Money'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _addTransaction(isAdd: true),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.remove),
                              label: const Text('Spend Money'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _addTransaction(isAdd: false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Total Added',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '₹${_totalAdded.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Total Spent',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '₹${_totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Transactions',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${_transactions.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_transactions.isEmpty)
                          const Text(
                            'No transactions yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ..._transactions.map((tx) {
                          final date = (tx['date'] as Timestamp).toDate();
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                tx['type'] == 'add'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx['type'] == 'add'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                '${tx['category']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${date.year}-${date.month}-${date.day}${tx['note'] != null && tx['note'].isNotEmpty ? '\n${tx['note']}' : ''}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: Text(
                                (tx['type'] == 'add' ? '+' : '-') +
                                    '₹${tx['amount'].toString()}',
                                style: TextStyle(
                                  color: tx['type'] == 'add'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
