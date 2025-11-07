import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerOpinionModel {
  final int opinionId;
  final String opinionText;
  final int questionId;
  final DateTime? createdAt;

  AnswerOpinionModel({
    required this.opinionId,
    required this.opinionText,
    required this.questionId,
    this.createdAt,
  });

  factory AnswerOpinionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnswerOpinionModel(
      opinionId: data['opinion_id'] as int,
      opinionText: data['opinion_text'] as String,
      questionId: data['question_id'] as int,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory AnswerOpinionModel.fromMap(Map<String, dynamic> data) {
    return AnswerOpinionModel(
      opinionId: data['opinion_id'] as int,
      opinionText: data['opinion_text'] as String,
      questionId: data['question_id'] as int,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opinion_id': opinionId,
      'opinion_text': opinionText,
      'question_id': questionId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

