import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String description;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.description,
    this.photoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserModel(
        uid: doc.id,
        name: '',
        age: 0,
        gender: '',
        description: '',
        photoUrl: null,
      );
    }
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? '',
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
