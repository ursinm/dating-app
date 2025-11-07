import 'package:cloud_firestore/cloud_firestore.dart';

class UserAnswerModel {
  final int answerId;
  final int userId;
  final int questionId;
  final int opinionId;
  final DateTime? createdAt;

  UserAnswerModel({
    required this.answerId,
    required this.userId,
    required this.questionId,
    required this.opinionId,
    this.createdAt,
  });

  factory UserAnswerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Защита от null значений
    final answerId = data['answer_id'];
    final userId = data['user_id'];
    final questionId = data['question_id'];
    final opinionId = data['opinion_id'];
    
    // Пропускаем документы с некорректными данными
    if (answerId == null || userId == null || questionId == null || opinionId == null) {
      throw Exception('UserAnswer document has null required fields');
    }
    
    return UserAnswerModel(
      answerId: answerId is int ? answerId : int.parse(answerId.toString()),
      userId: userId is int ? userId : int.parse(userId.toString()),
      questionId: questionId is int ? questionId : int.parse(questionId.toString()),
      opinionId: opinionId is int ? opinionId : int.parse(opinionId.toString()),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory UserAnswerModel.fromMap(Map<String, dynamic> data) {
    return UserAnswerModel(
      answerId: data['answer_id'] as int,
      userId: data['user_id'] as int,
      questionId: data['question_id'] as int,
      opinionId: data['opinion_id'] as int,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'answer_id': answerId,
      'user_id': userId,
      'question_id': questionId,
      'opinion_id': opinionId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

