import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final int likeId;
  final int fromUserId;
  final int toUserId;
  final DateTime? createdAt;

  LikeModel({
    required this.likeId,
    required this.fromUserId,
    required this.toUserId,
    this.createdAt,
  });

  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Защита от null значений
    final likeId = data['like_id'];
    final fromUserId = data['from_user_id'];
    final toUserId = data['to_user_id'];
    
    // Пропускаем документы с некорректными данными
    if (likeId == null || fromUserId == null || toUserId == null) {
      throw Exception('Like document has null required fields');
    }
    
    return LikeModel(
      likeId: likeId is int ? likeId : int.parse(likeId.toString()),
      fromUserId: fromUserId is int ? fromUserId : int.parse(fromUserId.toString()),
      toUserId: toUserId is int ? toUserId : int.parse(toUserId.toString()),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory LikeModel.fromMap(Map<String, dynamic> data) {
    return LikeModel(
      likeId: data['like_id'] as int,
      fromUserId: data['from_user_id'] as int,
      toUserId: data['to_user_id'] as int,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'like_id': likeId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

