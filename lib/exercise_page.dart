// ============================================================================
// exercise_page.dart — บันทึกการออกกำลังกาย (ยังเป็น MOCK)
// ----------------------------------------------------------------------------
// ⚠️ ฟีเจอร์ยังไม่เสร็จ: กด "บันทึก" แค่โชว์ SnackBar
// ยังไม่บันทึกลง Firestore + ยังไม่หักจาก Calories Today ของ home
// TODO: integrate กับ meals collection หรือ exercises collection แยก
// ============================================================================

import 'package:flutter/material.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _kcal = TextEditingController(text: '0');

  @override
  void dispose() {
    _kcal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'บันทึกการออกกำลังกาย',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'เผาผลาญ (kcal)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_fire_department_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('บันทึก (Mock): เผาผลาญ ${_kcal.text} kcal')),
              );
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}
