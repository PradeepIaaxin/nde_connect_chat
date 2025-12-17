
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/message_handler.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/audio_reuable.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/date_separate.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/double_tick_ui.dart';
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/presantation/chat/widget/image_viewer.dart';
import 'package:nde_email/presantation/chat/widget/reation_bottom.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/buildMessageInputField_widgets.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/chat_widgets/Common/group_image_ui.dart';
import '../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import '../chat_group_Screen/group_media_viewer.dart';
import '../chat_list/chat_session_storage/chat_session.dart';
import 'messager_Bloc/MessagerEvent.dart';
import 'messager_Bloc/MessagerState.dart';
import 'messager_Bloc/widget/MixedMediaViewer.dart';
import 'messager_Bloc/widget/VideoPlayerScreen.dart';
import 'messager_Bloc/widget/VideoThumbUtil.dart';

class PrivateChatScreen extends StatefulWidget {
  final String convoId;
  final String profileAvatarUrl;
  final String userName;
  final String lastSeen;
  final String? receiverId;
  final String? datumId;
  final String? firstname;
  final String? lastname;
  final bool grpChat;
  final bool favourite;

  /// Optional initial messages to show immediately (useful after forwarding)
  final List<Map<String, dynamic>>? initialMessages;

  const PrivateChatScreen({
    super.key,
    required this.convoId,
    required this.profileAvatarUrl,
    required this.userName,
    required this.lastSeen,
    this.receiverId,
    required this.datumId,
    this.firstname,
    this.lastname,
    required this.grpChat,
    required this.favourite,
    this.initialMessages,
  });

  @override
  _PrivateChatScreenState createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  // Controllers / focus
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Inline reaction overlay
  bool _suppressReactionDialog = false;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Map<String, BuildContext> _messageContexts = {};

  // Services & handlers
  final SocketService socketService = SocketService();
  late MessagerBloc _messagerBloc;
  MessageHandler? _messageHandler;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;

  // Message storage (in-memory)
  final List<Map<String, dynamic>> socketMessages = [];
  final List<Map<String, dynamic>> dbMessages = [];
  final List<Map<String, dynamic>> messages = [];

  // Seen IDs to dedupe
  final Set<String> _seenMessageIds = <String>{};

  // Debounce saving
  Timer? _saveDebounceTimer;
  final Duration _saveDebounceDuration = const Duration(milliseconds: 300);

  // Notifier for the UI list
  final ValueNotifier<List<Map<String, dynamic>>> _messagesNotifier =
  ValueNotifier([]);
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  // State
  String currentUserId = '';
  bool _showSearchAppBar = false;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedFilePath;
  bool isSentByMe =false;
  // Pagination / client-side windowing
  int _currentPage = 1;
  final int _initialLimit = 10;
  final int _pageSize = 5;

  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  double _prevScrollExtentBeforeLoad = 0.0;

  // Selection / reactions
  final Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;
  final List<dynamic> _selectedMessages = [];
  StreamSubscription<MessageReaction>? _reactionSubscription;
  final Set<String> _alreadyRead = {};
  final Set<String> _unreadMessageIds = {};
  bool _hasSentInitialReadReceipts = false;
  final Set<String> _selectedMessageKeys = {};
  Map<String, dynamic>? _replyMessage;   // full original message (for sending)
  Map<String, dynamic>? _replyPreview;   // small map for input UI

  /// Full message history for this conversation (normalized)
  final List<Map<String, dynamic>> _allMessages = [];

  /// How many from the **end** we are currently showing
  int _visibleCount = 0;

  /// Show +5 older messages each time user scrolls to top
  final int _pageStep = 5;
  final int _initialVisible = 10;

  // Media
  File? _imageFile;
  File? _fileUrl;
  final List<Map<String, dynamic>> _offlineQueue = [];

  // Recorder helper
  final recorderHelper = AudioRecorderHelper();
  bool _initialScrollDone = false;
  bool _screenActive = false;

