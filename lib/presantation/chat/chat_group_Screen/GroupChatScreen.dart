import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/api_servicer.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_state.dart';
import 'package:nde_email/presantation/chat/widget/custom_appbar.dart';
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/presantation/chat/widget/scaffold.dart';
import 'package:nde_email/presantation/chat/widget/voicerec_ui.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_widget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/grp_showbottom_sheet.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:objectid/objectid.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/respiratory.dart';
import '../../../utils/simmer_effect.dart/chat_simmerefect.dart';
import '../../widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import '../../widgets/chat_widgets/messager_Wifgets/buildMessageInputField_widgets.dart';
import '../Socket/Socket_Service.dart';
import 'group_media_viewer.dart';
import '../chat_private_screen/messager_Bloc/widget/VideoPlayerScreen.dart';
import '../chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';
import '../chat_private_screen/messager_Bloc/widget/double_tick_ui.dart';
import 'package:nde_email/presantation/chat/widget/image_viewer.dart';
import '../chat_list/chat_session_storage/chat_session.dart';
import '../chat_list/chat_bloc.dart';
import '../chat_list/chat_event.dart';

import '../model/emoj_model.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.groupAvatarUrl,
    required this.currentUserId,
    required this.conversationId,
    required this.datumId,
    required this.grpChat,
    required this.favorite,
    required this.groupMembers,
  });

  final String conversationId;
  final String currentUserId;
  final String datumId;
  final String groupAvatarUrl;
  final String groupName;
  final List<String>? groupMembers;
  final bool grpChat;
  final bool favorite;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  String currentUserId = '';
  List<Map<String, dynamic>> dbMessages = [];

  final ValueNotifier<bool> isLongPressed = ValueNotifier<bool>(false);
  late List<String> groupMembers;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> socketMessages = [];
  final SocketService socketService = SocketService();

  Duration _audioDuration = Duration.zero;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  Duration _currentDuration = Duration.zero;
  bool _hasLeftGroup = false;
  Map<String, dynamic>? _permissionResponse;
  int _currentPage = 1;

  File? _fileUrl;
  final FocusNode _focusNode = FocusNode();
  late final GroupChatBloc _groupBloc;
  bool _hasNextPage = false;

  File? _imageFile;

  bool _initialScrollDone = false;
  bool _isCompleted = false;
  bool _isDeletingMessages = false;
  bool _isLoadingMore = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _isSelectionMode = false;

  bool _isTyping = false;
  int _limit = 40;

  final TextEditingController _messageController = TextEditingController();

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  int _recordDuration = 0;
  Timer? _recordTimer;
  File? _recordedFile;
  String? _recordedFilePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late final RecorderController _recorderController = RecorderController();
  Timer? _recordingTimer;
  Map<String, dynamic>? _replyMessage;
  Map<String, dynamic>? _replyPreview;
  final ScrollController _scrollController = ScrollController();
  // 🔥 Highlight Logic
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Set<String> _selectedMessageIds = {};
  final Set<String> _selectedMessageKeys = {};
  List<dynamic> _selectedMessages = [];
  bool _showEmoji = false;
  bool _showSearchAppBar = false;
  Timer? _timer;
  Duration _totalDuration = Duration.zero;
  bool _permissionChecked = false;

  // Pagination / Windowing
  List<Map<String, dynamic>> _allMessages = [];
  int _visibleCount = 0;
  final int _pageStep = 20;
  final int _initialVisible = 20;
  final ValueNotifier<List<Map<String, dynamic>>> _messagesNotifier =
      ValueNotifier([]);

  // 👇 NEW: reaction stream + seen ids (for dedupe)
  StreamSubscription<MessageReaction>? _reactionSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  final Set<String> _seenMessageIds = {};

  // Status & Connectivity
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final Set<String> _alreadyRead = {};
  final List<Map<String, dynamic>> _offlineQueue = [];
  final Map<String, String> _pendingStatusUpdates =
      {}; // Buffer for race conditions

  // Track last loaded data to prevent overwrite
  List<dynamic>? _lastLoadedData;

  @override
  void dispose() {
    final unsentText = _messageController.text.trim();
    if (unsentText.isNotEmpty) {
      GrpLocalChatStorage.saveDraftMessage(widget.conversationId, unsentText);
    } else {
      GrpLocalChatStorage.clearDraftMessage(widget.conversationId);
    }
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    _timer?.cancel();
    _recordingTimer?.cancel();
    _recordTimer?.cancel();

    _reactionSubscription?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _connSub?.cancel();

    _clearSessionImagePath();
    // SocketService().disconnect();

    super.dispose();
  }

  List<String> extractGroupMembers(List<dynamic> messages) {
    final Set<String> memberIds = {};

    for (var msg in messages) {
      if (msg['properties'] != null) {
        for (var prop in msg['properties']) {
          if (prop['user'] != null && prop['user']['_id'] != null) {
            memberIds.add(prop['user']['_id']);
          }
        }
      }
    }

    return memberIds.toList();
  }

  @override
  void initState() {
    super.initState();
    currentUserId = widget.currentUserId;

    _checkingPersmmion();
    _initMessages();

    // Check connectivity
    Connectivity().checkConnectivity().then((results) {
      final hasNet =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      if (mounted) setState(() => _isOnline = hasNet);
    });

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      if (hasNet != _isOnline) {
        if (mounted) setState(() => _isOnline = hasNet);
        if (hasNet) {
          _flushOfflinePendingMessages();
        }
      }
    });

    _groupBloc = GroupChatBloc(socketService, GrpMessagerApiService());
    _initializeSocket();

    _loadCurrentUserId();

    if (!_permissionChecked) {
      _groupBloc.add(PermissionCheck(widget.datumId));
      _permissionChecked = true;
    }

    _fetchMessages2();

    _scrollController.addListener(_scrollListener);
    _setupReactionListener();
    _setupMessageListener();
    // Add text change listener for draft saving
    _messageController.addListener(() {
      final text = _messageController.text.trim();
      if (text.isEmpty) {
        _clearDraft();
      } else {
        _saveDraft(text);
      }
    });

    // Load draft after initialization
    _loadDraft();
    groupMembers = widget.groupMembers ?? [];
    print("Group Members: $groupMembers");
