// ============================================================================
// user_profile.dart — โมเดลข้อมูลโปรไฟล์ + สูตรคำนวณ TDEE/macros
// ----------------------------------------------------------------------------
// เก็บที่ Firestore: collection "users" → doc id = uid
// ใช้ที่:
//   - profile_view_page (แสดงผล)
//   - profile_edit_page (ฟอร์มกรอก)
//   - home_page (คำนวณเป้าแคล + macro targets)
// สูตร: Mifflin-St Jeor BMR × activity factor (ดู getter ด้านล่าง)
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// Activity multiplier — มาจากสูตรมาตรฐาน Harris-Benedict / Mifflin
// ค่า 1.375 (light) คือ default — ขยับน้อย-เบา 1-3 วัน/สัปดาห์
const _activityFactors = <String, double>{
  'sedentary': 1.2,
  'light': 1.375,
  'moderate': 1.55,
  'active': 1.725,
  'very_active': 1.9,
};

const activityLabels = <String, String>{
  'sedentary': 'นั่งโต๊ะ (แทบไม่ออกกำลังกาย)',
  'light': 'เบา (1-3 วัน/สัปดาห์)',
  'moderate': 'ปานกลาง (3-5 วัน/สัปดาห์)',
  'active': 'หนัก (6-7 วัน/สัปดาห์)',
  'very_active': 'หนักมาก (วันละ 2 ครั้ง / งานหนัก)',
};

const genderLabels = <String, String>{
  'male': 'ชาย',
  'female': 'หญิง',
  'other': 'ไม่ระบุ',
};

class UserProfile {
  final String firstName;
  final String nickName;
  final int age;
  final double heightCm;
  final double weightKg;
  final String gender;
  final String activityLevel;

  const UserProfile({
    required this.firstName,
    required this.nickName,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.gender = 'other',
    this.activityLevel = 'light',
  });

  static int _toInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.round();
    return int.tryParse(v.toString().trim()) ?? def;
  }

  static double _toDouble(dynamic v, {double def = 0}) {
    if (v == null) return def;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? def;
  }

  static String _toStr(dynamic v) => (v ?? '').toString().trim();

  // ----- คำนวณพลังงานพื้นฐาน (BMR) ด้วยสูตร Mifflin-St Jeor -----
  // Men:    BMR = 10W + 6.25H - 5A + 5
  // Women:  BMR = 10W + 6.25H - 5A - 161
  // Other:  เฉลี่ยกลาง (-78) — กรณีไม่ระบุเพศ
  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    switch (gender) {
      case 'male':
        return base + 5;
      case 'female':
        return base - 161;
      default:
        return base - 78; // gender-neutral average
    }
  }

  double get activityFactor => _activityFactors[activityLevel] ?? 1.375;

  /// TDEE = BMR × activity factor (kcal ที่ควรกินต่อวัน)
  /// คืน 0 ถ้า profile ยังไม่ครบ → home_page จะ fallback เป็น 2000
  int get dailyCalorieGoal {
    if (age <= 0 || heightCm <= 0 || weightKg <= 0) return 0;
    return (bmr * activityFactor).round();
  }

  // Macro targets เป็นกรัม
  // ใช้สัดส่วน 50/25/25 ของแคลทั้งหมด:
  //   - Carbs 50% (4 kcal/g)
  //   - Protein 25% (4 kcal/g)
  //   - Fat 25% (9 kcal/g)
  int get carbsTargetG => (dailyCalorieGoal * 0.50 / 4).round();
  int get proteinTargetG => (dailyCalorieGoal * 0.25 / 4).round();
  int get fatTargetG => (dailyCalorieGoal * 0.25 / 9).round();

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'nickName': nickName,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'gender': gender,
        'activityLevel': activityLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static UserProfile fromMap(Map<String, dynamic> m) {
    final genderRaw = _toStr(m['gender']);
    final activityRaw = _toStr(m['activityLevel']);
    return UserProfile(
      firstName: _toStr(m['firstName']),
      nickName: _toStr(m['nickName']),
      age: _toInt(m['age']),
      heightCm: _toDouble(m['heightCm']),
      weightKg: _toDouble(m['weightKg']),
      gender: genderLabels.containsKey(genderRaw) ? genderRaw : 'other',
      activityLevel:
          _activityFactors.containsKey(activityRaw) ? activityRaw : 'light',
    );
  }

  static UserProfile fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return fromMap(data);
  }

  UserProfile copyWith({
    String? firstName,
    String? nickName,
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? activityLevel,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      nickName: nickName ?? this.nickName,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}
