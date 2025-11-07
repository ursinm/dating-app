import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerOptionModel {
  final String id;
  final String text;

  AnswerOptionModel({required this.id, required this.text});

  factory AnswerOptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return AnswerOptionModel(
      id: doc.id,
      text: data?['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
    };
  }
}