  // Inline emoji overlay
  OverlayEntry? _reactionOverlayEntry;
  Timer? _reactionOverlayTimer;
  final List<String> _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '👏'];

  @override
  void initState() {
    super.initState();
    _messagerBloc = context.read<MessagerBloc>();
    _scrollController.addListener(_scrollListener);
    _initializeChat();
    _screenActive = true;


    // initial state
    Connectivity().checkConnectivity().then((results) {
      final hasNet = results.isNotEmpty &&
          results.first != ConnectivityResult.none;
      setState(() => _isOnline = hasNet);
    });

    // listen for changes
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.isNotEmpty &&
          results.first != ConnectivityResult.none;

      if (hasNet != _isOnline) {
        setState(() => _isOnline = hasNet);
        if (hasNet) {
          _flushOfflinePendingMessages();
        }
      }
    });
  }

  @override
  void dispose() {
    _reactionSubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _connSub?.cancel();      // 👈 don’t forget

    _saveDebounceTimer?.cancel();
    _saveAllMessages();
    _statusSubscription?.cancel();
    _highlightTimer?.cancel();

    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _messagesNotifier.dispose();
    _screenActive = false;
    final unsentText = _messageController.text.trim();
    if (unsentText.isNotEmpty) {
      _saveDraftToStorage(unsentText);
    } else {
      _clearDraftFromStorage();
    }
    super.dispose();
  }

  // ------------------ Initialization ------------------
  Future<void> _initializeChat() async {
    log("Initializing chat for convoId: ${widget.convoId}");
    socketMessages.clear();
    messages.clear();
    dbMessages.clear();
    _seenMessageIds.clear();
    _initialScrollDone = false;

    // 1) initialMessages (from forwarding)
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      final normalized = widget.initialMessages!
          .map<Map<String, dynamic>>((raw) => normalizeMessage(raw))
          .where((m) => m.isNotEmpty)
          .toList();
      dbMessages.addAll(normalized);
      for (var m in normalized) {
        final id = (m['message_id'] ?? '').toString();
        if (id.isNotEmpty) _seenMessageIds.add(id);
      }
      _updateNotifier();
      _scheduleSaveMessages();
    } else if (widget.convoId.isNotEmpty) {
      // 2) cached local messages
      final loaded = LocalChatStorage.loadMessages(widget.convoId) ?? [];
      final normalized = [
        for (var msg in loaded)
          if (msg.isNotEmpty) normalizeMessage(msg)
      ];
      dbMessages.addAll(normalized);
      for (var m in normalized) {
        final id = (m['message_id'] ?? '').toString();
        if (id.isNotEmpty) _seenMessageIds.add(id);
      }
      _updateNotifier();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialScrollDone) {
          _scrollToBottom();
          _initialScrollDone = true;
        }
      });
    }

    await Future.wait([_initializeSocket(), _loadCurrentUserId()]);

    if (widget.convoId.isNotEmpty) {
      _fetchMessages();
    }
    final draft = LocalChatStorage.getDraftMessage(widget.convoId);
    if (draft != null && draft.isNotEmpty) {
      _messageController.text = draft;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialReadReceiptsIfNeeded();
    });
  }
  Future<void> _flushOfflinePendingMessages() async {
    if (_offlineQueue.isEmpty) return;

    final pending = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final item in pending) {
      final text = item['text'] as String;
      final reply = item['reply'];
      final replyMessageId = item['replyMessageId'] as String?;
      final localId = item['localId'] as String;

      try {
        final completer = Completer<Message>();
        final subscription = _messagerBloc.stream.listen((state) {
          if (state is MessageSentSuccessfully) {
            completer.complete(state.sentMessage);
          }
        });

        _messagerBloc.add(
          SendMessageEvent(
            convoId: widget.convoId,
            message: text,
            senderId: currentUserId,
            receiverId: widget.datumId!,
            replyTo: reply,
            replyMessageId: replyMessageId,
          ),
        );

        final sent = await completer.future;
        await subscription.cancel();

        _replaceTempMessageWithReal(
          tempId: localId,
          realId: sent.messageId ?? '',
          status: sent.messageStatus ?? 'sent',
        );
      } catch (e, st) {
        log('❌ resend offline msg failed: $e\n$st');
        _updateMessageStatus(localId, 'failed');
      }
    }
  }

  void _sendReadForNewOutgoing(String serverMessageId) {
    // Do NOT add to _alreadyRead, this is not "unread from other user"
    _sendReadReceipts([serverMessageId]);
  }

  void _saveDraft(String draft) {
    if (widget.convoId.isEmpty) return;
    LocalChatStorage.saveDraftMessage(widget.convoId, draft);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.convoId,
      draftMessage: draft.isEmpty ? null : draft,
    );
    // Trigger UI refresh in chat list
    if (mounted) {
      context.read<ChatListBloc>().add(UpdateLocalChatList());
    }
  }

  void _clearDraft() {
    if (widget.convoId.isEmpty) return;
    LocalChatStorage.clearDraftMessage(widget.convoId);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.convoId,
      draftMessage: null,
    );
    // Trigger UI refresh in chat list
    if (mounted) {
      context.read<ChatListBloc>().add(UpdateLocalChatList());
    }
  }

  void _saveDraftToStorage(String draft) {
    if (widget.convoId.isEmpty) return;
    LocalChatStorage.saveDraftMessage(widget.convoId, draft);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.convoId,
      draftMessage: draft.isEmpty ? null : draft,
    );
  }

  void _clearDraftFromStorage() {
    if (widget.convoId.isEmpty) return;
    LocalChatStorage.clearDraftMessage(widget.convoId);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.convoId,
      draftMessage: null,
    );
  }
  void _markVisibleMessagesAsRead(List<Map<String, dynamic>> combined) {
    if (!_screenActive) return;

    // 1) Collect all unread messages from other user
    final allUnreadIds = _getUnreadMessageIds(combined);
    log("🟢 visible unreadIds: $allUnreadIds");

    // 2) Filter out ones we already sent to server
    final idsToSend = allUnreadIds
        .where((id) => id.trim().isNotEmpty && !_alreadyRead.contains(id))
        .toList();

    log("🟢 idsToSend after _alreadyRead filter: $idsToSend");

    if (idsToSend.isEmpty) return;

    // 3) Mark them as read locally
    for (final id in idsToSend) {
      log("🔵 Locally marking message as read: $id");
      _updateMessageStatus(id, 'read');
    }

    // 4) Remember we already sent read for these
    _alreadyRead.addAll(idsToSend);

    // 5) Send to socket (NO filtering here)
    _sendReadReceipts(idsToSend);
  }

  void _updateNotifierFromAll() {
    final total = _allMessages.length;
    final count = _visibleCount.clamp(0, total);
    final startIndex = total - count;

    final visibleSlice = (count == 0)
        ? <Map<String, dynamic>>[]
        : _allMessages.sublist(startIndex, total);

    _messagesNotifier.value =
    List<Map<String, dynamic>>.unmodifiable(visibleSlice);
  }

  void _handleIncomingRawMessage(Map<String, dynamic> raw, {String? event}) {
    final rawConvoId =
    (raw['conversation_id'] ?? raw['conversationId'] ?? raw['convoId'])
        ?.toString();

    if (rawConvoId != null &&
        rawConvoId.isNotEmpty &&
        rawConvoId != widget.convoId) {
      log('🚫 Ignoring message for convo=$rawConvoId (this screen=${widget.convoId})');
      return;
    }

    final normalized = normalizeMessage(raw);
    final msgId = (normalized['message_id'] ?? '').toString();
    final senderId = (normalized['senderId'] ?? '').toString();

    // ignore my own echo (for receive_message/forward_message socket event)
    if (senderId == currentUserId) {
      if (event == 'forward_message' && msgId.isNotEmpty) {
        _replaceLocalForwardIdWithRealId(msgId, normalized);
      }
      log('Echo of my own message ignored: $msgId');
      return;
    }

    if (msgId.isNotEmpty &&
        !msgId.startsWith('temp_') &&
        !msgId.startsWith('forward_') &&
        _seenMessageIds.contains(msgId)) {
      log('Duplicate incoming message blocked: $msgId');
      return;
    }

    final alreadyInList = [dbMessages, messages, socketMessages].any(
          (list) => list.any(
            (m) =>
        (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString() ==
            msgId,
      ),
    );

    if (alreadyInList) {
      log('Message already exists in local lists: $msgId');
      return;
    }

    // enrich with media info
    normalized['imageUrl'] = raw['originalUrl'] ?? raw['thumbnailUrl'];
    normalized['fileUrl'] = raw['originalUrl'] ?? raw['fileUrl'];
    normalized['fileName'] = raw['fileName'];
    normalized['fileType'] = raw['mimeType'] ?? raw['fileType'];
    normalized['isForwarded'] = raw['isForwarded'] == true;
    normalized['roomId'] = raw['roomId']?.toString();

    socketMessages.add(normalized);

    if (msgId.isNotEmpty &&
        !msgId.startsWith('temp_') &&
        !msgId.startsWith('forward_')) {
      _seenMessageIds.add(msgId);
    }

    if (!mounted) return;

    _rebuildFromStore(resetVisibleIfEmpty: true);
    _scrollToBottom();

    if (msgId.isNotEmpty) {
      _sendReadReceipts([msgId]);
    }

    log('New incoming message added: $msgId from $senderId');
  }

  Future<void> _initializeSocket() async {
    final token = await UserPreferences.getAccessToken();
    if (token == null) {
      log("Access token is null. Socket connection not initialized.");
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await UserPreferences.getUserId() ?? '';
    if (userId.isEmpty || (widget.datumId?.isEmpty ?? true)) {
      debugPrint('⚠️ _loadCurrentUserId: missing userId or datumId');
      return;
    }

    currentUserId = userId;
    _messageHandler =
        MessageHandler(currentUserId: currentUserId, convoId: widget.convoId);

    await socketService.connectPrivateRoom(
        currentUserId, widget.datumId!, onMessageReceived, false);

    _setupMessageListener();
    _setupReactionListener();

    if (mounted) setState(() {});
  }

  bool _hasReplyForMessage(Map<String, dynamic> message) {
    if (message == null) return false;

    if (message['_localHasReply'] == true) return true;

    final replyRaw = message['reply'];
    Map<String, dynamic>? reply;
    if (replyRaw is Map) reply = Map<String, dynamic>.from(replyRaw);
    else if (replyRaw is String) {
      try {
        final decoded = jsonDecode(replyRaw);
        if (decoded is Map) reply = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    if (reply != null && reply.isNotEmpty) {
      final id = (reply['id'] ??
          reply['message_id'] ??
          reply['messageId'] ??
          reply['reply_message_id'] ??
          reply['_id'])
          ?.toString();

      final replyContent = (reply['replyContent'] ?? reply['content'] ?? reply['message'] ?? '').toString();

      final hasMedia = (reply['originalUrl'] ??
          reply['fileUrl'] ??
          reply['imageUrl'] ??
          reply['replyUrl'] ??
          reply['reply_url'] ??
          reply['thumbnailUrl'] ??
          reply['thumbnail_url'])
          ?.toString()
          .isNotEmpty == true;

      if ((id != null && id.isNotEmpty) || replyContent.isNotEmpty || hasMedia) {
        return true;
      }
    }

    final topReplyId = (message['reply_message_id'] ??
        message['replyMessageId'] ??
        message['reply_to'] ??
        message['replyId'] ??
        message['repliedMessageId'])
        ?.toString();
    if (topReplyId != null && topReplyId.isNotEmpty) return true;

    return false;
  }

  Map<String, dynamic> _mergeReplyInfoIfMissing(
      Map<String, dynamic> fresh,
      Map<String, dynamic> existing,
      )
  {
    final merged = Map<String, dynamic>.from(fresh);

    final hadReplyBefore = _hasReplyForMessage(existing);
    final hasReplyNow = _hasReplyForMessage(fresh);

    if (hadReplyBefore && !hasReplyNow) {
      if (existing['isReplyMessage'] == true) {
        merged['isReplyMessage'] = true;
      }

      if (existing['reply_message_id'] != null) {
        merged['reply_message_id'] ??= existing['reply_message_id'];
      }

      if (existing['reply'] is Map) {
        merged['reply'] ??= Map<String, dynamic>.from(existing['reply']);
      }
    }

    final oldStatus = (existing['messageStatus'] ?? '').toString();
    final newStatus = (fresh['messageStatus'] ?? '').toString();

    if (oldStatus == 'read' && newStatus != 'read') {
      merged['messageStatus'] = 'read';
    }

    return merged;
  }
  /// Collect reactions for a message id from all local lists and merge them
  List<Map<String, dynamic>> _collectMergedReactionsForMessage(String messageId) {
    final Map<String, Map<String, dynamic>> byUser = {};

    List<List<Map<String, dynamic>>> sources = [dbMessages, messages, socketMessages];

    for (final list in sources) {
      for (final msg in list) {
        final mid = (msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? '').toString();
        if (mid != messageId) continue;

        final raw = msg['reactions'];
        if (raw is! List) continue;

        for (final r in raw) {
          if (r is! Map) continue;
          final emoji = (r['emoji'] ?? '').toString();
          if (emoji.isEmpty) continue;

          String? userId = r['userId']?.toString();
          final user = r['user'];
          if ((userId == null || userId.isEmpty) && user is Map) {
            userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
          }
          if (userId == null || userId.isEmpty) continue;

          // Keep latest per user — later sources overwrite earlier ones
          byUser[userId] = {
            'emoji': emoji,
            'userId': userId,
            'user': user is Map ? Map<String, dynamic>.from(user) : null,
            'reacted_at': (r['reacted_at'] ?? r['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
          };
        }
      }
    }

    // Return list of reactions
    return byUser.values.toList();
  }

  void _setupMessageListener() {
    if (currentUserId.isEmpty || widget.datumId == null) return;

    _messagerBloc.add(
        ListenToMessages(senderId: currentUserId, receiverId: widget.datumId!));
    _statusSubscription ??=
        socketService.statusUpdateStream.listen((statusUpdate) {
          if (!mounted) return;

          final dynamic rawStatus = statusUpdate['messageStatus'] ?? statusUpdate['status'];
          final status = (rawStatus ?? '').toString().trim();
          if (status.isEmpty) return;

          final ids = statusUpdate['messageIds'] ?? statusUpdate['singleMessageId'] ?? statusUpdate['messageId'];

          debugPrint('📥 Status update received: $statusUpdate');

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
            // find local message
            final local = _getCombinedMessages().firstWhere(
                  (m) {
                    final mid = _normalizeMessageIdForApi((m['message_id'] ?? m['messageId'] ?? '').toString());
                    final incomingIdNormalized = _normalizeMessageIdForApi(mid);
                    return mid == incomingIdNormalized;
              },
              orElse: () => {},
            );

            final senderId = (local != null && local.isNotEmpty)
                ? (local['senderId'] ?? local['sender']?['_id'] ?? local['sender'])?.toString()
                : null;

            // If this status is about a message we sent, avoid treating it as a 'read' coming from remote.
            if (senderId != null && senderId == currentUserId && status == 'read') {
              log("⚠️ Ignoring server 'read' status for my own message id=$id");
              continue;
            }

            // apply update normally
            _updateMessageStatus(id, status);
          }
        });
  }

  void _setupReactionListener() {
    _reactionSubscription = socketService.reactionStream.listen((reaction) {
      _updateMessageWithReaction(reaction);
    });
  }

  // ------------------ Message Handler helpers ------------------
  Map<String, dynamic> normalizeMessage(dynamic rawMsg) {

    if (rawMsg == null) return {};

    final m = <String, dynamic>{};

    // ========== BASIC (canonical ID) ==========
    String? canonicalId;

    for (final k in ['message_id', 'messageId', 'id', '_id']) {
      final v = rawMsg[k];
      if (v != null && v.toString().isNotEmpty) {
        canonicalId = v.toString();
        break;
      }
    }

    canonicalId ??= rawMsg['message_id']?.toString() ??
        rawMsg['messageId']?.toString() ??
        rawMsg['id']?.toString() ??
        rawMsg['_id']?.toString();

    // Mirror same id to all id-like keys
    m['message_id'] = canonicalId;
    m['id'] = canonicalId;
    m['messageId'] = canonicalId;
    m['_id'] = canonicalId;

    m['content'] = (rawMsg['content'] ?? rawMsg['message'] ?? '').toString();
    m['time'] = rawMsg['time'] ?? rawMsg['createdAt'];

    m['messageStatus'] = (rawMsg['messageStatus'] ??
        rawMsg['status'] ??
        rawMsg['deliveryStatus'] ??
        'sent')
        .toString();

    if ((m['messageStatus'] as String).isEmpty) {
      m['messageStatus'] = 'sent';
    }

    // ========== SENDER ==========
    dynamic senderRaw = rawMsg['sender'];
    String? senderId = rawMsg['senderId']?.toString();

    if (senderRaw is Map) {
      senderId ??=
          (senderRaw['_id'] ?? senderRaw['id'] ?? senderRaw['userId'])
              ?.toString();
    } else if (senderRaw != null && senderId == null) {
      senderId = senderRaw.toString();
      senderRaw = {'_id': senderId};
    } else if (senderRaw == null && senderId != null) {
      senderRaw = {'_id': senderId};
    }

    m['sender'] = senderRaw;
    m['senderId'] = senderId;

    // ========== RECEIVER ==========
    dynamic receiverRaw = rawMsg['receiver'];
    String? receiverId = rawMsg['receiverId']?.toString();

    if (receiverRaw is Map) {
      receiverId ??=
          (receiverRaw['_id'] ?? receiverRaw['id'] ?? receiverRaw['userId'])
              ?.toString();
    } else if (receiverRaw != null && receiverId == null) {
      receiverId = receiverRaw.toString();
      receiverRaw = {'_id': receiverId};
    } else if (receiverRaw == null && receiverId != null) {
      receiverRaw = {'_id': receiverId};
    }

    m['receiver'] = receiverRaw;
    m['receiverId'] = receiverId;

    // ========== REPLY ==========
    // ========== REPLY ==========
    bool isReply = rawMsg['isReplyMessage'] == true;
    Map<String, dynamic>? replyMap;

// accept reply as JSON-string or Map or replyTo map
    if (rawMsg['reply'] is String) {
      try {
        final decoded = jsonDecode(rawMsg['reply']);
        if (decoded is Map) replyMap = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    } else if (rawMsg['reply'] is Map) {
      replyMap = Map<String, dynamic>.from(rawMsg['reply']);
    } else if (rawMsg['replyTo'] is Map) {
      replyMap = Map<String, dynamic>.from(rawMsg['replyTo']);
    }

// collect potential reply id candidates from many places
    String? replyId = (rawMsg['reply_message_id'] ??
        rawMsg['replyMessageId'] ??
        rawMsg['reply_to'] ??
        rawMsg['replyId'] ??
        rawMsg['repliedMessageId'] ??
        rawMsg['parent_message_id'] ??
        rawMsg['parentMessageId'])?.toString();

// if not found, look inside replyMap
    if ((replyId == null || replyId.isEmpty) && replyMap != null) {
      replyId = (replyMap['id'] ??
          replyMap['_id'] ??
          replyMap['message_id'] ??
          replyMap['messageId'] ??
          replyMap['reply_message_id'])?.toString();
    }

// if replyTo is just an id value (string/num)
    final replyToRaw = rawMsg['replyTo'];
    if ((replyId == null || replyId.isEmpty) && replyToRaw != null) {
      if (replyToRaw is String) replyId = replyToRaw;
      if (replyToRaw is num) replyId = replyToRaw.toString();
    }

// quoted reply text (variants)
    final replyContent = (rawMsg['replyContent'] ??
        replyMap?['replyContent'] ??
        replyMap?['content'] ??
        replyMap?['message'] ??
        '')?.toString();

// decide if we should treat as a reply
    final bool hasAnyReplyData =
        (replyId != null && replyId.isNotEmpty) || replyContent!.isNotEmpty || isReply;

    if (hasAnyReplyData) {
      isReply = true;
      replyMap ??= <String, dynamic>{};

      // mirror id fields
      if (replyId != null && replyId.isNotEmpty) {
        replyMap['id'] = replyId;
        replyMap['_id'] = replyId;
        replyMap['message_id'] = replyId;
        replyMap['messageId'] = replyId;
        replyMap['reply_message_id'] = replyId;
        m['reply_message_id'] = replyId;
      }

      // quoted text
      replyMap['replyContent'] = replyContent;
      replyMap['content'] ??= replyContent;

      // --- Copy media keys from raw reply map (server-specific keys) ---
      if (rawMsg['reply'] is Map) {
        final rawReply = rawMsg['reply'] as Map;
        // canonical copies
        if (rawReply['originalUrl'] != null) replyMap['originalUrl'] = rawReply['originalUrl'];
        if (rawReply['thumbnailUrl'] != null) replyMap['thumbnailUrl'] = rawReply['thumbnailUrl'];
        if (rawReply['imageUrl'] != null) replyMap['imageUrl'] = rawReply['imageUrl'];
        if (rawReply['fileUrl'] != null) replyMap['fileUrl'] = rawReply['fileUrl'];
        if (rawReply['fileName'] != null) replyMap['fileName'] = rawReply['fileName'];
        if (rawReply['fileType'] != null) replyMap['fileType'] = rawReply['fileType'];

        // server-specific variants
        if (rawReply['replyUrl'] != null) {
          replyMap['originalUrl'] ??= rawReply['replyUrl'];
          replyMap['fileUrl'] ??= rawReply['replyUrl'];
          replyMap['imageUrl'] ??= rawReply['replyUrl'];
        }
        if (rawReply['reply_url'] != null) {
          replyMap['originalUrl'] ??= rawReply['reply_url'];
          replyMap['fileUrl'] ??= rawReply['reply_url'];
          replyMap['imageUrl'] ??= rawReply['reply_url'];
        }
        if (rawReply['replyImageUrl'] != null) replyMap['imageUrl'] ??= rawReply['replyImageUrl'];
        if (rawReply['reply_image_url'] != null) replyMap['imageUrl'] ??= rawReply['reply_image_url'];
        if (rawReply['reply_image'] != null) replyMap['imageUrl'] ??= rawReply['reply_image'];

        // ContentType mapping (server can send ContentType: 'file'/'image'/'video')
        if (rawReply['ContentType'] != null && (replyMap['fileType'] == null || replyMap['fileType'].toString().isEmpty)) {
          final ct = rawReply['ContentType'].toString();
          if (ct.contains('/')) {
            replyMap['fileType'] = ct.toLowerCase();
          } else {
            final lc = ct.toLowerCase();
            if (lc == 'image' || lc == 'file') {
              replyMap['fileType'] = 'image/jpeg';
            } else if (lc.contains('video')) {
              replyMap['fileType'] = 'video/mp4';
            } else {
              replyMap['fileType'] = lc;
            }
          }
        }
      }

      // --- Copy media keys from top-level raw message if reply map was missing them ---
      // typical server variants we have seen:
      final candidates = <String>[
        'replyImageUrl', 'reply_image_url', 'reply_original_url', 'replyFileUrl',
        'reply_file_url', 'replyThumbnail', 'replyThumbnailUrl', 'reply_thumbnail_url',
        'replyUrl', 'reply_url', 'thumbnailUrl', 'originalUrl', 'imageUrl', 'fileUrl', 'file_with_text'
      ];

      for (final c in candidates) {
        if ((replyMap['imageUrl'] == null || replyMap['imageUrl'].toString().isEmpty) &&
            rawMsg[c] != null &&
            rawMsg[c].toString().isNotEmpty) {
          replyMap['imageUrl'] = rawMsg[c].toString();
        }
      }

      // top-level fallbacks
      replyMap['imageUrl'] ??= rawMsg['replyImageUrl'] ??
          rawMsg['reply_image_url'] ??
          rawMsg['thumbnailUrl'] ??
          rawMsg['imageUrl'];

      replyMap['fileUrl'] ??= rawMsg['replyFileUrl'] ??
          rawMsg['reply_file_url'] ??
          rawMsg['fileUrl'] ??
          rawMsg['originalUrl'] ??
          rawMsg['localFilePath'];

      replyMap['originalUrl'] ??= rawMsg['originalUrl'] ?? rawMsg['fileUrl'] ?? replyMap['fileUrl'];

      // normalize fileType from various places
      replyMap['fileType'] ??= rawMsg['replyFileType'] ??
          rawMsg['reply_file_type'] ??
          rawMsg['fileType'] ??
          rawMsg['mimeType'] ??
          rawMsg['mimetype'];

      // if still missing, try ContentType top-level (server might send 'file'/'image'/'video')
      if ((replyMap['fileType'] == null || replyMap['fileType'].toString().isEmpty) && rawMsg['ContentType'] != null) {
        final ct = rawMsg['ContentType'].toString();
        if (ct.contains('/')) {
          replyMap['fileType'] = ct.toLowerCase();
        } else {
          final lc = ct.toLowerCase();
          if (lc == 'image' || lc == 'file') {
            replyMap['fileType'] = 'image/jpeg';
          } else if (lc.contains('video')) {
            replyMap['fileType'] = 'video/mp4';
          } else {
            replyMap['fileType'] = lc;
          }
        }
      }

      // final normalization: lowercase fileType string
      if (replyMap['fileType'] is String) replyMap['fileType'] = (replyMap['fileType'] as String).toLowerCase();

      // ensure canonical keys exist for UI code (always present, even if empty)
      replyMap['originalUrl'] ??= '';
      replyMap['imageUrl'] ??= '';
      replyMap['fileUrl'] ??= '';
      replyMap['fileType'] ??= '';
      replyMap['fileName'] ??= replyMap['fileName'] ?? rawMsg['fileName'] ?? '';

      m['reply'] = replyMap;
      m['isReplyMessage'] = true;
    }

    // ========== REACTIONS ==========
    if (rawMsg['reactions'] is List) {
      m['reactions'] = _extractReactions(rawMsg['reactions']);
    }

    // ========== FORWARDED ==========
    final bool isForwarded = rawMsg['isForwarded'] == true ||
        rawMsg['forwarded'] == true ||
        rawMsg['is_forwarded'] == true ||
        rawMsg['isForwardMessage'] == true;

    if (isForwarded) {
      m['isForwarded'] = true;
    }

    final original = rawMsg['original_message_id'] ??
        rawMsg['originalMessageId'] ??
        rawMsg['parent_message_id'] ??
        rawMsg['parentMessageId'];

    if (original != null && original.toString().isNotEmpty) {
      m['original_message_id'] = original.toString();
    }

    // ========== MEDIA ==========
    m['imageUrl'] = rawMsg['imageUrl'] ??
        rawMsg['originalUrl'] ??
        rawMsg['thumbnailUrl'] ??
        rawMsg['localImagePath'];

    m['fileUrl'] =
        rawMsg['fileUrl'] ?? rawMsg['originalUrl'] ?? rawMsg['localFilePath'];

    m['fileName'] = rawMsg['fileName'];
    m['fileType'] = rawMsg['mimeType'] ?? rawMsg['fileType'];

    return m;
  }

  DateTime _parseTime(dynamic time) {
    _ensureMessageHandler();
    return _messageHandler!.parseTime(time);
  }

  String _generateMessageKey(Map<String, dynamic> msg) {
    _ensureMessageHandler();
    return _messageHandler!.generateMessageKey(msg);
  }

  bool isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year &&
        d1.month == d2.month &&
        d1.day == d2.day;
  }


  void _ensureMessageHandler() {
    _messageHandler ??=
        MessageHandler(currentUserId: currentUserId, convoId: widget.convoId);
  }

  // ------------------ Debounced disk save ------------------
  void _scheduleSaveMessages() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveDebounceDuration, () {
      if (widget.convoId.isEmpty) return;
      final combined = [...dbMessages, ...messages, ...socketMessages];
      LocalChatStorage.saveMessages(widget.convoId, combined);
    });
  }

  void _updateNotifier() {
    final full = _getCombinedMessages();

    _allMessages
      ..clear()
      ..addAll(full);

    if (_visibleCount == 0) {
      final total = _allMessages.length;
      _visibleCount =
      total >= _initialVisible ? _initialVisible : total; // last 10 or less
    }

    _updateNotifierFromAll();
  }

  // ------------------ SEND MESSAGE (with reply support) ------------------
  /// This is the **old working reply logic**, adapted to your new storage.
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.datumId == null) {
      return;
    }

    final reply = _replyMessage;
    final text = _messageController.text.trim();
    final visibleMessages = _messagesNotifier.value;
    print("visibleMessages ${visibleMessages}");
    final unreadIds = _getUnreadMessageIds(visibleMessages);
    print("unreadIds $unreadIds");// uses _isUnreadMessage
    if (unreadIds.isNotEmpty) {
      _sendReadReceipts(unreadIds);
    }
    final String? replyMessageId = reply == null
        ? null
        : (reply['message_id'] ?? reply['messageId'] ?? reply['id'])
        ?.toString();

    final replyPayload = reply == null
        ? null
        : <String, dynamic>{
      'id': replyMessageId,
      'message_id': replyMessageId,
      'reply_message_id': replyMessageId,
      'replyContent': (reply['content'] ?? reply['message'] ?? '').toString(),
      'content': (reply['content'] ?? reply['message'] ?? '').toString(),

      // Normalized media fields (try many keys; prefer originalUrl if available)
      'originalUrl': reply['originalUrl'] ??
          reply['fileUrl'] ??
          reply['imageUrl'] ??
          reply['thumbnailUrl'] ??
          reply['localImagePath'] ??
          '',

      'imageUrl': reply['imageUrl'] ??
          reply['thumbnailUrl'] ??
          reply['localImagePath'] ??
          '',

      'fileUrl': reply['fileUrl'] ?? reply['originalUrl'] ?? '',

      'fileName': reply['fileName'] ?? '',

      'fileType': (reply['fileType'] ?? reply['mimeType'] ?? reply['mimetype'] ?? '').toString(),
    };



    log('SENDING replyPayload: $replyPayload');

    final localId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // ✅ consider both network AND socket connection
    final bool canSendNow = _isOnline && socketService.isConnected;
print("hiiilocalId ${localId}");
    final localMessage = {
      'message_id': localId,
      'content': text,
      'sender': {'_id': currentUserId},
      'senderId': currentUserId,
      'receiver': {'_id': widget.datumId},
      'receiverId': widget.datumId,
      'time': DateTime.now().toIso8601String(),
      'isReplyMessage': replyPayload != null,
      if (replyPayload != null) 'reply': replyPayload,
      if (replyPayload != null) 'reply_message_id': replyMessageId,
      // 👇 IMPORTANT
      'messageStatus': canSendNow ? 'sending' : 'pending_offline',
    };
    localMessage['message_id'] = localId;
    localMessage['time'] = DateTime.now().toIso8601String();
    if (replyPayload != null) {
      localMessage['_localHasReply'] = true;
      localMessage['_localReply'] = Map<String, dynamic>.from(replyPayload);
    }

    setState(() {
      socketMessages.add(localMessage);
      if (!_seenMessageIds.contains(localId)) {
        _seenMessageIds.add(localId);
      }
      _rebuildFromStore(resetVisibleIfEmpty: true);
     // _scrollToBottom();
    });
    _refreshMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    _saveAllMessages();
    final unreadFromOtherUser = _collectUnreadIds();
    _sendReadReceipts(unreadFromOtherUser);
    _messageController.clear();
    _clearDraft();
    _replyMessage = null;
    _imageFile = null;
    _replyPreview = null;

    // -------- OFFLINE / SOCKET DISCONNECTED --------
    if (!canSendNow) {
      _offlineQueue.add({
        'text': text,
        'reply': reply,
        'replyMessageId': replyMessageId,
        'localId': localId,
      });
      return;
    }

    // -------- ONLINE + SOCKET CONNECTED → send --------
    try {
      final completer = Completer<Message>();
      final subscription = _messagerBloc.stream.listen((state) {
        if (state is MessageSentSuccessfully) {
          completer.complete(state.sentMessage);
        }
      });

      _messagerBloc.add(
        SendMessageEvent(
          convoId: widget.convoId,
          message: text,
          senderId: currentUserId,
          receiverId: widget.datumId!,
          replyTo: reply,
          replyMessageId: replyMessageId,

        ),
      );

      final sent = await completer.future;
      await subscription.cancel();

      _replaceTempMessageWithReal(
        tempId: localId,
        realId: sent.messageId ?? '',
        status: sent.messageStatus ?? 'sent',
      );

    } catch (e, st) {
      log('❌ send message error: $e\n$st');
      _updateMessageStatus(localId, 'failed');
    }
  }
  void _refreshMessagesWithReplies() {
    final combined = _getCombinedMessages();

    for (final msg in combined) {
      if (msg['isReplyMessage'] == true &&
          msg['repliedMessage'] == null) {
        final resolved = resolveRepliedMessage(
          message: msg,
          allMessages: combined,
        );

        if (resolved != null) {
          msg['repliedMessage'] = resolved;
        }
      }
    }

    // 🔥 THIS LINE IS THE MOST IMPORTANT LINE
    _messagesNotifier.value = List<Map<String, dynamic>>.from(combined);
  }

  void _replaceTempMessageWithReal({
    required String tempId,
    required String realId,
    required String status,
  })
  {
    bool changed = false;

    void updateList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final mid = (m['message_id'] ?? m['messageId'] ?? '').toString();
        if (mid == tempId) {
          final copy = Map<String, dynamic>.from(m);

          // Preserve reply info in a durable local field so merges won't lose it.
          if (copy['reply'] != null || copy['reply_message_id'] != null) {
            copy['_localHasReply'] = true;
            try {
              copy['_localReply'] = Map<String, dynamic>.from(copy['reply'] ?? {});
            } catch (_) {
              copy['_localReply'] = copy['reply'];
            }
          }

          // Assign server id + status
          copy['message_id'] = realId;
          copy['messageStatus'] = status;

          list[i] = copy;
          changed = true;
          break;
        }
      }
    }

    updateList(socketMessages);
    updateList(messages);
    updateList(dbMessages);

    if (changed) {
      if (!_seenMessageIds.contains(realId)) _seenMessageIds.add(realId);
      _updateNotifier();
      _scheduleSaveMessages();
    }
  }
  void _refreshMessages() {
    _messagesNotifier.value = _getCombinedMessages();
  }

  String _anyId(Map<String, dynamic> m) {
    final candidates = [
      m['message_id'],
      m['messageId'],
      m['id'],
      m['_id'],
      m['reply_message_id'],
    ];

    for (final c in candidates) {
      if (c != null && c.toString().isNotEmpty) {
        return c.toString();
      }
    }
    return '';
  }

  void _highlightMessage(String messageId) {
    setState(() => _highlightedMessageId = messageId);

    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _highlightedMessageId = null);
    });
  }


  Future<bool> _scrollToMessageById(
      String messageId, {
        bool fetchIfMissing = false,
      }) async {
    final targetId = messageId.trim();
    if (targetId.isEmpty) return false;

    final ctx = _messageContexts[targetId];

    if (ctx != null && ctx.mounted) {
      // 🧠 ensure after frame build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ctx.mounted) return;

        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.5, // center
        );

        _highlightMessage(targetId);
      });

      return true;
    }

    // 🔁 Try loading older messages if not found
    if (fetchIfMissing) {
      await _loadMoreMessages();

      // wait for rebuild
      await Future.delayed(const Duration(milliseconds: 150));

      return _scrollToMessageById(
        messageId,
        fetchIfMissing: false,
      );
    }

    return false;
  }





  // ------------------ Send image (optimistic) ------------------
  void _sendMessageImage() async {
    await _loadSessionImagePath();
    await _loadSessionFilePath();

    final nowIso = DateTime.now().toIso8601String();
    final String? mimeType =
    _fileUrl != null ? lookupMimeType(_fileUrl!.path) : null;

    final optimistic = {
      'message_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'content': _messageController.text.trim(),
      'sender': {'_id': currentUserId},
      'receiver': {'_id': widget.datumId},
      'messageStatus': 'pending',
      'time': nowIso,
      'fileName': _fileUrl?.path.split('/').last,
      'fileType': mimeType,
      'imageUrl': _imageFile?.path,
      'fileUrl': _fileUrl?.path,
      // --- NEW: if replying include reply metadata ---
      if (_replyMessage != null) 'reply': {
        'id': _replyMessage!['message_id'] ?? _replyMessage!['messageId'] ?? _replyMessage!['id'],
        'reply_message_id': _replyMessage!['message_id'] ?? _replyMessage!['messageId'] ?? _replyMessage!['id'],
        'replyContent': (_replyMessage!['content'] ?? '')?.toString() ?? '',
        if (_replyMessage!['originalUrl'] != null) 'originalUrl': _replyMessage!['originalUrl'],
        if (_replyMessage!['imageUrl'] != null) 'imageUrl': _replyMessage!['imageUrl'],
        if (_replyMessage!['fileUrl'] != null) 'fileUrl': _replyMessage!['fileUrl'],
        if (_replyMessage!['fileName'] != null) 'fileName': _replyMessage!['fileName'],
        if (_replyMessage!['fileType'] != null) 'fileType': _replyMessage!['fileType'],
      },
    };

    socketMessages.add(optimistic);
    final idStr = (optimistic['message_id'] ?? '').toString();
    if (idStr.isNotEmpty) _seenMessageIds.add(idStr);
    _updateNotifier();
    _scheduleSaveMessages();
    _scrollToBottom();

    if (_fileUrl != null) {
      context.read<MessagerBloc>().add(
        UploadFileEvent(
          File(_fileUrl!.path),
          widget.convoId,
          currentUserId,
          widget.datumId ?? "",
          "",
        ),
      );
    }

    _messageController.clear();
    _imageFile = null;
    _fileUrl = null;
    await _clearSessionPaths();
  }

  Future<void> _openCamera() async {
    try {
      final XFile? file =
      await ImagePicker().pickImage(source: ImageSource.camera);
      if (file != null) {
        final localFile = File(file.path);
        if (!localFile.existsSync()) {
          Messenger.alert(msg: "Selected image is missing.");
          return;
        }
        final mimeType = lookupMimeType(file.path);
        final isImage = mimeType != null && mimeType.startsWith('image/');
        final prefs = await SharedPreferences.getInstance();
        if (isImage) {
          await prefs.setString('chat_image_path', localFile.path);
        }

        ShowAltDialog.showOptionsDialog(context,
            conversationId: widget.convoId,
            senderId: currentUserId,
            receiverId: widget.datumId!,
            isGroupChat: false,
            onOptionSelected: (List<Map<String, dynamic>> localMessages) {
              if (localMessages.isEmpty) return;

              setState(() {
                // Add all local messages (grouped or single) to the socket list
                socketMessages.addAll(localMessages);

                // Mark them as seen so we don't re-add them if they come back from server
                for (var msg in localMessages) {
                  final id = (msg['message_id'] ?? '').toString();
                  if (id.isNotEmpty) _seenMessageIds.add(id);
                }
              });

              // Refresh UI immediately
              _updateNotifier();
              _scheduleSaveMessages();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            });

        final message = {
          'message_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'content': '',
          'sender': {'_id': currentUserId},
          'receiver': {'_id': widget.receiverId},
          'messageStatus': 'pending',
          'time': DateTime.now().toIso8601String(),
          'localImagePath': file.path,
          'fileName': file.name,
          'fileType': mimeType,
          'imageUrl': file.path,
          'fileUrl': null,
        };

        socketMessages.add(message);
        _seenMessageIds.add((message['message_id'] ?? "").toString());
        _updateNotifier();

        context.read<MessagerBloc>().add(
          UploadFileEvent(
            localFile,
            widget.convoId,
            currentUserId,
            widget.datumId ?? "",
            "",
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Messenger.alert(msg: "Could not open camera.");
    }
  }
  // ------------------ Incoming messages ------------------
  void onMessageReceived(Map<String, dynamic> data) {
    debugPrint('RECEIVED message (id=${data['message_id'] ?? data['id']}): reply=${data['reply']}');
    debugPrint('INCOMING raw message: ${data}'); // rawMsg is what you received from server/socket
    debugPrint('INCOMING raw reply field: ${data['reply']}');
    debugPrint('INCOMING reply_message_id: ${data['reply_message_id'] ?? data['replyMessageId'] ?? data['reply_to']}');

    final event = data['event'];
    log("statusssssssssssss ${data}");

    if (event == 'update_message_read') {
      final messageId =
          data['data']?['messageId'] ?? data['data']?['message_id'];
      if (messageId != null) {
        print("statusssssssssssss ${messageId.toString()}");
        _updateMessageStatus(messageId.toString(), 'read');
      }
      return;
    }

    if (event == 'updated_reaction') {
      _handleReactionUpdate(data['data']);
      return;
    }

    if (event == 'receive_message' || event == 'forward_message') {
      final raw = data['data'];
      if (raw == null) return;
      _handleIncomingRawMessage(raw, event: event);
      return;
    }
// inside your NewMessageReceivedState or onMessageReceived handler:
    debugPrint('INCOMING raw message: ${data}'); // rawMsg is what you received from server/socket
    debugPrint('INCOMING raw reply field: ${data['reply']}');
    debugPrint('INCOMING reply_message_id: ${data['reply_message_id'] ?? data['replyMessageId'] ?? data['reply_to']}');

    log("⚠️ Unknown socket event: $event");
  }
  void _applyReactionUpdateFromSocket({
    required String messageId,
    required String emoji,
    required String userId,
    String? firstName,
    String? lastName,
    required bool isRemoval,
  }) {
    if (!mounted) return;
    if (userId == currentUserId) return; // you already optimistically updated locally

    String normalizeId(dynamic id) => id?.toString().trim() ?? '';

    bool updated = false;

    void updateList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final msg = list[i];
        final msgId = normalizeId(msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? '');
        if (msgId != messageId) continue;

        final existing = _extractReactions(msg['reactions']);
        // Build incoming single reaction map
        final incoming = <Map<String, dynamic>>[
          {
            'emoji': emoji,
            'userId': userId,
            'user': {'_id': userId, 'first_name': firstName ?? '', 'last_name': lastName ?? ''},
            'reacted_at': DateTime.now().toIso8601String(),
          }
        ];

        List<Map<String, dynamic>> merged;
        if (isRemoval) {
          // remove any reaction from this user
          merged = existing.where((r) => (r['userId']?.toString() ?? r['user']?['_id']?.toString() ?? '') != userId).toList();
        } else {
          // union by userId, prefer incoming for this user
          merged = _mergeReactions(local: existing, incoming: incoming);
        }

        msg['reactions'] = merged;
        updated = true;
        break;
      }
    }

    updateList(dbMessages);
    updateList(messages);
    updateList(socketMessages);

    if (updated) {
      _updateNotifier();
      _scheduleSaveMessages();
    } else {
      _fetchMessages(); // message not found locally — refresh
    }
  }


  // ------------------ Reaction handling ------------------
  void _handleReactionUpdate(dynamic reactionData) {
    try {
      if (reactionData == null) return;

      // Backend may send:
      //  - a single Map
      //  - a List<Map>
      //  - a wrapper with `reactions` or `reaction`
      List<Map<String, dynamic>> rawList = [];

      if (reactionData is List) {
        rawList = reactionData.whereType<Map<String, dynamic>>().toList();
      } else if (reactionData is Map<String, dynamic>) {
        if (reactionData['reactions'] is List) {
          rawList = (reactionData['reactions'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        } else if (reactionData['reaction'] is Map) {
          rawList = [
            Map<String, dynamic>.from(
                reactionData['reaction'] as Map),
          ];
        } else {
          rawList = [reactionData];
        }
      }

      for (final r in rawList) {
        final emoji = r['emoji']?.toString();
        final msgId =
            r['messageId']?.toString() ?? r['message_id']?.toString();

        if (emoji == null || emoji.isEmpty || msgId == null || msgId.isEmpty) {
          continue;
        }

        final userRaw = r['user'];

        String? userId;
        String? firstName;
        String? lastName;

        if (userRaw is Map) {
          userId = (userRaw['_id'] ?? userRaw['id'] ?? userRaw['userId'])
              ?.toString();
          firstName = userRaw['first_name']?.toString();
          lastName = userRaw['last_name']?.toString();
        } else if (userRaw is String) {
          userId = userRaw;
        }

        if (userId == null || userId.isEmpty) continue;

        final isRemoval =
            r['isRemoval'] == true || r['removed'] == true || r['remove'] == true;

        _applyReactionUpdateFromSocket(
          messageId: msgId,
          emoji: emoji,
          userId: userId,
          firstName: firstName,
          lastName: lastName,
          isRemoval: isRemoval,
        );
      }
    } catch (e, st) {
      debugPrint('❌ Reaction update failed: $e\n$st');
    }
  }

  void _replaceLocalForwardIdWithRealId(
      String realId, Map<String, dynamic> serverMsg)
  {
    final serverOriginalId = (serverMsg['original_message_id'] ??
        serverMsg['originalMessageId'] ??
        serverMsg['parent_message_id'] ??
        serverMsg['parentMessageId'] ??
        '')
        .toString();

    final serverContent = (serverMsg['content'] ?? '').toString();

    bool replaced = false;

    void tryReplaceIn(List<Map<String, dynamic>> list) {
      if (replaced) return;

      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final mid = (m['message_id'] ?? m['messageId'] ?? '').toString();

        final isSynthetic =
            mid.startsWith('temp_') || mid.startsWith('forward_');
        if (!isSynthetic) continue;

        final localOriginalId = (m['original_message_id'] ??
            m['originalMessageId'] ??
            m['parent_message_id'] ??
            m['parentMessageId'] ??
            '')
            .toString();

        final localContent = (m['content'] ?? '').toString();

        final sameOriginal = serverOriginalId.isNotEmpty &&
            localOriginalId.isNotEmpty &&
            serverOriginalId == localOriginalId;

        final sameContent =
            serverContent.isNotEmpty && serverContent == localContent;

        if (sameOriginal || sameContent) {
          final copy = Map<String, dynamic>.from(m);
          copy['message_id'] = realId;
          copy['messageStatus'] = serverMsg['messageStatus'] ?? 'delivered';
          copy['isForwarded'] = true;
          if (serverOriginalId.isNotEmpty) {
            copy['original_message_id'] = serverOriginalId;
          }

          list[i] = copy;
          replaced = true;
          log('✅ Replaced synthetic id $mid → real id $realId');
          break;
        }
      }
    }

    tryReplaceIn(socketMessages);
    tryReplaceIn(messages);
    tryReplaceIn(dbMessages);

    if (replaced) {
      _seenMessageIds.add(realId);
      _updateNotifier();
      _scheduleSaveMessages();
    } else {
      log('ℹ️ _replaceLocalForwardIdWithRealId: no temp_ message matched');
    }
  }

  void _updateMessageWithReaction(MessageReaction reaction) {
    if (!mounted) return;

    // 🔕 Ignore my own reaction echo on this device (sender already updated optimistically)
    if (reaction.user.id == currentUserId) {
      return;
    }

    String normalizeId(dynamic id) => id?.toString().trim() ?? '';

    final targetId = normalizeId(reaction.messageId);
    if (targetId.isEmpty) return;

    bool updated = false;

    void updateReactions(List<Map<String, dynamic>> list) {
      for (var msg in list) {
        final msgId = normalizeId(
          msg['message_id'] ?? msg['messageId'] ?? msg['_id'],
        );

        if (msgId != targetId) continue;

        // Normalize existing reactions
        final reactions = _extractReactions(msg['reactions']);

        // remove old reaction from this user (if any)
        reactions.removeWhere((r) {
          final uid = (r['userId'] ?? r['user']?['_id'])?.toString();
          return uid == reaction.user.id;
        });

        // add new if not removal
        if (!reaction.isRemoval) {
          reactions.add({
            'emoji': reaction.emoji,
            'userId': reaction.user.id,
            'user': {
              '_id': reaction.user.id,
              'first_name': reaction.user.firstName,
              'last_name': reaction.user.lastName,
            },
            'reacted_at': reaction.reactedAt.toIso8601String(),
          });
        }

        msg['reactions'] = reactions;
        updated = true;
        break;
      }
    }

    updateReactions(dbMessages);
    updateReactions(messages);
    updateReactions(socketMessages);

    if (updated) {
      _updateNotifier();
      _scheduleSaveMessages();
    } else {
      // if message not found locally (older / pagination), try refetch
      _fetchMessages();
    }
  }

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

      if (userId == null || userId.isEmpty) continue;

      out.add({
        'emoji': emoji,
        'userId': userId,
        'user': user is Map ? Map<String, dynamic>.from(user) : null,
        'reacted_at': (m['reacted_at'] ?? m['createdAt'] ?? '').toString(),
      });
    }

    return out;
  }

  void _updateMessageStatus(String messageId, String status, {bool localMark = false}) {
    log("🔄 _updateMessageStatus called for $messageId → $status (localMark=$localMark)");

    bool updated = false;

    void updateInList(List<Map<String, dynamic>> list) {
      for (var msg in list) {
        final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
        if (id == messageId) {
          final current = (msg['messageStatus'] ?? '').toString();

          // Once read, never downgrade to less final states
          if (current == 'read' && status != 'read') {
            return;
          }

          if (current != status) {
            msg['messageStatus'] = status;
            updated = true;
          }

          if (status == 'read' && localMark == true) {
            msg['_localMarkedRead'] = true;
          }

          break;
        }
      }
    }

    updateInList(messages);
    updateInList(socketMessages);
    updateInList(dbMessages);

    if (updated) {
      _updateNotifier();
      _scheduleSaveMessages();
    }
  }

  String get roomId =>
      socketService.generateRoomId(currentUserId, widget.datumId ?? '');

  void _sendReadReceipts(List<String> messageIds) {
    log("🟢 _sendReadReceipts called with: $messageIds");

    // helper: try to find message locally by id
    Map<String, dynamic>? _findLocalMessageById(String id) {
      if (id.trim().isEmpty) return null;
      final combined = _getCombinedMessages();
      try {
        return combined.firstWhere((m) {
          final mid = (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';
          return mid == id;
        }, orElse: () => <String, dynamic>{});
      } catch (_) {
        return null;
      }
    }

    // keep unique & non-empty
    final uniqueAll = messageIds
        .where((id) => id.trim().isNotEmpty && !_alreadyRead.contains(id))
        .toSet()
        .toList();

    // Defensive filter: only mark/read/send receipts for messages that are
    // actually from the OTHER user (not messages sent by currentUser).
    final unique = <String>[];
    for (final id in uniqueAll) {
      final msg = _findLocalMessageById(id);
      final senderId = (msg != null && msg.isNotEmpty)
          ? (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender'])?.toString()
          : null;

      // If we have a local message and senderId equals currentUserId then skip it.
      if (senderId != null && senderId == currentUserId) {
        log("⚠️ Skipping local marking as read for my own message id: $id");
        continue;
      }

      // If we don't have the message locally, it's safer to keep sending the
      // receipt to server (server might know it), but avoid marking locally.
      // You can choose to include it in the outgoing socket call or not;
      // here we include it (so server gets receipt) but we avoid local marking.
      unique.add(id);
    }

    log("🟢 unique read IDs after filter: $unique");

    if (unique.isEmpty) {
      log("ℹ️ _sendReadReceipts: nothing to send (empty after filter).");
      return;
    }

    // remember we already sent these
    _alreadyRead.addAll(unique);

    // Locally mark read only for messages we can locate & that are NOT ours
    for (final id in unique) {
      final msg = _findLocalMessageById(id);
      final senderId = (msg != null && msg.isNotEmpty)
          ? (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender'])?.toString()
          : null;

      if (senderId != null && senderId != currentUserId) {
        log("🔵 Locally marking message as read: $id");
        _updateMessageStatus(id, 'read', localMark: true);
      } else {
        log("ℹ️ Not locally marking (not found or message is mine): $id");
      }
    }

    final computedRoomId = socketService.generateRoomId(currentUserId, widget.datumId ?? '');
    socketService.sendReadReceipts(
      messageIds: unique,
      conversationId: widget.convoId,
      roomId: computedRoomId,
    );
  }
  List<String> _collectUnreadIds() {
    final combined = _messagesNotifier.value;

    final ids = combined
        .where(_isUnreadMessage) // your existing function
        .map((m) => (m['message_id'] ?? m['messageId'] ?? m['id']).toString())
        .where((id) => id.isNotEmpty)
        .toList();

    log("📥 _collectUnreadIds -> $ids");
    return ids;
  }

  Future<void> _fetchMessages() async {
    _messagerBloc.add(FetchMessagesEvent(
        convoId: widget.convoId, page: _currentPage, limit: _initialLimit));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // if scrolled near the top, try to load older messages
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 50) {
      final total = _allMessages.length;
      if (_visibleCount < total && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        // increase visible window locally first for snappier UI
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          setState(() {
            _visibleCount = (_visibleCount + _pageStep).clamp(0, total);
            _isLoadingMore = false;
          });

          _updateNotifierFromAll();
        });
      } else {
        // if we already show all from local cache but there is a next page on server, fetch it
        if (!_isLoadingMore && _hasNextPage) {
          _loadMoreMessages();
        }
      }
    }
  }

   _loadMoreMessages() {
    if (!_hasNextPage || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    // increment page BEFORE fetching so bloc receives new page number
    _currentPage++;

    // small delay to avoid calling too rapidly while scrolling
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _fetchMessages();
    });
  }


  List<Map<String, dynamic>> _inferGrouping(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return messages;

    messages.sort((a, b) => _parseTime(a['time']).compareTo(_parseTime(b['time'])));

    for (int i = 0; i < messages.length; i++) {
      final currentMsg = messages[i];

      // already grouped? skip
      if (currentMsg['is_group_message'] == true &&
          currentMsg['group_message_id'] != null) {
        continue;
      }

      // 🔹 detect image
      final hasImage =
          (currentMsg['imageUrl'] != null &&
              currentMsg['imageUrl'].toString().isNotEmpty) ||
              (currentMsg['localImagePath'] != null &&
                  currentMsg['localImagePath'].toString().isNotEmpty);

      // 🔹 detect video
      final String fileType = (currentMsg['fileType'] ??
          currentMsg['mimeType'] ??
          '')
          .toString()
          .toLowerCase();
      final String fileUrl =
      (currentMsg['fileUrl'] ?? currentMsg['originalUrl'] ?? '')
          .toString();

      final bool hasVideo =
          fileType.startsWith('video/') ||
              ['.mp4', '.mov', '.mkv', '.avi', '.webm']
                  .any((ext) => fileUrl.toLowerCase().endsWith(ext));

      final bool isMedia = hasImage || hasVideo;
      if (!isMedia) continue;

      // same as before – find consecutive messages from same sender within 1 min
      List<int> groupIndices = [i];
      final currentSender = currentMsg['sender'] is Map
          ? currentMsg['sender']['_id']
          : currentMsg['sender'];
      final currentTime = _parseTime(currentMsg['time']);

      for (int j = i + 1; j < messages.length; j++) {
        final nextMsg = messages[j];
        final nextSender = nextMsg['sender'] is Map
            ? nextMsg['sender']['_id']
            : nextMsg['sender'];
        final nextTime = _parseTime(nextMsg['time']);

        // detect media for next
        final nextHasImage =
            (nextMsg['imageUrl'] != null &&
                nextMsg['imageUrl'].toString().isNotEmpty) ||
                (nextMsg['localImagePath'] != null &&
                    nextMsg['localImagePath'].toString().isNotEmpty);

        final String nextFileType = (nextMsg['fileType'] ??
            nextMsg['mimeType'] ??
            '')
            .toString()
            .toLowerCase();
        final String nextFileUrl =
        (nextMsg['fileUrl'] ?? nextMsg['originalUrl'] ?? '')
            .toString();
        final bool nextHasVideo =
            nextFileType.startsWith('video/') ||
                ['.mp4', '.mov', '.mkv', '.avi', '.webm']
                    .any((ext) => nextFileUrl.toLowerCase().endsWith(ext));

        final bool nextIsMedia = nextHasImage || nextHasVideo;

        if (nextSender != currentSender ||
            !nextIsMedia ||
            nextTime.difference(currentTime).inMinutes.abs() > 1) {
          break;
        }

        // already grouped by server? treat that as a boundary
        if (nextMsg['is_group_message'] == true &&
            nextMsg['group_message_id'] != null) {
          break;
        }

        groupIndices.add(j);
      }

      if (groupIndices.length > 1) {
        final groupId =
            'generated_group_${currentTime.millisecondsSinceEpoch}_$i';
        for (final index in groupIndices) {
          messages[index]['is_group_message'] = true;
          messages[index]['group_message_id'] = groupId;
        }
        i = groupIndices.last;
      }
    }

    return messages;
  }

  // ------------------ UI builders ------------------
  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isSentByMe, bool isReply) {
    return MessageBubble(
      message: message,
      isSentByMe: isSentByMe,
      isSelected: _selectedMessageKeys.contains(_generateMessageKey(message)),
      onTap: () => _onMessageTap(message),
      onLongPress: () => _onMessageLongPress(message),
      onRightSwipe: () => _replyToMessage(message),
      onFileTap: (url, type) => _openFile(url, type),
      onImageTap: (url) => ImageViewer.show(context, url),
      buildStatusIcon: (status) => MessageStatusIcon(status: status ?? 'sent'),
      buildReactionsBar: (msg, sentByMe) => _buildReactionsBar(msg, sentByMe),
      sentMessageColor: senderColor,
      receivedMessageColor: receiverColor,
      selectedMessageColor: senderColor.withOpacity(0.2),
      borderColor: Colors.blue,
      chatColor: chatColor,
      onReact: (msg, emoji) {
        setState(() {
          _handleReactionTap(msg, emoji);
          _showSearchAppBar = false;
          _isSelectionMode = false;
          _selectedMessages.clear();
          _selectedMessageKeys.clear();
        });
      },
      emojpicker: () => ReactionDialog.show(
        context: context,
        messageId: message['message_id']?.toString() ?? '',
        reactions: message['reactions'] as List<Map<String, dynamic>>? ?? [],
        currentUserId: currentUserId,
        convoId: widget.convoId,
        receiverId: widget.datumId ?? "",
        firstName: widget.firstname ?? "",
        lastName: widget.lastname ?? "",
      ),
      isReply: isReply,
      onReplyTap: () {
        print("hiiii");
        final replyId =
            message['reply']?['id'] ??
                message['reply']?['message_id'];

        if (replyId != null) {
          print("replyIddd $replyId");

           _scrollToMessageById(
             replyId,
            fetchIfMissing: false,
          );
        }
      },
    );
  }

  Widget _buildReactionsBar(Map<String, dynamic> message, bool sentByMe) {
    final messageId = (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '').toString();
    final mergedReactions = messageId.isNotEmpty ? _collectMergedReactionsForMessage(messageId) : <Map<String,dynamic>>[];

    final msgCopy = Map<String, dynamic>.from(message);
    msgCopy['reactions'] = mergedReactions;

    return ReactionBar(
      message: msgCopy,
      currentUserId: currentUserId,
      onReactionTap: (msg, emoji) => _handleReactionTap(msg, emoji),
      onOpenReactors: (msg, emoji) => _showReactionsBottomSheet(msg, emoji),
    );
  }

  void _onMessageTap(Map<String, dynamic> message) async {
    if (_isSelectionMode) {
      _toggleMessageSelection(message);
      return;
    }

    debugPrint('📩 tapped message id: ${_anyId(message)}');
    debugPrint('📩 tapped message raw: $message');

    String? extractReplyId(Map<String, dynamic> m) {
      final reply = m['reply'];

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

  void _onMessageLongPress(Map<String, dynamic> message) {
    log("replyIdsss ${message}");

    final msgId = message['message_id']?.toString();
    if (msgId == null || msgId.isEmpty) {
      _toggleMessageSelection(message);
    } else {
      if (!_isSelectionMode) {
        setState(() {
          _isSelectionMode = true;
        });
      }
      if (!_selectedMessageIds.contains(msgId)) {
        _selectedMessageIds.add(msgId);
        _selectedMessageKeys.add(_generateMessageKey(message));
        _selectedMessages.add(message);
      }
    }
  }

  void _removeInlineReactionPicker() {
    try {
      _reactionOverlayTimer?.cancel();
      _reactionOverlayTimer = null;
      _reactionOverlayEntry?.remove();
      _reactionOverlayEntry = null;
    } catch (_) {}
    _suppressReactionDialog = false;
  }

  void _showInlineReactionPicker(Map<String, dynamic> message) {
    if (_reactionOverlayEntry != null) return;

    _suppressReactionDialog = true;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _reactionOverlayEntry = OverlayEntry(builder: (context) {
      final media = MediaQuery.of(context);
      final bottomPadding = media.viewInsets.bottom;
      final top = media.size.height - 180 - bottomPadding;

      return Positioned(
        top: top,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _quickReactions.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      try {
                        _handleReactionTap(message, emoji);
                      } catch (e) {
                        log("Error applying reaction: $e");
                      } finally {
                        _removeInlineReactionPicker();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    });

    overlay.insert(_reactionOverlayEntry!);

    _reactionOverlayTimer?.cancel();
    _reactionOverlayTimer = Timer(const Duration(seconds: 6), () {
      _removeInlineReactionPicker();
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      _suppressReactionDialog = false;
    });
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

  List<Map<String, dynamic>> _mergeReactions({
    List<Map<String, dynamic>>? local,
    List<Map<String, dynamic>>? incoming,
  })
  {
    final Map<String, Map<String, dynamic>> byUser = {};

    void addList(List<Map<String, dynamic>>? list) {
      if (list == null) return;
      for (final r in list) {
        if (r == null || r is! Map) continue;
        final uid = (r['userId'] ?? r['user']?['_id'])?.toString() ?? '';
        final emoji = r['emoji']?.toString() ?? '';
        if (uid.isEmpty || emoji.isEmpty) continue;
        // Keep the most recent incoming attributes but prefer incoming when duplicate
        byUser[uid] = {
          'emoji': emoji,
          'userId': uid,
          'user': r['user'] is Map ? Map<String, dynamic>.from(r['user']) : r['user'],
          'reacted_at': (r['reacted_at'] ?? r['createdAt'] ?? '').toString(),
        };
      }
    }

    // local first so incoming can overwrite if needed (server is source-of-truth)
    addList(local);
    addList(incoming);

    return byUser.values.toList();
  }

  Future<void> _showReactionsBottomSheet(Map<String, dynamic> message, String initialEmoji) async {
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
        if ((userId == null || userId.isEmpty) && user is Map) {
          userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
        }
        if (userId == null || userId.isEmpty) continue;
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
    const List<String> pickerEmojis = ['👍', '❤️', '😂', '😮', '😢', '👏', '🔥', '🎉', '🤝', '💯'];

    // first build the initial normalized list
    List<Map<String, dynamic>> allReacts = _normalizeFromMap(message);
    if (allReacts.isEmpty) {
      // you might still want to show the sheet with just Add button. For now, return.
      return;
    }

    // group builder (returns grouped map)
    Map<String, List<Map<String, dynamic>>> buildGroupedFromList(List<Map<String, dynamic>> list) {
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
        Map<String, List<Map<String, dynamic>>> grouped = buildGroupedFromList(allReacts);
        final emojis = grouped.keys.toList();
        String selectedEmoji = emojis.contains(initialEmoji) ? initialEmoji : (emojis.isNotEmpty ? emojis.first : (initialEmoji.isNotEmpty ? initialEmoji : pickerEmojis.first));

        // function to attempt to refresh `message` from current combined store
        void refreshFromStore(StateSetter setStateSB) {
          try {
            final id = (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '').toString();
            if (id.isNotEmpty) {
              final latest = _getCombinedMessages().firstWhere((m) {
                final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
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
                maxHeight: showEmojiPicker?MediaQuery.of(context).size.height * 0.45:MediaQuery.of(context).size.height * 0.30,
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),

                  // TOP: emoji chips (Add first)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        // Add chip (always visible)
                        GestureDetector(
                          onTap: () {
                            setStateSB(() {
                              showEmojiPicker = !showEmojiPicker; // toggle emoji picker inside sheet
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: showEmojiPicker ? Colors.green.withOpacity(0.12) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.emoji_emotions_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                      showEmojiPicker = false; // hide picker if open
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.greenAccent.withOpacity(0.3) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(e, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text('$cnt', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                     Divider(height: 1,color:Colors.grey.shade200 ,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                debugPrint('Error while handling reaction pick: $e');
                              }

                              // hide picker and refresh sheet lists
                              setStateSB(() {
                                showEmojiPicker = false;
                              });

                              // give a tiny delay to allow local updates to settle, then refresh the grouped list
                              await Future.delayed(const Duration(milliseconds: 120));
                              refreshFromStore(setStateSB);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.shade100,
                              ),
                              child: Text(emo, style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  Divider(height: 1,color:Colors.grey.shade200 ,),

                  // header: "X reactions"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('${grouped[selectedEmoji]?.length ?? 0} reactions', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                      ],
                    ),
                  ),

                  Divider(height: 1,color:Colors.grey.shade200 ,),

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
                          userId = (user['_id'] ?? user['id'] ?? user['userId'] ?? '').toString();
                          displayName = (user['first_name'] ?? user['name'] ?? user['firstName'] ?? user['email'] ?? '').toString();
                          avatarUrl = user['avatar']?.toString();
                        } else {
                          userId = (r['userId'] ?? '').toString();
                          displayName = userId;
                        }

                        final isMe = userId == currentUserId;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) as ImageProvider : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty) ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?') : null,
                          ),
                          title: Text(isMe ? 'You' : (displayName.isNotEmpty ? displayName : userId)),
                          subtitle: isMe ? const Text('Tap to remove', style: TextStyle(fontSize: 12)) : null,
                          trailing: isMe
                              ? TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop(); // close sheet
                              final msgId = (message['message_id'] ?? message['messageId'] ?? '').toString();
                              if (msgId.isEmpty) return;

                              // optimistic local removal of current user's reaction
                              _updateLocalReactions(msgId, null); // remove my reaction locally
                              final apiMessageId = _normalizeMessageIdForApi(msgId);

                              // dispatch your RemoveReaction event
                              _messagerBloc.add(RemoveReaction(
                                messageId: apiMessageId,
                                conversationId: widget.convoId,
                                emoji: selectedEmoji,
                                userId: currentUserId,
                                receiverId: widget.datumId ?? "",
                                firstName: widget.firstname ?? "",
                                lastName: widget.lastname ?? "",
                              ));
                            },
                            child: const Text('Remove', style: TextStyle(color: Colors.red)),
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

  void _handleReactionTap(Map<String, dynamic> message, String emoji) {
    try {
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

        _messagerBloc.add(RemoveReaction(
          messageId: apiMessageId,
          conversationId: widget.convoId,
          emoji: emoji,
          userId: currentUserId,
          receiverId: widget.datumId ?? "",
          firstName: widget.firstname ?? "",
          lastName: widget.lastname ?? "",
        ));
        return;
      }

      // CASE 2: change emoji
      if (hasMyReaction && oldEmoji != emoji) {
        _updateLocalReactions(rawId, emoji);

        _messagerBloc.add(RemoveReaction(
          messageId: apiMessageId,
          conversationId: widget.convoId,
          emoji: oldEmoji ?? '',
          userId: currentUserId,
          receiverId: widget.datumId ?? "",
          firstName: widget.firstname ?? "",
          lastName: widget.lastname ?? "",
        ));

        _messagerBloc.add(AddReaction(
          messageId: apiMessageId,
          conversationId: widget.convoId,
          emoji: emoji,
          userId: currentUserId,
          receiverId: widget.datumId ?? "",
          firstName: widget.firstname ?? "",
          lastName: widget.lastname ?? "",
        ));
        return;
      }

      // CASE 3: first time reacting
      _updateLocalReactions(rawId, emoji);

      _messagerBloc.add(AddReaction(
        messageId: apiMessageId,
        conversationId: widget.convoId,
        emoji: emoji,
        userId: currentUserId,
        receiverId: widget.datumId ?? "",
        firstName: widget.firstname ?? "",
        lastName: widget.lastname ?? "",
      ));
      _saveAllMessages();
    } catch (e, st) {
      log('❌ Error handling reaction tap: $e\n$st');
    }
  }

  bool isValidUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  void _openFile(String urlOrPath, String? fileType) async {
    // ✅ 1. VIDEO: open in your own player
    if (fileType != null && fileType.startsWith('video/')) {
      final isNetwork = urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            path: urlOrPath,
            isNetwork: isNetwork,
          ),
        ),
      );
      return;
    }

    // ✅ 2. everything else = your existing code
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

  void _updateLocalReactions(String targetMessageId, String? newEmoji) {
    if (targetMessageId.trim().isEmpty) return;

    String normalizeId(dynamic id) => id?.toString().trim() ?? '';

    bool changed = false;

    void updateList(List<Map<String, dynamic>> list) {
      for (var msg in list) {
        final msgId = normalizeId(
          msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? msg['_id'],
        );

        if (msgId != targetMessageId) continue;

        // Normalize existing reactions
        final reactions = _extractReactions(msg['reactions']);

        // remove my old reaction (if any)
        reactions.removeWhere((r) {
          final uid = (r['userId'] ?? r['user']?['_id'])?.toString();
          return uid == currentUserId;
        });

        // add new reaction if not null/empty
        if (newEmoji != null && newEmoji.isNotEmpty) {
          reactions.add({
            'emoji': newEmoji,
            'userId': currentUserId,
            'user': {
              '_id': currentUserId,
              'first_name': widget.firstname ?? "",
              'last_name': widget.lastname ?? "",
            },
            'reacted_at': DateTime.now().toIso8601String(),
          });
        }

        msg['reactions'] = reactions;
        changed = true;
      }
    }

    setState(() {
      updateList(dbMessages);
      updateList(messages);
      updateList(socketMessages);

      if (changed && widget.convoId.isNotEmpty) {
        final combined = [...dbMessages, ...messages, ...socketMessages];
        LocalChatStorage.saveMessages(widget.convoId, combined);
      }

      if (changed) {
        _updateNotifier(); // rebuild visible list
      }
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

  void _markMessagesAsDeleted(List<String> messageIds) {
    if (messageIds.isEmpty) return;

    bool changed = false;

    void markInList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final msg = list[i];
        final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
        if (id.isNotEmpty && messageIds.contains(id)) {
          msg['content'] = "Message Deleted";
          msg['imageUrl'] = "";
          msg['fileUrl'] = "";
          msg['fileName'] = "";
          msg['mimeType'] = msg['mimeType'] ?? msg['fileType'] ?? "";
          msg['messageStatus'] = 'deleted';
          changed = true;
        }
      }
    }

    setState(() {
      markInList(socketMessages);
      markInList(messages);
      markInList(dbMessages);
    });

    if (changed) {
      try {
        _updateNotifier();
      } catch (_) {}
      try {
        _scheduleSaveMessages();
      } catch (_) {
        if (widget.convoId.isNotEmpty) {
          final combined = [...dbMessages, ...messages, ...socketMessages];
          LocalChatStorage.saveMessages(widget.convoId, combined);
        }
      }
    }
  }

  void _forwardSelectedMessages() {
    MyRouter.pushReplace(
      screen: ForwardMessageScreen(
        messages: _selectedMessages.toList(),
        currentUserId: currentUserId,
        conversionalid: widget.convoId,
        username: widget.firstname ?? "",
      ),
    );

    setState(() {
      _selectedMessages.clear();
      _selectedMessageKeys.clear();
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelectedMessages() {
    if (_selectedMessageIds.isEmpty) return;

    _markMessagesAsDeleted(_selectedMessageIds.toList());

    _messagerBloc.add(DeleteMessagesEvent(
      messageIds: _selectedMessageIds.toList(),
      convoId: widget.convoId,
      senderId: currentUserId,
      receiverId: widget.datumId ?? "",
      message:
      _selectedMessageKeys.isNotEmpty ? _selectedMessageKeys.first : "",
    ));

    setState(() {
      _selectedMessages.clear();
      _selectedMessageIds.clear();
      _selectedMessageKeys.clear();
      _isSelectionMode = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages();
    });

    _scheduleSaveMessages();
  }

  void _starSelectedMessages() {
    setState(() {
      _selectedMessages.clear();
      _selectedMessageKeys.clear();
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  void _replyToMessage(Map<String, dynamic> message,{bool isSendMe=false}) {
    if (message.isEmpty) return;
   log("messsssssssssssssssssssss $message");
    // 🔹 Raw data from original message
    final String content =
    (message['content'] ?? message['message'] ?? '').toString();

    final String? imageUrl =
        message['imageUrl'] ??
            message['thumbnailUrl'] ??
            message['localImagePath'];

    final String? fileUrl     = message['fileUrl'];
    final String? fileName    = message['fileName'];
    final String? fileType    = message['fileType'];
    final String? originalUrl = message['originalUrl'] ?? fileUrl;

    final String userName =
        message['senderName'] ??
            message['userName'] ??
            (message['sender']?['name'] ?? '');

    final String ftLower = (fileType ?? '').toLowerCase();
    final bool isVideo = ftLower.startsWith('video/');

    setState(() {
      // 1️⃣ Keep the FULL message as-is for _sendMessage (your old behaviour)
      _replyMessage = message;

      // 2️⃣ Build a lightweight map only for the input field UI
      _replyPreview = {
        'message_id': (message['message_id'] ??
            message['messageId'] ??
            message['id'])
            ?.toString(),
        'content': content,
        'imageUrl': imageUrl ?? '',
        'fileUrl': fileUrl ?? '',
        'fileName': fileName ?? '',
        'fileType': fileType ?? '',
        'originalUrl': originalUrl ?? '',
        'userName': userName,
        'isVideo': (message['fileType'] ?? '').toString().toLowerCase().startsWith('video/'),
        'receiver':message["receiver"],
        'sender':message["sender"],
        "isSendMe":isSendMe,
        "senderId":widget.datumId
      };

      _focusNode.requestFocus();
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return CommonAppBarBuilder.build(
      context: context,
      showSearchAppBar: _showSearchAppBar,
      isSelectionMode: _isSelectionMode,
      selectedMessages: _selectedMessages,
      toggleSelectionMode: () {
        setState(() {
          _isSelectionMode = !_isSelectionMode;
          if (!_isSelectionMode) {
            _selectedMessages.clear();
            _selectedMessageIds.clear();
            _selectedMessageKeys.clear();
          }
        });
      },
      deleteSelectedMessages: () {
        DeleteMessageDialog.show(
          context: context,
          onDeleteForEveryone: () {},
          onDeleteForMe: () => _deleteSelectedMessages(),
        );
      },
      forwardSelectedMessages: _forwardSelectedMessages,
      starSelectedMessages: _starSelectedMessages,
      replyToMessage: _replyToMessage,
      profileAvatarUrl: widget.profileAvatarUrl,
      userName: widget.userName,
      firstname: widget.firstname,
      lastname: widget.lastname,
      lastSeen: widget.lastSeen,
      convertionId: widget.convoId,
      grpId: widget.datumId ?? "",
      resvID: widget.datumId ?? "",
      favouitre: widget.favourite,
      grpChat: widget.grpChat,
      onSearchTap: () => toggleSearchAppBar(),
      onCloseSearch: () => toggleSearchAppBar(), hasLeftGroup: false, groupMembers: [],
    );
  }

  void toggleSearchAppBar() =>
      setState(() => _showSearchAppBar = !_showSearchAppBar);

  void _saveAllMessages() {
    if (widget.convoId.isEmpty) return;
    final combined = [...dbMessages, ...messages, ...socketMessages];
    LocalChatStorage.saveMessages(widget.convoId, combined);

  }

  bool _shouldAddMessage(Map<String, dynamic> msg) {
    return msg['content']?.toString().trim().isNotEmpty == true ||
        (msg['imageUrl']?.toString().isNotEmpty == true) ||
        (msg['fileUrl']?.toString().isNotEmpty == true);
  }

  bool _isUnreadMessage(dynamic msg) {
    if (msg is Map<String, dynamic>) {
      final senderId =
      (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender']?['id'])
          ?.toString();

      return msg['messageStatus'] != 'read' &&
          senderId != currentUserId &&           // 👈 only msgs from others
          msg['message_id'] != null;
    }
    return false;
  }

  List<String> _getUnreadMessageIds(List<dynamic> msgs) {
    return msgs
        .where(_isUnreadMessage)
        .map((m) => m['message_id'].toString())
        .toList();
  }

  Future<void> _loadSessionImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('chat_image_path');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() => _imageFile = File(imagePath));
    }
  }

  Future<void> _loadSessionFilePath() async {
    final prefs = await SharedPreferences.getInstance();
    final filePath = prefs.getString('chat_file_path');
    if (filePath != null && filePath.isNotEmpty) {
      setState(() => _fileUrl = File(filePath));
    }
  }

  Future<void> _clearSessionImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_image_path');
  }

  Future<void> _clearSessionFilePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_file_path');
  }

  Future<void> _clearSessionPaths() async {
    await _clearSessionImagePath();
    await _clearSessionFilePath();
  }
  /// Call this after messages are loaded and socket is connected.
  Future<void> _sendInitialReadReceiptsIfNeeded() async {
    if (!mounted) return;
    log("🔁 _sendInitialReadReceiptsIfNeeded(): start");

    // Wait short time for socket to become connected (try a few times)
    const maxAttempts = 8;
    var attempt = 0;
    while (!socketService.isConnected && attempt < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 250));
      attempt++;
    }

    if (!socketService.isConnected) {
      log("⚠️ Socket not connected after wait — skipping initial read receipts.");
      return;
    }

    // Only send if the screen is active and visible to user
    if (!_screenActive) {
      log("ℹ️ Screen not active — skipping initial read receipts.");
      return;
    }

    // Build combined messages and collect unread ids (messages from other user)
    final combined = _getCombinedMessages();
    final unread = _getUnreadMessageIds(combined)
        .where((id) => id.trim().isNotEmpty && !_alreadyRead.contains(id))
        .toList();

    log("🟢 initial unread IDs found (pre-check): $unread");

    // if (unread.isEmpty) {
    //   log("ℹ️ No unread messages to mark as read on init.");
    //   return;
    // }

    // Mark locally & remember
    for (final id in unread) {
      _updateMessageStatus(id, 'read');
    }
    _alreadyRead.addAll(unread);

    // compute consistent roomId
    final computedRoomId = socketService.generateRoomId(currentUserId, widget.datumId ?? '');
    socketService.sendReadReceipts(
      messageIds: unread,
      conversationId: widget.convoId,
      roomId: computedRoomId,
    );

    log("✅ initial read receipts emitted: $unread (roomId=$computedRoomId)");
  }

  void _scrollToBottom({int maxRetries = 6}) {
    if (!_scrollController.hasClients) {
      // schedule to try after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(maxRetries: maxRetries);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // small delays help let layout settle (keyboard, images, etc.)
      int attempt = 0;
      while (attempt < maxRetries) {
        try {
          if (!_scrollController.hasClients) break;

          final maxScroll = _scrollController.position.maxScrollExtent;
          // if already at bottom, no need to animate
          final isAtBottom = (_scrollController.offset - maxScroll).abs() < 1.0;
          if (isAtBottom) return;

          // Try animate first -- smoother
          await _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );

          // If after animate still not at bottom, try jumpTo as a fallback
          if (_scrollController.hasClients &&
              (_scrollController.offset - _scrollController.position.maxScrollExtent).abs() > 1.0) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }

          return;
        } catch (e) {
          // layout may still be changing; wait and retry
          await Future.delayed(const Duration(milliseconds: 80));
          attempt++;
        }
      }

      // final fallback: try a small delay then jump
      await Future.delayed(const Duration(milliseconds: 120));
      if (_scrollController.hasClients) {
        try {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } catch (_) {}
      }
    });
  }


  // ------------------ Build ------------------
  @override
  Widget build(BuildContext context) {
    return ReusableChatScaffold(
      appBar: _buildAppBar(),
      chatBody: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _messagesNotifier,
        builder: (context, combinedMessages, child) {
          _markVisibleMessagesAsRead(combinedMessages);

          return BlocConsumer<MessagerBloc, MessagerState>(
            listener: (context, state) {
              if (state is MessageSentSuccessfully) {
                // ⛔ DO NOT add message again, _sendMessage already added it.

                print("messageStatus ${state.sentMessage.messageStatus}");
                final id = state.sentMessage.messageId ?? '';
                if (id.isNotEmpty) {
                  _updateMessageStatus(
                      id, state.sentMessage.messageStatus ?? 'pending');
                //  _sendReadForNewOutgoing(id);  // only if your backend really expects this

                }
              }
              else if (state is MessagerLoaded) {
                _hasNextPage = state.response.hasNextPage;
                _isLoadingMore = false;

                // 1) Flatten groups → List<Datum>
                final allMessages = state.response.data
                    .expand((group) => group.messages)
                    .toList();

                // 2) Normalize server data
                var newDbMessages = allMessages
                    .map<Map<String, dynamic>>(
                      (datum) => normalizeMessage(datum.toJson()),
                )
                    .where((m) => m.isNotEmpty)
                    .toList();
                newDbMessages = _inferGrouping(newDbMessages);

                // 🔥 3) MERGE: keep local reactions if server doesn't send them
                // 🔥 3) MERGE: keep local reactions and local read-state if present
                // build previousById as before
                final Map<String, Map<String, dynamic>> previousById = {};
                for (final old in dbMessages) {
                  final id = (old['message_id'] ?? old['messageId'] ?? old['id'] ?? '').toString();
                  if (id.isEmpty) continue;
                  previousById[id] = old;
                }

                for (final m in newDbMessages) {
                  final id = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
                  if (id.isEmpty) continue;
                  final prev = previousById[id];
                  if (prev == null) continue;

// --- preserve local reply if present on prev (marker set earlier) ---
                  final bool prevHasLocalReply = prev['_localHasReply'] == true;
                  if (prevHasLocalReply) {
                    // if server message lacks reply, restore it from prev
                    final newHasReply = _hasReplyForMessage(m);
                    if (!newHasReply) {
                      try {
                        if (prev['_localReply'] != null) {
                          m['reply'] = Map<String, dynamic>.from(prev['_localReply']);
                        } else if (prev['reply'] != null) {
                          m['reply'] = Map<String, dynamic>.from(prev['reply']);
                        }
                        m['reply_message_id'] ??= (m['reply'] != null)
                            ? (m['reply']['id'] ??
                            m['reply']['message_id'] ??
                            m['reply']['reply_message_id'])
                            ?.toString()
                            : m['reply_message_id'];
                        m['isReplyMessage'] = true;
                        // carry the local marker forward so future merges still know
                        m['_localHasReply'] = true;
                        m['_localReply'] = m['reply'];
                      } catch (_) {}
                    }
                  }

// preserve local reactions if server omitted them
                  final prevReactions = _extractReactions(prev['reactions']);
                  final newReactions = _extractReactions(m['reactions']);
                  if (newReactions.isEmpty && prevReactions.isNotEmpty) {
                    m['reactions'] = prevReactions;
                  } else if (newReactions.isNotEmpty && prevReactions.isNotEmpty) {
                    // merge them (union by user)
                    m['reactions'] = _mergeReactions(local: prevReactions, incoming: newReactions);
                  }

// preserve local 'read' only if we locally marked it
                  final prevStatus = (prev['messageStatus'] ?? prev['status'] ?? '').toString();
                  final newStatus = (m['messageStatus'] ?? m['status'] ?? '').toString();
                  final bool prevLocallyMarkedRead = prev['_localMarkedRead'] == true;
                  if (prevLocallyMarkedRead && prevStatus == 'read' && newStatus != 'read') {
                    m['messageStatus'] = 'read';
                    m['_localMarkedRead'] = true;
                  }

                  // Optional: time-based tie-breaker if you want to compare timestamps (keep as-is if complex)
                }

                // 4) Now replace / prepend with merged list
                if (_currentPage == 1) {
                  final Map<String, Map<String, dynamic>> byId = {};
// overlay fresh messages from server
                  for (final fresh in newDbMessages) {
                    final id = (fresh['message_id'] ?? fresh['messageId'] ?? fresh['id'])?.toString() ?? '';
                    if (id.isEmpty) {
                      // server returned a message without id — keep it as-is (append)
                      // you may want to add it to dbMessages directly, but here we keep within byId
                      final tempKey = '__noid_${DateTime.now().microsecondsSinceEpoch}';
                      byId[tempKey] = fresh;
                      continue;
                    }

                    // if we already had a local version, merge some important local-only fields
                    final prev = byId[id]; // this checks values already in byId (from cached dbMessages earlier)
                    // If `prev` is null, try to find a cached local message from your existing dbMessages:
                    final localPrev = prev ?? dbMessages.firstWhere(
                          (m) => (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() == id,
                      orElse: () => {},
                    );

                    // Start with fresh copy we'll store
                    final Map<String, dynamic> merged = Map<String, dynamic>.from(fresh);

                    // ---- Preserve reply info if local had it but server omitted it ----
                    try {
                      final bool prevHasLocalReply = (localPrev != null && localPrev.isNotEmpty) &&
                          (localPrev['_localHasReply'] == true ||
                              localPrev['reply'] != null ||
                              localPrev['reply_message_id'] != null);

                      final bool freshHasReply = _hasReplyForMessage(merged);

                      if (prevHasLocalReply && !freshHasReply) {
                        // Prefer a locally stored _localReply if present (set when you replaced temp->real)
                        if (localPrev['_localReply'] != null) {
                          merged['reply'] = Map<String, dynamic>.from(localPrev['_localReply']);
                        } else if (localPrev['reply'] != null) {
                          merged['reply'] = Map<String, dynamic>.from(localPrev['reply']);
                        }

                        // ensure top-level id fields exist
                        if (merged['reply'] != null) {
                          merged['reply_message_id'] ??= (merged['reply']['id'] ??
                              merged['reply']['message_id'] ??
                              merged['reply']['reply_message_id'])?.toString();
                        }

                        merged['isReplyMessage'] = true;
                        merged['_localHasReply'] = true;
                        merged['_localReply'] = merged['reply'];
                      }
                    } catch (_) {
                      // don't crash merging — server data might have unexpected shapes
                    }

                    // ---- Preserve local reactions if server omitted them (optional) ----
                    try {
                      final prevReactions = (localPrev != null && localPrev.isNotEmpty) ? _extractReactions(localPrev['reactions']) : <Map<String,dynamic>>[];
                      final newReactions = _extractReactions(merged['reactions']);
                      if (newReactions.isEmpty && prevReactions.isNotEmpty) {
                        merged['reactions'] = prevReactions;
                      }
                    } catch (_) {}

                    // ---- Preserve locally marked read state if we previously flagged it ----
                    try {
                      final prevLocallyMarkedRead = (localPrev != null && localPrev.isNotEmpty) && localPrev['_localMarkedRead'] == true;
                      final newStatus = (merged['messageStatus'] ?? merged['status'] ?? '').toString();
                      if (prevLocallyMarkedRead && newStatus != 'read') {
                        merged['messageStatus'] = 'read';
                        merged['_localMarkedRead'] = true;
                      }
                    } catch (_) {}

                    // finally store merged into byId (overlaying server)
                    byId[id] = merged;
                  }

                  dbMessages
                    ..clear()
                    ..addAll(byId.values);
                } else {
                  dbMessages.insertAll(0, newDbMessages);
                }

                // 5) Track seen IDs
                for (var m in newDbMessages) {
                  final id =
                  (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
                  if (id.isNotEmpty) _seenMessageIds.add(id);
                }

                // 6) Rebuild combined list & notify UI
                _updateNotifier();
                _scheduleSaveMessages();

                if (_currentPage == 1) {
                  _scrollToBottom();
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      if (_prevScrollExtentBeforeLoad > 0 &&
                          _scrollController.hasClients) {
                        final newMax = _scrollController.position.maxScrollExtent;
                        final delta = newMax - _prevScrollExtentBeforeLoad;
                        final newOffset =
                        (_scrollController.offset + delta).clamp(
                          0.0,
                          _scrollController.position.maxScrollExtent,
                        );
                        _scrollController.jumpTo(newOffset);
                      }
                    } catch (_) {}
                    _prevScrollExtentBeforeLoad = 0.0;
                  });
                }
              }
              else if (state is NewMessageReceivedState) {
                onMessageReceived(state.message);

                normalizeReplyMessages(socketMessages);
                _updateNotifier();
              }

            },
            builder: (context, state) {
              final bool showShimmer = state is MessagerLoading &&
                  _currentPage == 1 &&
                  messages.isEmpty &&
                  socketMessages.isEmpty &&
                  combinedMessages.isEmpty;

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
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Loading older messages...', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      )
                          : (!_hasNextPage && _allMessages.isNotEmpty)
                          ? Padding(
                        key: const ValueKey('all_loaded'),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text('All messages loaded', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),

                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: combinedMessages.length,
                        itemBuilder: (context, index) {
                          final message = combinedMessages[index];
                             log("messagessssssssss ${message}");
                          final senderMap = message['sender'] is Map
                              ? Map<String, dynamic>.from(message['sender'])
                              : <String, dynamic>{};
                      
                          final senderId = (message['senderId'] ??
                              senderMap['_id'] ??
                              senderMap['id'] ??
                              message['sender'])
                              ?.toString() ??
                              '';
                      
                           isSentByMe = senderId == currentUserId;
                           print("isssssssssssssss R${isSentByMe.runtimeType}");
                          final showDate = index == 0 ||
                              !isSameDay(
                                _parseTime(message['time']),
                                _parseTime(combinedMessages[index - 1]['time']),
                              );
                          final isGroupMessage = message['is_group_message'] == true;
                          final groupMessageId = message['group_message_id']?.toString();
                      
                          if (isGroupMessage &&
                              groupMessageId != null &&
                              groupMessageId.isNotEmpty) {
                      
                            // Is this the first message in the group?
                            final isFirstInGroup = index == 0 ||
                                combinedMessages[index - 1]['group_message_id']?.toString() !=
                                    groupMessageId;
                      
                            // Skip non-first items
                            if (!isFirstInGroup) {
                              return const SizedBox.shrink();
                            }
                      
                            // 👇 collect ALL media (images + videos) in this group
                            final List<GroupMediaItem> groupMedia = [];
                            final String messageStatus = message['messageStatus']?.toString() ?? 'sent';
                      
                            for (int i = index; i < combinedMessages.length; i++) {
                              final nextMsg = combinedMessages[i];
                              final nextGrpId = nextMsg['group_message_id']?.toString();
                              if (nextGrpId != groupMessageId) break;
                      
                              final String? thumb = nextMsg['originalUrl']?.toString()
                                  ?? nextMsg['imageUrl']?.toString()
                                  ?? nextMsg['localImagePath']?.toString();
                      
                              final String? fileUrl = nextMsg['fileUrl']?.toString();
                              final String fileType =
                              (nextMsg['fileType'] ?? nextMsg['mimeType'] ?? '').toString().toLowerCase();
                      
                              final bool isVideo = fileType.startsWith('video/') ||
                                  (fileUrl != null &&
                                      RegExp(r'\.(mp4|mov|mkv|avi|webm)$', caseSensitive: false).hasMatch(fileUrl));
                      
                              if (!isVideo && thumb != null && thumb.isNotEmpty) {
                                groupMedia.add(GroupMediaItem(
                                  previewUrl: thumb,
                                  mediaUrl: thumb,
                                  isVideo: false,
                                ));
                              } else if (isVideo) {
                                final preview = thumb ?? fileUrl ?? '';
                                final media = fileUrl ?? thumb ?? '';
                                if (media.isNotEmpty) {
                                  groupMedia.add(GroupMediaItem(
                                    previewUrl: preview,
                                    mediaUrl: media,
                                    isVideo: true,
                                  ));
                                }
                              }
                            }
                      
                      
                            // Render grouped media if we have any
                            if (groupMedia.isNotEmpty) {
                              return Column(
                                crossAxisAlignment:
                                isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (showDate)
                                    DateSeparator(dateTime: _parseTime(message['time'])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: GroupedMediaWidget(
                                      media: groupMedia,
                                      isSentByMe: isSentByMe,
                                      time: TimeUtils.formatUtcToIst(message['time']),
                                      messageStatus: message['messageStatus']?.toString() ?? 'sent',
                                      buildStatusIcon: (status) => MessageStatusIcon(status: status ?? 'sent',isStatus: true,),
                                      onImageTap:  (tappedIndex) {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            transitionDuration: const Duration(milliseconds: 300),
                                            pageBuilder: (_, __, ___) => MixedMediaViewer(
                                              items: groupMedia,
                                              initialIndex:tappedIndex,
                                            ),
                                          ),
                                        );

                                      },

                                    ),
                                  ),
                                ],
                              );
                            }
                      
                          }
                      
                      
                          final hasReply = _hasReplyForMessage(message);
                      
                          print("hasReply $hasReply");
                      
                          final messageId = (message['message_id'] ??
                              message['messageId'] ??
                              message['id'] ??
                              '')
                              .toString();
                      
                          final bool isHighlighted = _highlightedMessageId == messageId;
                      
                          return Builder(
                            builder: (ctx) {
                              final messageId = _anyId(message)?.toString();
                              if (messageId != null && messageId.isNotEmpty) {
                                _messageContexts[messageId] = ctx;
                              }
                              return SwipeTo(
                                animationDuration: const Duration(milliseconds: 650),
                                iconOnRightSwipe: Icons.reply,
                                iconColor: Colors.grey.shade600,
                                iconSize: 24.0,
                                offsetDx: 0.3,
                                swipeSensitivity: 5,
                                onRightSwipe: (details) => _replyToMessage(message,isSendMe: isSentByMe),
                                child: AnimatedContainer(
                                  key: ValueKey(messageId),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  color: isHighlighted
                                      ? Colors.yellow.withOpacity(0.25)
                                      : Colors.transparent,
                                  child: !hasReply
                                      ? _buildMessageBubble(message, isSentByMe, hasReply)
                                      : Column(
                                    crossAxisAlignment: isSentByMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (showDate)
                                        DateSeparator(
                                            dateTime: _parseTime(message['time'])),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 6),
                                       // padding: const EdgeInsets.all(7),
                                        constraints:
                                        const BoxConstraints(maxWidth: 160),
                                        decoration: BoxDecoration(
                                          color: (isSentByMe
                                              ? const Color(0xFFD8E1FE)
                                              : Colors.white),
                                          borderRadius: BorderRadius.only(
                                            topLeft: isSentByMe
                                                ? Radius.zero
                                                : const Radius.circular(18),
                                            topRight: isSentByMe
                                                ? const Radius.circular(18)
                                                : Radius.zero,
                                            bottomLeft: isSentByMe
                                                ? const Radius.circular(18)
                                                : Radius.zero,
                                            bottomRight: isSentByMe
                                                ? Radius.zero
                                                : const Radius.circular(16),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            _buildMessageBubble(
                                                message, isSentByMe, hasReply),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }
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
      voiceRecordingUI: _buildVoiceRecordingUI(),
      messageInputBuilder: (isKeyboardVisible) =>
          _buildMessageInputField(isKeyboardVisible,isSentByMe),
      isRecording: _isRecording,
      bloc: _messagerBloc,
    );
  }

  Widget _buildVoiceRecordingUI() {
    return VoiceRecordingWidget(
      isRecording: _isRecording,
      isPaused: _isPaused,
      recordDuration: Duration(seconds: _recordDuration),
      formatDuration: (duration) => _formatDuration(duration.inSeconds),
      onStartRecording: recorderHelper.startRecording,
      onPauseRecording: recorderHelper.pauseRecording,
      onResumeRecording: recorderHelper.resumeRecording,
      onStopRecording: recorderHelper.stopRecording,
      onPlayRecording: recorderHelper.playRecording,
      onSendRecording: recorderHelper.sendRecording,
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

  List<Map<String, dynamic>> _getCombinedMessages() {
    final combined = <Map<String, dynamic>>[];

    int idx = 0;

    void addWithIndex(List<Map<String, dynamic>> source) {
      for (var m in source) {
        if (m.isNotEmpty) {
          final copy = Map<String, dynamic>.from(m);
          copy['_localIndex'] ??= idx++;
          combined.add(copy);
        }
      }
    }

    addWithIndex(dbMessages);
    addWithIndex(messages);
    addWithIndex(socketMessages);

    combined.sort((a, b) {
      try {
        final ta = _parseTime(a['time']);
        final tb = _parseTime(b['time']);
        final cmp = ta.compareTo(tb);
        if (cmp != 0) return cmp;

        final ia = a['_localIndex'] as int? ?? 0;
        final ib = b['_localIndex'] as int? ?? 0;
        return ia.compareTo(ib);
      } catch (_) {
        return 0;
      }
    });

    final result = <Map<String, dynamic>>[];

    for (final m in combined) {
      final id =
          (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';

      if (id.isEmpty) {
        result.add(m);
        continue;
      }

      final existingIndex = result.indexWhere((e) {
        final eid =
            (e['message_id'] ?? e['messageId'] ?? e['id'])?.toString() ?? '';
        return eid == id;
      });

      if (existingIndex == -1) {
        result.add(m);
      } else {
        final existing = result[existingIndex];

        final existingHasReply = _hasReplyForMessage(existing);
        final newHasReply = _hasReplyForMessage(m);

        final existingIsForwarded = existing['isForwarded'] == true;
        final newIsForwarded = m['isForwarded'] == true;

        if ((!existingHasReply && newHasReply) ||
            (!existingIsForwarded && newIsForwarded)) {
          result[existingIndex] = m;
        } else {
          // otherwise pick the one with reply or the incoming one (your current policy).
          result[existingIndex] = newHasReply ? m : existing;
        }
      }
    }
    for (final msg in result) {
      if (msg['isReplyMessage'] == true && msg['repliedMessage'] == null) {
        final resolved = resolveRepliedMessage(
          message: msg,
          allMessages: result,
        );

        if (resolved != null) {
          msg['repliedMessage'] = resolved;
        }
      }
    }
    return result;
  }
  void normalizeReplyMessages(List<Map<String, dynamic>> messages) {
    for (final msg in messages) {
      if (msg['isReplyMessage'] == true &&
          msg['repliedMessage'] == null &&
          msg['reply_message_id'] != null) {
        final replyId = msg['reply_message_id'].toString();

        try {
          final original = messages.firstWhere(
                (m) =>
            (m['message_id'] ?? m['messageId'] ?? m['id'])
                ?.toString() ==
                replyId,
          );

          msg['repliedMessage'] = {
            'replyContent': original['content'],
            'fileType': original['fileType'] ?? original['mimeType'],
            'originalUrl': original['originalUrl'] ??
                original['imageUrl'] ??
                original['fileUrl'],
            'thumbnailUrl': original['thumbnailUrl'],
            'fileUrl': original['fileUrl'],
            'imageUrl': original['imageUrl'],
            'senderName': original['senderName'],
            'duration': original['duration'],
          };
        } catch (_) {
          // original not loaded yet (pagination case)
        }
      }
    }
  }

  void _rebuildFromStore({bool resetVisibleIfEmpty = false}) {
    final fullCombined = _getCombinedMessages();
    _allMessages
      ..clear()
      ..addAll(fullCombined);

    final total = _allMessages.length;

    if (_visibleCount == 0 || (resetVisibleIfEmpty && _visibleCount > total)) {
      _visibleCount = total >= _initialVisible ? _initialVisible : total;
    } else if (_visibleCount > total) {
      _visibleCount = total;
    } else {
      // If new messages were appended and we already are showing a window,
      // increase the visible window by 1 so newly appended messages show up.
      // This prevents the case where we're viewing only last N and new item gets hidden.
      _visibleCount = (_visibleCount < total) ? (_visibleCount + 1) : _visibleCount;
    }

    _updateNotifierFromAll();
    _scheduleSaveMessages();
  }
  Map<String, dynamic>? resolveRepliedMessage({
    required Map<String, dynamic> message,
    required List<Map<String, dynamic>> allMessages,
  }) {
    if (message['isReplyMessage'] != true) return null;

    // already resolved
    if (message['repliedMessage'] != null) {
      return Map<String, dynamic>.from(message['repliedMessage']);
    }

    final String? replyId = message['replyMessageId']?.toString();
    if (replyId == null || replyId.isEmpty) return null;

    try {
      final original = allMessages.firstWhere(
            (m) => m['message_id']?.toString() == replyId,
      );

      return {
        'content': original['content'],
        'imageUrl': original['imageUrl'],
        'fileUrl': original['fileUrl'],
        'fileType': original['fileType'],
        'originalUrl': original['originalUrl'],
        'isVideo': original['isVideo'],
        'fileName': original['fileName'],
        'senderName': original['senderName'],
      };
    } catch (_) {
      return null;
    }
  }

  Widget _buildReplyPreview(Map<String, dynamic> message) {
    log("dddddddddddddddddddd $message");
    return StatefulBuilder(builder: (ctx, setLocalState) {
      // --- normalize reply map (defend if it's a JSON string) ---
      if (message['reply'] is String) {
        try {
          message['reply'] = jsonDecode(message['reply']);
        } catch (e) {
          debugPrint('Could not jsonDecode reply string: $e');
          message['reply'] = <String, dynamic>{};
        }
      }
      final replyMap = (message['repliedMessage'] is Map)
          ? Map<String, dynamic>.from(message['repliedMessage'])
          : <String, dynamic>{};

      // --- keys & initial values ---
      final replyId = (replyMap['id'] ??
          replyMap['message_id'] ??
          replyMap['messageId'] ??
          replyMap['reply_message_id'] ??
          message['reply_message_id'])
          ?.toString() ??
          '';

      String replyContent = (replyMap['replyContent'] ??
          replyMap['content'] ??
          replyMap['message'] ??
          '')
          .toString();

      String fileType = (replyMap['fileType'] ??
          replyMap['mimeType'] ??
          replyMap['mimetype'] ??
          '')
          .toString()
          .toLowerCase();

      String imageOrVideoUrl = (replyMap['originalUrl'] ??
          replyMap['replyUrl'] ??
          replyMap['reply_url'] ??
          replyMap['thumbnailUrl'] ??
          replyMap['fileUrl'] ??
          replyMap['imageUrl'] ??
          '').toString();

print("imageOrVideoUrl $imageOrVideoUrl");
      final senderName = (replyMap['senderName'] ??
          replyMap['sender']?['name'] ??
          replyMap['fromName'] ??
          '')
          .toString();

      final dynamic durRaw = replyMap['videoDuration'] ?? replyMap['duration'];
      int durationSec = durRaw is int ? durRaw : int.tryParse(durRaw?.toString() ?? '') ?? 0;

      bool looksLikeNetwork(String s) => s.startsWith('http://') || s.startsWith('https://');

      // Fast path: try to resolve from combined messages if missing
      if (imageOrVideoUrl.isEmpty && replyId.isNotEmpty) {
        try {
          final all = _getCombinedMessages();
          final original = all.firstWhere(
                (m) {
              final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
              return mid == replyId;
            },
            orElse: () => <String, dynamic>{},
          );

          if (original.isNotEmpty) {
            imageOrVideoUrl = (original['originalUrl'] ?? original['thumbnailUrl'] ?? original['fileUrl'] ?? original['imageUrl'] ?? '').toString();
            if (fileType.isEmpty) {
              fileType = (original['fileType'] ?? original['mimeType'] ?? original['mimetype'] ?? '').toString().toLowerCase();
            }

            // persist into message['reply'] so future builds will find it
            message['reply'] = (message['reply'] is Map) ? Map<String, dynamic>.from(message['reply']) : <String, dynamic>{};
            message['reply']['originalUrl'] = imageOrVideoUrl;
            message['reply']['fileType'] = fileType;
          }
        } catch (e) {
          debugPrint('reply quick lookup failed: $e');
        }
      }

      // If still missing, schedule async fetch once
      if (imageOrVideoUrl.isEmpty && replyId.isNotEmpty) {
        Future.microtask(() async {
          try {
            final fetched = await _scrollToMessageById(replyId, fetchIfMissing: true);
            if (fetched) {
              final all2 = _getCombinedMessages();
              final original2 = all2.firstWhere(
                    (m) {
                  final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
                  return mid == replyId;
                },
                orElse: () => <String, dynamic>{},
              );

              if (original2.isNotEmpty) {
                final foundUrl = (original2['originalUrl'] ?? original2['thumbnailUrl'] ?? original2['fileUrl'] ?? original2['imageUrl'] ?? '').toString();
                final foundType = (original2['fileType'] ?? original2['mimeType'] ?? original2['mimetype'] ?? '').toString().toLowerCase();
                if (foundUrl.isNotEmpty) {
                  imageOrVideoUrl = foundUrl;
                  fileType = foundType;

                  // write back into message.reply
                  message['reply'] = (message['reply'] is Map) ? Map<String, dynamic>.from(message['reply']) : <String, dynamic>{};
                  message['reply']['originalUrl'] = foundUrl;
                  message['reply']['fileType'] = foundType;

                  setLocalState(() {}); // re-render
                }
              }
            }
          } catch (e) {
            debugPrint('reply async fetch error: $e');
          }
        });
      }

      final bool isVideo = fileType.startsWith('video/') ||
          ['mp4', 'mov', 'mkv', 'avi', 'webm'].any((ext) => imageOrVideoUrl.toLowerCase().endsWith(ext));
      final bool isImage = fileType.startsWith('image/') ||
          ['jpg', 'jpeg', 'png', 'gif', 'webp'].any((ext) => imageOrVideoUrl.toLowerCase().endsWith(ext));

      // if nothing at all, hide
      if (replyId.isEmpty && replyContent.isEmpty && imageOrVideoUrl.isEmpty) {
        return const SizedBox.shrink();
      }

      String formatDuration(int sec) {
        if (sec <= 0) return '';
        final d = Duration(seconds: sec);
        final m = d.inMinutes;
        final s = d.inSeconds % 60;
        return '$m:${s.toString().padLeft(2, '0')}';
      }

      Widget buildThumbNow(String url, bool video) {
        if (video) {
          return FutureBuilder<File?>(
            future: VideoThumbUtil.generateFromUrl(url),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return Container(color: Colors.grey.shade300);
              if (!snap.hasData || snap.data == null) return Container(color: Colors.black, child: const Icon(Icons.videocam, color: Colors.white, size: 18));
              return Image.file(snap.data!, fit: BoxFit.cover);
            },
          );
        } else {
          if (looksLikeNetwork(url)) {
            return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (c, _) => Container(color: Colors.grey.shade300));
          } else {
            final f = File(url);
            if (f.existsSync()) return Image.file(f, fit: BoxFit.cover);
            return Container(color: Colors.grey.shade300);
          }
        }
      }

      return GestureDetector(
        onTap: () async {
          if (isVideo && imageOrVideoUrl.isNotEmpty) {
            final isNet = looksLikeNetwork(imageOrVideoUrl);
            Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(path: imageOrVideoUrl, isNetwork: isNet)));
          } else if (isImage && imageOrVideoUrl.isNotEmpty) {
            ImageViewer.show(context, imageOrVideoUrl);
          } else if (replyContent.isNotEmpty) {
            final found = await _scrollToMessageById(replyId, fetchIfMissing: true);
            if (!found) Messenger.alert(msg: "Original message not loaded. Scroll up to load older messages.");
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 3, height: 40, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (senderName.isNotEmpty) Text(senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (isVideo)
                    Row(children: [const Icon(Icons.videocam, size: 14), const SizedBox(width: 4), Text('Video' + (durationSec > 0 ? ' (${formatDuration(durationSec)})' : ''), style: const TextStyle(fontSize: 12))])
                  else if (isImage)
                    Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.image, size: 14), SizedBox(width: 4), Text('Photo', style: TextStyle(fontSize: 12))])
                  else if (replyContent.isNotEmpty)
                      Text(replyContent, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  if (replyContent.isNotEmpty && (isVideo || isImage))
                    Text(replyContent, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ]),
              ),
              const SizedBox(width: 8),
              if ((isImage || isVideo) && imageOrVideoUrl.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 42, height: 42, child: buildThumbNow(imageOrVideoUrl, isVideo))),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMessageInputField(bool isKeyboardVisible,bool isSentByMe) {
    return MessageInputField(
      messageController: _messageController,
      focusNode: _focusNode,
      onSendPressed: _sendMessage,
      onEmojiPressed: () {
        setState(() {});
      },
      onAttachmentPressed: () => ShowAltDialog.showOptionsDialog(context,
          conversationId: widget.convoId,
          senderId: currentUserId,
          receiverId: widget.datumId!,
          isGroupChat: false,
          onOptionSelected: (List<Map<String, dynamic>> localMessages) {
            if (localMessages.isEmpty) return;

            setState(() {
              socketMessages.addAll(localMessages);
              for (var msg in localMessages) {
                final id = (msg['message_id'] ?? '').toString();
                if (id.isNotEmpty) _seenMessageIds.add(id);
              }
            });
            _updateNotifier();
            _scheduleSaveMessages();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }),      onCameraPressed: _openCamera,
      onRecordPressed: _isRecording
          ? recorderHelper.stopRecording
          : recorderHelper.startRecording,
      isRecording: _isRecording,
      replyText: _replyPreview,
      onCancelReply: () {
        recorderHelper.cancelReply();
        _replyPreview = null;
        _messageController.clear();
        setState(() {});
      },
      reciverID: widget.datumId ?? "",
      onDraftChanged: (text) {
        if (text.isNotEmpty) {
          _saveDraft(text);
        } else {
          _clearDraft();
        }
      },
      isSender: isSentByMe,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
