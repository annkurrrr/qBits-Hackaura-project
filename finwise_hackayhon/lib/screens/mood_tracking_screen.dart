import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int _moodStreak = 0;
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

  String? _selectedMood;
  final TextEditingController _noteController = TextEditingController();
  bool _loading = false;
  bool _alreadyLoggedToday = false;

  @override
  void initState() {
    super.initState();
    _checkMoodLoggedToday();
    _getMoodStreak();
  }

  Future<void> _getMoodStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final streakDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('streaks')
        .get();
    setState(() {
      _moodStreak = streakDoc.data()?['moodStreak'] ?? 0;
    });
  }

  Future<void> _checkMoodLoggedToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wellbeing')
        .doc('${now.year}-${now.month}-${now.day}')
        .get();
    setState(() {
      _alreadyLoggedToday = doc.exists;
    });
  }

  Future<void> _saveMood() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final moodData = {
      'date': now,
      'mood': _selectedMood,
      'note': _noteController.text,
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wellbeing')
        .doc('${now.year}-${now.month}-${now.day}')
        .set(moodData);
    // Streak logic
    final streakRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('streaks');
    final streakDoc = await streakRef.get();
    int prevStreak = streakDoc.data()?['moodStreak'] ?? 0;
    DateTime? lastDate;
    if (streakDoc.exists && streakDoc.data()?['lastMoodDate'] != null) {
      lastDate = (streakDoc.data()?['lastMoodDate'] as Timestamp).toDate();
    }
    bool isConsecutive = false;
    if (lastDate != null) {
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      isConsecutive =
          lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day;
    }
    int newStreak = isConsecutive ? prevStreak + 1 : 1;
    await streakRef.set({
      'moodStreak': newStreak,
      'lastMoodDate': now,
    }, SetOptions(merge: true));
    setState(() {
      _moodStreak = newStreak;
    });
    await _updatePoints(10); // Award points for mood log
    setState(() {
      _loading = false;
      _alreadyLoggedToday = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mood saved!')));
    _noteController.clear();
    setState(() => _selectedMood = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Your Mood')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'How are you feeling today?',
                  style: TextStyle(fontSize: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Streak: $_moodStreak',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_alreadyLoggedToday)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You have already logged your mood for today. Come back tomorrow!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: const Text('60a Happy'),
                    selected: _selectedMood == 'Happy',
                    onSelected: (_) => setState(() => _selectedMood = 'Happy'),
                  ),
                  ChoiceChip(
                    label: const Text('610 Neutral'),
                    selected: _selectedMood == 'Neutral',
                    onSelected: (_) =>
                        setState(() => _selectedMood = 'Neutral'),
                  ),
                  ChoiceChip(
                    label: const Text('614 Sad'),
                    selected: _selectedMood == 'Sad',
                    onSelected: (_) => setState(() => _selectedMood = 'Sad'),
                  ),
                  ChoiceChip(
                    label: const Text('61f Stressed'),
                    selected: _selectedMood == 'Stressed',
                    onSelected: (_) =>
                        setState(() => _selectedMood = 'Stressed'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Add a note (optional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading || _selectedMood == null
                      ? null
                      : _saveMood,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
