import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? profileImageUrl;

  @HiveField(4)
  int? age;

  @HiveField(5)
  String? address;

  @HiveField(6)
  String? bio;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? lastSyncedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.age,
    this.address,
    this.bio,
    required this.createdAt,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'age': age,
      'address': address,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      age: data['age'] as int?,
      address: data['address'] as String?,
      bio: data['bio'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastSyncedAt: data['lastSyncedAt'] != null
          ? DateTime.parse(data['lastSyncedAt'] as String)
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    int? age,
    String? address,
    String? bio,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      age: age ?? this.age,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
