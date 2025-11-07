import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final int userId;
  final String userName;
  final String userEmail;
  final int? userAge;
  final String? userGender;
  final String? userDescription;
  final String? userPhotoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAge,
    this.userGender,
    this.userDescription,
    this.userPhotoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Защита от null значений
    final userId = data['user_id'];
    final userName = data['user_name'];
    final userEmail = data['user_email'];
    
    // Пропускаем документы с некорректными данными
    if (userId == null || userName == null || userEmail == null) {
      throw Exception('User document has null required fields');
    }
    
    return UserModel(
      userId: userId is int ? userId : int.parse(userId.toString()),
      userName: userName.toString(),
      userEmail: userEmail.toString(),
      userAge: data['user_age'] as int?,
      userGender: data['user_gender'] as String?,
      userDescription: data['user_description'] as String?,
      userPhotoUrl: data['user_photo_url'] as String?,
      isOnline: data['is_online'] as bool? ?? false,
      lastSeen: (data['last_seen'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userId: data['user_id'] as int,
      userName: data['user_name'] as String,
      userEmail: data['user_email'] as String,
      userAge: data['user_age'] as int?,
      userGender: data['user_gender'] as String?,
      userDescription: data['user_description'] as String?,
      userPhotoUrl: data['user_photo_url'] as String?,
      isOnline: data['is_online'] as bool? ?? false,
      lastSeen: (data['last_seen'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_age': userAge,
      'user_gender': userGender,
      'user_description': userDescription,
      'user_photo_url': userPhotoUrl,
      'is_online': isOnline,
      'last_seen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    int? userId,
    String? userName,
    String? userEmail,
    int? userAge,
    String? userGender,
    String? userDescription,
    String? userPhotoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAge: userAge ?? this.userAge,
      userGender: userGender ?? this.userGender,
      userDescription: userDescription ?? this.userDescription,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

