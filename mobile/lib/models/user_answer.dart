import 'package:cloud_firestore/cloud_firestore.dart';

class UserAnswerModel {
  final String userId;
  final String questionId;
  final String answerId;

  UserAnswerModel({
    required this.userId,
    required this.questionId,
    required this.answerId,
  });

  // --- ДОБАВЬТЕ ЭТОТ КОНСТРУКТОР ---
  factory UserAnswerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserAnswerModel(
      userId: data['userId'] ?? '',
      questionId: data['questionId'] ?? '',
      answerId: data['answerId'] ?? '',
    );
  }

  // --- ДОБАВЬТЕ ЭТОТ МЕТОД ---
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'questionId': questionId,
      'answerId': answerId,
    };
  }
}

