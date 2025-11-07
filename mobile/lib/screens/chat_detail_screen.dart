import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/models/message_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/storage_service.dart';
import 'package:dating_app/services/online_status_service.dart';
import 'package:dating_app/screens/user_profile_screen.dart';
import 'package:dating_app/widgets/optimized_image.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final int chatId;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  int? _currentUserId;
  bool _isRecording = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  int? _playingMessageId;
  MessageModel? _replyToMessage; // Сообщение, на которое отвечаем

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await _authService.getCurrentUserId();
    _markChatAsRead();
    _listenToMessages();
  }

  Future<void> _markChatAsRead() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      await _apiService.markChatAsRead(widget.chatId, userId);
    }
  }

  void _listenToMessages() {
    _apiService.getMessagesByChatId(widget.chatId).listen((messages) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    
    final replyToId = _replyToMessage?.messageId;
    setState(() => _replyToMessage = null); // Сбрасываем ответ

    try {
      await _apiService.createMessage(
        MessageModel(
          messageId: 0,
          chatId: widget.chatId,
          senderId: _currentUserId!,
          messageText: messageText,
          messageType: MessageType.text,
          replyTo: replyToId,
        ),
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _sendImageMessage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    try {
      final imageUrl = await _storageService.uploadMessageImage(
        File(image.path),
        widget.chatId,
      );

      final replyToId = _replyToMessage?.messageId;
      setState(() => _replyToMessage = null); // Сбрасываем ответ
      
      await _apiService.createMessage(
        MessageModel(
          messageId: 0,
          chatId: widget.chatId,
          senderId: _currentUserId!,
          messageText: '📷 Фото',
          messageType: MessageType.image,
          fileUrl: imageUrl,
          replyTo: replyToId,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки фото: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Обновляем длительность каждую секунду
      while (_isRecording) {
        await Future.delayed(const Duration(seconds: 1));
        if (_isRecording) {
          setState(() => _recordingDuration++);
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (_recordingPath != null) {
        final voiceUrl = await _storageService.uploadVoiceMessage(
          _recordingPath!,
          widget.chatId,
        );

        final replyToId = _replyToMessage?.messageId;
        setState(() => _replyToMessage = null); // Сбрасываем ответ
        
        await _apiService.createMessage(
          MessageModel(
            messageId: 0,
            chatId: widget.chatId,
            senderId: _currentUserId!,
            messageText: '🎤 Голосовое сообщение',
            messageType: MessageType.voice,
            fileUrl: voiceUrl,
            voiceDuration: _recordingDuration,
            replyTo: replyToId,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки голосового: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  Future<void> _playVoiceMessage(MessageModel message) async {
    if (_playingMessageId == message.messageId) {
      await _audioPlayer.stop();
      setState(() => _playingMessageId = null);
    } else {
      await _audioPlayer.play(UrlSource(message.fileUrl!));
      setState(() => _playingMessageId = message.messageId);
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _playingMessageId = null);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: widget.otherUser.userId),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.purpleLight,
                ),
                child: widget.otherUser.userPhotoUrl != null
                    ? ClipOval(
                        child: OptimizedImage(
                          imageUrl: widget.otherUser.userPhotoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: const Icon(
                            Icons.person,
                            color: AppTheme.purplePrimary,
                            size: 20,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppTheme.purplePrimary,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.otherUser.isOnline 
                          ? 'В сети' 
                          : OnlineStatusService.formatLastSeen(widget.otherUser.lastSeen),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.otherUser.isOnline 
                            ? AppTheme.success 
                            : AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: Container(
              color: Colors.white,
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Начните разговор',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == _currentUserId;

                        return Dismissible(
                          key: Key('message_${message.messageId}'),
                          direction: isMe ? DismissDirection.endToStart : DismissDirection.none,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppTheme.error,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Удалить сообщение?'),
                                content: const Text('Сообщение будет удалено для всех.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          },
                          onDismissed: (direction) async {
                            await _apiService.deleteMessage(message.messageId);
                          },
                          child: GestureDetector(
                            onLongPress: () {
                              setState(() {
                                _replyToMessage = message;
                              });
                            },
                            child: _buildMessage(message, isMe),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Панель ввода
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Панель ответа (если выбрано сообщение для ответа)
                  if (_replyToMessage != null) _buildReplyPanel(),
                  // Панель ввода или записи
                  _isRecording
                      ? _buildRecordingPanel()
                      : _buildInputPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purpleLight,
              ),
              child: widget.otherUser.userPhotoUrl != null
                  ? ClipOval(
                      child: OptimizedImage(
                        imageUrl: widget.otherUser.userPhotoUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        placeholder: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: const Icon(
                          Icons.person,
                          color: AppTheme.purplePrimary,
                          size: 18,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: AppTheme.purplePrimary,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.purplePrimary : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Отображаем ответ, если он есть
                  if (message.replyTo != null) _buildReplyPreview(message, isMe),
                  if (message.isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: OptimizedImage(
                        imageUrl: message.fileUrl,
                        fit: BoxFit.cover,
                        width: 200,
                        placeholder: Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    )
                  else if (message.isVoice)
                    InkWell(
                      onTap: () => _playVoiceMessage(message),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _playingMessageId == message.messageId
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: isMe ? Colors.white : AppTheme.purplePrimary,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${message.voiceDuration ?? 0}s',
                            style: TextStyle(
                              color: isMe ? Colors.white : AppTheme.textDark,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      message.messageText,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.textDark,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message.createdAt != null
                        ? DateFormat('HH:mm').format(message.createdAt!)
                        : '',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : AppTheme.textGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purplePrimary,
              ),
              child: _currentUserId != null && widget.otherUser.userId == _currentUserId
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : FutureBuilder<int?>(
                      future: _authService.getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return FutureBuilder<UserModel?>(
                            future: _apiService.getUserById(snapshot.data!),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.hasData && userSnapshot.data?.userPhotoUrl != null) {
                                return ClipOval(
                                  child: OptimizedImage(
                                    imageUrl: userSnapshot.data!.userPhotoUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    placeholder: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                );
                              }
                              return const Icon(Icons.person, color: Colors.white, size: 18);
                            },
                          );
                        }
                        return const Icon(Icons.person, color: Colors.white, size: 18);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview(MessageModel message, bool isMe) {
    return FutureBuilder<MessageModel?>(
      future: _apiService.getMessageById(message.replyTo!),
      builder: (context, snapshot) {
        final replyMsg = snapshot.data;
        if (replyMsg == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.purpleLight.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border(
                left: BorderSide(
                  color: isMe ? Colors.white : AppTheme.purplePrimary,
                  width: 3,
                ),
              ),
            ),
            child: const Text(
              'Сообщение удалено',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textGrey,
              ),
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.purpleLight.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: isMe ? Colors.white : AppTheme.purplePrimary,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                replyMsg.senderId == _currentUserId ? 'Вы' : widget.otherUser.userName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : AppTheme.purplePrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                replyMsg.isImage 
                    ? '📷 Фото' 
                    : replyMsg.isVoice 
                        ? '🎤 Голосовое' 
                        : replyMsg.messageText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : AppTheme.textGrey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            color: AppTheme.purplePrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyToMessage!.senderId == _currentUserId ? 'Вы' : widget.otherUser.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.purplePrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToMessage!.isImage 
                      ? '📷 Фото' 
                      : _replyToMessage!.isVoice 
                          ? '🎤 Голосовое' 
                          : _replyToMessage!.messageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() => _replyToMessage = null);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.image_outlined),
          onPressed: _sendImageMessage,
          color: AppTheme.purplePrimary,
          iconSize: 24,
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _replyToMessage != null ? 'Ответить...' : 'Сообщение...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.mic_outlined),
          onPressed: _startRecording,
          color: AppTheme.purplePrimary,
          iconSize: 24,
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _sendTextMessage,
          color: AppTheme.purplePrimary,
          iconSize: 24,
        ),
      ],
    );
  }

  Widget _buildRecordingPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.error,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelRecording,
            color: AppTheme.error,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _stopRecording,
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }
}

