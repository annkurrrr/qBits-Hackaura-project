import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class WellbeingDashboardScreen extends StatelessWidget {
  const WellbeingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your dashboard.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Well-being Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wellbeing')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No mood logs yet.'));
          }
          // Prepare data for graph
          final stressLevels = <FlSpot>[];
          for (int i = 0; i < docs.length; i++) {
            final data = docs[i].data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final mood = data['mood'] ?? '';
            double stress = _stressLevel(mood);
            stressLevels.add(FlSpot(i.toDouble(), stress));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 280,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stress Level Trend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              minY: 1,
                              maxY: 4,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 1:
                                          return const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Text(
                                              '😊',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          );
                                        case 2:
                                          return const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Text(
                                              '😐',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          );
                                        case 3:
                                          return const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Text(
                                              '😔',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          );
                                        case 4:
                                          return const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Text(
                                              '😟',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          );
                                        default:
                                          return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < docs.length) {
                                        final data =
                                            docs[idx].data()
                                                as Map<String, dynamic>;
                                        final date = (data['date'] as Timestamp)
                                            .toDate();
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            '${date.month}/${date.day}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: stressLevels,
                                  isCurved: true,
                                  color: Colors.deepPurple,
                                  barWidth: 4,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 5,
                                              color: Colors.deepPurple,
                                              strokeWidth: 0,
                                            ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.deepPurple.withOpacity(0.18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(docs.length, (index) {
                final data =
                    docs[docs.length - 1 - index].data()
                        as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();
                final mood = data['mood'] ?? '';
                final note = data['note'] ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(
                      _moodEmoji(mood),
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text('${_moodLabel(mood)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${date.year}-${date.month}-${date.day}'),
                        if (note.isNotEmpty) Text(note),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'Happy':
        return '😊';
      case 'Neutral':
        return '😐';
      case 'Sad':
        return '😔';
      case 'Stressed':
        return '😟';
      default:
        return '❓';
    }
  }

  String _moodLabel(String mood) {
    switch (mood) {
      case 'Happy':
        return 'Happy';
      case 'Neutral':
        return 'Neutral';
      case 'Sad':
        return 'Sad';
      case 'Stressed':
        return 'Stressed';
      default:
        return 'Unknown';
    }
  }

  double _stressLevel(String mood) {
    switch (mood) {
      case 'Happy':
        return 1;
      case 'Neutral':
        return 2;
      case 'Sad':
        return 3;
      case 'Stressed':
        return 4;
      default:
        return 2;
    }
  }
}
