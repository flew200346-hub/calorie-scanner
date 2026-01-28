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

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'nickName': nickName,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  static UserProfile fromMap(Map<String, dynamic> m) {
    return UserProfile(
      firstName: (m['firstName'] ?? '').toString(),
      nickName: (m['nickName'] ?? '').toString(),
      age: (m['age'] ?? 0) is int
          ? (m['age'] ?? 0)
          : int.tryParse('${m['age']}') ?? 0,
      heightCm: (m['heightCm'] ?? 0).toDouble(),
      weightKg: (m['weightKg'] ?? 0).toDouble(),
    );
  }
}
