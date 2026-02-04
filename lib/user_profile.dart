import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String firstName;
  final String nickName;
  final int age;
  final double heightCm;
  final double weightKg;

  const UserProfile({
    required this.firstName,
    required this.nickName,
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  // ===== helper parse กันชน =====
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

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'nickName': nickName,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        // แนะนำให้ใช้ serverTimestamp ใน Firestore จะชัวร์กว่า
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ใช้กรณีอ่านจาก Map ธรรมดา
  static UserProfile fromMap(Map<String, dynamic> m) {
    return UserProfile(
      firstName: _toStr(m['firstName']),
      nickName: _toStr(m['nickName']),
      age: _toInt(m['age']),
      heightCm: _toDouble(m['heightCm']),
      weightKg: _toDouble(m['weightKg']),
    );
  }

  // ใช้กรณีอ่านจาก DocumentSnapshot โดยตรง
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
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      nickName: nickName ?? this.nickName,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }
}