// Fetch fresh group details to ensure we have all members
    _groupBloc.add(FetchGroupDetails(groupId: widget.datumId));
    _loadCurrentUserName();

    // Listen to BLoC states for instant status updates
    _groupBloc.stream.listen((state) {
      if (state is GrpMessageSentSuccessfully) {
        final serverMessageId = state.sentMessage.messageId;
        final serverStatus = state.sentMessage.messageStatus ?? 'sent';

        if (serverMessageId != null && serverMessageId.isNotEmpty) {
          debugPrint(
              '📤 Message sent successfully: $serverMessageId with status: $serverStatus');
          _updateMessageStatus(serverMessageId, serverStatus);
        }
      }
    });
  }

  String currentUserName = "";
  Future<void> _loadCurrentUserName() async {
    final name = await UserPreferences.getUsername();
    if (name != null) {
      setState(() {
        currentUserName = name;
      });
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (file != null) {
        final File localFile = File(file.path);

        if (!localFile.existsSync()) {
          log("  File does not exist at: ${file.path}");
          Messenger.alert(msg: "Selected image is missing.");
          return;
        }

        final mimeType = lookupMimeType(file.path);
        final isImage = mimeType != null && mimeType.startsWith('image/');
        log("📄 MIME Type: $mimeType");
        log("🖼️ Is Image: $isImage");

        final prefs = await SharedPreferences.getInstance();

        if (isImage) {
          await prefs.setString('chat_image_path', localFile.path);
          log(" Image path saved: ${localFile.path}");
        }

        GrpShowAltDialog.grpshowOptionsDialog(context,
            conversationId: widget.conversationId,
            senderId: currentUserId,
            receiverId: widget.datumId,
            isGroupChat: true,
            onOptionSelected: _sendMessageImage);

        final message = {
          'content': '',
          'sender': {'_id': currentUserId},
          'receiver': {'_id': widget.datumId},
          'messageStatus': 'pending',
          'time': DateTime.now().toIso8601String(),
          'localImagePath': file.path,
          'fileName': file.name,
          'fileType': mimeType,
          'imageUrl': file.path,
          'fileUrl': null,
        };

        log("🟢 Local message metadata: $message");

        setState(() {
          socketMessages.add(message);
        });

        context.read<GroupChatBloc>().add(
              GrpUploadFileEvent(
                file: localFile,
                convoId: widget.conversationId,
                senderId: currentUserId,
                receiverId: widget.datumId,
                groupId: widget.datumId,
                message: "",
                isGroupMessage: false,
                groupMessageId: null,
              ),
            );

        Navigator.pop(context);
      }
    } catch (e) {
      log('  Error opening camera: $e');
      Messenger.alert(msg: "Could not open camera.");
    }
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        _startTimer();

        setState(() {
          _isRecording = true;
          _recordedFilePath = path;
        });
      } else {
        Messenger.alert(msg: "Microphone permission denied");
      }
    } catch (e) {
      log('Error starting recording: $e');
      setState(() => _isRecording = false);
    }
  }

  bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void toggleSearchAppBar() {
    setState(() {
      _showSearchAppBar = !_showSearchAppBar;
    });
  }

  /// 🔁 SOCKET CALLBACK – now also understands reaction events, like private chat
  void onMessageReceived(Map<String, dynamic> rawData) {
    // Step 1: Extract the actual message from the weird wrapper
    Map<String, dynamic> messageData;

    if (rawData['data'] != null) {
      // Case 1: { "data": { ...message... } } → your log shows this
      messageData = rawData['data'] as Map<String, dynamic>;
    } else if (rawData is Map && rawData.values.isNotEmpty) {
      // Case 2: The message is directly in rawData (fallback)
      messageData = rawData;
    } else {
      log("Invalid message format: $rawData");
      return;
    }

    // Step 2: Handle reactions (if backend sends event separately)
    if (messageData['event'] == 'updated_reaction') {
      _handleReactionUpdate(messageData['data']);
      return;
    }

    // Step 3: Extract fields safely
    final content = (messageData['content'] ?? '').toString().trim();
    final imageUrl = messageData['thumbnailUrl'] ?? messageData['originalUrl'];
    final fileUrl = messageData['originalUrl'] ?? messageData['fileUrl'];
    final fileName = messageData['fileName'];
    final userName = messageData['userName'] ?? 'Unknown';

    if (content.isEmpty && imageUrl == null && fileUrl == null) return;

    final messageId =
        (messageData['message_id'] ?? messageData['id'])?.toString();
    if (messageId != null && _seenMessageIds.contains(messageId)) {
      log("Duplicate group message ignored: $messageId");
      return;
    }
    if (messageId != null) _seenMessageIds.add(messageId);

    final newMessage = {
      'message_id': messageId,
      'content': content,
      'sender': messageData['sender'] ?? {},
      'receiver': messageData['receiver'] ?? {},
      'messageStatus': messageData['messageStatus'] ?? 'delivered',
      'time': messageData['time'],
      'imageUrl': imageUrl,
      'fileName': fileName,
      'userName': userName,
      'fileUrl': fileUrl,
      'fileType': messageData['mimeType'] ?? messageData['fileType'],
      'isForwarded': messageData['isForwarded'] ?? false,
      'ContentType': messageData['ContentType'] ?? 'text',
      'isReplyMessage': messageData['isReplyMessage'] ?? false,
      'repliedMessage': messageData['reply'] ?? messageData['repliedMessage'],
      'reactions': messageData['reactions'] ?? [],
    };

    if (!mounted) return;

    setState(() {
      final exists = socketMessages.any((msg) =>
          (msg['message_id'] ?? msg['id']) == newMessage['message_id']);

      if (!exists) {
        socketMessages.add(newMessage);
        _scrollToBottom();
        log("NEW GROUP MESSAGE ADDED: $content - $userName");
      }

      final combined = [...dbMessages, ...messages, ...socketMessages];
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      _updateNotifier();
    });
  }

  void _handleReactionUpdate(dynamic reactionData) {
    try {
      MessageReaction? reaction;
      if (reactionData is Map<String, dynamic>) {
        reaction = MessageReaction.fromMap(reactionData);
      } else if (reactionData is List &&
          reactionData.isNotEmpty &&
          reactionData.first is Map) {
        reaction = MessageReaction.fromMap(
            Map<String, dynamic>.from(reactionData.first));
      }
      if (reaction == null) return;
      _updateMessageWithReaction(reaction);
    } catch (e, st) {
      debugPrint('❌ Group reaction update failed: $e\n$st');
    }
  }

  /// 🔁 listen to SocketService.reactionStream (same as private)
  void _setupReactionListener() {
    _reactionSubscription?.cancel();
    _reactionSubscription = _reactionSubscription =
        socketService.reactionStream.listen((MessageReaction reaction) {
      _updateMessageWithReaction(reaction);
    });
  }

  /// 🔁 Listen to Message Stream
  void _setupMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription =
        socketService.messageStream.listen((Map<String, dynamic> data) {
      log("📩 Stream received message update: $data");
      onMessageReceived(data);
    });
  }

  /// 🔁 Listen to Status Update Stream
  void _setupStatusListener() {
    _statusSubscription?.cancel();
    _statusSubscription =
        socketService.statusUpdateStream.listen((statusUpdate) {
      if (!mounted) return;

      final dynamic rawStatus =
          statusUpdate['messageStatus'] ?? statusUpdate['status'];
      final status = (rawStatus ?? '').toString().trim();
      if (status.isEmpty) return;

      final ids = statusUpdate['messageIds'] ??
          statusUpdate['singleMessageId'] ??
          statusUpdate['messageId'];

      debugPrint('📥 Group Status update received: $statusUpdate');

      // normalize to List<String>
      final List<String> idList = [];
      if (ids is List) {
        for (final id in ids) {
          if (id != null) idList.add(id.toString());
        }
      } else if (ids != null) {
        idList.add(ids.toString());
      }

      for (final id in idList) {
        _updateMessageStatus(id, status);
      }
    });
  }

  /// Update message status in all local lists
  void _updateMessageStatus(String messageId, String status) {
    if (messageId.isEmpty || status.isEmpty) return;

    bool updated = false;

    void updateInList(List<Map<String, dynamic>> list, String listName) {
      for (int i = 0; i < list.length; i++) {
        final msg = list[i];
        final msgId = (msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? '')
            .toString();
        if (msgId == messageId) {
          final oldStatus = (msg['messageStatus'] ?? '').toString();

          // Don't downgrade status (read > delivered > sent)
          if (oldStatus != 'read' || status == 'read') {
            // Create new map instance to force UI rebuild
            final newMsg = Map<String, dynamic>.from(msg);
            newMsg['messageStatus'] = status;
            list[i] = newMsg;
            updated = true;
            debugPrint(
                '✅ Updated message $messageId status to $status in $listName');
          }
          break;
        }
      }
    }

    setState(() {
      updateInList(dbMessages, 'dbMessages');
      updateInList(messages, 'messages');
      updateInList(socketMessages, 'socketMessages');

      if (updated) {
        final combined = _getCombinedMessages();
        GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      } else {
        // ⚠️ Race condition handling: Message might be temporary (pending replacement)
        // Store status to apply later when real ID arrives
        _pendingStatusUpdates[messageId] = status;
        debugPrint(
            '⏳ Buffered status update for missing ID: $messageId -> $status');
      }
      _updateNotifier();
      _refreshMessages();
    });
  }

  /// Actually apply reaction change to in-memory lists and save
  void _updateMessageWithReaction(MessageReaction reaction) {
    if (!mounted) return;
    String normalizeId(dynamic id) => id?.toString().trim() ?? '';

    bool updated = false;
    final targetId = normalizeId(reaction.messageId);
    log('🔍 _updateMessageWithReaction: Target ID: $targetId, Emoji: ${reaction.emoji}');

    void updateReactions(List<Map<String, dynamic>> list, String listName) {
      for (var msg in list) {
        final msgId = normalizeId(
            msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? msg['id']);
        if (msgId == targetId) {
          log('✅ Found message in $listName. Updating reactions...');
          List<Map<String, dynamic>> oldReactions =
              List<Map<String, dynamic>>.from(msg['reactions'] ?? []);

          // remove old reaction from same user
          oldReactions.removeWhere((r) =>
              normalizeId(r['user']?['_id']) == normalizeId(reaction.user.id));

          if (!reaction.isRemoval) {
            oldReactions.add({
              'emoji': reaction.emoji,
              'reacted_at': reaction.reactedAt.toIso8601String(),
              'user': {
                '_id': reaction.user.id,
                'first_name': reaction.user.firstName,
                'last_name': reaction.user.lastName,
              }
            });
          }

          msg['reactions'] = List<Map<String, dynamic>>.from(oldReactions);
          updated = true;
          break;
        }
      }
    }

    updateReactions(dbMessages, 'dbMessages');
    updateReactions(messages, 'messages');
    updateReactions(socketMessages, 'socketMessages');

    if (updated) {
      log('🔄 Reaction update successful. Triggering rebuild.');
      setState(() {
        // _reactionRebuildCounter++; // Force rebuild - Removed
        _updateNotifier();
      });
      final combined = _getCombinedMessages();
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
    } else {
      log('⚠️ Message with ID $targetId not found in any list.');
    }
  }

  // ------------------ Reaction Helpers ------------------

  List<Map<String, dynamic>> _extractReactions(dynamic raw) {
    final List<Map<String, dynamic>> out = [];

    if (raw is! List) return out;

    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);

      final emoji = m['emoji']?.toString();
      if (emoji == null || emoji.trim().isEmpty) continue;

      String? userId = m['userId']?.toString();
      final user = m['user'];

      // user is full object
      if ((userId == null || userId.isEmpty) && user is Map) {
        userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
      }

      // user is just string id
      if ((userId == null || userId.isEmpty) && user is String) {
        userId = user;
      }

      if (userId == null || userId.isEmpty) {
        userId = "unknown";
      }

      out.add({
        'emoji': emoji,
        'userId': userId,
        'user': user is Map ? Map<String, dynamic>.from(user) : null,
        'reacted_at': (m['reacted_at'] ?? m['createdAt'] ?? '').toString(),
      });
    }

    return out;
  }

  String _normalizeMessageIdForApi(String messageId) {
    if (messageId.isEmpty) return messageId;

    if (messageId.startsWith('forward_')) {
      final parts = messageId.split('_');
      if (parts.length >= 3) {
        return parts[1];
      }
    }
    return messageId;
  }

  void _updateLocalReactions(String targetMessageId, String? newEmoji) {
    if (targetMessageId.trim().isEmpty) return;

    String normalizeId(dynamic id) => id?.toString().trim() ?? '';
    final apiTargetId = _normalizeMessageIdForApi(targetMessageId);

    bool changed = false;

    void updateList(List<Map<String, dynamic>> list, String listName) {
      for (int i = 0; i < list.length; i++) {
        final msg = list[i];
        final rawMsgId = normalizeId(
          msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? msg['_id'],
        );
        final normalizedMsgId = _normalizeMessageIdForApi(rawMsgId);

        // Check both exact match and normalized match
        if (rawMsgId != targetMessageId && normalizedMsgId != apiTargetId) {
          continue;
        }

        debugPrint(
            "⚡ [GroupChat] Optimistic reaction update for $targetMessageId in $listName");

        // Normalize existing reactions
        final reactions = _extractReactions(msg['reactions']);

        // remove my old reaction (if any)
        reactions.removeWhere((r) {
          final uid = (r['userId'] ?? r['user']?['_id'])?.toString();
          return uid == currentUserId;
        });

        // add new reaction if not null/empty
        if (newEmoji != null && newEmoji.isNotEmpty) {
          final nameParts = currentUserName.split(" ");
          final firstName = nameParts.length > 0 ? nameParts.first : "";
          final lastName =
              nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

          reactions.add({
            'emoji': newEmoji,
            'userId': currentUserId,
            'user': {
              '_id': currentUserId,
              'first_name': firstName,
              'last_name': lastName,
            },
            'reacted_at': DateTime.now().toIso8601String(),
          });
        }

        // DEEP COPY the message map to force UI rebuild
        final newMessageMap = Map<String, dynamic>.from(msg);
        newMessageMap['reactions'] = reactions;

        list[i] = newMessageMap; // Replace with new reference
        changed = true;
      }
    }

    setState(() {
      updateList(dbMessages, "dbMessages");
      updateList(messages, "messages");
      updateList(socketMessages, "socketMessages");

      if (changed) {
        debugPrint(
            "✅ [GroupChat] Reaction state updated locally. Saving to storage.");
        // We need to ensure _getCombinedMessages will pick up the changes.
        // Since we modified the source lists in place (with new maps), it should work.
        final combined = _getCombinedMessages();
        GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      } else {
        debugPrint(
            "⚠️ [GroupChat] Reaction target $targetMessageId (API: $apiTargetId) not found locally.");
      }
      _updateNotifier();
    });
  }

  void _handleReactionTap(Map<String, dynamic> message, String emoji) {
    try {
      if (_hasLeftGroup) {
        Messenger.alert(msg: "You have left this group");
        return;
      }

      String rawId = (message['message_id'] ??
              message['messageId'] ??
              message['id'] ??
              message['_id'] ??
              '')
          .toString();

      if (rawId.isEmpty) {
        log('⚠️ Skipping reaction: message has empty id');
        return;
      }

      final apiMessageId = _normalizeMessageIdForApi(rawId);

      // normalize reactions for this message
      final List<Map<String, dynamic>> reactions =
          _extractReactions(message['reactions']);

      int myIndex = -1;
      String? oldEmoji;

      for (var i = 0; i < reactions.length; i++) {
        final r = reactions[i];
        final uid = (r['userId'] ?? r['user']?['_id'])?.toString();
        if (uid == currentUserId) {
          myIndex = i;
          oldEmoji = r['emoji']?.toString();
          break;
        }
      }

      final bool hasMyReaction = myIndex != -1;

      // CASE 1: tap same emoji → remove
      if (hasMyReaction && oldEmoji == emoji) {
        _updateLocalReactions(rawId, null);

        context.read<GroupChatBloc>().add(GroupRemoveReaction(
              messageId: apiMessageId,
              conversationId: widget.conversationId,
              emoji: emoji,
              userId: currentUserId,
              receiverId: widget.datumId,
            ));
        return;
      }

      // CASE 2: change emoji
      if (hasMyReaction && oldEmoji != emoji) {
        _updateLocalReactions(rawId, emoji);

        context.read<GroupChatBloc>().add(GroupRemoveReaction(
              messageId: apiMessageId,
              conversationId: widget.conversationId,
              emoji: oldEmoji ?? '',
              userId: currentUserId,
              receiverId: widget.datumId,
            ));

        context.read<GroupChatBloc>().add(GroupAddReaction(
              messageId: apiMessageId,
              conversationId: widget.conversationId,
              emoji: emoji,
              userId: currentUserId,
              receiverId: widget.datumId,
            ));
        return;
      }

      // CASE 3: first time reacting
      _updateLocalReactions(rawId, emoji);

      context.read<GroupChatBloc>().add(GroupAddReaction(
            messageId: apiMessageId,
            conversationId: widget.conversationId,
            emoji: emoji,
            userId: currentUserId,
            receiverId: widget.datumId,
          ));

      // Clear selection mode after reacting
      if (_isSelectionMode) {
        setState(() {
          _isSelectionMode = false;
          _selectedMessages.clear();
          _selectedMessageIds.clear();
          _selectedMessageKeys.clear();
        });
      }
    } catch (e, st) {
      log('❌ Error handling reaction tap: $e\n$st');
    }
  }

  Map<String, dynamic> normalizeMessage(dynamic rawMsg) {
    if (rawMsg == null) return {};
    if (rawMsg is String) return {};
    if (rawMsg is! Map && rawMsg is! GroupMessageModel) return {};

    Map<String, dynamic> message = {};

    if (rawMsg is GroupMessageModel) {
      message = rawMsg.toJson();
    } else if (rawMsg is Map) {
      try {
        message = Map<String, dynamic>.from(rawMsg);
      } catch (e) {
        return {};
      }
    }

    final content = message['content']?.toString().trim() ?? '';
    final userName = message['userName'] ?? '';
    final isForwarded = message['isForwarded'] ?? false;
    final imageUrl = message['originalUrl'] ?? message['imageUrl'];
    final fileUrl = message['originalUrl'] ?? message['fileUrl'];
    final fileName = message['fileName'];
    final fileType = message['mimeType'] ?? message['fileType'];
    final messageId = message['message_id'] ?? message['id'];
    final contentType = message['ContentType'] ?? message['contentType'];

    final isReplyMessage = message['isReplyMessage'] ?? false;
    final reply = message['reply'] ?? message['repliedMessage'];

    final senderData = message['sender'] is Map ? message['sender'] : {};
    final String profilePic = senderData['profile_pic_path'] ??
        senderData['profilePic'] ??
        senderData['avatar'] ??
        '';

    final normalizedReply = (reply != null && reply is Map<String, dynamic>)
        ? {
            "userId": reply["userId"] ?? reply["senderId"],
            "id": reply["id"] ?? reply["message_id"] ?? reply["messageId"],
            "mimeType": reply["mimeType"] ?? reply["fileType"] ?? "",
            "fileType": reply["fileType"] ?? reply["mimeType"] ?? "",
            "ContentType": reply["ContentType"] ?? "",
            "replyContent": reply["content"] ?? reply["replyContent"] ?? "",
            "replyToUser": reply["senderName"] ??
                reply["userName"] ??
                reply["replyToUser"] ??
                reply["replyToUSer"] ??
                "",
            "fileName": reply["fileName"] ?? "",
            "first_name": reply["first_name"] ?? "",
            "last_name": reply["last_name"] ?? "",
            "imageUrl": reply["imageUrl"] ?? reply["thumbnailUrl"] ?? "",
            "fileUrl": reply["fileUrl"] ?? "",
            "originalUrl": reply["originalUrl"] ?? "",
            "videoDuration": reply["videoDuration"] ?? reply["duration"],
            'profile_pic_path': message['sender']?['profile_pic_path'] ??
                message['sender']?['profilePic'] ??
                message['profile_pic_path'] ??
                '',
          }
        : null;

    // 🔥 NEW: Deep normalization of reactions to prevent "Unknown User"
    final rawReactions = message['reactions'] as List? ?? [];
    final List<Map<String, dynamic>> normalizedReactions = [];

    for (var r in rawReactions) {
      if (r is! Map) continue;
      final reactionMap = Map<String, dynamic>.from(r);

      // Fix User Data Structure
      var userObj = reactionMap['user'];
      String? userId = reactionMap['userId']?.toString();

      // Case: user is just an ID string
      if (userObj is String) {
        if (userId == null || userId.isEmpty) userId = userObj;
        userObj = {'_id': userId}; // Create stub user object
      }
      // Case: user is Map
      else if (userObj is Map) {
        if (userId == null || userId.isEmpty) {
          userId = userObj['_id']?.toString() ??
              userObj['id']?.toString() ??
              userObj['userId']?.toString();
        }
      }

      // Ensure we have a valid userId at the top level for _extractReactions
      reactionMap['userId'] = userId;
      reactionMap['user'] = userObj;

      normalizedReactions.add(reactionMap);
    }

    final messageStatus = (message['messageStatus'] ??
            message['status'] ??
            message['deliveryStatus'] ??
            'sent')
        .toString();

    return {
      'message_id': messageId,
      'content': content,
      'userName': userName,
      'sender': message['sender'],
      'receiver': message['receiver'],
      'messageStatus': messageStatus.isEmpty ? 'sent' : messageStatus,
      'time': message['time'],
      'imageUrl': imageUrl,
      'fileName': fileName,
      'ContentType': contentType,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'isForwarded': isForwarded,
      'isReplyMessage': isReplyMessage,
      'repliedMessage': normalizedReply,
      'reactions': normalizedReactions, // ✅ Use normalized list
      'profile_pic_path': profilePic,
    };
  }

  bool isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    log(imageUrl);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4,
            child: imageUrl.startsWith('https')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text("Failed to load image",
                          style: TextStyle(color: Colors.white)),
                    ),
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text("Failed to load image",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.movie;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _initMessages() async {
    final savedMessages =
        await GrpLocalChatStorage.loadMessages(widget.conversationId);

    setState(() {
      dbMessages = savedMessages
          .map<Map<String, dynamic>>((msg) => normalizeMessage(msg))
          .where((m) => m.isNotEmpty)
          .toList();

      for (var m in dbMessages) {
        final id = (m['message_id'] ?? m['id'])?.toString();
        if (id != null && id.isNotEmpty) _seenMessageIds.add(id);
      }
    });
    _updateNotifier();
  }

// ------------------ Draft Methods ------------------

  void _saveDraft(String draft) {
    if (widget.conversationId.isEmpty) return;
    GrpLocalChatStorage.saveDraftMessage(widget.conversationId, draft);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.conversationId,
      draftMessage: draft.isEmpty ? null : draft,
    );
    // Trigger UI refresh in chat list
    if (mounted) {
      context.read<ChatListBloc>().add(UpdateLocalChatList());
    }
  }

  void _clearDraft() {
    if (widget.conversationId.isEmpty) return;
    GrpLocalChatStorage.clearDraftMessage(widget.conversationId);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.conversationId,
      draftMessage: null,
    );
    // Trigger UI refresh in chat list
    if (mounted) {
      context.read<ChatListBloc>().add(UpdateLocalChatList());
    }
  }

  Future<void> _loadDraft() async {
    if (widget.conversationId.isEmpty) return;
    final draft = GrpLocalChatStorage.getDraftMessage(widget.conversationId);
    if (draft != null && draft.isNotEmpty) {
      _messageController.text = draft;
    }
  }

  Future<void> _initializeSocket() async {
    final String? token = await UserPreferences.getAccessToken();
    if (token == null) {
      log("Access token is null. Socket connection not initialized.");
      return;
    }

    if (currentUserId.isNotEmpty && widget.datumId.isNotEmpty) {
      _setupReactionListener();
      _setupStatusListener();
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await UserPreferences.getUserId();
    if (userId != null && userId.isNotEmpty) {
      if (mounted) {
        setState(() {
          currentUserId = userId;
        });
      }
    }
  }

  void _fetchMessages2() {
    _groupBloc.add(
      FetchGroupMessages(
        convoId: widget.conversationId,
        page: _currentPage,
        limit: _limit,
      ),
    );
  }

  void _fetchMessages() {
    _groupBloc.add(
      FetchGroupMessages(
        convoId: widget.conversationId,
        page: _currentPage,
        limit: _limit,
      ),
    );

    // _checkingPersmmion();
  }

  void _checkingPersmmion() {
    context.read<GroupChatBloc>().add(
          PermissionCheck(widget.datumId),
        );
  }

// Add this method to handle permission state changes
  void _handlePermissionResponse(Map<String, dynamic>? response) {
    print("Handling permission response: $response");

    if (response != null && response['type'] == 'left') {
      if (mounted) {
        setState(() {
          _hasLeftGroup = true;
          _permissionResponse = response;
        });
      }

      print("❌ User has left the group: $_hasLeftGroup");

      // Clear any draft messages
      if (mounted) {
        _messageController.clear();
        _clearDraft();
      }

      // Show a snackbar notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left this group'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _hasLeftGroup = false;
          _permissionResponse = null;
        });
      }

      print("✅ User has permission to chat: $_hasLeftGroup");
    }
  }

  Future<void> _loadSessionImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('chat_image_path');

    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _imageFile = File(imagePath);
        log(" -----image-- $_imageFile");
      });
    }
  }

  Future<void> _clearSessionPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_image_path');
    await prefs.remove('chat_file_path');
  }

  Future<void> _loadSessionFilePath() async {
    final prefs = await SharedPreferences.getInstance();
    final filePath = prefs.getString('chat_file_path');

    if (filePath != null && filePath.isNotEmpty) {
      setState(() {
        _fileUrl = File(filePath);
        log(" ------- $_fileUrl");
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.datumId.isEmpty) {
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // 🛠 Construct a clean reply payload
    final Map<String, dynamic>? replyPayload = _replyMessage != null
        ? {
            'message_id': _replyMessage!['message_id'] ?? _replyMessage!['id'],
            'content': _replyMessage!['content'] ?? '',
            'id': _replyMessage!['message_id'] ??
                _replyMessage!['id'], // redundant but safe
            'sender': _replyMessage!['sender'],
            'replyToUser': _replyMessage!['senderName'] ??
                _replyMessage!['userName'] ??
                (_replyMessage!['sender'] is Map
                    ? _replyMessage!['sender']['name']
                    : ''),
            'imageUrl': _replyMessage!['imageUrl'] ??
                _replyMessage!['thumbnailUrl'] ??
                _replyMessage!['localImagePath'],
            'fileUrl': _replyMessage!['fileUrl'],
            'fileName': _replyMessage!['fileName'],
            'fileType': _replyMessage!['fileType'],
            'originalUrl': _replyMessage!['originalUrl'],
          }
        : null;

    final message = {
      'message_id': tempId,
      'content': _messageController.text.trim(),
      'sender': {'_id': currentUserId},
      'receiver': {'_id': widget.datumId},
      // 🟢 Check connectivity for initial status
      'messageStatus': (_isOnline && socketService.isConnected)
          ? 'sending'
          : 'pending_offline',
      'time': nowIso,
      if (replyPayload != null) 'repliedMessage': replyPayload,
      if (replyPayload != null) 'isReplyMessage': true,
    };

    setState(() {
      socketMessages.add(message);
      _scrollToBottom();

      final combined = [...dbMessages, ...messages, ...socketMessages];
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      _updateNotifier();
    });

    final String textToSend = _messageController.text.trim();

    setState(() {
      _messageController.clear();
      _replyMessage = null;
      _replyPreview = null;
      _imageFile = null;
    });
    _clearDraft();

    if (!(_isOnline && socketService.isConnected)) {
      // Offline: Add to queue
      _offlineQueue.add({
        'message_id': tempId, // Store tempId to replace later if needed
        'content': textToSend,
        'replyTo': replyPayload,
      });
      return;
    }

   try {
      final completer = Completer<GrpMessage>();
      final subscription = _groupBloc.stream.listen((state) {
        if (state is GrpMessageSentSuccessfully) {
          // We assume the next success is ours.
          // Ideally we'd match ID, but the server generates a new one.
          // Matching content/time is a heuristics.
          // For now, satisfy with the first success event.
          if (!completer.isCompleted) {
            completer.complete(state.sentMessage);
          }
        } else if (state is GroupChatError) {
          if (!completer.isCompleted) {
            completer.completeError(state.message);
          }
        }
      });

      _groupBloc.add(
        SendMessageEvent(
          convoId: widget.conversationId,
          message: textToSend,
          senderId: currentUserId,
          receiverId: widget.datumId,
          replyTo: replyPayload,
        ),
      );

      final sentMsg = await completer.future;
      await subscription.cancel();

      // Swap temp ID with real server ID
      _replaceTempMessageWithReal(
        tempId: tempId,
        realId: sentMsg.messageId,
        status: 'sent',
      );
    } catch (e) {
      log("❌ FetchGroupMessages Error: $e");
      Messenger.alert(msg: "Failed to send message.");
    }
  }

  void _sendMessageImage() async {
    await _loadSessionImagePath();
    await _loadSessionFilePath();

    log("Sending message with image and file");
    final nowIso = DateTime.now().toIso8601String();
    final messageId = ObjectId().toString(); // Generate ID
    final String? mimeType =
        _fileUrl != null ? lookupMimeType(_fileUrl!.path) : null;

    final message = {
      'message_id': messageId, // Add ID
      'localImagePath': _imageFile?.path, // Add localImagePath for consistency
      'content': _messageController.text.trim(),
      'sender': {'_id': currentUserId},
      'receiver': {'_id': widget.datumId},
      'messageStatus': 'sending',
      'time': nowIso,
      'fileName': _fileUrl?.path.split('/').last,
      'fileType': mimeType,
      'imageUrl': _imageFile?.path,
      'fileUrl': _fileUrl?.path,
    };

    log(message.toString());
    setState(() {
      socketMessages.add(message);
      _scrollToBottom();

      final combined = [...dbMessages, ...messages, ...socketMessages];
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      _updateNotifier();
    });
    setState(() {
      _messageController.clear();
      _imageFile = null;
      _fileUrl = null;
    });

    await _clearSessionPaths();
    _clearDraft();
  }

  void _sendMultipleFiles(List<XFile> files) async {
    if (files.isEmpty) return;
    log("📤 Sending ${files.length} multiple files");

    final count = files.length;
    final isGrouped = count >= 4;
    final String? groupMessageId = isGrouped ? ObjectId().toString() : null;
    final nowIso = DateTime.now().toIso8601String();

    for (final file in files) {
      final localFile = File(file.path);
      final String? mimeType = lookupMimeType(file.path);
      final bool isImage = mimeType != null && mimeType.startsWith('image/');
      final messageId = ObjectId().toString();

      final message = {
        'message_id': messageId,
        'localImagePath': isImage ? file.path : null,
        'content': '', // No caption for bulk upload
        'sender': {'_id': currentUserId},
        'receiver': {'_id': widget.datumId},
        'messageStatus':
            'sending', // Optimistic status (marked sending until synced)
        'time': nowIso,
        'fileName': file.name,
        'fileType': mimeType,
        'imageUrl': isImage ? file.path : null,
        'fileUrl': !isImage ? file.path : null,
      };

      // 1. Optimistic Update
      setState(() {
        socketMessages.add(message);
        _updateNotifier();
      });

      // 2. Send Event via BLoC
      // Note: We replicate the logic from GrpShowAltDialog's legacy path here
      context.read<GroupChatBloc>().add(
            GrpUploadFileEvent(
              file: localFile,
              convoId: widget.conversationId,
              senderId: currentUserId,
              receiverId: widget.datumId,
              groupId: widget.datumId,
              message: "",
              isGroupMessage: isGrouped,
              groupMessageId: groupMessageId,
            ),
          );
    }

    _scrollToBottom();

    // Persist optimistic messages
    final combined = [...dbMessages, ...messages, ...socketMessages];
    GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(
          const Duration(milliseconds: 400),
          () => _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              ));
    }
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // 1. Check if scrolled near the TOP (maxScrollExtent in reverse list)
    //    We use a threshold (e.g. 50-100 pixels) to trigger loading
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      final total = _allMessages.length;

      // Case A: We have more local messages hidden (client-side windowing)
      if (_visibleCount < total && !_isLoadingMore) {
        setState(() => _isLoadingMore = true);

        // Add small delay to simulate load (and allow UI to show spinner if desired)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() {
            _visibleCount = (_visibleCount + _pageStep).clamp(0, total);
            _isLoadingMore = false;
          });
          _updateNotifierFromAll();
        });
      }
      // Case B: We showed all local messages, check if server has more
      else if (_hasNextPage && !_isLoadingMore) {
        _loadMoreMessages();
      }
    }
  }

  void _loadMoreMessages() {
    if (!_hasNextPage || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    _currentPage++;
    _fetchMessages();
  }

  void _appendMessage(Map<String, dynamic> message) {
    setState(() {
      messages.add(message);
      _updateNotifier();
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) return 'Today';
    if (messageDate == yesterday) return 'Yesterday';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessages.clear();
      _selectedMessageKeys.clear();
    });
  }

  void _markMessagesAsDeleted(List<String> messageIds) {
    log("Marking messages as deleted: $messageIds");

    setState(() {
      List<Map<String, dynamic>> updateMessages(
          List<Map<String, dynamic>> list) {
        return list.map((msg) {
          if (messageIds.contains(msg['message_id']?.toString())) {
            return {
              ...msg,
              'content': 'Message Deleted',
              'imageUrl': null,
              'fileUrl': null,
              'fileName': null,
              'fileType': null,
              'isDeleted': true,
            };
          }
          return msg;
        }).toList();
      }

      messages = updateMessages(messages);
      dbMessages = updateMessages(dbMessages);
      socketMessages = updateMessages(socketMessages);

      final combined = [...dbMessages, ...messages, ...socketMessages];
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      _updateNotifier();
    });
  }

  void _deleteSelectedMessages() {
    if (_selectedMessageIds.isEmpty) {
      log("No messages selected to delete");
      return;
    }

    setState(() {
      _isDeletingMessages = true;
    });

    _markMessagesAsDeleted(_selectedMessageIds.toList());

    _groupBloc.add(DeleteMessagesEvent(
      messageIds: _selectedMessageIds.toList(),
      convoId: widget.conversationId,
      senderId: currentUserId,
      receiverId: widget.datumId,
      message: _selectedMessageKeys.first,
    ));

    setState(() {
      _selectedMessages.clear();
      _selectedMessageIds.clear();
      _selectedMessageKeys.clear();
      _isSelectionMode = false;
      _isDeletingMessages = false;
    });
  }

  void _toggleMessageSelection(Map<String, dynamic> msg) {
    final key = _generateMessageKey(msg);
    final String? messageId = msg['message_id']?.toString();

    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        _selectedMessageKeys.remove(key);
        _selectedMessages.removeWhere((m) => _generateMessageKey(m) == key);
      } else if (messageId != null) {
        _selectedMessageIds.add(messageId);
        _selectedMessageKeys.add(key);
        _selectedMessages.add(msg);
      }
      _isSelectionMode = _selectedMessageIds.isNotEmpty;
    });
  }

  void _forwardSelectedMessages() {
    MyRouter.pushReplace(
      screen: ForwardMessageScreen(
        messages: _selectedMessages.toList(),
        currentUserId: currentUserId,
        conversionalid: "",
        username: widget.groupName,
      ),
    );

    setState(() {
      _selectedMessages.clear();
      _selectedMessageKeys.clear();
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  void _starSelectedMessages() {
    setState(() {
      _selectedMessages.clear();
      _isSelectionMode = false;
    });
  }

  void _onMessageTap(Map<String, dynamic> message) async {
    if (_isSelectionMode) {
      _toggleMessageSelection(message);
      return;
    }

    debugPrint('📩 tapped message id: ${message['message_id']}');

    String? extractReplyId(Map<String, dynamic> m) {
      final reply = m['reply'] ?? m['repliedMessage'];

      // 1️⃣ Check inside reply map
      if (reply is Map<String, dynamic>) {
        for (final key in [
          'reply_message_id',
          'message_id',
          'messageId',
          'id',
          '_id',
        ]) {
          final v = reply[key];
          if (v != null && v.toString().isNotEmpty) {
            return v.toString();
          }
        }
      }

      // 2️⃣ Check top-level reply fields
      for (final key in ['reply_message_id', 'replyId', 'reply_to_id']) {
        final v = m[key];
        if (v != null && v.toString().isNotEmpty) {
          return v.toString();
        }
      }

      return null;
    }

    final replyId = extractReplyId(message);
    debugPrint('📌 extracted replyId: $replyId');

    if (replyId != null && replyId.isNotEmpty) {
      final found = await _scrollToMessageById(replyId, fetchIfMissing: true);
      if (!found) {
        Messenger.alert(
          msg: "Original message not loaded. Scroll up to load older messages.",
        );
      }
    }
  }

  void _replyToMessage(Map<String, dynamic> message) {
    if (message.isEmpty) return;

    // 🔹 Raw data from original message
    final String content =
        (message['content'] ?? message['message'] ?? '').toString();

    final String? imageUrl = message['imageUrl'] ??
        message['thumbnailUrl'] ??
        message['localImagePath'];

    final String? fileUrl = message['fileUrl'];
    final String? fileName = message['fileName'];
    final String? fileType = message['fileType'];
    final String? originalUrl = message['originalUrl'] ?? fileUrl;

    final String userName = message['senderName'] ??
        message['userName'] ??
        (message['sender']?['name'] ?? '');

    final String ftLower = (fileType ?? '').toLowerCase();
    final bool isVideo = ftLower.startsWith('video/');

    setState(() {
      // 1️⃣ Keep the FULL message as-is for _sendMessage
      _replyMessage = message;

      // 2️⃣ Build a lightweight map only for the input field UI
      _replyPreview = {
        'message_id':
            (message['message_id'] ?? message['messageId'] ?? message['id'])
                ?.toString(),
        'content': content,
        'imageUrl': imageUrl ?? '',
        'fileUrl': fileUrl ?? '',
        'fileName': fileName ?? '',
        'fileType': fileType ?? '',
        'originalUrl': originalUrl ?? '',
        'userName': userName,
        'isVideo': isVideo,
      };

      _focusNode.requestFocus();
    });
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      _showEmoji = !_showEmoji;
    });

    if (_showEmoji) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  Future<void> _clearSessionImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_image_path');
    await prefs.remove('chat_file_path');
  }

  String _generateMessageKey(Map<String, dynamic> msg) {
    return '${msg['message_id'] ?? msg['time']}_${msg['content']}_${msg['imageUrl'] ?? ''}_${msg['fileUrl'] ?? ''}${msg['userName'] ?? ''}';
  }

  List<Map<String, dynamic>> _inferGrouping(
      List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return messages;

    for (int i = 0; i < messages.length; i++) {
      final currentMsg = messages[i];

      // Skip if already grouped
      if (currentMsg['is_group_message'] == true &&
          currentMsg['group_message_id'] != null) {
        continue;
      }

      // 🔹 Detect image
      final hasImage = (currentMsg['imageUrl'] != null &&
              currentMsg['imageUrl'].toString().isNotEmpty) ||
          (currentMsg['localImagePath'] != null &&
              currentMsg['localImagePath'].toString().isNotEmpty);

      // 🔹 Detect video
      final String fileType =
          (currentMsg['fileType'] ?? currentMsg['mimeType'] ?? '')
              .toString()
              .toLowerCase();
      final String fileUrl =
          (currentMsg['fileUrl'] ?? currentMsg['originalUrl'] ?? '').toString();

      final bool hasVideo = fileType.startsWith('video/') ||
          ['.mp4', '.mov', '.mkv', '.avi', '.webm']
              .any((ext) => fileUrl.toLowerCase().endsWith(ext));

      final bool isMedia = hasImage || hasVideo;
      if (!isMedia) continue;

      // Look ahead for consecutive media from same sender within time threshold
      List<int> groupIndices = [i];
      final currentSender = currentMsg['sender'] is Map
          ? currentMsg['sender']['_id']?.toString()
          : currentMsg['sender']?.toString();
      final currentTime = _parseTime(currentMsg['time']);

      for (int j = i + 1; j < messages.length; j++) {
        final nextMsg = messages[j];
        final nextSender = nextMsg['sender'] is Map
            ? nextMsg['sender']['_id']?.toString()
            : nextMsg['sender']?.toString();
        final nextTime = _parseTime(nextMsg['time']);

        // Detect media for next message
        final nextHasImage = (nextMsg['imageUrl'] != null &&
                nextMsg['imageUrl'].toString().isNotEmpty) ||
            (nextMsg['localImagePath'] != null &&
                nextMsg['localImagePath'].toString().isNotEmpty);

        final String nextFileType =
            (nextMsg['fileType'] ?? nextMsg['mimeType'] ?? '')
                .toString()
                .toLowerCase();
        final String nextFileUrl =
            (nextMsg['fileUrl'] ?? nextMsg['originalUrl'] ?? '').toString();
        final bool nextHasVideo = nextFileType.startsWith('video/') ||
            ['.mp4', '.mov', '.mkv', '.avi', '.webm']
                .any((ext) => nextFileUrl.toLowerCase().endsWith(ext));

        final bool nextIsMedia = nextHasImage || nextHasVideo;

        if (nextSender != currentSender ||
            !nextIsMedia ||
            nextTime.difference(currentTime).inMinutes.abs() > 1) {
          break;
        }

        // Already grouped by server? Treat as boundary
        if (nextMsg['is_group_message'] == true &&
            nextMsg['group_message_id'] != null) {
          break;
        }

        groupIndices.add(j);
      }

      // If we found a group of 2+ media items
      if (groupIndices.length > 1) {
        final groupId =
            'generated_group_${currentTime.millisecondsSinceEpoch}_$i';
        log('🔍 Inferring group $groupId for ${groupIndices.length} media items');

        // ✅ CRITICAL: Persist grouping info to the ORIGINAL SOURCE messages
        for (final index in groupIndices) {
          final messageToGroup = messages[index];
          final msgId = (messageToGroup['message_id'] ??
                  messageToGroup['messageId'] ??
                  messageToGroup['id'])
              ?.toString();

          // Apply grouping to combined list
          messageToGroup['is_group_message'] = true;
          messageToGroup['group_message_id'] = groupId;

          // Also persist to source arrays
          if (msgId != null) {
            _applyGroupingToSource(msgId, groupId);
          }
        }
        // Skip the processed messages in the outer loop
        i = groupIndices.last;
      }
    }
    return messages;
  }

  /// Persist grouping info to source message arrays
  void _applyGroupingToSource(String messageId, String groupId) {
    void applyToList(List<Map<String, dynamic>> list) {
      for (var msg in list) {
        final mId =
            (msg['message_id'] ?? msg['messageId'] ?? msg['id'])?.toString();
        if (mId == messageId) {
          msg['is_group_message'] = true;
          msg['group_message_id'] = groupId;
          break;
        }
      }
    }

    applyToList(socketMessages);
    applyToList(messages);
    applyToList(dbMessages);
  }

  /// Merge all messages (db + messages + socket), sort, dedupe
  List<Map<String, dynamic>> _getCombinedMessages() {
    final List<Map<String, dynamic>> combined = [];

    void addUnique(Map<String, dynamic> msg) {
      if (msg['content']?.toString().trim() == '' &&
          (msg['imageUrl'] == null || msg['imageUrl'].toString().isEmpty) &&
          (msg['fileUrl'] == null || msg['fileUrl'].toString().isEmpty)) {
        return;
      }

      // 1. Check by ID first (strongest check)
      final msgId =
          msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? msg['id'];
      if (msgId != null) {
        final idString = msgId.toString();
        final existsById = combined.any((m) {
          final mId = m['message_id'] ?? m['messageId'] ?? m['_id'] ?? m['id'];
          return mId != null && mId.toString() == idString;
        });
        if (existsById) return;
      }

      // 2. Fallback to content/time check
      bool exists = combined.any((m) =>
          m['time'] == msg['time'] &&
          m['content'] == msg['content'] &&
          m['ContentType'] == msg['ContentType'] &&
          (m['isReplyMessage'] ?? false) == (msg['isReplyMessage'] ?? false) &&
          (m['imageUrl'] ?? '') == (msg['imageUrl'] ?? '') &&
          (m['fileName'] ?? '') == (msg['fileName'] ?? '') &&
          (m['fileUrl'] ?? '') == (msg['fileUrl'] ?? ''));

      if (!exists) {
        // Create a copy to ensure Flutter detects changes when reactions are modified
        final copy = Map<String, dynamic>.from(msg);
        combined.add(copy);
      }
    }

    // Prioritize LIVE messages (socket) > Fetched (messages) > Local (dbMessages)
    for (var m in socketMessages) addUnique(m);
    for (var m in messages) addUnique(m);
    for (var m in dbMessages) addUnique(m);

    combined.sort(
      (a, b) => _parseTime(a['time']).compareTo(_parseTime(b['time'])),
    );

    return _inferGrouping(combined);
  }

  void _refreshMessages() {
    _messagesNotifier.value =
        List<Map<String, dynamic>>.from(_getCombinedMessages());
  }

  // ------------------ Pagination Helpers ------------------

  /// Rebuilds the master list `_allMessages` from sources, then updates view
  /// Rebuilds the master list `_allMessages` from sources, then updates view
  void _updateNotifier() {
    final full = _getCombinedMessages();
    // _getCombinedMessages sorts by time (Old -> New)
    // So `full` is [Oldest, ..., Newest]

    _allMessages
      ..clear()
      ..addAll(full);

    // If first load (or reset), determine initial visible count
    if (_visibleCount == 0) {
      final total = _allMessages.length;
      _visibleCount =
          total >= _initialVisible ? _initialVisible : total; // Show last N
    }
    debugPrint(
        '🔄 _updateNotifier: total=${_allMessages.length}, visible=$_visibleCount');

    _updateNotifierFromAll();
  }

  /// Updates `_messagesNotifier` with the currently visible slice of `_allMessages`
  void _updateNotifierFromAll() {
    final total = _allMessages.length;
    final count = _visibleCount.clamp(0, total);

    // _allMessages is Old -> New.
    // We want the *last* `count` messages (the newest ones).
    // Start index = total - count.
    final startIndex = total - count;
    debugPrint(
        '📊 _updateNotifierFromAll: total=$total, count=$count, startIndex=$startIndex');

    final visibleSlice = (count == 0)
        ? <Map<String, dynamic>>[]
        : _allMessages.sublist(startIndex, total);

    debugPrint('   - visibleSlice length: ${visibleSlice.length}');

    // List passed to ListView (reverse: true).
    // The list itself is [OldestSlice, ..., NewestSlice].
    // ListView index 0 (bottom) will be the last item of this list.
    // This matches PrivateChatScreen logic.

   _messagesNotifier.value = List<Map<String, dynamic>>.from(visibleSlice);
  }

  /// Load older pages until message with [messageId] exists or no more pages
  Future<bool> _fetchUntilMessageFound(String messageId) async {
    if (messageId.isEmpty) return false;
    int safety = 0;

    while (safety < 10 && mounted) {
      safety++;

      final combined = _getCombinedMessages();
      final exists = combined.any((m) {
        final mid = (m['message_id'] ?? m['id'])?.toString() ?? '';
        return mid == messageId;
      });

      if (exists) return true;
      if (!_hasNextPage) return false;

      final completer = Completer<void>();
      late final StreamSubscription sub;

      sub = _groupBloc.stream.listen((state) {
        if (state is GroupChatLoaded && !completer.isCompleted) {
          completer.complete();
        }
      });

      _currentPage++;
      _groupBloc.add(
        FetchGroupMessages(
          convoId: widget.conversationId,
          page: _currentPage,
          limit: _limit,
        ),
      );

      try {
        await completer.future;
      } finally {
        await sub.cancel();
      }
    }

    final combined = _getCombinedMessages();
    return combined.any((m) {
      final mid = (m['message_id'] ?? m['id'])?.toString() ?? '';
      return mid == messageId;
    });
  }

  /// Scroll to message used in reply, with pagination + local storage
  Future<bool> _scrollToMessageById(String messageId,
      {bool fetchIfMissing = true}) async {
    if (messageId.isEmpty) return false;

    List<Map<String, dynamic>> combined = _getCombinedMessages();

    int index = combined.indexWhere((m) {
      final mid = (m['message_id'] ?? m['id'])?.toString() ?? '';
      return mid == messageId;
    });

    if (index == -1 && fetchIfMissing) {
      final found = await _fetchUntilMessageFound(messageId);
      if (!found) return false;

      combined = _getCombinedMessages();
      index = combined.indexWhere((m) {
        final mid = (m['message_id'] ?? m['id'])?.toString() ?? '';
        return mid == messageId;
      });

      if (index == -1) return false;
    }

    // Ensure the message is within the visible window
    final int neededVisible = combined.length - index;
    if (_visibleCount < neededVisible) {
      setState(() {
        _visibleCount = neededVisible + 5; // Add a small buffer
        // Clamp to max length to be safe, though neededVisible <= combined.length should hold
        if (_visibleCount > combined.length) _visibleCount = combined.length;
      });
      _updateNotifier();
      // Allow UI to rebuild with new items
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!_scrollController.hasClients) return false;

    // ✨ CRITICAL: ListView is REVERSED (newest at bottom, oldest at top)
    // So we need to calculate from the END of the list (which is 0 in UI)
    const double itemHeightEstimate = 80.0;

    // The logic: proper offset = (visual_index) * height.
    // Visual index 0 is bottom (newest).
    // Message index (in combined) is 0 (oldest) ... N (newest).
    // Visual Index = (Total - 1 - index).
    // Note: Use combined.length as the total reference since we ensured visibility.
    final reversedIndex = combined.length - 1 - index;

    final double offset = (reversedIndex * itemHeightEstimate)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    await _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    // ✨ Highlight the target message
    if (mounted) {
      setState(() => _highlightedMessageId = messageId);

      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _highlightedMessageId = null);
        }
      });
    }

    return true;
  }

  /// Reply preview (tap → scroll to original). Works after reopen because ids are persisted.
  Widget _buildReplyPreview(Map<String, dynamic> message, bool isSentByMe) {
    final Map<String, dynamic> replyMap =
        (message['repliedMessage'] ?? message['reply']) is Map
            ? Map<String, dynamic>.from(
                message['repliedMessage'] ?? message['reply'])
            : <String, dynamic>{};

    if (replyMap.isEmpty) return const SizedBox.shrink();

    final replyId = (replyMap['id'] ??
                replyMap['message_id'] ??
                replyMap['messageId'] ??
                replyMap['reply_message_id'])
            ?.toString() ??
        '';

    final senderName = (replyMap['senderName'] ??
            replyMap['userName'] ??
            replyMap['first_name'] ??
            replyMap['replyToUser'] ??
            '')
        .toString();

    final replyContent = (replyMap['replyContent'] ??
            replyMap['content'] ??
            replyMap['message'] ??
            '')
        .toString();

    // 👇 media info
    String fileType = (replyMap['fileType'] ??
            replyMap['mimeType'] ??
            replyMap['mimetype'] ??
            '')
        .toString()
        .toLowerCase();

    String imageOrVideoUrl = (replyMap['originalUrl'] ??
            replyMap['imageUrl'] ??
            replyMap['fileUrl'] ??
            '')
        .toString();

    // 👇 duration in seconds (change key if needed)
    final dynamic durRaw = replyMap['videoDuration'] ?? replyMap['duration'];
    final int durationSec =
        durRaw is int ? durRaw : int.tryParse(durRaw?.toString() ?? '') ?? 0;

    String _formatDuration(int sec) {
      if (sec <= 0) return '';
      final d = Duration(seconds: sec);
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }

    // Try to recover media info from original message if missing in reply map
    if (imageOrVideoUrl.isEmpty && replyId.isNotEmpty) {
      try {
        final all = _getCombinedMessages();
        final original = all.firstWhere(
          (m) {
            final mid =
                (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
            return mid == replyId;
          },
          orElse: () => <String, dynamic>{},
        );

        if (original.isNotEmpty) {
          imageOrVideoUrl = (original['originalUrl'] ??
                  original['imageUrl'] ??
                  original['thumbnailUrl'] ??
                  original['fileUrl'] ??
                  '')
              .toString();

          if (fileType.isEmpty) {
            fileType = (original['fileType'] ??
                    original['mimeType'] ??
                    original['mimetype'] ??
                    original['ContentType'] ??
                    '')
                .toString()
                .toLowerCase();
          }
        }
      } catch (e) {
        debugPrint('reply preview lookup failed: $e');
      }
    }

    final bool isVideo = fileType.startsWith('video/') ||
        ['mp4', 'mov', 'mkv', 'avi', 'webm']
            .any((ext) => imageOrVideoUrl.toLowerCase().endsWith(ext));

    final bool isImage = fileType.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp']
            .any((ext) => imageOrVideoUrl.toLowerCase().endsWith(ext));

    bool _looksLikeNetwork(String s) =>
        s.startsWith('http://') || s.startsWith('https://');

    if (replyId.isEmpty && replyContent.isEmpty && imageOrVideoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        // open original based on media
        if (isVideo && imageOrVideoUrl.isNotEmpty) {
          final isNetwork = _looksLikeNetwork(imageOrVideoUrl);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                path: imageOrVideoUrl,
                isNetwork: isNetwork,
              ),
            ),
          );
        } else if (isImage && imageOrVideoUrl.isNotEmpty) {
          ImageViewer.show(context, imageOrVideoUrl);
        } else if (replyId.isNotEmpty) {
          debugPrint("🖱️ Tapped reply preview. ID: $replyId");
          final found =
              await _scrollToMessageById(replyId, fetchIfMissing: true);
          if (!found && mounted) {
            Messenger.alert(
                msg:
                    "Original message not loaded. Scroll up to load older messages.");
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // left colored bar
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),

            // TEXT PART
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (senderName.isNotEmpty)
                    Text(
                      senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (isVideo) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.videocam, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Video'
                              '${durationSec > 0 ? " (${_formatDuration(durationSec)})" : ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else if (isImage) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.image, size: 14),
                        SizedBox(width: 4),
                        Text('Photo', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ] else if (replyContent.isNotEmpty) ...[
                    Text(
                      replyContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                  if (replyContent.isNotEmpty && (isVideo || isImage))
                    Text(
                      replyContent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // THUMBNAIL ON THE RIGHT
            if (imageOrVideoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: isVideo
                      // 🎥 VIDEO
                      ? FutureBuilder<File?>(
                          future:
                              VideoThumbUtil.generateFromUrl(imageOrVideoUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(color: Colors.grey.shade300);
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Container(
                                color: Colors.black,
                                child: const Icon(Icons.videocam,
                                    color: Colors.white, size: 18),
                              );
                            }
                            return Image.file(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      // 🖼 IMAGE
                      : (_looksLikeNetwork(imageOrVideoUrl)
                          ? CachedNetworkImage(
                              imageUrl: imageOrVideoUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, _) =>
                                  Container(color: Colors.grey.shade300),
                              errorWidget: (c, _, __) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.error, size: 18),
                              ),
                            )
                          : Image.file(
                              File(imageOrVideoUrl),
                              fit: BoxFit.cover,
                            )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> flattenGroupedMessages(
      List<GroupMessageGroup> groups) {
    final List<Map<String, dynamic>> flat = [];

    for (var group in groups) {
      for (var msg in group.messages) {
        flat.add(msg.toJson());
      }
    }

    return flat;
  }

  Widget _buildChatBody() {
    return BlocListener<GroupChatBloc, GroupChatState>(
      listener: (context, state) {
        if (state is PermissionState) {
          _handlePermissionResponse(state.response);
        }
        if (state is GrpMessageSentSuccessfully) {
          // Handled by _sendMessage completer
        } else if (state is GroupChatError) {
          setState(() {
            _isDeletingMessages = false;
            _isLoadingMore = false;
          });
        } else if (state is GroupChatLoaded) {
          // ALWAYS update these flags when state arrives, even if data is same
          _hasNextPage = state.response.hasNextPage;
          if (_isLoadingMore) {
            setState(() => _isLoadingMore = false);
          }

          if (_lastLoadedData != state.response.data) {
            _lastLoadedData = state.response.data;
            final incomingLoaded = flattenGroupedMessages(state.response.data);

            final incomingNormalized = incomingLoaded
                .map<Map<String, dynamic>>((msg) => normalizeMessage(msg))
                .where((m) => m.isNotEmpty)
                .toList();

            debugPrint('🔍 PAGINATION DEBUG:');
            debugPrint('   - Current page: $_currentPage');
            debugPrint('   - Incoming messages: ${incomingNormalized.length}');
            debugPrint('   - Current dbMessages count: ${dbMessages.length}');

            setState(() {
              // --- ROBUST MERGE STRATEGY ---
              // Overlays incoming messages on top of existing ones by ID
              // This preserves older history when Page 1 is refreshed
              final Map<String, Map<String, dynamic>> messagesMap = {};

              // 1. Put existing messages into map
              for (var m in dbMessages) {
                final id = (m['message_id'] ?? m['id'] ?? '').toString();
                if (id.isNotEmpty) messagesMap[id] = m;
              }

              // 2. Overlay incoming messages (may override existing or add new)
              for (var m in incomingNormalized) {
                final id = (m['message_id'] ?? m['id'] ?? '').toString();
                if (id.isNotEmpty) messagesMap[id] = m;
              }

              // 3. Rebuild dbMessages from merged map
              dbMessages = messagesMap.values.toList();
              debugPrint(
                  '   - After merge, dbMessages count: ${dbMessages.length}');
            });

            // Save merged list to local storage
            GrpLocalChatStorage.saveMessages(widget.conversationId, dbMessages);

            for (var m in incomingNormalized) {
              final id = (m['message_id'] ?? m['id'])?.toString();
              if (id != null && id.isNotEmpty) _seenMessageIds.add(id);
            }

            // Sync notifier
            _updateNotifier();

            // After _updateNotifier(), if this is pagination (page > 1),
            // ensure _visibleCount shows all messages available so far
            if (_currentPage > 1) {
              setState(() {
                _visibleCount = _allMessages.length;
              });
              _updateNotifierFromAll();
              debugPrint(
                  '   - Page $_currentPage: Set _visibleCount to ${_visibleCount} to show all messages');
            }

            debugPrint(
                '✅ GroupChatLoaded processed: total=${_allMessages.length}, visible=$_visibleCount');
          }
        } else if (state is GroupDetailsLoaded) {
          debugPrint(
              'ℹ️ GroupDetailsLoaded emitted. Ignoring for message list.');
        }
      },
      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _messagesNotifier,
        builder: (context, combinedMessages, child) {
          debugPrint(
              '🎨 Rebuild UI with ${combinedMessages.length} messages. State: ${_groupBloc.state.runtimeType}');

          if (combinedMessages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _markVisibleMessagesAsRead(combinedMessages);
            });
          }

          return BlocBuilder<GroupChatBloc, GroupChatState>(
            builder: (context, state) {
              debugPrint('🏗️ BlocBuilder state: ${state.runtimeType}');
              final bool showShimmer = state is GroupChatLoading &&
                  _currentPage == 1 &&
                  combinedMessages
                      .isEmpty; // Check combinedMessages instead of _allMessages directly for safety

              if (showShimmer) {
                return ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ShimmerMessageBubble(
                      isSentByMe: index % 3 == 0,
                    );
                  },
                );
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isLoadingMore
                          ? Padding(
                              key: const ValueKey('top_loader'),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : (!_hasNextPage &&
                                  _allMessages.isNotEmpty &&
                                  _visibleCount >= _allMessages.length)
                              ? Padding(
                                  key: const ValueKey('all_loaded'),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: const Text('All messages loaded',
                                          style: TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: combinedMessages.length,
                        reverse: true, // Start from bottom
                        itemBuilder: (context, index) {
                          // Calculate real index for [Oldest ... Newest] list
                          // combinedMessages is [Oldest ... Newest]
                          // ListView index 0 is at Bottom (Newest)
                          final int realIndex =
                              combinedMessages.length - 1 - index;

                          if (realIndex < 0 ||
                              realIndex >= combinedMessages.length) {
                            return const SizedBox.shrink();
                          }

                          final message = combinedMessages[realIndex];
                          final senderMap = (message['sender'] is Map)
                              ? Map<String, dynamic>.from(message['sender'])
                              : <String, dynamic>{};

                          final isSentByMe = senderMap['_id'] == currentUserId;
                          final isSystem = message['ContentType'] == "system";
                          final content = message['content']?.toString() ?? '';

                          final currentTime = _parseTime(message['time']);
                          final prevTime = realIndex > 0
                              ? _parseTime(
                                  combinedMessages[realIndex - 1]['time'])
                              : null;

                          // Grouping Logic
                          final isGroupMessage =
                              message['is_group_message'] == true;
                          final groupMessageId =
                              message['group_message_id']?.toString();

                          if (isGroupMessage &&
                              groupMessageId != null &&
                              groupMessageId.isNotEmpty) {
                            // First in group?
                            final isFirstInGroup = realIndex == 0 ||
                                combinedMessages[realIndex - 1]
                                            ['group_message_id']
                                        ?.toString() !=
                                    groupMessageId;

                            if (!isFirstInGroup) {
                              return const SizedBox.shrink();
                            }

                            List<String> groupImages = [];
                            for (int i = realIndex;
                                i < combinedMessages.length;
                                i++) {
                              final nextMsg = combinedMessages[i];
                              final nextGrpId =
                                  nextMsg['group_message_id']?.toString();
                              if (nextGrpId == groupMessageId) {
                                final mediaUrl =
                                    nextMsg['originalUrl']?.toString() ??
                                        nextMsg['fileUrl']?.toString() ??
                                        nextMsg['thumbnailUrl']?.toString() ??
                                        nextMsg['imageUrl']?.toString() ??
                                        nextMsg['localImagePath']?.toString() ??
                                        '';
                                if (mediaUrl.isNotEmpty) {
                                  groupImages.add(mediaUrl);
                                }
                              } else {
                                break;
                              }
                            }

                            if (groupImages.isNotEmpty) {
                              return _hasLeftGroup
                                  ? SizedBox()
                                  : Column(
                                      crossAxisAlignment: isSentByMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (realIndex == 0 ||
                                            !isSameDay(currentTime, prevTime))
                                          _buildDateSeparator(currentTime),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                          child: Align(
                                            alignment: isSentByMe
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.75,
                                              ),
                                              child: Stack(
                                                children: [
                                                  GroupedMediaWidget(
                                                    mediaUrls: groupImages,
                                                    onMediaTap: (index) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              GroupedMediaViewer(
                                                            mediaUrls:
                                                                groupImages,
                                                            initialIndex: index,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    bottom: 5,
                                                    right: 5,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.45),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            TimeUtils
                                                                .formatUtcToIst(
                                                                    message[
                                                                        'time']),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          if (isSentByMe) ...[
                                                            const SizedBox(
                                                                width: 4),
                                                            Builder(builder:
                                                                (context) {
                                                              final status =
                                                                  message['messageStatus']
                                                                          ?.toString() ??
                                                                      'sent';
                                                              switch (status) {
                                                                case 'sent':
                                                                  return const Icon(
                                                                      Icons
                                                                          .check,
                                                                      size: 12,
                                                                      color: Colors
                                                                          .white);
                                                                case 'delivered':
                                                                  return const Icon(
                                                                      Icons
                                                                          .done_all_rounded,
                                                                      size: 12,
                                                                      color: Colors
                                                                          .white);
                                                                case 'read':
                                                                  return const Icon(
                                                                      Icons
                                                                          .done_all,
                                                                      size: 12,
                                                                      color: Colors
                                                                          .blueAccent);
                                                                default:
                                                                  return const Icon(
                                                                      Icons
                                                                          .access_time,
                                                                      size: 12,
                                                                      color: Colors
                                                                          .white);
                                                              }
                                                            }),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                            }
                          }

                          List<Widget> children = [];

                          if (isSystem &&
                              (content.contains('Group created by') ||
                                  content.contains('added') ||
                                  content.contains('left'))) {
                            children.add(_buildtextSeparator(content));
                          }

                          if (realIndex == 0 ||
                              !isSameDay(currentTime, prevTime)) {
                            children.add(_buildDateSeparator(currentTime));
                          }

                          children
                              .add(_buildMessageBubble(message, isSentByMe));

                          final messageId = (message['message_id'] ??
                                  message['messageId'] ??
                                  message['id'])
                              ?.toString();
                          final isHighlighted =
                              _highlightedMessageId == messageId;

                          return _hasLeftGroup
                              ? SizedBox()
                              : AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  color: isHighlighted
                                      ? Colors.yellow.withOpacity(0.25)
                                      : Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment: isSentByMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: children,
                                  ),
                                );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVideoPreviewTile(
    BuildContext context,
    String fileUrl,
    String fileName,
    bool isSentByMe,
    Map<String, dynamic> message,
  ) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              final isNetwork = fileUrl.startsWith('http://') ||
                  fileUrl.startsWith('https://');

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    path: fileUrl,
                    isNetwork: isNetwork,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 300,
                color: Colors.black,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FutureBuilder<File?>(
                        future: VideoThumbUtil.generateFromUrl(fileUrl),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.file(
                              snapshot.data!,
                              width: 260,
                              height: 200,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Icon(Icons.videocam,
                              color: Colors.white, size: 50);
                        },
                      ),
                      Container(
                        color: Colors.black26,
                        child: const Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 50),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TimeUtils.formatUtcToIst(message['time']),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 4),
                    Builder(builder: (context) {
                      final status =
                          message['messageStatus']?.toString() ?? 'sent';
                      switch (status) {
                        case 'sent':
                          return const Icon(Icons.check,
                              size: 12, color: Colors.white);
                        case 'delivered':
                          return const Icon(Icons.done_all_rounded,
                              size: 12, color: Colors.white);
                        case 'read':
                          return const Icon(Icons.done_all,
                              size: 12, color: Colors.blue);
                        default:
                          return const SizedBox.shrink();
                      }
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isSentByMe) {
    final String content = message['content']?.toString() ?? '';
    final String? imageUrl = message['imageUrl'] ?? _imageFile;
    final String? fileUrl = message['fileUrl'] ?? _fileUrl;
    final String? fileName = message['fileName'];
    final String? fileType = message['fileType'];
    final bool? isForwarded = message['isForwarded'];
    final String userName = message['userName'] ?? "";
    final String contentType = message['ContentType'] ?? "";
    final senderData = message['sender'] is Map ? message['sender'] : {};
    final String profileImageUrl = senderData['profile_pic_path']?.toString() ??
        senderData['profilePic']?.toString() ??
        senderData['avatar']?.toString() ??
        message['profile_pic_path']?.toString() ??
        "";

    final bool isImage =
        (fileType != null && fileType.toLowerCase().startsWith("image")) ||
            (fileName != null &&
                RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$', caseSensitive: false)
                    .hasMatch(fileName));

    final bool isVideo =
        (fileType != null && fileType.toLowerCase().startsWith("video")) ||
            (fileName != null &&
                RegExp(r'\.(mp4|mov|avi|mkv|webm)$', caseSensitive: false)
                    .hasMatch(fileName));

    if (message['isDeleted'] == true ||
        message['content'] == 'Message Deleted') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "This message was deleted",
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    final String messageStatus =
        message['messageStatus']?.toString() ?? 'delivered';

    if (content.isEmpty &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (fileUrl == null || fileUrl.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isSelected =
        _selectedMessageKeys.contains(_generateMessageKey(message));

    // reply detection – don't depend only on isReplyMessage flagvered status io
    final bool hasReply = (message['repliedMessage'] is Map &&
            (message['repliedMessage']['id'] ??
                    message['repliedMessage']['message_id'] ??
                    message['repliedMessage']['messageId']) !=
                null) ||
        (message['reply'] is Map &&
            (message['reply']['id'] ??
                    message['reply']['message_id'] ??
                    message['reply']['messageId']) !=
                null);

    return message['content'].contains('Group created by')
        ? voidBox
        : (contentType == "system" &&
                (content.contains('added') || content.contains('left')))
            ? voidBox
            : SwipeTo(
                animationDuration: const Duration(milliseconds: 300),
                iconOnRightSwipe: Icons.reply,
                iconColor: Colors.grey.shade600,
                iconSize: 24.0,
                offsetDx: 0.3,
                swipeSensitivity: 5,
                onRightSwipe: (details) {
                  _replyToMessage(message);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () => _onMessageTap(message),
                    onLongPress: () {
                      if (_isSelectionMode) {
                        _toggleMessageSelection(message);
                      } else {
                        _showReactionPicker(context, message);

                        // Enter selection mode
                        setState(() {
                          _isSelectionMode = true;
                        });
                        _toggleMessageSelection(message);
                      }
                    },
                    child: Align(
                      alignment: isSentByMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 36),
                            child: Container(
                              margin: EdgeInsets.only(
                                left: 5,
                                right: 5,
                                top: 6,
                                bottom: (message['reactions'] != null &&
                                        message['reactions'].isNotEmpty)
                                    ? 20 // WHEN REACTION EXISTS
                                    : 6,
                              ),
                              padding: const EdgeInsets.all(7),
                              constraints: const BoxConstraints(maxWidth: 250),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? senderColor.withOpacity(0.2)
                                    : (isSentByMe
                                        ? senderColor
                                        : receiverColor),
                                borderRadius: BorderRadius.only(
                                  topLeft: isSentByMe
                                      ? const Radius.circular(18)
                                      : const Radius.circular(18),
                                  topRight: isSentByMe
                                      ? const Radius.circular(18)
                                      : const Radius.circular(18),
                                  bottomLeft: isSentByMe
                                      ? const Radius.circular(18)
                                      : Radius.zero,
                                  bottomRight: isSentByMe
                                      ? Radius.zero
                                      : const Radius.circular(16),
                                ),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: hasReply
                                    ? CrossAxisAlignment.stretch
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isSentByMe && userName.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: ColorUtil.getColorFromAlphabet(
                                              userName),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),

                                  // REPLY PREVIEW
                                  if (hasReply)
                                    _buildReplyPreview(message, isSentByMe),

                                  if (isForwarded == true)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          "assets/images/forward.png",
                                          height: 14,
                                          width: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Forwarded",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (imageUrl != null &&
                                      imageUrl.isNotEmpty &&
                                      (isImage || imageUrl != fileUrl))
                                    content == "Message Deleted"
                                        ? const SizedBox.shrink()
                                        : Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _showFullImage(
                                                    context, imageUrl),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: imageUrl.startsWith(
                                                              'https') ||
                                                          imageUrl.startsWith(
                                                              'http')
                                                      ? CachedNetworkImage(
                                                          imageUrl: imageUrl,
                                                          width: 240,
                                                          height: 300,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const Center(
                                                                  child:
                                                                      CircularProgressIndicator()),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error,
                                                                  color: Colors
                                                                      .red),
                                                        )
                                                      : Image.file(
                                                          File(imageUrl),
                                                          width: 240,
                                                          height: 240,
                                                          fit: BoxFit.cover),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                bottom: 0,
                                                left: isSentByMe ? -60 : null,
                                                right: isSentByMe ? null : -60,
                                                child: Center(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      onTap: () {
                                                        MyRouter.push(
                                                          screen:
                                                              ForwardMessageScreen(
                                                            messages: [message],
                                                            currentUserId:
                                                                currentUserId,
                                                            conversionalid: "",
                                                            username: widget
                                                                .groupName,
                                                          ),
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: Image.asset(
                                                          "assets/images/forward.png",
                                                          height: 20,
                                                          width: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 5,
                                                right: 4,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 2,
                                                        offset:
                                                            const Offset(0, 1),
                                                      ),
                                                    ],
                                                    color: Colors.black45
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        TimeUtils
                                                            .formatUtcToIst(
                                                                message[
                                                                    'time']),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      if (isSentByMe) ...[
                                                        const SizedBox(
                                                            width: 4),
                                                        Builder(
                                                            builder: (context) {
                                                          switch (
                                                              messageStatus) {
                                                            case 'sent':
                                                              return const Icon(
                                                                  Icons.check,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .white);
                                                            case 'delivered':
                                                              return const Icon(
                                                                  Icons
                                                                      .done_all_rounded,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .white);
                                                            case 'read':
                                                              return const Icon(
                                                                  Icons
                                                                      .done_all,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .blue);
                                                            default:
                                                              return const SizedBox
                                                                  .shrink();
                                                          }
                                                        }),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                  if (fileUrl != null &&
                                      fileUrl.isNotEmpty &&
                                      isVideo)
                                    _buildVideoPreviewTile(
                                        context,
                                        fileUrl,
                                        fileName ?? 'Video',
                                        isSentByMe,
                                        message)
                                  else if (fileUrl != null &&
                                      fileUrl.isNotEmpty &&
                                      !(content == "Message Deleted" ||
                                          isImage || // Use pre-calculated isImage
                                          (fileType != null &&
                                              fileType
                                                  .toLowerCase()
                                                  .startsWith("image")) ||
                                          (fileName != null &&
                                              RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$',
                                                      caseSensitive: false)
                                                  .hasMatch(fileName))))
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 300,
                                              margin:
                                                  const EdgeInsets.only(top: 8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_getFileIcon(fileType),
                                                      color: chatColor,
                                                      size: 30),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      fileName ??
                                                          'Download file',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.download_rounded),
                                                    onPressed: () => _openFile(
                                                        fileUrl, fileType),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2, right: 0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    TimeUtils.formatUtcToIst(
                                                        message['time']),
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black54),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (isSentByMe)
                                                    _buildStatusIcon(
                                                        messageStatus,message),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          left: isSentByMe ? -60 : null,
                                          right: isSentByMe ? null : -60,
                                          child: Center(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                onTap: () {
                                                  MyRouter.push(
                                                    screen:
                                                        ForwardMessageScreen(
                                                      messages: [message],
                                                      currentUserId:
                                                          currentUserId,
                                                      conversionalid: "",
                                                      username:
                                                          widget.groupName,
                                                    ),
                                                  );
                                                },
                                                child: CircleAvatar(
                                                  maxRadius: 16,
                                                  backgroundColor: Colors.white,
                                                  child: Image.asset(
                                                    "assets/images/forward.png",
                                                    height: 20,
                                                    width: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  if (content.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: hasReply
                                            ? CrossAxisAlignment.stretch
                                            : CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (RegExp(r'https?:\/\/[^\s]+')
                                              .hasMatch(content))
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                AnyLinkPreview(
                                                  link:
                                                      RegExp(r'https?:\/\/[^\s]+')
                                                              .firstMatch(
                                                                  content)
                                                              ?.group(0) ??
                                                          '',
                                                  displayDirection: UIDirection
                                                      .uiDirectionVertical,
                                                  showMultimedia: true,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  bodyStyle: const TextStyle(
                                                      color:
                                                          Colors.transparent),
                                                  cache:
                                                      const Duration(hours: 1),
                                                ),
                                                Positioned(
                                                  top: 100,
                                                  bottom: 0,
                                                  left: isSentByMe ? -60 : null,
                                                  right:
                                                      isSentByMe ? null : -60,
                                                  child: Center(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        onTap: () {
                                                          MyRouter.push(
                                                            screen:
                                                                ForwardMessageScreen(
                                                              messages: [
                                                                message
                                                              ],
                                                              currentUserId:
                                                                  currentUserId,
                                                              conversionalid:
                                                                  "",
                                                              username: widget
                                                                  .groupName,
                                                            ),
                                                          );
                                                        },
                                                        child: CircleAvatar(
                                                          maxRadius: 16,
                                                          backgroundColor:
                                                              Colors.white,
                                                          child: Image.asset(
                                                            "assets/images/forward.png",
                                                            height: 20,
                                                            width: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          Stack(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5.0),
                                                child: RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      ...(() {
                                                        final List<InlineSpan>
                                                            spans = [];
                                                        final RegExp urlRegExp =
                                                            RegExp(
                                                                r'((https?:\/\/)|(www\.))[^\s]+');
                                                        final matches =
                                                            urlRegExp
                                                                .allMatches(
                                                                    content);
                                                        int start = 0;

                                                        for (final match
                                                            in matches) {
                                                          if (match.start >
                                                              start) {
                                                            spans.add(
                                                              TextSpan(
                                                                text: content
                                                                    .substring(
                                                                        start,
                                                                        match
                                                                            .start),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    color: Colors
                                                                        .black87),
                                                              ),
                                                            );
                                                          }

                                                          final String url =
                                                              content.substring(
                                                                  match.start,
                                                                  match.end);

                                                          spans.add(
                                                            TextSpan(
                                                              text: url,
                                                              style:
                                                                  const TextStyle(
                                                                color:
                                                                    Colors.blue,
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline,
                                                              ),
                                                              recognizer:
                                                                  TapGestureRecognizer()
                                                                    ..onTap =
                                                                        () async {
                                                                      try {
                                                                        final uri = Uri.parse(url.startsWith('www.')
                                                                            ? 'https://$url'
                                                                            : url);
                                                                        if (!await launchUrl(
                                                                            uri,
                                                                            mode:
                                                                                LaunchMode.externalApplication)) {
                                                                          throw 'Could not launch $uri';
                                                                        }
                                                                      } catch (e) {
                                                                        debugPrint(
                                                                            'Could not launch url: $e');
                                                                      }
                                                                    },
                                                            ),
                                                          );

                                                          start = match.end;
                                                        }

                                                        if (start <
                                                            content.length) {
                                                          spans.add(
                                                            TextSpan(
                                                              text: content
                                                                  .substring(
                                                                      start),
                                                              style: const TextStyle(
                                                                  fontSize: 15,
                                                                  color: Colors
                                                                      .black87),
                                                            ),
                                                          );
                                                        }

                                                        return spans;
                                                      })(),
                                                      WidgetSpan(
                                                          child: SizedBox(
                                                        width: isSentByMe
                                                            ? 75
                                                            : 60,
                                                      )),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              Positioned(
                                                top: 0,
                                                bottom: 0,
                                                left: isSentByMe ? -60 : null,
                                                right: isSentByMe ? null : -60,
                                                child: Center(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      onTap: () {
                                                        MyRouter.push(
                                                          screen:
                                                              ForwardMessageScreen(
                                                            messages: [message],
                                                            currentUserId:
                                                                currentUserId,
                                                            conversionalid: "",
                                                            username: widget
                                                                .groupName,
                                                          ),
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: Image.asset(
                                                          "assets/images/forward.png",
                                                          height: 20,
                                                          width: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              /// ---- TIMESTAMP & STATUS (DISABLED TOUCH) ----
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: IgnorePointer(
                                                  ignoring: true,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        TimeUtils
                                                            .formatUtcToIst(
                                                                message[
                                                                    'time']),
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Colors.black54),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      if (isSentByMe &&
                                                          content !=
                                                              "Message Deleted")
                                                        _buildStatusIcon(
                                                            messageStatus,message),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // REACTIONS BAR - Positioned outside the Container
                          if (message['reactions'] != null &&
                              message['reactions'].isNotEmpty)
                            Positioned(
                              bottom: -10,
                              left: isSentByMe ? 48 : 48,
                              right: null,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: 12,
                                  left: isSentByMe ? 0 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    debugPrint('🔥 Tapped on reacted emoji!');
                                    debugPrint(
                                        '🔥 Message: ${message['message_id']}');
                                    // Get first emoji from reactions or default to empty
                                    final reactions =
                                        _extractReactions(message['reactions']);
                                    final firstEmoji = reactions.isNotEmpty
                                        ? (reactions.first['emoji']
                                                ?.toString() ??
                                            '')
                                        : '';
                                    debugPrint(
                                        '🔥 About to call _showReactionsBottomSheet');
                                    _showReactionsBottomSheet(
                                        message, firstEmoji);
                                  },
                                  child:
                                      _buildReactionsBar(message, isSentByMe),
                                ),
                              ),
                            ),
                          isSentByMe
                              ? const SizedBox.shrink()
                              : Positioned(
                                  left: isSentByMe ? null : 2,
                                  right: isSentByMe ? 2 : null,
                                  top: 10,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.transparent,
                                    child: ClipOval(
                                      child: profileImageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: profileImageUrl,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  _buildAvatarWithInitial(
                                                      userName),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      _buildAvatarWithInitial(
                                                          userName),
                                            )
                                          : _buildAvatarWithInitial(userName),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
  }

  void _openFile(String urlOrPath, String? fileType) async {
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      try {
        await launchUrl(Uri.parse(urlOrPath),
            mode: LaunchMode.externalApplication);
      } catch (e) {
        Messenger.alertError("Could not open file from URL.");
      }
    } else {
      final result = await OpenFile.open(urlOrPath);
      if (result.type != ResultType.done) {
        Messenger.alertError("Could not open local file.");
      }
    }
  }

  DateTime _parseTime(dynamic time) {
    if (time == null) return DateTime.now();
    if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
    if (time is String) {
      try {
        return DateTime.parse(time);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

Widget _buildStatusIcon(String status, Map<String, dynamic> message) {
    // Add tap handler for all unsent/pending messages
    // Allow resend/delete for: failed, pending_offline, pending, sending
    if (status == 'failed' ||
        status == 'pending_offline' ||
        status == 'pending' ||
        status == 'sending') {
      return GestureDetector(
        onTap: () => _showResendDialog(message),
        child: MessageStatusIcon(status: status),
      );
    }
    return MessageStatusIcon(status: status);
  }
  void _showResendDialog(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message not sent'),
        content:
            Text('This message couldn\'t be sent. Do you want to try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resendMessage(message);
            },
            child: Text('Resend'),
          ),
        ],
      ),
    );
  }
  void _resendMessage(Map<String, dynamic> failedMessage) async {
    final oldMessageId = failedMessage['message_id']?.toString() ?? '';
    final content = failedMessage['content']?.toString() ?? '';

    if (content.isEmpty) return;

    if (!(_isOnline && socketService.isConnected)) {
      Messenger.alertError("Cannot resend: No internet or socket disconnected");
      _updateMessageStatus(oldMessageId, 'failed');
      return;
    }

    // Update status to sending for the existing message
    _updateMessageStatus(oldMessageId, 'sending');

    try {
      // Create a completer to wait for the sent message
      final completer = Completer<GrpMessage>();
      final subscription = _groupBloc.stream.listen((state) {
        if (state is GrpMessageSentSuccessfully) {
          completer.complete(state.sentMessage);
        } else if (state is GroupChatError) {
          completer.completeError(state.message);
        }
      });

      // Dispatch the send event (this creates a NEW message with NEW ID)
      _groupBloc.add(
        SendMessageEvent(
          convoId: widget.conversationId,
          message: content,
          senderId: currentUserId,
          receiverId: widget.datumId,
          replyTo: failedMessage['reply'],
        ),
      );

      // Wait for the server response
      final sentMsg = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Resend timed out');
        },
      );
      await subscription.cancel();

      // Replace the old failed message with the new successful one
      _replaceTempMessageWithReal(
        tempId: oldMessageId,
        realId: sentMsg.messageId,
        status: 'sent',
      );
    } catch (e) {
      debugPrint('❌ Resend failed: $e');
      _updateMessageStatus(oldMessageId, 'failed');
      if (e is! TimeoutException) {
        Messenger.alertError("Resend failed: $e");
      }
    }
  }

  /// Delete a failed message
  void _deleteMessage(Map<String, dynamic> message) {
    final messageId = message['message_id']?.toString() ?? '';

    setState(() {
      socketMessages
          .removeWhere((m) => (m['message_id'] ?? '').toString() == messageId);
      messages
          .removeWhere((m) => (m['message_id'] ?? '').toString() == messageId);
      dbMessages
          .removeWhere((m) => (m['message_id'] ?? '').toString() == messageId);

      _refreshMessages();
    });

    // Save to storage
    final combined = _getCombinedMessages();
    GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
  }
  Widget _buildDateSeparator(DateTime? dateTime) {
    if (dateTime == null) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDateTime(dateTime),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildtextSeparator(String? text) {
    if (text == null) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
      _replyPreview = null;
    });
  }

  void _startRecordingFs() async {
    await _recorder.startRecorder(toFile: 'voice.aac');
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordDuration = 0;
    });
    _startTimer();
  }

  void _pauseRecordingFs() async {
    await _recorder.pauseRecorder();
    setState(() {
      _isPaused = true;
    });
    _timer?.cancel();
  }

  void _resumeRecordingFs() async {
    await _recorder.resumeRecorder();
    setState(() {
      _isPaused = false;
    });
    _startTimer();
  }

  void _stopRecordingFs() async {
    String? path = await _recorder.stopRecorder();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordedFilePath = path;
    });
  }

  void _playRecording() async {
    if (_recordedFilePath != null) {
      await _player.startPlayer(fromURI: _recordedFilePath);
    }
  }

  void _sendRecording() {
    if (_recordedFilePath != null) {
      log("Send: $_recordedFilePath");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Widget _buildVoiceRecordingUI() {
    return VoiceRecordingWidget(
      isRecording: _isRecording,
      isPaused: _isPaused,
      recordDuration: Duration(seconds: _recordDuration),
      formatDuration: (duration) => _formatDuration(duration.inSeconds),
      onStartRecording: _startRecordingFs,
      onPauseRecording: _pauseRecordingFs,
      onResumeRecording: _resumeRecordingFs,
      onStopRecording: _stopRecordingFs,
      onPlayRecording: _playRecording,
      onSendRecording: _sendRecording,
      recordedFilePath: _recordedFilePath,
      onCancel: () {
        _timer?.cancel();
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _recordedFilePath = null;
        });
      },
    );
  }

  Widget _buildMessageInputField(bool isKeyboardVisible, bool thereORleft) {
    return MessageInputField(
      messageController: _messageController,
      reciverID: widget.datumId,
      focusNode: _focusNode,
      onSendPressed: _sendMessage,
      onEmojiPressed: _toggleEmojiKeyboard,
      onAttachmentPressed: () => GrpShowAltDialog.grpshowOptionsDialog(
        context,
        conversationId: widget.conversationId,
        senderId: currentUserId,
        receiverId: widget.datumId,
        isGroupChat: true,
        onOptionSelected: _sendMessageImage,
        onFilesSelected: _sendMultipleFiles,
      ),

      //     (List<Map<String, dynamic>> localMessages) {
      //   setState(() {
      //     socketMessages.addAll(localMessages);
      //   });
      // }),
      onCameraPressed: _openCamera,
      onRecordPressed: _isRecording ? _stopRecordingFs : _startRecordingFs,
      isRecording: _isRecording,
      replyText: _replyPreview,
      onCancelReply: _cancelReply,
      thereORleft: thereORleft,
      isGroupChat: true,
    );
  }

  void _showReactionPicker(BuildContext context, Map<String, dynamic> message) {
    final List<String> emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis
                .map((emoji) => GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleReactionTap(message, emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  // PreferredSizeWidget _buildAppBar() {
  //   return CommonAppBarBuilder.build(
  //       context: context,
  //       showSearchAppBar: _showSearchAppBar,
  //       isSelectionMode: _isSelectionMode,
  //       selectedMessages: _selectedMessages,
  //       toggleSelectionMode: _toggleSelectionMode,
  //       deleteSelectedMessages: _deleteSelectedMessages,
  //       forwardSelectedMessages: _forwardSelectedMessages,
  //       starSelectedMessages: _starSelectedMessages,
  //       replyToMessage: _replyToMessage,
  //       profileAvatarUrl: widget.groupAvatarUrl,
  //       convertionId: widget.conversationId,
  //       userName: widget.groupName,
  //       firstname: widget.groupName,
  //       grpId: widget.datumId,
  //       grpChat: widget.grpChat,
  //       resvID: widget.datumId,
  //       favouitre: widget.favorite,
  //       onSearchTap: () {
  //         setState(() {
  //           _showSearchAppBar = !_showSearchAppBar;
  //         });
  //       },
  //       onCloseSearch: () {
  //         setState(() {
  //           _showSearchAppBar = false;
  //         });
  //       });
  // }

  PreferredSizeWidget _buildAppBar() {
    print(_hasLeftGroup);
    return CommonAppBarBuilder.build(
      context: context,
      showSearchAppBar: _showSearchAppBar,
      groupMembers: groupMembers,
      isSelectionMode: _isSelectionMode,
      selectedMessages: _selectedMessages,
      toggleSelectionMode: _hasLeftGroup
          ? () {}
          : () {
              print(_hasLeftGroup);
              if (_hasLeftGroup) return;

              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _selectedMessages.clear();
                  _selectedMessageIds.clear();
                  _selectedMessageKeys.clear();
                }
              });
            },
      deleteSelectedMessages: _hasLeftGroup
          ? () {}
          : () {
              print(_hasLeftGroup);
              if (_hasLeftGroup) return;
              DeleteMessageDialog.show(
                context: context,
                onDeleteForEveryone: () {},
                onDeleteForMe: () => _deleteSelectedMessages(),
              );
            },
      forwardSelectedMessages: _hasLeftGroup ? () {} : _forwardSelectedMessages,
      starSelectedMessages: _hasLeftGroup ? () {} : _starSelectedMessages,
      replyToMessage: _replyToMessage,
      profileAvatarUrl: widget.groupAvatarUrl,
      userName: widget.groupName,
      firstname: widget.groupName,
      grpId: widget.datumId,
      convertionId: widget.conversationId,
      resvID: widget.datumId,
      favouitre: widget.favorite,
      grpChat: widget.grpChat,
      onSearchTap: _hasLeftGroup ? () {} : () => toggleSearchAppBar(),
      onCloseSearch: _hasLeftGroup ? () {} : () => toggleSearchAppBar(),
      hasLeftGroup: _hasLeftGroup,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReusableChatScaffold(
      appBar: _buildAppBar(),
      chatBody: _buildChatBody(),
      voiceRecordingUI: _buildVoiceRecordingUI(),
      messageInputBuilder: (context) {
        return BlocListener<GroupChatBloc, GroupChatState>(
          bloc: _groupBloc,
          listenWhen: (previous, current) =>
              current is GroupLeftState ||
              current is GroupChatError ||
              current is GroupDetailsLoaded,
          listener: (context, state) {
            if (state is GroupLeftState) {
              setState(() {
                _hasLeftGroup = true;
              });
            }
            if (state is GroupDetailsLoaded) {
              if (mounted) {
                setState(() {
                  final members = state.groupDetails['groupMembers'];
                  if (members is List) {
                    groupMembers = members.map((m) {
                      if (m is Map) {
                        return (m['member_id'] ?? m['id'] ?? m['_id'] ?? "")
                            .toString();
                      }
                      return m.toString();
                    }).toList();
                    print("✅ Updated Group Members from API: $groupMembers");
                  }
                });
              }
            }
            if (state is GroupChatError) {
              log("GroupChatError: ${state.message}");
            }
          },
          child: BlocBuilder<GroupChatBloc, GroupChatState>(
            bloc: _groupBloc,
            buildWhen: (previous, current) =>
                current is! GroupLeftState, // Avoid conflict with listener
            builder: (context, state) {
              /// 🔒 User has left the group — show banner instead of input
              if (_hasLeftGroup) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'You have left the group',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              final isKeyboardVisible =
                  WidgetsBinding.instance.window.viewInsets.bottom > 0;

              /// Normal message input UI
              return _buildMessageInputField(isKeyboardVisible, false);
            },
          ),
        );
      },
      isRecording: _isRecording,
      bloc: _groupBloc,
    );
  }

  Widget _buildAvatarWithInitial(String name) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: name.isNotEmpty
            ? ColorUtil.getColorFromAlphabet(name)
            : Colors.grey.shade400,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildReactionsBar(Map<String, dynamic> message, bool isSentByMe) {
    final reactionsRaw = message['reactions'] ?? [];

    final reactions = (reactionsRaw as List?)
            ?.where((r) => r is Map)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList() ??
        [];

    if (reactions.isEmpty) return const SizedBox.shrink();

    // Count occurrences of each emoji
    final Map<String, int> reactionCounts = {};
    for (final reaction in reactions) {
      final emoji = reaction['emoji']?.toString();
      if (emoji != null && emoji.isNotEmpty) {
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionCounts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showReactionsBottomSheet(
      Map<String, dynamic> message, String initialEmoji) async {
    // helper to build normalized reactions list for a message object
    List<Map<String, dynamic>> _normalizeFromMap(Map<String, dynamic> msg) {
      final List<Map<String, dynamic>> out = [];
      if (msg['reactions'] is! List) return out;
      for (final r in (msg['reactions'] as List)) {
        if (r is! Map) continue;
        final mm = Map<String, dynamic>.from(r);
        final emoji = (mm['emoji'] ?? '').toString();
        if (emoji.isEmpty) continue;

        String? userId = mm['userId']?.toString();
        final user = mm['user'];

        // Try to extract userId from user object if userId is null
        if ((userId == null || userId.isEmpty) && user is Map) {
          userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
        }

        // IMPORTANT: Allow reactions even without userId - use "unknown" as fallback
        // This ensures the bottom sheet shows even when user info is incomplete
        if (userId == null || userId.isEmpty) {
          userId =
              "unknown_${DateTime.now().millisecondsSinceEpoch}"; // unique fallback
        }

        out.add({
          'emoji': emoji,
          'userId': userId,
          'user': user is Map ? Map<String, dynamic>.from(user) : null,
          'reacted_at': (mm['reacted_at'] ?? mm['createdAt'] ?? '').toString(),
        });
      }
      return out;
    }

    // default emoji set (change if you want)
    const List<String> pickerEmojis = [
      '👍',
      '❤️',
      '😂',
      '😮',
      '😢',
      '👏',
      '🔥',
      '🎉',
      '🤝',
      '💯'
    ];

    // first build the initial normalized list
    List<Map<String, dynamic>> allReacts = _normalizeFromMap(message);

    // Debug logging
    debugPrint('🔍 _showReactionsBottomSheet called');
    debugPrint('🔍 Message reactions raw: ${message['reactions']}');
    debugPrint('🔍 Normalized reactions: $allReacts');
    debugPrint('🔍 Initial emoji: $initialEmoji');

    // Allow showing sheet even if empty - users can still add reactions
    // if (allReacts.isEmpty) {
    //   return;
    // }

    // group builder (returns grouped map)
    Map<String, List<Map<String, dynamic>>> buildGroupedFromList(
        List<Map<String, dynamic>> list) {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final r in list) {
        final e = r['emoji'] as String;
        grouped.putIfAbsent(e, () => []).add(r);
      }
      return grouped;
    }

    // show sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        // local UI state inside sheet
        bool showEmojiPicker = false;
        Map<String, List<Map<String, dynamic>>> grouped =
            buildGroupedFromList(allReacts);
        final emojis = grouped.keys.toList();
        String selectedEmoji = emojis.contains(initialEmoji)
            ? initialEmoji
            : (emojis.isNotEmpty
                ? emojis.first
                : (initialEmoji.isNotEmpty
                    ? initialEmoji
                    : pickerEmojis.first));

        // function to attempt to refresh `message` from current combined store
        void refreshFromStore(StateSetter setStateSB) {
          try {
            final id = (message['message_id'] ??
                    message['messageId'] ??
                    message['id'] ??
                    '')
                .toString();
            if (id.isNotEmpty) {
              final latest = _getCombinedMessages().firstWhere((m) {
                final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '')
                    .toString();
                return mid == id;
              }, orElse: () => message);
              // rebuild normalized list and grouped
              allReacts = _normalizeFromMap(latest);
              grouped = buildGroupedFromList(allReacts);
              final newEmojis = grouped.keys.toList();
              if (!newEmojis.contains(selectedEmoji) && newEmojis.isNotEmpty) {
                selectedEmoji = newEmojis.first;
              }
              setStateSB(() {}); // rebuild sheet
            } else {
              // no id: just keep what we have
              setStateSB(() {});
            }
          } catch (_) {
            // ignore and keep current values
            setStateSB(() {});
          }
        }

        return StatefulBuilder(builder: (ctx2, setStateSB) {
          final reactors = grouped[selectedEmoji] ?? [];

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: showEmojiPicker
                    ? MediaQuery.of(context).size.height * 0.45
                    : MediaQuery.of(context).size.height * 0.30,
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4)),
                  ),

                  // TOP: emoji chips (Add first)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        // Add chip (always visible)
                        GestureDetector(
                          onTap: () {
                            setStateSB(() {
                              showEmojiPicker =
                                  !showEmojiPicker; // toggle emoji picker inside sheet
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: showEmojiPicker
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.emoji_emotions_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Add',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // existing reaction chips (scrollable)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: grouped.keys.map((e) {
                                final cnt = grouped[e]?.length ?? 0;
                                final isSelected = e == selectedEmoji;
                                return GestureDetector(
                                  onTap: () {
                                    setStateSB(() {
                                      selectedEmoji = e;
                                      showEmojiPicker =
                                          false; // hide picker if open
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.greenAccent.withOpacity(0.3)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: isSelected
                                              ? Colors.green
                                              : Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(e,
                                            style:
                                                const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text('$cnt',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // optionally show emoji picker panel inside sheet
                  if (showEmojiPicker) ...[
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pickerEmojis.map((emo) {
                          return GestureDetector(
                            onTap: () async {
                              // user selected an emoji to add/change their reaction:
                              try {
                                // call your existing handler which handles add/change/remove logic
                                _handleReactionTap(message, emo);
                                Navigator.pop(context);
                              } catch (e) {
                                debugPrint(
                                    'Error while handling reaction pick: $e');
                              }

                              // hide picker and refresh sheet lists
                              setStateSB(() {
                                showEmojiPicker = false;
                              });

                              // give a tiny delay to allow local updates to settle, then refresh the grouped list
                              await Future.delayed(
                                  const Duration(milliseconds: 120));
                              refreshFromStore(setStateSB);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.shade100,
                              ),
                              child: Text(emo,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),

                  // header: "X reactions"
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('${grouped[selectedEmoji]?.length ?? 0} reactions',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close')),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),

                  // reactors list
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: reactors.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final r = reactors[i];
                        final user = r['user'];
                        String userId;
                        String displayName = '';
                        String? avatarUrl;

                        if (user is Map) {
                          userId = (user['_id'] ??
                                  user['id'] ??
                                  user['userId'] ??
                                  '')
                              .toString();
                          displayName = (user['first_name'] ??
                                  user['name'] ??
                                  user['firstName'] ??
                                  user['email'] ??
                                  '')
                              .toString();
                          avatarUrl = user['avatar']?.toString();
                        } else {
                          userId = (r['userId'] ?? '').toString();
                          displayName = userId;
                        }

                        final isMe = userId == currentUserId;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl) as ImageProvider
                                    : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?')
                                : null,
                          ),
                          title: Text(isMe
                              ? 'You'
                              : (displayName.isNotEmpty
                                  ? displayName
                                  : 'Unknown User')),
                          subtitle: isMe
                              ? const Text('Tap to remove',
                                  style: TextStyle(fontSize: 12))
                              : null,
                          trailing: isMe
                              ? TextButton(
                                  onPressed: () async {
                                    Navigator.of(ctx).pop(); // close sheet
                                    final msgId = (message['message_id'] ??
                                            message['messageId'] ??
                                            '')
                                        .toString();
                                    if (msgId.isEmpty) return;

                                    // optimistic local removal of current user's reaction
                                    _updateLocalReactions(msgId,
                                        null); // remove my reaction locally
                                    final apiMessageId =
                                        _normalizeMessageIdForApi(msgId);

                                    // dispatch your GroupRemoveReaction event
                                    context
                                        .read<GroupChatBloc>()
                                        .add(GroupRemoveReaction(
                                          messageId: apiMessageId,
                                          conversationId: widget.conversationId,
                                          emoji: selectedEmoji,
                                          userId: currentUserId,
                                          receiverId: widget.datumId,
                                        ));
                                  },
                                  child: const Text('Remove',
                                      style: TextStyle(color: Colors.red)),
                                )
                              : null,
                          onTap: () {
                            // optional: open user profile
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ------------------ Helper Methods for Read Receipts ------------------

  bool _isUnreadMessage(dynamic msg) {
    if (msg is Map<String, dynamic>) {
      String? senderId = msg['senderId']?.toString();
      if (senderId == null) {
        final dynamic sender = msg['sender'];
        if (sender is Map) {
          senderId = (sender['_id'] ?? sender['id'])?.toString();
        } else if (sender is String) {
          senderId = sender;
        }
      }

      return msg['messageStatus'] != 'read' &&
          senderId != null &&
          senderId != currentUserId && // 👈 only msgs from others
          msg['message_id'] != null;
    }
    return false;
  }

  List<String> _getUnreadMessageIds(List<Map<String, dynamic>> messages) {
    return messages
        .where(_isUnreadMessage)
        .map((m) => (m['message_id'] ?? m['messageId'] ?? m['id']).toString())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  void _replaceTempMessageWithReal({
    required String tempId,
    required String realId,
    required String status,
  }) {
    bool changed = false;

    // Check if we have a buffered status update for this realId
    String finalStatus = status;
    if (_pendingStatusUpdates.containsKey(realId)) {
      final bufferedStatus = _pendingStatusUpdates[realId]!;
      // Only apply if buffered status is "better" (e.g. read > delivered > sent)
      // For simplicity, we assume buffered is always newer/better than "sent"
      finalStatus = bufferedStatus;
      _pendingStatusUpdates.remove(realId);
      debugPrint('🚀 Applied buffered status $finalStatus to new ID $realId');
    }

    void updateList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final mid = (m['message_id'] ?? m['messageId'] ?? '').toString();
        if (mid == tempId) {
          final copy = Map<String, dynamic>.from(m);

          // Assign server id + status
          copy['message_id'] = realId;
          copy['messageStatus'] = finalStatus;

          list[i] = copy;
          changed = true;
          break;
        }
      }
    }

    // Usually optimistic messages are only in socketMessages
    updateList(socketMessages);
    updateList(messages);
    updateList(dbMessages);

    if (changed) {
      if (!_seenMessageIds.contains(realId)) _seenMessageIds.add(realId);
      final combined = _getCombinedMessages();
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      setState(() {}); // Trigger rebuild
      _refreshMessages();
    }
  }

  void _markVisibleMessagesAsRead(List<Map<String, dynamic>> combined) {
    final allUnreadIds = _getUnreadMessageIds(combined);
    final idsToSend = allUnreadIds
        .where((id) => id.trim().isNotEmpty && !_alreadyRead.contains(id))
        .toList();

    if (idsToSend.isEmpty) return;

    // bool updated = false; // logic unused for now
    for (final id in idsToSend) {
      _updateMessageStatus(id, 'read');
    }

    _alreadyRead.addAll(idsToSend);

    _sendReadReceipts(idsToSend);
  }

  void _sendReadReceipts(List<String> messageIds) {
    if (messageIds.isEmpty || widget.conversationId.isEmpty) return;

    // Using conversationId as roomId/channelId for group logic if applicable
    socketService.sendReadReceipts(
      messageIds: messageIds,
      conversationId: widget.conversationId,
      roomId: widget.datumId,
    );
  }

Future<void> _flushOfflinePendingMessages() async {
    if (_offlineQueue.isEmpty) return;
    if (!(_isOnline && socketService.isConnected)) return;

    final pending = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final item in pending) {
      final String? tempId = item['message_id'];
      final String content = item['content'];
      final Map<String, dynamic>? replyTo = item['replyTo'];

      if (tempId == null) continue;

      // Update status to sending for the existing message
      _updateMessageStatus(tempId, 'sending');

      try {
        // Create a completer to wait for the sent message
        final completer = Completer<GrpMessage>();
        final subscription = _groupBloc.stream.listen((state) {
          if (state is GrpMessageSentSuccessfully) {
            completer.complete(state.sentMessage);
          } else if (state is GroupChatError) {
            completer.completeError(state.message);
          }
        });

        // Dispatch the send event (this creates a NEW message with NEW ID)
        _groupBloc.add(
          SendMessageEvent(
            convoId: widget.conversationId,
            message: content,
            senderId: currentUserId,
            receiverId: widget.datumId,
            replyTo: replyTo,
          ),
        );

        // Wait for the server response
        final sentMsg = await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Flush timed out');
          },
        );
        await subscription.cancel();

        // Replace the old failed message with the new successful one
        _replaceTempMessageWithReal(
          tempId: tempId,
          realId: sentMsg.messageId,
          status: 'sent',
        );
      } catch (e) {
        debugPrint('❌ Flush failed for $tempId: $e');
        _updateMessageStatus(tempId, 'failed');
      }
    }
  }
}
