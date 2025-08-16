import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gemini_ai_service.dart';

class WeeklyExpenseTrackerScreen extends StatefulWidget {
  const WeeklyExpenseTrackerScreen({super.key});

  @override
  State<WeeklyExpenseTrackerScreen> createState() =>
      _WeeklyExpenseTrackerScreenState();
}

class _WeeklyExpenseTrackerScreenState
    extends State<WeeklyExpenseTrackerScreen> {
  final _expenseController = TextEditingController();
  double? _income;
  String? _summary;
  String? _safeSpendingNextWeek;
  String? _reductionAdvice;
  List<String>? _tips;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('financial_profile')
          .doc('profile')
          .get();
      if (profileDoc.exists) {
        setState(() {
          _income = (profileDoc.data()?['currentIncome'] ?? 0).toDouble();
        });
      }
    }
  }

  Future<void> _generateInsight() async {
    setState(() {
      _loading = true;
      _summary = null;
      _safeSpendingNextWeek = null;
      _reductionAdvice = null;
      _tips = null;
      _error = null;
    });
    try {
      final expense = double.tryParse(_expenseController.text) ?? 0;
      final income = _income ?? 0;
      final profileData = {'currentIncome': income};
      final userAnswers = {'lastWeekExpense': expense.toString()};
      final aiResult = await GeminiAIService.generateFinancialInsights(
        profileData: profileData,
        userAnswers: userAnswers,
      );
      setState(() {
        _summary = aiResult['summary'] ?? 'No insight generated.';
        _safeSpendingNextWeek = aiResult['safeSpendingNextWeek'];
        _reductionAdvice = aiResult['reductionAdvice'];
        final tipsRaw = aiResult['tips'];
        if (tipsRaw is List) {
          _tips = tipsRaw.map((e) => e.toString()).toList();
        } else {
          _tips = null;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Expense Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_income != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Your Monthly Income: ₹${_income!.toStringAsFixed(0)}',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _expenseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Last Week's Spending",
                hintText: 'Enter amount spent last week',
                prefixIcon: Icon(Icons.money_off),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _generateInsight,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Get AI Insight'),
            ),
            const SizedBox(height: 24),
            if (_summary != null)
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Weekly Spending Advice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_summary!),
                      if (_safeSpendingNextWeek != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Safe Spending Next Week:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(_safeSpendingNextWeek!),
                      ],
                      if (_reductionAdvice != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Reduction Advice:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(_reductionAdvice!),
                      ],
                      if (_tips != null && _tips!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Tips:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        ..._tips!.map(
                          (tip) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(child: Text(tip)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
