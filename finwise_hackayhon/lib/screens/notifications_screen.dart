import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'debt_mapping_screen.dart';
import 'mood_tracking_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('financial_profile')
            .doc('debt_tracker')
            .collection('debts')
            .get(),
        builder: (context, snapshot) {
          final now = DateTime.now();
          final currentMonth = '${now.year}-${now.month}';
          final todayDocId = '${now.year}-${now.month}-${now.day}';
          List<Widget> notifications = [];
          // Debt notification
          if (snapshot.hasData) {
            int unpaid = 0;
            for (var doc in snapshot.data!.docs) {
              final debt = doc.data() as Map<String, dynamic>;
              if (debt['lastPaidMonth'] != currentMonth) {
                unpaid++;
              }
            }
            if (unpaid > 0) {
              notifications.add(
                Card(
                  color: Colors.red.shade100,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      'You have $unpaid debt installment(s) to pay this month!',
                    ),
                    trailing: TextButton(
                      child: const Text('Pay Now'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DebtMappingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }
          }
          // Mood reminder notification (only if not logged today)
          notifications.add(
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('wellbeing')
                  .doc(todayDocId)
                  .get(),
              builder: (context, moodSnapshot) {
                if (moodSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (moodSnapshot.hasData && moodSnapshot.data!.exists) {
                  // Mood already logged, don't show notification
                  return const SizedBox.shrink();
                }
                // Mood not logged, show notification
                return Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const Icon(
                      Icons.emoji_emotions,
                      color: Colors.blue,
                    ),
                    title: const Text('Log your mood for today!'),
                    trailing: TextButton(
                      child: const Text('Log Mood'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MoodTrackingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
          // Only show notifications that are not SizedBox.shrink()
          return ListView(
            padding: const EdgeInsets.all(16),
            children: notifications,
          );
        },
      ),
    );
  }
}
