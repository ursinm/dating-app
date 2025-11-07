import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating_app/models/answer_option.dart';
import 'package:dating_app/models/question.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/models/user_answer.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      // Используем user_id для идентификации документа
      final snapshot = await _db.collection('users')
          .where('user_id', isEqualTo: user.userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        // Обновляем существующий документ
        await snapshot.docs.first.reference.update(user.toMap());
      } else {
        // Создаем новый документ
        await _db.collection('users').add(user.toMap());
      }
    } catch (e) {
      print('ОШИБКА createUser: $e'); // Вывод в консоль
      rethrow;
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').get();
      final users = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc);
          users.add(user);
        } catch (e) {
          print('⚠️ Пропускаем пользователя ${doc.id}: $e');
          continue; // Пропускаем некорректный документ
        }
      }
      return users;
    } catch (e) {
      print('ОШИБКА getUsers: $e'); // Вывод в консоль
      rethrow;
    }
  }

  Future<UserModel?> getUser(int userId) async {
    try {
      final snapshot = await _db.collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return UserModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('ОШИБКА getUser: $e'); // Вывод в консоль
      rethrow;
    }
  }

  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      final snapshot = await _db.collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          ...data,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('ОШИБКА updateUser: $e'); // Вывод в консоль
      rethrow;
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final snapshot = await _db.collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }
    } catch (e) {
      print('ОШИБКА deleteUser: $e'); // Вывод в консоль
      rethrow;
    }
  }

  // --- 3. УЛУЧШЕНИЕ: Маппинг для QuestionModel ---
  Future<List<QuestionModel>> getQuestions() async {
    try {
      QuerySnapshot snapshot = await _db.collection('questions').get();
      return snapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ОШИБКА getQuestions: $e'); // Вывод в консоль
      rethrow;
    }
  }

  // --- 4. УЛУЧШЕНИЕ: Маппинг для AnswerOptionModel ---
  Future<List<AnswerOptionModel>> getAnswerOptions(String questionId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('questions')
          .doc(questionId)
          .collection('answer_options') // Исправлена опечатка 'answer_opinions'
          .get();
      return snapshot.docs
          .map((doc) => AnswerOptionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ОШИБКА getAnswerOptions: $e'); // Вывод в консоль
      rethrow;
    }
  }

  Future<void> saveUserAnswers(String userId, Map<String, String> answers) async {
    try {
      final batch = _db.batch();
      
      final snapshot = await _db
          .collection('user_answers')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      for (final entry in answers.entries) {
        final docRef = _db.collection('user_answers').doc();
        final userAnswer = UserAnswerModel(
          userId: userId,
          questionId: entry.key,
          answerId: entry.value,
        );
        batch.set(docRef, userAnswer.toFirestore()); // Используем .toFirestore()
      }
      
      await batch.commit();
    } catch (e) {
      print('ОШИБКА saveUserAnswers: $e'); // Вывод в консоль
      rethrow;
    }
  }

  Future<List<UserAnswerModel>> getAllUserAnswers() async {
    try {
      final snapshot = await _db.collection('user_answers').get();
      return snapshot.docs
          .map((doc) => UserAnswerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ОШИБКА getAllUserAnswers: $e');
      rethrow;
    }
  }

  Future<List<UserAnswerModel>> getAnswersForTwoUsers(
      String userId1, String userId2) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('user_answers')
          .where('userId', whereIn: [userId1, userId2]).get();
          
      return snapshot.docs
          .map((doc) => UserAnswerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ОШИБКА getAnswersForTwoUsers: $e'); // Вывод в консоль
      rethrow;
    }
  }
}

