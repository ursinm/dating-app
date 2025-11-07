import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String text;

  QuestionModel({required this.id, required this.text});

  // --- ДОБАВЬТЕ ЭТОТ КОНСТРУКТОР ---
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      text: data['text'] ?? '',
    );
  }

  // --- ДОБАВЬТЕ ЭТОТ МЕТОД ---
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
    };
  }
}

