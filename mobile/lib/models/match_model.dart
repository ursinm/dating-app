import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final int matchId;
  final int firstUserId;
  final int secondUserId;
  final DateTime? createdAt;

  MatchModel({
    required this.matchId,
    required this.firstUserId,
    required this.secondUserId,
    this.createdAt,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Защита от null значений
    final matchId = data['match_id'];
    final firstUserId = data['match_first_user_id'];
    final secondUserId = data['match_second_user_id'];
    
    // Пропускаем документы с некорректными данными
    if (matchId == null || firstUserId == null || secondUserId == null) {
      throw Exception('Match document has null required fields');
    }
    
    return MatchModel(
      matchId: matchId is int ? matchId : int.parse(matchId.toString()),
      firstUserId: firstUserId is int ? firstUserId : int.parse(firstUserId.toString()),
      secondUserId: secondUserId is int ? secondUserId : int.parse(secondUserId.toString()),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory MatchModel.fromMap(Map<String, dynamic> data) {
    return MatchModel(
      matchId: data['match_id'] as int,
      firstUserId: data['match_first_user_id'] as int,
      secondUserId: data['match_second_user_id'] as int,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'match_id': matchId,
      'match_first_user_id': firstUserId,
      'match_second_user_id': secondUserId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Проверяет, участвует ли пользователь в этом мэтче
  bool hasUser(int userId) {
    return firstUserId == userId || secondUserId == userId;
  }

  // Получает ID другого пользователя в мэтче
  int getOtherUserId(int currentUserId) {
    return firstUserId == currentUserId ? secondUserId : firstUserId;
  }
}

