import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final int questionId;
  final String questionText;
  final DateTime? createdAt;

  QuestionModel({
    required this.questionId,
    required this.questionText,
    this.createdAt,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      questionId: data['question_id'] as int,
      questionText: data['question_text'] as String,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory QuestionModel.fromMap(Map<String, dynamic> data) {
    return QuestionModel(
      questionId: data['question_id'] as int,
      questionText: data['question_text'] as String,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

