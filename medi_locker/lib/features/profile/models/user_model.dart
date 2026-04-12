import 'package:cloud_firestore/cloud_firestore.dart';

List<String> _stringListFromDynamic(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'nan')
        .toList();
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'nan') {
      return const [];
    }

    return normalized
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'nan')
        .toList();
  }

  return const [];
}

class UserModel {
  final String uid;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dob;
  final String bloodGroup;
  final String gender;
  final List<String> allergies;
  final List<String> chronicConditions;
  final bool isProfileComplete;
  final String? fcmToken;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dob,
    this.bloodGroup = '',
    this.gender = '',
    this.allergies = const [],
    this.chronicConditions = const [],
    this.isProfileComplete = false,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      firstName: d['first_name'] ?? '',
      lastName: d['last_name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'],
      dob: (d['dob'] as Timestamp?)?.toDate(),
      bloodGroup: d['blood_group'] ?? '',
      gender: d['gender'] ?? '',
      allergies: _stringListFromDynamic(d['allergies']),
      chronicConditions: _stringListFromDynamic(d['chronic_conditions']),
      isProfileComplete: d['is_profile_complete'] ?? false,
      fcmToken: d['fcm_token'],
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'dob': dob != null ? Timestamp.fromDate(dob!) : null,
        'blood_group': bloodGroup,
        'gender': gender,
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
        'is_profile_complete': isProfileComplete,
        'fcm_token': fcmToken,
      };

  UserModel copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dob,
    String? bloodGroup,
    String? gender,
    List<String>? allergies,
    List<String>? chronicConditions,
    bool? isProfileComplete,
    String? fcmToken,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        dob: dob ?? this.dob,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        gender: gender ?? this.gender,
        allergies: allergies ?? this.allergies,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        isProfileComplete: isProfileComplete ?? this.isProfileComplete,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );
}
