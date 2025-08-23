import 'package:flutter/material.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  Widget buildCategoryCard(String title, Color color, IconData icon, List<Map<String, String>> exercises) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      child: ExpansionTile(
        iconColor: color,
        collapsedIconColor: color,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: exercises.map((exercise) => Container(
                width: 260,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[50],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        exercise['image']!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ListTile(
                      title: Text(exercise['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(exercise['benefit']!),
                      trailing: Icon(Icons.favorite_border, color: Colors.grey),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personalizedDrills = [
      {'name': 'Balance Boost', 'benefit': 'Enhance ankle control', 'image': 'assets/balance_boost.gif'},
      {'name': 'Heel Support', 'benefit': 'Correct heel strike', 'image': 'assets/heel_support.gif'},
    ];

    final balanceExercises = [
      {'name': 'Single Leg Stand', 'benefit': 'Improve stability', 'image': 'assets/single_leg.gif'},
      {'name': 'Tandem Walk', 'benefit': 'Enhance coordination', 'image': 'assets/tandem_walk.gif'},
    ];
    final postureExercises = [
      {'name': 'Wall Angels', 'benefit': 'Correct shoulder alignment', 'image': 'assets/wall_angels.gif'},
      {'name': 'Chin Tucks', 'benefit': 'Neck posture correction', 'image': 'assets/chin_tucks.gif'},
    ];
    final flexibilityExercises = [
      {'name': 'Hamstring Stretch', 'benefit': 'Improve leg flexibility', 'image': 'assets/hamstring_stretch.gif'},
      {'name': 'Calf Stretch', 'benefit': 'Loosen calves', 'image': 'assets/calf_stretch.gif'},
    ];
    final gaitExercises = [
      {'name': 'Toe to Heel Walk', 'benefit': 'Normalize stride', 'image': 'assets/toe_heel_walk.gif'},
      {'name': 'Step Retrain Drill', 'benefit': 'Fix step length', 'image': 'assets/step_retrain.gif'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Your Personalized Fixes')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('🧠 Based on your last session',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: personalizedDrills.map((e) => Container(
                  width: 250,
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('Graph/Media Placeholder'),
                        ),
                      ),
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(e['image']!, height: 40, width: 40, fit: BoxFit.cover),
                        ),
                        title: Text(e['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(e['benefit']!),
                        trailing: Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const Divider(thickness: 1),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('🧩 Explore by Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            buildCategoryCard('🔵 Balance Training', Colors.blue, Icons.balance, balanceExercises),
            buildCategoryCard('🟡 Posture Correction', Colors.orange, Icons.accessibility_new, postureExercises),
            buildCategoryCard('🟢 Flexibility', Colors.green, Icons.self_improvement, flexibilityExercises),
            buildCategoryCard('🟣 Gait Retraining', Colors.purple, Icons.directions_walk, gaitExercises),
          ],
        ),
      ),
    );
  }
}