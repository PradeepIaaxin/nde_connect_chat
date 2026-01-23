import 'dart:convert';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/message_handler.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MediaPreviewScreen.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/audio_reuable.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/commonfuntion.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/date_separate.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/double_tick_ui.dart';
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/presantation/chat/widget/reation_bottom.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/buildMessageInputField_widgets.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import '../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import '../chat_list/chat_session_storage/chat_session.dart';
import 'messager_Bloc/MessagerEvent.dart';
import 'messager_Bloc/MessagerState.dart';
import 'messager_Bloc/widget/MixedMediaViewer.dart';
import 'messager_Bloc/widget/VideoPlayerScreen.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/whatsapp_swipe_to_reply.dart';

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
  final List<Map<String, dynamic>>? initialMessages;

  final List<File> sharedFiles;
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
    required this.sharedFiles,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PrivateChatScreenState createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  // Controllers / focus
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // final AudioPlayerService _audioPlayerService = AudioPlayerService();
  // Inline reaction overlay
  String? _highlightedMessageId;
  StreamSubscription<Map<String, dynamic>>? _crdtSub;
  String? currentUser;
  Timer? _highlightTimer;
  final Map<String, BuildContext> _messageContexts = {};

  // Services & handlers
  final SocketService socketService = SocketService();
  late MessagerBloc _messagerBloc;
  MessageHandler? _messageHandler;
  late ChatListBloc _chatListBloc;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  StreamSubscription? _messageDeletedSubscription;
  bool _isRecordingLocked = false;

  // Message storage (in-memory)
  final List<Map<String, dynamic>> socketMessages = [];
  final List<Map<String, dynamic>> dbMessages = [];
  final List<Map<String, dynamic>> messages = [];

  // ignore: unused_field
  final List<Map<String, dynamic>> _optimisticMessages = [];
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
  List<String> _searchMatchIds = [];
  int _currentSearchMatchIndex = -1;
  late String _currentConversationId;
  bool _isRecording = false;

  bool isSentMe = false;
  // Pagination / client-side windowing
  int _currentPage = 1;
  final int _initialLimit = 40;

  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  double _prevScrollExtentBeforeLoad = 0.0;

  // Selection / reactions
  final Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;
  final List<Map<String, dynamic>> _selectedMessages = [];
  StreamSubscription<MessageReaction>? _reactionSubscription;
  final Set<String> _alreadyRead = {};
  final Set<String> _selectedMessageKeys = {};
  Map<String, dynamic>? _replyMessage; // full original message (for sending)
  Map<String, dynamic>? _replyPreview; // small map for input UI

  /// Full message history for this conversation (normalized)
  final List<Map<String, dynamic>> _allMessages = [];

  /// How many from the **end** we are currently showing
  int _visibleCount = 0;

  /// Show +40 older messages each time user scrolls to top
  final int _pageStep = 40;
  final int _initialVisible = 40;

  // Media
  final List<Map<String, dynamic>> _offlineQueue = [];

  // Recorder helper
  final recorderHelper = AudioRecorderHelper();
  bool _initialScrollDone = false;
  bool _screenActive = false;
  StreamSubscription<Map<String, dynamic>>? _userStatusSub;
  List<String> recentEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  void initState() {
    super.initState();

    _currentConversationId = widget.convoId;
    print('🔐 private chat screen : $_currentConversationId');
    socketService.setActiveConversation(widget.convoId);
    print('🔐 private chat screen : ${widget.convoId}');

    _messagerBloc = context.read<MessagerBloc>();
    _chatListBloc = context.read<ChatListBloc>();
    _scrollController.addListener(_scrollListener);
    _initializeChat();
    _screenActive = true;
    SocketService().joinChatRoom(
      senderId: currentUserId,
      receiverId: widget.receiverId ?? "",
      isGroupChat: false,
    );

    _crdtSub = socketService.crdtMessageStream.listen((data) {
      final convoId = data['conversationId']?.toString();
      if (convoId == null) return;

      // 🔥 ONLY THIS FILTER MATTERS
      // Ignore if it matches NEITHER the initial widget ID NOR the current (possibly updated) ID
      // UNLESS we are in a "new chat" state (both empty), in which case we must inspect.
      final bool isNewChat =
          widget.convoId.isEmpty && _currentConversationId.isEmpty;
      if (!isNewChat &&
          convoId != widget.convoId &&
          convoId != _currentConversationId) {
        return;
      }
      log("kkkkkkkkkkkkkkkkkkkkkkkk ${data['messages']}");
      _applyCrdtMessages(
        convoId,
        Map<String, dynamic>.from(data['messages'] ?? {}),
      );
    });

    // initial state
    Connectivity().checkConnectivity().then((results) {
      final hasNet =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      setState(() => _isOnline = hasNet);
    });

    // listen for changes
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      if (hasNet != _isOnline) {
        setState(() => _isOnline = hasNet);
        if (hasNet) {
          _flushOfflinePendingMessages();
        }
      }
    });

    _userStatusSub = socketService.userStatusStream.listen((data) {
      log("👤 User status update received: $data");

      final userId = data['userId']?.toString();
      if (userId == widget.receiverId || userId == widget.datumId) {
        if (data['online'] == false) {
          // Update last seen if provided
          final lastSeenTime =
              data['lastSeen'] ?? data['last_seen'] ?? data['time'];
          if (lastSeenTime != null) {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService().clearActiveConversation();

    _reactionSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _connSub?.cancel();
    _userStatusSub?.cancel();
    _crdtSub?.cancel();
    _saveDebounceTimer?.cancel();
    _saveAllMessages();
    _statusSubscription?.cancel();
    _highlightTimer?.cancel();
    _searchController.dispose();

    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _messagesNotifier.dispose();
    _screenActive = false;
    final unsentText = _messageController.text.trim();
    if (unsentText.isNotEmpty) {
      _saveDraft(unsentText);
    } else {
      _clearDraft();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchMatchIds = [];
        _currentSearchMatchIndex = -1;
      });
      return;
    }

    final matches = _allMessages
        .where((msg) {
          final content = msg['content']?.toString().toLowerCase() ?? '';
          return content.contains(query.toLowerCase()) &&
              msg['is_deleted'] != true &&
              msg['messageStatus'] != 'deleted';
        })
        .map((msg) => _anyId(msg).toString())
        .toList();

    setState(() {
      _searchMatchIds = matches;
      if (matches.isNotEmpty) {
        _currentSearchMatchIndex = 0;
        _scrollToMessageById(matches[0], fetchIfMissing: false);
      } else {
        _currentSearchMatchIndex = -1;
      }
    });
  }

  void _onSearchUp() {
    if (_searchMatchIds.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex =
          (_currentSearchMatchIndex - 1 + _searchMatchIds.length) %
              _searchMatchIds.length;
      _scrollToMessageById(_searchMatchIds[_currentSearchMatchIndex],
          fetchIfMissing: false);
    });
  }

  void _onSearchDown() {
    if (_searchMatchIds.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex =
          (_currentSearchMatchIndex + 1) % _searchMatchIds.length;
      _scrollToMessageById(_searchMatchIds[_currentSearchMatchIndex],
          fetchIfMissing: false);
    });
  }

  void _hideSearchAppBar() {
    setState(() {
      _showSearchAppBar = false;
      _searchController.clear();
      _searchMatchIds = [];
      _currentSearchMatchIndex = -1;
    });
  }

  void _applyCrdtMessages(
    String convoId,
    Map<String, dynamic> messagesMap,
  ) {
    // log("messssssssssssssss $messagesMap");
    if (convoId != widget.convoId) return;

    final handler = MessageHandler(
      currentUserId: currentUserId,
      convoId: widget.convoId,
    );

    /// 1️⃣ Normalize CRDT messages
    final incoming = messagesMap.values
        .where((raw) => raw['isGroupChat'] != true)
        .map((raw) => handler.normalizeMessage(raw))
        .where((m) => m.isNotEmpty)
        .toList();

    if (incoming.isEmpty) return;

    /// 2️⃣ Merge with EXISTING messages (NO CLEAR)
    final Map<String, Map<String, dynamic>> merged = {};

    // ✅ keep existing (REST + socket optimistic)
    for (final m in _allMessages) {
      final id = m['message_id']?.toString();
      if (id != null) merged[id] = m;
    }

    // ✅ CRDT overrides same IDs only
    // ✅ CRDT overrides same IDs always
    for (final m in incoming) {
      final id = m['message_id']?.toString();

      if (id != null && id.isNotEmpty) {
        merged[id] = Map<String, dynamic>.from(m); // ALWAYS override
      }
    }

    /// 3️⃣ Sort Old → New (web behavior)
    final mergedList = merged.values.toList()
      ..sort(
        (a, b) => handler
            .parseTime(a['time'])
            .compareTo(handler.parseTime(b['time'])),
      );

    // final oldTotal = _allMessages.length;
    // log("mergedListsssssssss $mergedList");
    _allMessages
      ..clear()
      ..addAll(mergedList);

// 🔥 FIX: if CRDT brought new messages, show them
//     if (_allMessages.length > oldTotal) {
//       _visibleCount = _allMessages.length;
//     }
    _updateNotifierFromAll();
  }
//   void _applyCrdtMessages(
//     String convoId,
//     Map<String, dynamic> messagesMap,
//   )
//   {
//     // 1️⃣ ID CHECK
//     if (convoId != widget.convoId && convoId != _currentConversationId) {
//       // If we are NOT in a new chat state, return strict.
//       // If we ARE in a new chat state, we proceed to inspect.
//       if (widget.convoId.isNotEmpty || _currentConversationId.isNotEmpty) {
//         return;
//       }
//     }
//
//     final handler = MessageHandler(
//       currentUserId: currentUserId,
//       convoId: _currentConversationId.isNotEmpty
//           ? _currentConversationId
//           : widget.convoId,
//     );
//
//     // 2️⃣ NORMALIZE
//     final incoming = messagesMap.values
//         .where((raw) => raw['isGroupChat'] != true)
//         .map((raw) => handler.normalizeMessage(raw))
//         .where((m) => m.isNotEmpty)
//         .toList();
//
//     if (incoming.isEmpty) return;
//
//     // 🆕 NEW CHAT DETECTION:
//     // If we don't have a conversation ID yet, let's see if these messages belong to us.
//     if (_currentConversationId.isEmpty && widget.convoId.isEmpty) {
//       bool belongsToThisChat = false;
//       for (final m in incoming) {
//         final sender = m['sender'];
//         final receiver = m['receiver'];
//         final sId = (sender is Map ? sender['_id'] : sender)?.toString();
//         final rId = (receiver is Map ? receiver['_id'] : receiver)?.toString();
//
//         // Check if message is participants (Me & Receiver)
//         final isMe = sId == currentUserId;
//         final isOther = sId == widget.receiverId;
//         final receiverIsMe = rId == currentUserId;
//         final receiverIsOther = rId == widget.receiverId;
//
//         // Valid if: (Sender=Me AND Receiver=Other) OR (Sender=Other AND Receiver=Me)
//         if ((isMe && receiverIsOther) || (isOther && receiverIsMe)) {
//           belongsToThisChat = true;
//           break;
//         }
//       }
//
//       if (belongsToThisChat) {
//         debugPrint("🔥 MATCHED NEW CHAT ID: $convoId");
//         _currentConversationId = convoId;
//         socketService.setActiveConversation(convoId);
//       } else {
//         // Did not match participants, so this is just noise from another chat
//         return;
//       }
//     }
//
//     // Double check just in case (should match now if we set it above)
//     if (convoId != widget.convoId && convoId != _currentConversationId) return;
//
//     /// 2️⃣ Merge with EXISTING messages (NO CLEAR)
//     final Map<String, Map<String, dynamic>> merged = {};
//
//     // ✅ keep existing (REST + socket optimistic)
//     for (final m in _allMessages) {
//       final id = m['message_id']?.toString();
//       if (id != null) merged[id] = m;
//     }
//
//     // ✅ CRDT overrides same IDs only
//     for (final m in incoming) {
//       final senderId = m['senderId']?.toString();
//       final id = m['message_id']?.toString();
//
//       // 🔥 IGNORE MY OWN MESSAGES (already handled optimistically)
//       if (senderId == currentUserId) {
//         continue;
//       }
//
//       if (id != null && id.isNotEmpty) {
//         merged[id] = m;
//       }
//     }
//
//     /// 3️⃣ Sort Old → New (web behavior)
//     final mergedList = merged.values.toList()
//       ..sort(
//         (a, b) => handler
//             .parseTime(a['time'])
//             .compareTo(handler.parseTime(b['time'])),
//       );
//
//     final oldTotal = _allMessages.length;
//
//     _allMessages
//       ..clear()
//       ..addAll(mergedList);
//
// // 🔥 FIX: if CRDT brought new messages, show them
//     if (_allMessages.length > oldTotal) {
//       _visibleCount = _allMessages.length;
//     }
//
//     _updateNotifierFromAll();
//   }

  // ------------------ Initialization ------------------
  Future<void> _initializeChat() async {
    //  log("Initializing chat for convoId: ${widget.convoId}");
    socketMessages.clear();
    messages.clear();
    dbMessages.clear();
    _seenMessageIds.clear();
    _visibleCount = _allMessages.length;

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
      final loaded = LocalChatStorage.loadMessages(widget.convoId);
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
        final String? newConversationId =
            _currentConversationId.isEmpty ? null : _currentConversationId;

        _messagerBloc.add(
          SendMessageEvent(
            convoId: newConversationId,
            message: text,
            senderId: currentUserId,
            receiverId: widget.receiverId!,
            replyTo: reply,
            replyMessageId: replyMessageId,
          ),
        );

        final sent = await completer.future;
        await subscription.cancel();

        _replaceTempMessageWithReal(
          tempId: localId,
          realId: sent.messageId,
          status: sent.messageStatus,
        );
      } catch (e, st) {
        log('❌ resend offline msg failed: $e\n$st');
        _updateMessageStatus(localId, 'failed');
      }
    }
  }

  void sendReaction({
    required String emoji,
    required String messageId,
  }) {
    print('Sending reaction: $emoji to messageId: $messageId');
    print('Current convoId: ${widget.convoId}');
    SocketService().emitReaction(
        emoji: emoji,
        roomId: roomId,
        conversationId: widget.convoId,
        messageId: messageId,
        receiverId: widget.receiverId!,
        userId: currentUser!);
  }

  Future<void> _saveDraft(String draft) async {
    if (widget.convoId.isEmpty) return;
    await LocalChatStorage.saveDraftMessage(widget.convoId, draft);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.convoId,
      draftMessage: draft.isEmpty ? null : draft,
    );
    // Trigger UI refresh in chat list
    _chatListBloc.add(UpdateLocalChatList());
  }

  Future<void> _clearDraft() async {
    if (widget.convoId.isEmpty) return;
    await LocalChatStorage.clearDraftMessage(widget.convoId);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.convoId,
      draftMessage: null,
    );
    // Trigger UI refresh in chat list
    _chatListBloc.add(UpdateLocalChatList());
  }

  void _markVisibleMessagesAsRead(List<Map<String, dynamic>> combined) {
    if (!_screenActive) return;

    // 1) Collect all unread messages from other user
    final allUnreadIds = _getUnreadMessageIds(combined);
    //log("🟢 visible unreadIds: $allUnreadIds");

    // 2) Filter out ones we already sent to server
    final idsToSend = allUnreadIds
        .where((id) => id.trim().isNotEmpty && !_alreadyRead.contains(id))
        .toList();

    //  log("🟢 idsToSend after _alreadyRead filter: $idsToSend");

    if (idsToSend.isEmpty) return;

    // 3) Mark them as read locally
    for (final id in idsToSend) {
      // log("🔵 Locally marking message as read: $id");
      _updateMessageStatus(id, 'read');
    }

    // 4) Remember we already sent read for these
    _alreadyRead.addAll(idsToSend);

    // 5) Send to socket (NO filtering here)
    _sendReadReceipts(idsToSend);
  }

  void _updateNotifierFromAll() {
    final int total = _allMessages.length;

    if (total == 0) {
      _messagesNotifier.value = const [];
      return;
    }

    final visibleSlice =
        _allMessages.map((msg) => Map<String, dynamic>.from(msg)).toList();

    // ✅ immutable list
    _messagesNotifier.value =
        List<Map<String, dynamic>>.unmodifiable(visibleSlice);

    debugPrint('📊 UI now showing: ${_messagesNotifier.value.length} messages');
  }

  void _debugPrintMessages() {
    debugPrint('🔍 DEBUG MESSAGE LISTS:');
    debugPrint('_allMessages: ${_allMessages.length}');
    debugPrint('dbMessages: ${dbMessages.length}');
    debugPrint('socketMessages: ${socketMessages.length}');
    debugPrint('messages: ${messages.length}');
    debugPrint('_messagesNotifier: ${_messagesNotifier.value.length}');

    if (_allMessages.isNotEmpty) {
      debugPrint('Last 3 messages in _allMessages:');
      for (var i = math.max(0, _allMessages.length - 3);
          i < _allMessages.length;
          i++) {
        final msg = _allMessages[i];
        debugPrint(
            '  [$i] id: ${msg['message_id']}, content: "${msg['content']?.toString().substring(0, msg['content']?.toString().length ?? 0)}", sender: ${msg['senderId']}');
      }
    }
  }

  void _handleIncomingRawMessage(Map<String, dynamic> raw, {String? event}) {
    try {
      if (raw['isGroupChat'] == true) return;
      final normalized = normalizeMessage(raw);
      if (normalized.isEmpty) {
        debugPrint('⚠️ normalizeMessage returned empty');
        return;
      }

      final realId = normalized['message_id']?.toString();
      if (realId == null || realId.isEmpty) {
        debugPrint('⚠️ No message ID in normalized message');
        return;
      }

      final senderId = normalized['senderId']?.toString();
      final content = normalized['content']?.toString() ?? '';
      final status = normalized['messageStatus']?.toString() ?? '';

      debugPrint(
          '📥 Incoming message: id=$realId, sender=$senderId, content="$content", status="$status"');
      // Check if we already have this message
      final existingIndex = _allMessages.indexWhere((m) {
        final mid =
            (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
        return mid == realId;
      });

      // If sender is current user, try to find and replace temp message
      if (senderId == currentUserId) {
        bool foundTemp = false;

        // Look for temp message to replace
        for (int i = 0; i < _allMessages.length; i++) {
          final m = _allMessages[i];
          final isTemp = m['_isTempMessage'] == true;
          final tempContent = (m['content'] ?? '').toString();
          final tempFileName = (m['fileName'] ?? '').toString();

          // 🆕 Enhanced matching: content for text, fileName for files
          final bool contentMatch =
              tempContent == content && content.isNotEmpty;
          final bool fileMatch = tempFileName.isNotEmpty &&
              tempFileName == (normalized['fileName'] ?? '').toString();

          if (isTemp &&
              m['senderId'] == currentUserId &&
              (contentMatch || fileMatch) &&
              (m['messageStatus'] == 'sending' ||
                  m['messageStatus'] == 'pending_offline')) {
            debugPrint(
                '🔄 Replacing temp message at index $i with real id $realId');

            // Keep important local data
            final updated = Map<String, dynamic>.from(normalized);
            updated['_isTempMessage'] = false;
            updated['_isOptimistic'] = false;

            // Preserve locals
            if (m['_localHasReply'] == true) {
              updated['_localHasReply'] = true;
              updated['reply'] = m['reply'] ?? m['_localReply'];
              updated['reply_message_id'] = m['reply_message_id'];
            }

            _allMessages[i] = updated;
            foundTemp = true;
            break;
          }
        }

        // If no temp found, just add the message
        if (!foundTemp && existingIndex == -1) {
          debugPrint('➕ Adding my own message (no temp found)');
          _allMessages.add(normalized);
        } else if (existingIndex != -1) {
          _allMessages[existingIndex] = normalized;
        }
      }
      // Message from other user
      else if (existingIndex == -1) {
        debugPrint('➕ Adding message from other user');
        _allMessages.add(normalized);
      } else {
        debugPrint('♻️ Updating existing message');
        _allMessages[existingIndex] = normalized;
      }

      // Sort messages chronologically
      _allMessages.sort((a, b) {
        try {
          final ta = _parseTime(a['time']);
          final tb = _parseTime(b['time']);
          return ta.compareTo(tb);
        } catch (e) {
          return 0;
        }
      });

      _visibleCount = _allMessages.length;

      // Update the UI
      _updateNotifierFromAll();

      // Debug
      _debugPrintMessages();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
      });
    } catch (e, st) {
      debugPrint('❌ Error in _handleIncomingRawMessage: $e');
      debugPrint('Stack: $st');
    }
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

    _setupMessageListener();
    _setupReactionListener();

    if (mounted) setState(() {});
  }

  bool _hasReplyForMessage(Map<String, dynamic> message) {
    if (message == null) return false;

    if (message['_localHasReply'] == true) return true;

    final replyRaw = message['reply'];
    Map<String, dynamic>? reply;
    if (replyRaw is Map) {
      reply = Map<String, dynamic>.from(replyRaw);
    } else if (replyRaw is String) {
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

      final replyContent =
          (reply['replyContent'] ?? reply['content'] ?? reply['message'] ?? '')
              .toString();

      final hasMedia = (reply['originalUrl'] ??
                  reply['fileUrl'] ??
                  reply['imageUrl'] ??
                  reply['replyUrl'] ??
                  reply['reply_url'] ??
                  reply['thumbnailUrl'] ??
                  reply['thumbnail_url'])
              ?.toString()
              .isNotEmpty ==
          true;

      if ((id != null && id.isNotEmpty) ||
          replyContent.isNotEmpty ||
          hasMedia) {
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

  /// Collect reactions for a message id from all local lists and merge them
  List<Map<String, dynamic>> _collectMergedReactionsForMessage(
      String messageId) {
    final Map<String, Map<String, dynamic>> byUser = {};

    List<List<Map<String, dynamic>>> sources = [
      dbMessages,
      messages,
      socketMessages
    ];

    for (final list in sources) {
      for (final msg in list) {
        final mid = (msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? '')
            .toString();
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
            'reacted_at': (r['reacted_at'] ??
                    r['createdAt'] ??
                    DateTime.now().toIso8601String())
                .toString(),
          };
        }
      }
    }

    // Return list of reactions
    return byUser.values.toList();
  }

  void _setupMessageListener() {
    if (currentUserId.isEmpty || widget.datumId == null) return;

    _messagerBloc.add(ListenToMessages(
        senderId: currentUserId, receiverId: widget.receiverId ?? ""));
    _statusSubscription ??=
        socketService.statusUpdateStream.listen((statusUpdate) {
      if (!mounted) return;

      final dynamic rawStatus =
          statusUpdate['messageStatus'] ?? statusUpdate['status'];
      final status = (rawStatus ?? '').toString().trim();
      if (status.isEmpty) return;

      final ids = statusUpdate['messageIds'] ??
          statusUpdate['singleMessageId'] ??
          statusUpdate['messageId'];

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
            final mid = _normalizeMessageIdForApi(
                (m['message_id'] ?? m['messageId'] ?? '').toString());
            final incomingIdNormalized = _normalizeMessageIdForApi(mid);
            return mid == incomingIdNormalized;
          },
          orElse: () => {},
        );

        final senderId = (local.isNotEmpty)
            ? (local['senderId'] ?? local['sender']?['_id'] ?? local['sender'])
                ?.toString()
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

    //messgae deleted listener
    _messageDeletedSubscription =
        socketService.messageDeletedStream.listen((messageId) {
      log("🗑️ Received message_deleted event for: $messageId");
      _markMessagesAsDeleted([messageId], deleteFor: 'everyone');
    });
  }

  void _setupReactionListener() {
    _reactionSubscription = socketService.reactionStream.listen((reaction) {
      _updateMessageWithReaction(reaction);
    });
  }

  // Update the normalizeMessage function to handle LORRO data structure
  Map<String, dynamic> normalizeMessage(dynamic rawMsg) {
    if (rawMsg == null) return {};

    // Handle LORRO specific structure
    if (rawMsg is Map) {
      // Check if it's a LORRO-style message
      if (rawMsg.containsKey('v') && rawMsg.containsKey('ts')) {
        log('⚠️ Detected LORRO vector message format');
        // Extract actual message data from LORRO structure
        final content = rawMsg['v'] is Map ? rawMsg['v'] : rawMsg;
        return _normalizeStandardMessage(content);
      }
    }

    return _normalizeStandardMessage(rawMsg);
  }

  Map<String, dynamic> _normalizeStandardMessage(dynamic rawMsg) {
    if (rawMsg == null) return {};

    final m = <String, dynamic>{};

    // ================= EXTRACT ID =================
    String? canonicalId;
    for (final k in ['message_id', 'messageId', 'id', '_id', 'messageID']) {
      final v = rawMsg[k];
      if (v != null && v.toString().isNotEmpty) {
        canonicalId = v.toString();
        break;
      }
    }

    // If no ID found, generate one for debugging
    if (canonicalId == null) {
      canonicalId = 'no_id_${DateTime.now().millisecondsSinceEpoch}';
      log('⚠️ Message has no ID, generated: $canonicalId');
    }

    m['message_id'] = rawMsg["message_id"];
    m['id'] = rawMsg["message_id"];
    m['messageId'] = rawMsg["message_id"];
    m['_id'] = rawMsg["message_id"];

    // ================= EXTRACT CONTENT =================
    m['content'] = (rawMsg['content'] ?? rawMsg['content'] ?? '').toString();

    // Check for LORRO content structure
    if (m['content'].isEmpty && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        m['content'] = (v['content'] ?? v['content'] ?? '').toString();
      }
    }

    // ================= EXTRACT TIME =================
    dynamic timeRaw =
        rawMsg['time'] ?? rawMsg['createdAt'] ?? rawMsg['created_at'];

    // Handle LORRO timestamp structure
    if (timeRaw == null && rawMsg is Map && rawMsg.containsKey('ts')) {
      final ts = rawMsg['ts'];
      if (ts is Map && ts.containsKey('wallTime')) {
        timeRaw = ts['wallTime'];
      } else if (ts is int) {
        // Convert milliseconds to ISO string
        timeRaw = DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String();
      }
    }

    m['time'] = timeRaw;
    //////////
    final List<Map<String, dynamic>> reactions = [];
    final Map<String, Map<String, dynamic>> unique = {};

// from reactions array
    if (rawMsg['reactions'] is List) {
      for (final r in rawMsg['reactions']) {
        if (r is Map) {
          final user = r['user'] ?? {};
          final uid = user['_id']?.toString() ?? r['userId']?.toString();
          if (uid == null || uid.isEmpty) continue;

          unique[uid] = {
            'emoji': r['emoji'],
            'reacted_at': r['reacted_at'],
            'user': {
              '_id': uid,
              'first_name': user['first_name'] ?? '',
              'last_name': user['last_name'] ?? '',
            }
          };
        }
      }
    }

// from properties.reaction (SOCKET CASE)
    if (rawMsg['properties'] is List) {
      for (final p in rawMsg['properties']) {
        if (p is Map && p['reaction'] != null) {
          final r = p['reaction'];
          final uid = p['member_id']?.toString();
          if (uid == null || uid.isEmpty) continue;

          unique[uid] = {
            'emoji': r['emoji'],
            'reacted_at': r['reacted_at'],
            'user': {
              '_id': uid,
              'first_name': '',
              'last_name': '',
            }
          };
        }
      }
    }

    reactions.addAll(unique.values);
    m['reactions'] = reactions;

    // ================= EXTRACT SENDER =================
    dynamic senderRaw = rawMsg['sender'];
    String? senderId = rawMsg['senderId']?.toString();

    // Handle LORRO sender structure
    if (senderRaw == null && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        senderRaw = v['sender'];
        senderId = v['senderId']?.toString();
      }
    }

    if (senderRaw is Map) {
      senderId ??= senderRaw['_id']?.toString() ??
          senderRaw['id']?.toString() ??
          senderRaw['userId']?.toString();

      senderRaw = {
        '_id': senderId,
        'id': senderId,
        'first_name': senderRaw['first_name'] ?? senderRaw['firstName'] ?? '',
        'last_name': senderRaw['last_name'] ?? senderRaw['lastName'] ?? '',
      };
    } else if (senderRaw != null && senderId == null) {
      senderId = senderRaw.toString();
      senderRaw = {'_id': senderId, 'id': senderId};
    } else if (senderRaw == null && senderId != null) {
      senderRaw = {'_id': senderId, 'id': senderId};
    }

    // Also check 'from' field
    if ((senderId == null || senderId.isEmpty) && rawMsg['from'] != null) {
      senderId = rawMsg['from'].toString();
      senderRaw = {'_id': senderId, 'id': senderId};
    }

    m['sender'] = senderRaw;
    m['senderId'] = senderId ?? '';
    m['from'] = senderId ?? '';

    // ================= STATUS =================
    m['messageStatus'] = (rawMsg['messageStatus'] ??
            rawMsg['status'] ??
            rawMsg['deliveryStatus'] ??
            'sent')
        .toString();

    final rawReply = rawMsg['reply'] ?? rawMsg['repliedMessage'];
    String? originalKey = rawMsg['originalKey'];

    if (rawReply is Map) {
      final String? replyUrl = rawReply['replyUrl'] ??
          rawReply['originalUrl'] ??
          rawReply['fileUrl'];
      log("rawReply['replyContent'] ${rawReply['replyContent']}");
      final String? fileName = rawReply['fileName'];
      final String? contentType =
          rawReply['ContentType'] ?? rawReply['fileType'];

      m['reply'] = {
        'message_id': rawReply['reply_message_id'],
        'reply_message_id': rawReply['reply_message_id'],
        'content': rawReply['replyContent'] ?? '',
        'replyContent': rawReply['replyContent'] ?? '',
        'originalUrl': replyUrl,
        'imageUrl': replyUrl,
        'fileUrl': replyUrl,
        'fileName': fileName,
        'fileType': contentType,
      };

      m['isReplyMessage'] = true;
    }
    // ================= DELETED STATUS =================
    m['is_deleted'] = rawMsg['is_deleted'] == true;
    m['isForwarded'] = rawMsg['isForwarded'];
    m['is_grouped_message'] = rawMsg['is_grouped_message'];
    m['group_message_id'] = rawMsg['group_message_id'];
    m['originalKey'] = originalKey;
    m['mimeType'] = rawMsg['mimeType'];

    // ================= MEDIA =================
    String? imageUrl = rawMsg['imageUrl'];
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      imageUrl = rawMsg['thumbnailUrl'];
    }

    // Check LORRO structure
    if ((imageUrl == null || imageUrl.isEmpty) && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        imageUrl = v['imageUrl'] ?? v['thumbnailUrl'];
      }
    }

    String? originalUrl = rawMsg['originalUrl'];
    if (originalUrl == null || originalUrl.toString().isEmpty) {
      originalUrl = rawMsg['fileUrl'];
    }

    // Check LORRO structure
    if ((originalUrl == null || originalUrl.isEmpty) && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        originalUrl = v['originalUrl'] ?? v['fileUrl'];
      }
    }

    m['imageUrl'] = imageUrl;
    m['originalUrl'] = originalUrl;
    m['fileUrl'] = rawMsg['fileUrl'] ?? originalUrl;
    m['fileName'] = rawMsg['fileName'] ?? rawMsg['filename'] ?? rawMsg['name'];
    if (m['fileName'] == null && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        m['fileName'] = v['fileName'] ?? v['filename'] ?? v['name'];
      }
    }

    // 🔥 Fix: Preserve ContentType and duration for Audio
    m['ContentType'] = rawMsg['ContentType'] ?? rawMsg['contentType'];
    if (m['ContentType'] == null && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        m['ContentType'] = v['ContentType'] ?? v['contentType'];
      }
    }

    // 🔥 NEW: Robust inference if ContentType is still missing
    if (m['ContentType'] == null || m['ContentType'].toString().isEmpty) {
      final fname = (m['fileName'] ?? '').toString().toLowerCase();
      final furl =
          (m['fileUrl'] ?? m['originalUrl'] ?? '').toString().toLowerCase();
      if (fname.contains('audio_') ||
          fname.endsWith('.m4a') ||
          fname.endsWith('.mp3') ||
          fname.endsWith('.opus') ||
          furl.contains('/audio/')) {
        m['ContentType'] = 'audio';
        log('🎵 Inferred ContentType: audio for ${m['message_id']}');
      }
    }

    m['duration'] = rawMsg['duration'] ??
        rawMsg['audioDuration'] ??
        rawMsg['videoDuration'];
    if (m['duration'] == null && rawMsg is Map) {
      final v = rawMsg['v'];
      if (v is Map) {
        m['duration'] =
            v['duration'] ?? v['audioDuration'] ?? v['videoDuration'];
      }
    }

// ================= EXTRACT REPLY DATA =================
    // Ensure reply fields are set on snapshot load

    final rawReplyId = rawMsg['reply_message_id'] ?? rawMsg['replyMessageId'];
    final rawReplyContent = rawMsg['replyContent'];
    final rawIsReplyMessage = rawMsg['isReplyMessage'];

    // Set isReplyMessage flag
    if (rawIsReplyMessage == true ||
        rawReply != null ||
        rawReplyId != null ||
        rawReplyContent != null) {
      m['isReplyMessage'] = true;
    }

    if (m['message_id'] == null) {
      final sender = m['senderId'] ?? '';
      final time = m['time'] ?? '';
      final content = m['content'] ?? '';
      final media = m['fileUrl'] ?? m['imageUrl'] ?? '';

      m['forwardFingerprint'] = '$sender|$time|$content|$media';
    }

    // Set reply object if present
    if (rawReply is Map) {
      m['reply'] = {
        'reply_message_id':
            rawReply['reply_message_id'] ?? rawReply['message_id'],
        'message_id': rawReply['reply_message_id'] ?? rawReply['message_id'],
        'id': rawReply['reply_message_id'] ?? rawReply['message_id'],
        'replyContent': rawReply['replyContent'] ?? rawReply['content'] ?? '',
        'content': rawReply['replyContent'] ?? rawReply['content'] ?? '',
        'fileName': rawReply['fileName'],
        'fileType': rawReply['fileType'] ?? rawReply['ContentType'],
        'group_message_id': rawReply['isGroupedMessageId'],
        'is_grouped_message': rawReply['isGroupedMessage'] ?? false,
        'originalUrl': rawReply['originalUrl'],
        'imageUrl': rawReply['imageUrl'],
        'fileUrl': rawReply['fileUrl'],
      };
    }

    // Set reply_message_id if present
    if (rawReplyId != null) {
      m['reply_message_id'] = rawReplyId;
      m['replyMessageId'] = rawReplyId;
    }

    // Set replyContent if present
    if (rawReplyContent != null) {
      m['replyContent'] = rawReplyContent.toString();
    }

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
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
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

  void _updateNotifier({bool isInitialLoad = false}) {
    final full = _getCombinedMessages();
    final oldTotal = _allMessages.length;

    _allMessages
      ..clear()
      ..addAll(full);

    final newTotal = _allMessages.length;

    if (isInitialLoad || _visibleCount == 0) {
      _visibleCount = newTotal >= _initialVisible ? _initialVisible : newTotal;
    } else {
      // If messages were added (sent/received/paginated), increase visibleCount
      final diff = newTotal - oldTotal;
      if (diff > 0) {
        _visibleCount += diff;
      }
      // Ensure it doesn't exceed total
      if (_visibleCount > newTotal) _visibleCount = newTotal;
    }

    _updateNotifierFromAll();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.datumId == null) {
      return;
    }
    print('🔐 private chat screen : ${widget.convoId}');

    final reply = _replyMessage;
    log("reeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee $reply");
    final text = _messageController.text.trim();

    // ---------- READ RECEIPTS ----------
    final visibleMessages = _messagesNotifier.value;
    final unreadIds = _getUnreadMessageIds(visibleMessages);
    if (unreadIds.isNotEmpty) {
      _sendReadReceipts(unreadIds);
    }

    // ---------- REPLY INFO ----------
    final String? replyMessageId = reply == null
        ? null
        : (reply['message_id'] ?? reply['messageId'] ?? reply['id'])
            ?.toString();

    final String? replyGroupMessageId =
        reply == null ? null : reply['group_message_id']?.toString();

    final bool replyIsGroupMessage =
        reply != null && reply['is_grouped_message'] == true;

    final replyPayload = reply == null
        ? null
        : <String, dynamic>{
            'id': replyMessageId,
            'message_id': replyMessageId,
            'reply_message_id': replyMessageId,
            'group_message_id': reply['group_message_id'],
            'is_grouped_message': reply['group_message_id'] != null,
            'content': (reply['content'] ?? reply['message'] ?? '').toString(),
            'replyContent': _replyPreview?["content"] ??
                (reply['content'] ?? reply['message'] ?? '').toString(),
            'originalUrl': reply['originalUrl'] ??
                reply['fileUrl'] ??
                reply['imageUrl'] ??
                '',
            'imageUrl': reply['imageUrl'] ?? '',
            'fileUrl': reply['fileUrl'] ?? '',
            'fileName': reply['fileName'] ?? '',
            'fileType':
                (reply['fileType'] ?? reply['mimeType'] ?? '').toString(),
            'imageCount': _replyPreview?['imageCount'],
            'videoCount': _replyPreview?['videoCount'],
          };

    // ---------- TEMP MESSAGE ----------
    final localId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final bool canSendNow = _isOnline && socketService.isConnected;

    final Map<String, dynamic> localMessage = {
      'message_id': localId,
      'id': localId,
      '_id': localId,
      'content': text,
      'sender': {
        '_id': currentUserId,
        'id': currentUserId,
        'first_name': widget.firstname ?? '',
        'last_name': widget.lastname ?? '',
      },
      'senderId': currentUserId,
      'from': currentUserId,
      'receiver': {'_id': widget.datumId},
      'receiverId': widget.receiverId,
      'time': DateTime.now().toIso8601String(),
      'messageStatus': canSendNow ? 'sending' : 'pending_offline',
      'isReplyMessage': replyPayload != null,
      if (replyPayload != null) 'reply': replyPayload,
      if (replyPayload != null) 'reply_message_id': replyMessageId,
      '_isTempMessage': true,
      '_isOptimistic': true,
      '_isSentByMe': true,
    };

    if (replyPayload != null) {
      localMessage['_localHasReply'] = true;
      localMessage['_localReply'] = Map<String, dynamic>.from(replyPayload);
    }

    // =========================================================
    // 🔥 SINGLE SOURCE OF TRUTH — ADD TEMP MESSAGE
    // =========================================================
    _allMessages.add(localMessage);

    _allMessages.sort(
      (a, b) => _parseTime(a['time']).compareTo(_parseTime(b['time'])),
    );

    _visibleCount = _allMessages.length;
    _updateNotifierFromAll();

    //_audioPlayerService.playMessageSentSound();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _seenMessageIds.add(localId);

    // ---------- RESET INPUT ----------
    _messageController.clear();
    setState(() {});
    await _clearDraft();
    _replyMessage = null;

    // ---------- OFFLINE ----------
    if (!canSendNow) {
      _offlineQueue.add({
        'text': text,
        'reply': reply,
        'replyMessageId': replyMessageId,
        'localId': localId,
      });
      return;
    }

    // ---------- SEND TO SERVER ----------
    try {
      final completer = Completer<Message>();

      final sub = _messagerBloc.stream.listen((state) {
        if (state is MessageSentSuccessfully) {
          completer.complete(state.sentMessage);
        }
      });
      log(" _replyPreview ${_replyPreview}");
      _messagerBloc.add(
        SendMessageEvent(
            convoId: _currentConversationId,
            message: text,
            senderId: currentUserId,
            receiverId: widget.receiverId!,
            replyTo: reply,
            replyMessageId: replyMessageId,
            // replyGroupMessageId: replyGroupMessageId,
            //replyIsGroupMessage: replyIsGroupMessage,
            replyGroupMessageCount: _replyPreview?["content"]),
      );

      final sent = await completer.future;
      await sub.cancel();
      _replyPreview = null;
      _replaceTempMessageWithReal(
        tempId: localId,
        realId: sent.messageId,
        status: sent.messageStatus,
      );
    } catch (e, st) {
      log('❌ send message error: $e\n$st');
      _updateMessageStatus(localId, 'failed');
    }
  }

  void _replaceTempMessageWithReal({
    required String tempId,
    required String realId,
    required String status,
  }) {
    bool changed = false;

    void updateList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final mid =
            (m['message_id'] ?? m['messageId'] ?? m['id'] ?? m['_id'] ?? '')
                .toString();

        if (mid == tempId) {
          final copy = Map<String, dynamic>.from(m);

          // 🔥 preserve reply info
          if (copy['reply'] != null || copy['reply_message_id'] != null) {
            copy['_localHasReply'] = true;
            try {
              copy['_localReply'] =
                  Map<String, dynamic>.from(copy['reply'] ?? {});
            } catch (_) {
              copy['_localReply'] = copy['reply'];
            }
          }

          // 🔥 preserve grouping
          if (copy['group_message_id'] != null) {
            copy['group_message_id'] = copy['group_message_id']?.toString();
            copy['is_grouped_message'] = copy['is_grouped_message'] == true;
          }

          // 🔥 replace temp id with real id (ALL fields)
          copy['message_id'] = realId;
          copy['messageId'] = realId;
          copy['id'] = realId;
          copy['_id'] = realId;

          // 🔥 update status
          copy['messageStatus'] = status;
          copy['status'] = status;

          // 🔥 mark no longer temp
          copy['_isTempMessage'] = false;
          copy['_isOptimistic'] = false;

          list[i] = copy;
          changed = true;
          break;
        }
      }
    }

    // 🔥 UPDATE ALL STORES
    updateList(socketMessages);
    updateList(messages);
    updateList(dbMessages);
    updateList(_allMessages);
    // _audioPlayerService.playMessageSentSound();

    if (changed) {
      _seenMessageIds.remove(tempId);
      _seenMessageIds.add(realId);

      // 🔥 rebuild UI from single source of truth
      _updateNotifierFromAll();
      _scheduleSaveMessages();
    }
  }

  String _anyId(Map<String, dynamic> m) {
    final candidates = [
      m['message_id'],
      m['messageId'],
      m['id'],
      m['_id'],
      m['reply_message_id'],
      m['replyMessageId'],
      if (m['reply'] is Map) m['reply']['reply_message_id'],
      if (m['reply'] is Map) m['reply']['message_id'],
      if (m['reply'] is Map) m['reply']['id'],
      if (m['repliedMessage'] is Map) m['repliedMessage']['reply_message_id'],
      if (m['repliedMessage'] is Map) m['repliedMessage']['message_id'],
      if (m['repliedMessage'] is Map) m['repliedMessage']['id'],
    ];

    for (final c in candidates) {
      if (c != null && c.toString().isNotEmpty) {
        return c.toString();
      }
    }
    return '';
  }

  Future<bool> _scrollToMessageById(
    String messageId, {
    bool fetchIfMissing = false,
  }) async {
    final ctx = _messageContexts[messageId];

    if (ctx != null && ctx.mounted) {
      _highlightAndScrollToContext(ctx, messageId);
      return true;
    }

    final combinedMessages = _messagesNotifier.value;
    final int msgIndex = combinedMessages.indexWhere((m) {
      final mid =
          (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
      return mid == messageId;
    });

    if (msgIndex != -1) {
      final int listIndex = combinedMessages.length - 1 - msgIndex;

      final double estimatedOffset =
          _estimateScrollOffset(listIndex, combinedMessages);

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(estimatedOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ));
      }

      await Future.delayed(const Duration(milliseconds: 50));

      final targetCtx = _messageContexts[messageId];
      if (targetCtx != null && targetCtx.mounted) {
        _highlightAndScrollToContext(targetCtx, messageId);
        return true;
      }

      double currentEstimate = estimatedOffset;
      for (int attempt = 0; attempt < 3; attempt++) {
        await Future.delayed(const Duration(milliseconds: 50));

        final targetCtx = _messageContexts[messageId];
        if (targetCtx != null && targetCtx.mounted) {
          _highlightAndScrollToContext(targetCtx, messageId);
          return true;
        }

        int? closestVisibleIndex;
        double minDiff = double.infinity;

        for (final entry in _messageContexts.entries) {
          final ctx = entry.value;
          if (ctx.mounted) {
            final idx = combinedMessages.indexWhere((m) {
              final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '')
                  .toString();
              return mid == entry.key;
            });

            if (idx != -1) {
              final diff = (idx - msgIndex).abs().toDouble();
              if (diff < minDiff) {
                minDiff = diff;
                closestVisibleIndex = idx;
              }
            }
          }
        }

        if (closestVisibleIndex != null) {
          final int indexDiff = msgIndex - closestVisibleIndex;

          double correction = 0;
          final int start = indexDiff > 0 ? closestVisibleIndex : msgIndex;
          final int end = indexDiff > 0 ? msgIndex : closestVisibleIndex;

          for (int k = start; k < end; k++) {
            correction += _estimateMessageHeight(combinedMessages[k]);
          }

          if (indexDiff < 0) correction = -correction;

          currentEstimate += correction;
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(currentEstimate.clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ));
          }
        } else {
          break;
        }
      }

      final finalCtx = _messageContexts[messageId];
      if (finalCtx != null && finalCtx.mounted) {
        _highlightAndScrollToContext(finalCtx, messageId);
        return true;
      }

      _highlightMessage(messageId);
      return true;
    }

    if (fetchIfMissing) {
      _triggerServerFetch();
      await Future.delayed(const Duration(milliseconds: 300));
      return _scrollToMessageById(messageId);
    }

    return false;
  }

  void _highlightAndScrollToContext(BuildContext ctx, String messageId) {
    if (!ctx.mounted) return;

    _highlightMessage(messageId);

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.5,
    );
  }

  double _estimateScrollOffset(
      int listIndex, List<Map<String, dynamic>> messages) {
    double offset = 0.0;
    for (int i = 0; i < listIndex; i++) {
      final realIndex = messages.length - 1 - i;
      if (realIndex >= 0 && realIndex < messages.length) {
        offset += _estimateMessageHeight(messages[realIndex]);
      }
    }
    return offset;
  }

  double _estimateMessageHeight(Map<String, dynamic> message) {
    double height = 60.0;

    final content = (message['content'] ?? '').toString();
    if (content.isNotEmpty) {
      height += (content.length / 40) * 20.0;
    }

    // Media
    if ((message['imageUrl'] != null &&
            message['imageUrl'].toString().isNotEmpty) ||
        (message['localImagePath'] != null &&
            message['localImagePath'].toString().isNotEmpty) ||
        (message['fileUrl'] != null &&
            message['fileUrl'].toString().isNotEmpty)) {
      height += 250.0;
    }

    // Reply preview
    if (message['isReplyMessage'] == true || message['reply'] != null) {
      height += 60.0;
    }

    return height;
  }

  void _highlightMessage(String messageId) {
    setState(() => _highlightedMessageId = messageId);

    _highlightTimer?.cancel();
    _highlightTimer = Timer(
      const Duration(milliseconds: 1500),
      () {
        if (!mounted) return;
        setState(() => _highlightedMessageId = null);
      },
    );
  }

  // ------------------ Send image (optimistic) ------------------

  Future<void> _openCamera() async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (file == null) return;

      // Open preview screen (like Gallery does)
      final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (_) => MediaPreviewScreen(
            files: [file],
            conversationId: widget.convoId,
            senderId: currentUserId,
            receiverId: widget.receiverId!,
            isGroupChat: false,
          ),
        ),
      );

      // Add messages to UI when user confirms send
      if (localMessages != null && localMessages.isNotEmpty) {
        setState(() {
          socketMessages.addAll(localMessages);
          for (var msg in localMessages) {
            final id = (msg['message_id'] ?? '').toString();
            if (id.isNotEmpty) _seenMessageIds.add(id);
          }
        });

        _updateNotifier();
        _scheduleSaveMessages();

        // _audioPlayerService.playMessageSentSound();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      log('❌ Error opening camera: $e');
      Messenger.alert(msg: "Could not open camera.");
    }
  }

  // ------------------ Incoming messages ------------------
  void onMessageReceived(Map<String, dynamic> data) {
    final event = data['event'];

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
    debugPrint(
        'INCOMING raw message: $data'); // rawMsg is what you received from server/socket
    debugPrint('INCOMING raw reply field: ${data['reply']}');
    debugPrint(
        'INCOMING reply_message_id: ${data['reply_message_id'] ?? data['replyMessageId'] ?? data['reply_to']}');

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
    if (userId == currentUserId) {
      return; // you already optimistically updated locally
    }

    String normalizeId(dynamic id) => id?.toString().trim() ?? '';

    bool updated = false;

    void updateList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final msg = list[i];
        final msgId = normalizeId(
            msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? '');
        if (msgId != messageId) continue;

        final existing = _extractReactions(msg['reactions'] ?? msg['reaction']);
        // Build incoming single reaction map
        final incoming = <Map<String, dynamic>>[
          {
            'emoji': emoji,
            'userId': userId,
            'user': {
              '_id': userId,
              'first_name': firstName ?? '',
              'last_name': lastName ?? ''
            },
            'reacted_at': DateTime.now().toIso8601String(),
          }
        ];

        List<Map<String, dynamic>> merged;
        if (isRemoval) {
          // remove any reaction from this user
          merged = existing
              .where((r) =>
                  (r['userId']?.toString() ??
                      r['user']?['_id']?.toString() ??
                      '') !=
                  userId)
              .toList();
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
            Map<String, dynamic>.from(reactionData['reaction'] as Map),
          ];
        } else {
          rawList = [reactionData];
        }
      }

      for (final r in rawList) {
        final emoji = r['emoji']?.toString();
        final msgId = r['messageId']?.toString() ?? r['message_id']?.toString();

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

        final isRemoval = r['isRemoval'] == true ||
            r['removed'] == true ||
            r['remove'] == true;

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

  void _updateMessageStatus(String messageId, String status,
      {bool localMark = false}) {
    //log("🔄 _updateMessageStatus called for $messageId → $status (localMark=$localMark)");

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
    //log("🟢 _sendReadReceipts called with: $messageIds");

    // helper: try to find message locally by id
    Map<String, dynamic>? _findLocalMessageById(String id) {
      if (id.trim().isEmpty) return null;
      final combined = _getCombinedMessages();
      try {
        return combined.firstWhere((m) {
          final mid =
              (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';
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
          ? (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender'])
              ?.toString()
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

    //log("🟢 unique read IDs after filter: $unique");

    if (unique.isEmpty) {
      //log("ℹ️ _sendReadReceipts: nothing to send (empty after filter).");
      return;
    }

    // remember we already sent these
    _alreadyRead.addAll(unique);

    // Locally mark read only for messages we can locate & that are NOT ours
    for (final id in unique) {
      final msg = _findLocalMessageById(id);
      final senderId = (msg != null && msg.isNotEmpty)
          ? (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender'])
              ?.toString()
          : null;

      if (senderId != null && senderId != currentUserId) {
        // log("🔵 Locally marking message as read: $id");
        _updateMessageStatus(id, 'read', localMark: true);
      } else {
        log("ℹ️ Not locally marking (not found or message is mine): $id");
      }
    }

    final computedRoomId =
        socketService.generateRoomId(currentUserId, widget.datumId ?? '');
    socketService.sendReadReceipts(
      messageIds: unique,
      conversationId: widget.convoId,
      roomId: computedRoomId,
    );
  }

  Future<void> _fetchMessages() async {
    _messagerBloc.add(FetchMessagesEvent(
        convoId: widget.convoId, page: _currentPage, limit: _initialLimit));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // In a REVERSED list:
    // pixels = 0 is BOTTOM (newest)
    // pixels = maxScrollExtent is TOP (oldest)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final total = _allMessages.length;

      log('🔍 Scroll at top - total: $total, visible: $_visibleCount, hasNextPage: $_hasNextPage, isLoading: $_isLoadingMore');

      // 1. Client-side pagination: Show more from local cache
      if (_visibleCount < total && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        // Increase visible window locally first for snappier UI
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          final newVisibleCount = (_visibleCount + _pageStep).clamp(0, total);

          setState(() {
            _visibleCount = newVisibleCount;
            _isLoadingMore = false;
          });

          _updateNotifierFromAll();
          log('📜 Client Pagination: Loaded more messages. Now showing $_visibleCount of $total (local cache)');

          // ✅ AUTO-FETCH: If we just showed ALL local messages AND there's more on server
          if (_visibleCount >= total && _hasNextPage) {
            log('🔄 Auto-triggering server fetch after client pagination');
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted || _isLoadingMore) return;
              _triggerServerFetch();
            });
          }
        });
      }
      // 2. Server-side pagination: User scrolled with all local messages already shown
      else if (_visibleCount >= total && _hasNextPage && !_isLoadingMore) {
        _triggerServerFetch();
      }
    }
  }

  void _triggerServerFetch() {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    log('📡 Server Pagination: Fetching page $_currentPage from server... (hasNextPage: $_hasNextPage)');

    // Save current max scroll extent to maintain position after load
    _prevScrollExtentBeforeLoad = _scrollController.position.maxScrollExtent;

    _messagerBloc.add(
      FetchMessagesEvent(
        convoId: widget.convoId,
        page: _currentPage,
        limit: _initialLimit,
      ),
    );
  }

  List<Map<String, dynamic>> _inferGrouping(
      List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return messages;

    messages
        .sort((a, b) => _parseTime(a['time']).compareTo(_parseTime(b['time'])));

    for (int i = 0; i < messages.length; i++) {
      final currentMsg = messages[i];

      // already grouped? skip
      if (currentMsg['is_grouped_message'] == true &&
          currentMsg['group_message_id'] != null) {
        continue;
      }

      // 🔹 detect image
      final hasImage = (currentMsg['imageUrl'] != null &&
              currentMsg['imageUrl'].toString().isNotEmpty) ||
          (currentMsg['localImagePath'] != null &&
              currentMsg['localImagePath'].toString().isNotEmpty);

      // 🔹 detect video
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

        // already grouped by server? treat that as a boundary
        if (nextMsg['is_grouped_message'] == true &&
            nextMsg['group_message_id'] != null) {
          break;
        }

        groupIndices.add(j);
      }

      if (groupIndices.length > 1) {
        final String generatedGroupId = '${messages[i]["group_message_id"]}';

        for (final index in groupIndices) {
          messages[index]['is_grouped_message'] = true;
          messages[index]['group_message_id'] = generatedGroupId;
        }

        i = groupIndices.last;
      }
    }

    return messages;
  }

  // Map<String, dynamic>? resolveReplyOriginal(
  //   Map<String, dynamic> message,
  //   List<Map<String, dynamic>> allMessages,
  // )
  // {
  //   final replyId = message['reply']?['message_id'] ??
  //       message['reply']?['id'] ??
  //       message['reply_message_id'] ??
  //       message['replyMessageId'] ??
  //       message['replyToMessageId'];
  //
  //   if (replyId == null) {
  //     //   print("❌ replyId is null for message ${message['message_id']}");
  //     return null;
  //   }
  //
  //   // 1️⃣ Try direct message match
  //   for (final m in allMessages) {
  //     final id = (m['message_id'] ?? m['id'] ?? m['_id'] ?? m['messageId'])
  //         ?.toString();
  //
  //     if (id == replyId.toString()) {
  //       // print("✅ FOUND ORIGINAL MESSAGE => $m");
  //       return _mapReply(m);
  //     }
  //   }
  //
  //   // 2️⃣ Fallback: try group_message_id match
  //   for (final m in allMessages) {
  //     final groupId = m['group_message_id']?.toString();
  //     if (groupId == replyId.toString()) {
  //       print("✅ FOUND GROUP ORIGINAL MESSAGE => $m");
  //       return _mapReply(m);
  //     }
  //   }
  //
  //   print("❌ ORIGINAL MESSAGE NOT FOUND FOR => $replyId");
  //   return null;
  // }
  //
  // Map<String, dynamic> _mapReply(Map<String, dynamic> m) {
  //   return {
  //     'content':m['replyContent']?? m['content'],
  //     'imageUrl': m['imageUrl'],
  //     'fileUrl': m['fileUrl'],
  //     'originalUrl': m['originalUrl'],
  //     'fileName': m['fileName'],
  //     'fileType': m['fileType'],
  //     'mimeType': m['mimeType'],
  //     'group_message_id': m['group_message_id'],
  //     'is_grouped_message': m['is_grouped_message'] ?? false,
  //   };
  // }
  Map<String, dynamic>? resolveReplyOriginal(
    Map<String, dynamic> message,
    List<Map<String, dynamic>> allMessages,
  ) {
    final reply = message['reply'];

    final replyId =
        reply?['message_id'] ?? reply?['id'] ?? message['reply_message_id'];

    if (replyId == null) return null;

    for (final m in allMessages) {
      final id = (m['message_id'] ?? m['id'] ?? m['_id'] ?? m['messageId'])
          ?.toString();

      if (id == replyId.toString()) {
        return _mapReplyWithReplyPayload(m, reply);
      }
    }

    return null;
  }

  Map<String, dynamic> _mapReplyWithReplyPayload(
    Map<String, dynamic> original,
    Map<String, dynamic>? replyPayload,
  ) {
    String replyText = (replyPayload?['replyContent'] ??
            replyPayload?['content'] ??
            original['replyContent'] ??
            original['content'] ??
            '')
        .toString()
        .trim();

    // final fileType =
    // (original['fileType'] ?? original['mimeType'] ?? '').toString();
    //
    // final hasImage =
    //     (original['imageUrl'] ?? original['fileUrl'] ?? '').toString().isNotEmpty;
    //
    // if (replyText.isEmpty) {
    //   if (fileType.startsWith('video')) {
    //     replyText = 'Video';
    //   } else if (hasImage) {
    //     replyText = 'Photo';
    //   }
    // }

    return {
      'replyContent': replyText,
      'content': replyText,
      'imageUrl': original['imageUrl'],
      'fileUrl': original['fileUrl'],
      'originalUrl': original['originalUrl'],
      'fileName': original['fileName'],
      'fileType': original['fileType'],
      'mimeType': original['mimeType'],
      'group_message_id': replyPayload?['group_message_id'],
      'is_grouped_message': replyPayload?['is_grouped_message'] ?? false,
    };
  }

  // ------------------ UI builders ------------------
  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isSentByMe, bool isReply,
      {int? length}) {
    final String? bubbleSenderId = _getMessageSenderId(message);
    final bool correctIsSentByMe = bubbleSenderId == currentUserId;

    isSentByMe = correctIsSentByMe;

    // Handle deleted message display
    Map<String, dynamic> displayMessage = message;
    if (message['is_deleted'] == true) {
      displayMessage = Map<String, dynamic>.from(message);
      displayMessage['content'] = "🚫 This message was deleted";
      displayMessage['imageUrl'] = "";
      displayMessage['fileUrl'] = "";
      displayMessage['fileName'] = "";
      displayMessage['originalUrl'] = "";
      displayMessage['messageStatus'] = 'deleted';
    }

    final resolved = resolveReplyOriginal(message, _allMessages);

    final bubbleMessage = {
      ...displayMessage,
      'resolvedReply': resolved,
    };
    final messageId =
        (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '')
            .toString();
    int replyMediaCount = 0;
    final replyData = message['reply'] ?? message['repliedMessage'];
    if (replyData != null) {
      final String? replyGroupId = replyData['group_message_id']?.toString();
      if (replyGroupId != null && replyGroupId.isNotEmpty) {
        replyMediaCount = _allMessages
            .where((m) =>
                m['group_message_id']?.toString() == replyGroupId &&
                m['is_deleted'] != true)
            .length;
      }

      if (replyMediaCount == 0) {
        replyMediaCount = ((replyData['imageCount'] ?? 0) as int) +
            ((replyData['videoCount'] ?? 0) as int);
      }
    }

    return Builder(builder: (context) {
      // Register context for scrolling
      if (messageId.isNotEmpty) {
        _messageContexts[messageId] = context;
      }

      return MessageBubble(
        key: ValueKey(_generateMessageKey(message)),
        isSelectionMode: _isSelectionMode,
        message: bubbleMessage,
        isSentByMe: correctIsSentByMe,
        //   isSelected: _selectedMessageKeys.contains(_generateMessageKey(message)),
        isSelected: _selectedMessageKeys.contains(_generateMessageKey(message)),
        onTap: () => _onMessageTap(message),
        onLongPress: () => _onMessageLongPress(message),
        onRightSwipe: message['is_deleted'] == true
            ? null
            : () => _replyToMessage(message),
        onFileTap: (url, type) => _openFile(url, type),
        buildStatusIcon: (status) => MessageStatusIcon(status: status),
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
          receiverId: widget.receiverId ?? "",
          firstName: widget.firstname ?? "",
          lastName: widget.lastname ?? "",
        ),
        isReply: isReply,
        onReplyTap: () {
          final replyId = (message['reply']?['reply_message_id'] ??
                  message['reply']?['message_id'] ??
                  message['reply']?['id'] ??
                  message['repliedMessage']?['reply_message_id'] ??
                  message['repliedMessage']?['message_id'] ??
                  message['repliedMessage']?['id'] ??
                  message['reply_message_id'] ??
                  message['replyMessageId'])
              ?.toString();

          if (replyId != null && replyId.isNotEmpty) {
            _highlightMessage(replyId);

            _scrollToMessageById(
              replyId,
              fetchIfMissing: true,
            ).then((found) {
              if (!found && mounted) {
                Messenger.alert(
                  msg:
                      "Original message not loaded. Scroll up to load older messages.",
                );
              }
            }).catchError((error) {
              debugPrint('Error scrolling to message: $error');
            });
          }
        },
        groupMediaLength: replyMediaCount > 0 ? replyMediaCount : length,
        allMessages: _getCombinedMessages(),
        stretchReply: true,
        searchText: _searchController.text,
        recentEmojis: recentEmojis,
        onEmojiUpdated: (list) {
          setState(() => recentEmojis = list);
        },
        currentUserId: currentUser,

        //isHighlighted: messageId == _highlightedMessageId,
      );
    });
  }

  Widget _buildReactionsBar(Map<String, dynamic> message, bool sentByMe) {
    final messageId =
        (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '')
            .toString();
    final mergedReactions = messageId.isNotEmpty
        ? _collectMergedReactionsForMessage(messageId)
        : <Map<String, dynamic>>[];

    final msgCopy = Map<String, dynamic>.from(message);
    msgCopy['reactions'] = mergedReactions;

    return ReactionBar(
      message: message,
      currentUserId: currentUserId,
      onReactionTap: (msg, emoji) => _handleReactionTap(message, emoji),
      onOpenReactors: (msg, emoji) => _showReactionsBottomSheet(message, emoji),
      recentEmojis: recentEmojis,
      onEmojiUpdated: (list) {
        setState(() => recentEmojis = list);
      },
    );
  }

  void _onMessageTap(Map<String, dynamic> message) async {
    if (_isSelectionMode) {
      _toggleMessageSelection(message);
      return;
    }
    final bool isDeleted =
        message['is_deleted'] == true || message['messageStatus'] == 'deleted';

    if (isDeleted) return;

    debugPrint('📩 tapped message id: ${_anyId(message)}');
    log('📩 tapped message raw: $message');

    String? extractReplyId(Map<String, dynamic> m) {
      final reply = m['reply'];

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
      for (final key in [
        'reply_message_id',
        'replyId',
        'reply_to_id',
        'replyMessageId'
      ]) {
        final v = m[key];
        if (v != null && v.toString().isNotEmpty) {
          return v.toString();
        }
      }

      // 3️⃣ Check repliedMessage map (from MessageHandler)
      final replied = m['repliedMessage'];
      if (replied is Map<String, dynamic>) {
        for (final key in [
          'reply_message_id',
          'message_id',
          'messageId',
          'id',
          '_id',
        ]) {
          final v = replied[key];
          if (v != null && v.toString().isNotEmpty) {
            return v.toString();
          }
        }
      }

      return null;
    }

    final replyId = extractReplyId(message);
    debugPrint('📌 extracted replyId: $replyId');
    final groupId = message["reply"]?['group_message_id']?.toString() ?? "";
    debugPrint('📌 extracted groupId: $groupId');

    if (replyId != null && replyId.isNotEmpty) {
      final found = await _scrollToMessageById(
        replyId,
        fetchIfMissing: false,
      );
      if (!found) {
        Messenger.alert(
          msg: "Original message not loaded. Scroll up to load older messages.",
        );
      }
    }
  }

  void _onMessageLongPress(Map<String, dynamic> message) {
    if (message['is_deleted'] == true) {
      if (!_isSelectionMode) {
        setState(() {
          _isSelectionMode = true;
        });
      }
      _toggleMessageSelection(message);
      return;
    }

    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
      });
    }
    _toggleMessageSelection(message);
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
  }) {
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
          'user': r['user'] is Map
              ? Map<String, dynamic>.from(r['user'])
              : r['user'],
          'reacted_at': (r['reacted_at'] ?? r['createdAt'] ?? '').toString(),
        };
      }
    }

    // local first so incoming can overwrite if needed (server is source-of-truth)
    addList(local);
    addList(incoming);

    return byUser.values.toList();
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
    if (allReacts.isEmpty) {
      // you might still want to show the sheet with just Add button. For now, return.
      return;
    }

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
                              showEmojiPicker = !showEmojiPicker;
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
                                    ? displayName
                                        .trim()
                                        .characters
                                        .first
                                        .toUpperCase()
                                    : '?')
                                : null,
                          ),
                          title: Text(isMe
                              ? 'You'
                              : (displayName.isNotEmpty
                                  ? displayName
                                  : userId)),
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

                                    // dispatch your RemoveReaction event
                                    _messagerBloc.add(RemoveReaction(
                                      messageId: apiMessageId,
                                      conversationId: widget.convoId,
                                      emoji: selectedEmoji,
                                      userId: currentUserId,
                                      receiverId: widget.receiverId ?? "",
                                      firstName: widget.firstname ?? "",
                                      lastName: widget.lastname ?? "",
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

  Future<void> _handleReactionTap(
    Map<String, dynamic> message,
    String emoji,
  ) async {
    try {
      final rawId = (message['message_id'] ??
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

      // 🔥 Extract reactions safely
      final List<Map<String, dynamic>> reactions =
          _extractReactionsFromMessage(message);

      int myIndex = -1;
      String? oldEmoji;

      for (var i = 0; i < reactions.length; i++) {
        final r = reactions[i];
        final uid = (r['user']?['_id'] ?? r['userId'])?.toString();
        if (uid == currentUserId) {
          myIndex = i;
          oldEmoji = r['emoji']?.toString();
          break;
        }
      }

      final bool hasMyReaction = myIndex != -1;

      // CASE 1: remove
      if (hasMyReaction && oldEmoji == emoji) {
        _updateLocalReactions(rawId, null);

        _messagerBloc.add(RemoveReaction(
          messageId: apiMessageId,
          conversationId: widget.convoId,
          emoji: emoji,
          userId: currentUser!,
          receiverId: widget.receiverId ?? "",
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
          userId: currentUser!,
          receiverId: widget.receiverId ?? "",
          firstName: widget.firstname ?? "",
          lastName: widget.lastname ?? "",
        ));

        _messagerBloc.add(AddReaction(
          messageId: apiMessageId,
          conversationId: widget.convoId,
          emoji: emoji,
          userId: currentUser!,
          receiverId: widget.receiverId ?? "",
          firstName: widget.firstname ?? "",
          lastName: widget.lastname ?? "",
        ));
        return;
      }

      // CASE 3: new reaction
      _updateLocalReactions(rawId, emoji);

      _messagerBloc.add(AddReaction(
        messageId: apiMessageId,
        conversationId: widget.convoId,
        emoji: emoji,
        userId: currentUser!,
        receiverId: widget.receiverId ?? "",
        firstName: widget.firstname ?? "",
        lastName: widget.lastname ?? "",
      ));
    } catch (e, st) {
      log('❌ Error handling reaction tap: $e\n$st');
    }
  }

  List<Map<String, dynamic>> _extractReactionsFromMessage(
      Map<String, dynamic> message) {
    final List<Map<String, dynamic>> list = [];

    if (message['reactions'] is List) {
      for (final r in message['reactions']) {
        if (r is Map) list.add(Map<String, dynamic>.from(r));
      }
    }

    if (message['properties'] is List) {
      for (final p in message['properties']) {
        if (p is Map && p['reaction'] != null) {
          final r = p['reaction'];
          list.add({
            'emoji': r['emoji'],
            'reacted_at': r['reacted_at'],
            'user': {'_id': p['member_id']}
          });
        }
      }
    }

    return list;
  }

  bool isValidUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  void _openFile(String urlOrPath, String? fileType) async {
    // ✅ 1. VIDEO: open in your own player
    if (fileType != null && fileType.startsWith('video/')) {
      final isNetwork =
          urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://');

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

    // ✅ 2. IMAGE: open in MixedMediaViewer
    final lower = urlOrPath.toLowerCase();
    final bool isImage = (fileType != null && fileType.startsWith('image/')) ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif');

    if (isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MixedMediaViewer(
            items: [
              GroupMediaItem(
                previewUrl: urlOrPath,
                mediaUrl: urlOrPath,
                isVideo: false,
                senderName: widget.userName,
              ),
            ],
            initialIndex: 0,
            currentUserId: currentUser,
          ),
        ),
      );
      return;
    }

    // ✅ 3. everything else = your existing code
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

  void _markMessagesAsDeleted(List<String> messageIds,
      {String deleteFor = 'everyone'}) {
    if (messageIds.isEmpty) return;

    bool changed = false;

    void markInList(List<Map<String, dynamic>> list) {
      if (deleteFor == 'me') {
        final initialLen = list.length;
        list.removeWhere((msg) {
          final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
          return id.isNotEmpty && messageIds.contains(id);
        });
        if (list.length != initialLen) changed = true;
      } else {
        for (var i = 0; i < list.length; i++) {
          final msg = list[i];
          final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
          if (id.isNotEmpty && messageIds.contains(id)) {
            msg['content'] = "🚫 This message was deleted";
            msg['imageUrl'] = "";
            msg['fileUrl'] = "";
            msg['fileName'] = "";
            msg['mimeType'] = msg['mimeType'] ?? msg['fileType'] ?? "";
            msg['messageStatus'] = 'deleted';
            msg['is_deleted'] = true;
            changed = true;
          }
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
        isForward: isSentMe,
      ),
    );

    setState(() {
      _selectedMessages.clear();
      _selectedMessageKeys.clear();
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelectedMessages(String deleteFor) {
    if (_selectedMessageIds.isEmpty) return;

    _markMessagesAsDeleted(_selectedMessageIds.toList(), deleteFor: deleteFor);

    _messagerBloc.add(DeleteMessagesEvent(
        messageIds: _selectedMessageIds.toList(),
        convoId: widget.convoId,
        senderId: currentUserId,
        receiverId: widget.receiverId ?? "",
        message:
            _selectedMessageKeys.isNotEmpty ? _selectedMessageKeys.first : "",
        deleteFor: deleteFor));

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

  Map<String, dynamic> buildReplyPreviewFromGroup(
    List<Map<String, dynamic>> messages,
    bool isSendMe,
    String currentUserId,
  ) {
    int imageCount = 0;
    int videoCount = 0;

    for (final m in messages) {
      final String fileType =
          (m['fileType'] ?? m['mimeType'] ?? '').toString().toLowerCase();
      final String? fileUrl = m['fileUrl']?.toString();
      final String? imageUrl = m['imageUrl']?.toString();

      final bool isVideo = fileType.startsWith('video/') ||
          (fileUrl != null &&
              RegExp(r'\.(mp4|mov|mkv|avi|webm)$', caseSensitive: false)
                  .hasMatch(fileUrl));

      if (isVideo) {
        videoCount++;
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        imageCount++;
      }
    }

    String previewText;
    if (imageCount > 0 && videoCount > 0) {
      previewText = 'Media × ${imageCount + videoCount}';
    } else if (imageCount > 0) {
      previewText = 'Photo × $imageCount';
    } else if (videoCount > 0) {
      previewText = 'Video × $videoCount';
    } else {
      previewText = 'Message';
    }

    final first = messages.first;

    return {
      'message_id': first['message_id']?.toString(),
      'content': previewText,
      'isGroupedMedia': true,
      'imageCount': imageCount,
      'videoCount': videoCount,
      'userName': first['senderName'] ?? first['sender']?['first_name'] ?? '',
      'sender': first['sender'],
      'receiver': first['receiver'],
      'isSendMe': isSendMe,
      'senderId': currentUserId,
    };
  }

  void _replyToMessage(
    Map<String, dynamic> message, {
    bool isSendMe = false,
  }) {
    if (message.isEmpty) return;

    log("Reply source (swiped) => $message");

    // ✅ ALWAYS reply to the swiped message itself
    final Map<String, dynamic> replySource = Map<String, dynamic>.from(message);

    final String? originalUrl = replySource['originalUrl'] ??
        replySource['imageUrl'] ??
        replySource['fileUrl'];
    log("Reply replySource (swiped) => $replySource");

    final String fileType =
        replySource['mimeType'] ?? replySource['fileType'] ?? '';

    final bool isVideo = fileType.toLowerCase().startsWith('video/');
    log("Reply replySource (swiped) => $fileType");

    setState(() {
      _replyMessage = replySource;
      // Calculate counts if it's a grouped message
      int imageCount = 0;
      int videoCount = 0;
      final String? groupId = replySource['group_message_id']?.toString();

      if (groupId != null && groupId.isNotEmpty) {
        // Find all messages in this group
        final groupMessages = _allMessages
            .where((m) =>
                m['group_message_id']?.toString() == groupId &&
                m['is_deleted'] != true)
            .toList();

        for (var m in groupMessages) {
          final String fType = (m['mimeType'] ??
                  m['fileType'] ??
                  m['mimetype'] ??
                  m['ContentType'] ??
                  '')
              .toString()
              .toLowerCase();
          final String mUrl =
              (m['originalUrl'] ?? m['imageUrl'] ?? m['fileUrl'] ?? '')
                  .toString()
                  .toLowerCase();

          if (fType.startsWith('video/') ||
              mUrl.endsWith('.mp4') ||
              mUrl.endsWith('.mov') ||
              mUrl.endsWith('.mkv')) {
            videoCount++;
          } else if (fType.startsWith('image/') ||
              mUrl.endsWith('.jpg') ||
              mUrl.endsWith('.png') ||
              mUrl.endsWith('.jpeg') ||
              mUrl.endsWith('.webp')) {
            imageCount++;
          }
        }
      }

      _replyPreview = {
        'message_id': replySource['message_id'] ??
            replySource['messageId'] ??
            replySource['id'],

        'content': (replySource['content'] ?? '').toString(),

        // ✅ media (LOCAL or NETWORK)
        'originalUrl': originalUrl ?? '',
        'imageUrl': replySource['imageUrl'] ?? originalUrl ?? '',
        'fileUrl': replySource['fileUrl'] ?? originalUrl ?? '',
        'fileName': replySource['fileName'] ?? '',
        'fileType': fileType,
        'isVideo': isVideo,
        'isDocument': !isVideo &&
            (replySource['fileUrl'] != null &&
                replySource['fileUrl'].isNotEmpty &&
                (replySource['imageUrl'] == null ||
                    replySource['imageUrl'].isEmpty)),

        // user
        'sender': replySource['sender'],
        'receiver': replySource['receiver'],
        'senderId': currentUserId,
        'isSendMe': isSendMe,
        'imageCount': imageCount,
        'videoCount': videoCount,
        'group_message_id': groupId,
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
          onDeleteForEveryone: () => _deleteSelectedMessages('everyone'),
          onDeleteForMe: () => _deleteSelectedMessages('me'),
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
      resvID: widget.receiverId ?? widget.datumId ?? "",
      favouitre: widget.favourite,
      grpChat: widget.grpChat,
      onSearchTap: () {
        setState(() {
          _showSearchAppBar = true;
        });
      },
      onCloseSearch: _hideSearchAppBar,
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      onSearchUp: _onSearchUp,
      onSearchDown: _onSearchDown,
      searchMatchCount: _searchMatchIds.length,
      searchMatchIndex: _currentSearchMatchIndex,
      hasLeftGroup: false,
      groupMembers: [],
    );
  }

  String? _getMessageSenderId(Map<String, dynamic> message) {
    if (message.isEmpty) return null;

    // Try multiple fields in order of priority
    String? senderId;

    // 1. Check direct senderId field
    senderId = message['senderId']?.toString();
    if (senderId != null && senderId.isNotEmpty) return senderId;

    // 2. Check 'from' field
    senderId = message['from']?.toString();
    if (senderId != null && senderId.isNotEmpty) return senderId;

    // 3. Check sender object
    if (message['sender'] is Map) {
      final sender = message['sender'] is Map
          ? Map<String, dynamic>.from(message['sender'])
          : <String, dynamic>{};

      senderId = sender['_id']?.toString() ??
          sender['id']?.toString() ??
          sender['userId']?.toString();
      if (senderId != null && senderId.isNotEmpty) return senderId;
    }

    // 4. Check if it's a temp message (always from current user)
    final msgId = (message['message_id'] ?? '').toString();
    if (msgId.startsWith('temp_') || msgId.startsWith('forward_')) {
      return currentUserId;
    }

    return null;
  }

  void toggleSearchAppBar() =>
      setState(() => _showSearchAppBar = !_showSearchAppBar);

  void _saveAllMessages() {
    if (widget.convoId.isEmpty) return;
    final combined = [...dbMessages, ...messages, ...socketMessages];
    LocalChatStorage.saveMessages(widget.convoId, combined);
  }

  bool _isUnreadMessage(dynamic msg) {
    if (msg is Map<String, dynamic>) {
      final senderId =
          (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender']?['id'])
              ?.toString();

      return msg['messageStatus'] != 'read' &&
          senderId != currentUserId &&
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

  /// Call this after messages are loaded and socket is connected.
  Future<void> _sendInitialReadReceiptsIfNeeded() async {
    if (!mounted) return;
    //log("🔁 _sendInitialReadReceiptsIfNeeded(): start");

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

    //log("🟢 initial unread IDs found (pre-check): $unread");

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
    final computedRoomId =
        socketService.generateRoomId(currentUserId, widget.datumId ?? '');
    socketService.sendReadReceipts(
      messageIds: unread,
      conversationId: widget.convoId,
      roomId: computedRoomId,
    );

    //   log("✅ initial read receipts emitted: $unread (roomId=$computedRoomId)");
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

          const targetScroll = 0.0;
          // if already at bottom (0.0), no need to animate
          final isAtBottom =
              (_scrollController.offset - targetScroll).abs() < 1.0;
          if (isAtBottom) return;

          // Try animate first -,@message_ui.dart- smoother
          await _scrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );

          // If after animate still not at bottom, try jumpTo as a fallback
          if (_scrollController.hasClients &&
              (_scrollController.offset - targetScroll).abs() > 1.0) {
            _scrollController.jumpTo(targetScroll);
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
          _scrollController.jumpTo(0.0);
        } catch (_) {}
      }
    });
  }

  List<Map<String, dynamic>> _getGroupedMessages(
    List<Map<String, dynamic>> combinedMessages,
    int index,
  ) {
    final message = combinedMessages[index];
    final String? groupId = message['group_message_id']?.toString();

    // 🔹 Single message fallback
    if (groupId == null || groupId.isEmpty) {
      return [_normalizeForForward(message)];
    }

    final List<Map<String, dynamic>> result = [];

    for (int i = index; i < combinedMessages.length; i++) {
      final m = combinedMessages[i];

      if (m['group_message_id']?.toString() != groupId) break;

      result.add(_normalizeForForward(m));
    }

    return result;
  }

  Map<String, dynamic> _normalizeForForward(Map<String, dynamic> m) {
    final String? imageUrl =
        m['originalUrl'] ?? m['imageUrl'] ?? m['localImagePath'];

    final String? fileUrl = m['fileUrl'];
    final String fileType =
        (m['fileType'] ?? m['mimeType'] ?? '').toString().toLowerCase();

    final bool isVideo = fileType.startsWith('video/') ||
        (fileUrl != null &&
            RegExp(r'\.(mp4|mov|mkv|avi|webm)$', caseSensitive: false)
                .hasMatch(fileUrl));

    return {
      ...m,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'originalUrl': imageUrl,
      'isVideo': isVideo,
      'group_message_id': m['group_message_id'],
    };
  }

  Map<String, dynamic> _resolveReplySource(Map<String, dynamic> message) {
    return message;
  }

  List<Map<String, dynamic>> buildGroupedMessages(List raw) {
    List<Map<String, dynamic>> result = [];

    for (int i = 0; i < raw.length; i++) {
      final current = raw[i];

      final String currentType =
          (current['fileType'] ?? current['mimeType'] ?? '')
              .toString()
              .toLowerCase();

      final bool isMedia = current['imageUrl'] != null ||
          current['originalUrl'] != null ||
          current['fileUrl'] != null;

      if (!isMedia) {
        result.add(current);
        continue;
      }

      if (result.isNotEmpty) {
        final prev = result.last;

        final String prevType = (prev['fileType'] ?? prev['mimeType'] ?? '')
            .toString()
            .toLowerCase();

        final bool sameSender = prev['senderId'] == current['senderId'];

        final bool prevIsMedia = prev['imageUrl'] != null ||
            prev['originalUrl'] != null ||
            prev['fileUrl'] != null;

        final diff = _parseTime(current['time'])
            .difference(_parseTime(prev['time']))
            .inSeconds
            .abs();

        final bool sameMediaType = _sameMediaType(prevType, currentType);

        // Check if either message has a caption - don't group if they do
        final bool prevHasCaption =
            (prev['content']?.toString() ?? '').isNotEmpty;
        final bool currentHasCaption =
            (current['content']?.toString() ?? '').isNotEmpty;

        // Group only if: same sender, both media, within time window, same type, AND neither has a caption
        if (sameSender &&
            prevIsMedia &&
            diff <= 60 &&
            sameMediaType &&
            !prevHasCaption &&
            !currentHasCaption) {
          prev['is_grouped_message'] = true;
          prev['group_message_id'] ??= prev['message_id'];

          current['is_grouped_message'] = true;
          current['group_message_id'] = prev['group_message_id'];

          result.add(current);
          continue;
        }
      }

      result.add(current);
    }

    return result;
  }
  // bool _canGroupTogether(String a, String b) {
  //   final bool aIsVisual = a.startsWith('image') || a.startsWith('video');
  //   final bool bIsVisual = b.startsWith('image') || b.startsWith('video');
  //
  //   return aIsVisual && bIsVisual; // image+video allowed
  // }

  bool _sameMediaType(String a, String b) {
    final bool aIsVisual = a.startsWith('image') || a.startsWith('video');
    final bool bIsVisual = b.startsWith('image') || b.startsWith('video');

    return aIsVisual && bIsVisual;
  }

  void _selectGroupedMessages(List<Map<String, dynamic>> grouped) {
    final bool isGroupSelected = grouped.any(
      (m) => _selectedMessageKeys.contains(_generateMessageKey(m)),
    );

    setState(() {
      for (final m in grouped) {
        final key = _generateMessageKey(m);
        final id = m['message_id']?.toString();

        if (isGroupSelected) {
          _selectedMessageKeys.remove(key);
          _selectedMessageIds.remove(id);
          _selectedMessages.removeWhere((x) => _generateMessageKey(x) == key);
        } else {
          _selectedMessageKeys.add(key);
          if (id != null) _selectedMessageIds.add(id);
          _selectedMessages.add(m);
        }
      }

      _isSelectionMode = _selectedMessageKeys.isNotEmpty;
    });
  }

  // void _selectGroupedMessages(List<Map<String, dynamic>> group) {
  //   setState(() {
  //     _isSelectionMode = true;
  //
  //     for (final msg in group) {
  //       final key = _generateMessageKey(msg);
  //       final id = (msg['message_id'] ?? msg['id'] ?? msg['messageId'])?.toString();
  //
  //       if (id == null) continue;
  //
  //       if (!_selectedMessageKeys.contains(key)) {
  //         _selectedMessageKeys.add(key);
  //         _selectedMessageIds.add(id);
  //         _selectedMessages.add(msg);
  //       }
  //     }
  //   });
  // }

  // ------------------ Build ------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedMessageIds.clear();
            _selectedMessageKeys.clear();
            _selectedMessages.clear();
          });
          return false; // ⛔ don't exit screen
        }

        return true; // ✅ exit screen
      },
      child: ReusableChatScaffold(
        appBar: _buildAppBar(),
        chatBody: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _messagesNotifier,
          builder: (context, combinedMessages, child) {
            _markVisibleMessagesAsRead(combinedMessages);
            final groupedMessages = buildGroupedMessages(combinedMessages);

            return BlocConsumer<MessagerBloc, MessagerState>(
              listener: (context, state) {
                if (state is MessageSentSuccessfully) {
                  final convoId = state.sentMessage.conversationId;
                  log(convoId.toString());
                  log("Message sent successfully with convoId: $convoId");

                  if (convoId != null && convoId.isNotEmpty) {
                    // 🔥 FIRST MESSAGE ONLY
                    if (_currentConversationId.isEmpty) {
                      _currentConversationId = convoId;
                      print("🔥 $_currentConversationId");

                      socketService.setActiveConversation(convoId);

                      debugPrint("✅ Conversation created: $convoId");
                    }
                  }
                }

                if (state is MessageAckReceived) {
                  _replaceTempMessageWithReal(
                    tempId: state.tempId,
                    realId: state.realId,
                    status: state.status,
                  );
                } else if (state is LocalAudioMessageAdded) {
                  // ✅ Handle optimistic audio message - add directly to _allMessages
                  final audioMessage = state.message;
                  final id = audioMessage['message_id']?.toString();

                  if (id != null && id.isNotEmpty) {
                    // ✅ Check if not already in _allMessages (single source of truth)
                    final exists =
                        _allMessages.any((m) => (m['message_id'] ?? '') == id);

                    if (!exists) {
                      setState(() {
                        // ✅ Add directly to _allMessages to avoid merge conflicts
                        _allMessages.add(audioMessage);
                        _seenMessageIds.add(id);
                      });

                      // ✅ Sort messages by time
                      _allMessages.sort((a, b) {
                        try {
                          return _parseTime(a['time'])
                              .compareTo(_parseTime(b['time']));
                        } catch (e) {
                          return 0;
                        }
                      });

                      // ✅ Update visible count
                      _visibleCount = _allMessages.length;

                      // ✅ Update UI without re-merging (preserves existing statuses)
                      _updateNotifierFromAll();
                      _scheduleSaveMessages();

                      // Scroll to bottom to show new message
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                    }
                  }
                } else if (state is MessagerLoaded) {
                  final flat = state.response.data
                      .expand((g) => g.messages)
                      .map((e) => normalizeMessage(e.toJson()))
                      .where((m) => m.isNotEmpty)
                      .toList();

                  // 🔥 MERGE, DO NOT REPLACE
                  final Map<String, Map<String, dynamic>> merged = {
                    for (final m in _allMessages)
                      if (m['message_id'] != null) m['message_id']: m,
                  };

                  for (final m in flat) {
                    final id = m['message_id'];
                    if (id != null) merged[id] = m;
                  }

                  _allMessages
                    ..clear()
                    ..addAll(merged.values);

                  _allMessages.sort(
                    (a, b) =>
                        _parseTime(a['time']).compareTo(_parseTime(b['time'])),
                  );

                  _updateNotifierFromAll();
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
                    final id = (old['message_id'] ??
                            old['messageId'] ??
                            old['id'] ??
                            '')
                        .toString();
                    if (id.isEmpty) continue;
                    previousById[id] = old;
                  }

                  for (final m in newDbMessages) {
                    final id =
                        (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '')
                            .toString();
                    if (id.isEmpty) continue;
                    final prev = previousById[id];
                    if (prev == null) continue;

                    /// --- preserve local reply if present on prev (marker set earlier) ---
                    final bool prevHasLocalReply =
                        prev['_localHasReply'] == true;
                    if (prevHasLocalReply) {
                      // if server message lacks reply, restore it from prev
                      final newHasReply = _hasReplyForMessage(m);
                      if (!newHasReply) {
                        try {
                          if (prev['_localReply'] != null) {
                            m['reply'] =
                                Map<String, dynamic>.from(prev['_localReply']);
                          } else if (prev['reply'] != null) {
                            m['reply'] =
                                Map<String, dynamic>.from(prev['reply']);
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
                    } else if (newReactions.isNotEmpty &&
                        prevReactions.isNotEmpty) {
                      // merge them (union by user)
                      m['reactions'] = _mergeReactions(
                          local: prevReactions, incoming: newReactions);
                    }

                    /// preserve local 'read' only if we locally marked it
                    final prevStatus =
                        (prev['messageStatus'] ?? prev['status'] ?? '')
                            .toString();
                    final newStatus =
                        (m['messageStatus'] ?? m['status'] ?? '').toString();
                    final bool prevLocallyMarkedRead =
                        prev['_localMarkedRead'] == true;
                    if (prevLocallyMarkedRead &&
                        prevStatus == 'read' &&
                        newStatus != 'read') {
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
                      final id = (fresh['message_id'] ??
                                  fresh['messageId'] ??
                                  fresh['id'])
                              ?.toString() ??
                          '';
                      if (id.isEmpty) {
                        final tempKey =
                            '__noid_${DateTime.now().microsecondsSinceEpoch}';
                        byId[tempKey] = fresh;
                        continue;
                      }

                      // if we already had a local version, merge some important local-only fields
                      final prev = byId[
                          id]; // this checks values already in byId (from cached dbMessages earlier)
                      // If `prev` is null, try to find a cached local message from your existing dbMessages:
                      final localPrev = prev ??
                          dbMessages.firstWhere(
                            (m) =>
                                (m['message_id'] ?? m['messageId'] ?? m['id'])
                                    ?.toString() ==
                                id,
                            orElse: () => {},
                          );

                      // Start with fresh copy we'll store
                      final Map<String, dynamic> merged =
                          Map<String, dynamic>.from(fresh);

                      // ---- Preserve reply info if local had it but server omitted it ----
                      try {
                        final bool prevHasLocalReply = (localPrev.isNotEmpty) &&
                            (localPrev['_localHasReply'] == true ||
                                localPrev['reply'] != null ||
                                localPrev['reply_message_id'] != null);

                        final bool freshHasReply = _hasReplyForMessage(merged);

                        if (prevHasLocalReply && !freshHasReply) {
                          // Prefer a locally stored _localReply if present (set when you replaced temp->real)
                          if (localPrev['_localReply'] != null) {
                            merged['reply'] = Map<String, dynamic>.from(
                                localPrev['_localReply']);
                          } else if (localPrev['reply'] != null) {
                            merged['reply'] =
                                Map<String, dynamic>.from(localPrev['reply']);
                          }

                          // ensure top-level id fields exist
                          if (merged['reply'] != null) {
                            merged['reply_message_id'] ??= (merged['reply']
                                        ['id'] ??
                                    merged['reply']['message_id'] ??
                                    merged['reply']['reply_message_id'])
                                ?.toString();
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
                        final prevReactions = (localPrev.isNotEmpty)
                            ? _extractReactions(localPrev['reactions'])
                            : <Map<String, dynamic>>[];
                        final newReactions =
                            _extractReactions(merged['reactions']);
                        if (newReactions.isEmpty && prevReactions.isNotEmpty) {
                          merged['reactions'] = prevReactions;
                        }
                      } catch (_) {}

                      // ---- Preserve locally marked read state if we previously flagged it ----
                      try {
                        final prevLocallyMarkedRead = (localPrev.isNotEmpty) &&
                            localPrev['_localMarkedRead'] == true;
                        final newStatus =
                            (merged['messageStatus'] ?? merged['status'] ?? '')
                                .toString();
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
                        (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '')
                            .toString();
                    if (id.isNotEmpty) _seenMessageIds.add(id);
                  }

                  // 6) Rebuild combined list & notify UI
                  // _updateNotifier(isInitialLoad: _currentPage == 1);
                  // _scheduleSaveMessages();

                  if (_currentPage == 1) {
                    _scrollToBottom();
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      try {
                        if (_prevScrollExtentBeforeLoad > 0 &&
                            _scrollController.hasClients) {
                          final newMax =
                              _scrollController.position.maxScrollExtent;
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
                } else if (state is MessageAckReceived) {
                  _replaceTempMessageWithReal(
                    tempId: state.tempId,
                    realId: state.realId,
                    status: state.status,
                  );
                } else if (state is LocalAudioMessageAdded) {
                  final msg = state.message;
                  final id = (msg['message_id'] ?? '').toString();
                  if (id.isNotEmpty) _seenMessageIds.add(id);

                  setState(() {
                    socketMessages.add(msg);
                  });
                  _updateNotifier();
                  _scheduleSaveMessages();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                } else if (state is NewMessageReceivedState) {
                  if (state.message['isGroupChat'] == true) return;
                  final normalized = normalizeMessage(state.message);
                  if (normalized.isEmpty) return;

                  _handleIncomingRawMessage(normalized);
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: const SizedBox.shrink(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: groupedMessages.length,
                            reverse: true,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              // final message = combinedMessages[index];
                              final int realIndex =
                                  groupedMessages.length - 1 - index;
                              final message = groupedMessages[realIndex];
                              //     log("messagessssssssssssssssssssssssss $message");
                              final String? senderId =
                                  _getMessageSenderId(message);

                              final messageId = (message['message_id'] ??
                                      message['messageId'] ??
                                      message['id'] ??
                                      '')
                                  .toString();

                              final bool isHighlighted =
                                  _highlightedMessageId == messageId;
                              final List<GroupMediaItem> groupMedia = [];

                              // 🔥 FIX: Properly determine if message is sent by current user
                              final bool isSentByMe =
                                  senderId == currentUserId &&
                                      senderId != null &&
                                      senderId.isNotEmpty;
                              currentUser = senderId;
                              isSentMe = isSentByMe;

                              // Debug logging (remove after fixing)
                              if (senderId != null) {}

                              final showDate = realIndex == 0 ||
                                  !isSameDay(
                                    _parseTime(message['time']),
                                    _parseTime(
                                        groupedMessages[realIndex - 1]['time']),
                                  );
                              final isGroupMessage =
                                  message['is_grouped_message'] == true;
                              final groupMessageId =
                                  message['group_message_id']?.toString();

                              if (isGroupMessage &&
                                  groupMessageId != null &&
                                  groupMessageId.isNotEmpty) {
                                // Is this the first message in the group?
                                final isFirstInGroup = realIndex == 0 ||
                                    groupedMessages[realIndex - 1]
                                                ['group_message_id']
                                            ?.toString() !=
                                        groupMessageId;

                                // Skip non-first items
                                if (!isFirstInGroup) {
                                  return const SizedBox.shrink();
                                }

                                for (int i = realIndex;
                                    i < groupedMessages.length;
                                    i++) {
                                  final nextMsg = groupedMessages[i];
                                  final nextGrpId =
                                      nextMsg['group_message_id']?.toString();
                                  if (nextGrpId != groupMessageId) break;

                                  final String? previewUrl =
                                      nextMsg['originalUrl']?.toString() ??
                                          nextMsg['imageUrl']?.toString() ??
                                          nextMsg['localImagePath']?.toString();
                                  final String? mediaUrl =
                                      nextMsg['originalUrl']?.toString() ??
                                          nextMsg['imageUrl']?.toString() ??
                                          nextMsg['localImagePath']?.toString();

                                  final String? fileUrl =
                                      nextMsg['fileUrl']?.toString();
                                  final String fileType =
                                      (nextMsg['fileType'] ??
                                              nextMsg['mimeType'] ??
                                              '')
                                          .toString()
                                          .toLowerCase();

                                  final bool isVideo = fileType
                                          .startsWith('video/') ||
                                      (fileUrl != null &&
                                          RegExp(r'\.(mp4|mov|mkv|avi|webm)$',
                                                  caseSensitive: false)
                                              .hasMatch(fileUrl));
                                  final String uniqueId =
                                      '${message['message_id']}_${groupMedia.length}';
                                  if (!isVideo &&
                                      mediaUrl != null &&
                                      mediaUrl.isNotEmpty) {
                                    groupMedia.add(GroupMediaItem(
                                        previewUrl: mediaUrl,
                                        mediaUrl: mediaUrl,
                                        isVideo: false,
                                        uniqueId: uniqueId,   message: nextMsg));
                                  } else if (isVideo) {
                                    final preview = previewUrl ?? fileUrl ?? '';
                                    final media = fileUrl ?? mediaUrl ?? '';
                                    if (media.isNotEmpty) {
                                      groupMedia.add(GroupMediaItem(
                                          previewUrl: preview,
                                          mediaUrl: media,
                                          isVideo: true,
                                          uniqueId: uniqueId,   message: nextMsg));
                                    }
                                  }
                                }

                                // Render grouped media if we have any
                                if (groupMedia.isNotEmpty) {
                                  return Builder(builder: (ctx) {
                                    final groupId =
                                        message['group_message_id']?.toString();
                                    final bool? isForwarded =
                                        message['isForwarded'] ?? false;
                                    final messageId =
                                        _anyId(message)?.toString();
                                    final isReaction =
                                        message['reactions'] != null &&
                                            (message['reactions'] as List)
                                                .isNotEmpty;
                                    final String groupAnchorMessageId =
                                        message['message_id'] ?? message['id'];

                                    if (groupAnchorMessageId.isNotEmpty) {
                                      _messageContexts[groupAnchorMessageId] =
                                          ctx; // 🔥 IMPORTANT
                                    } else if (messageId != null &&
                                        messageId.isNotEmpty) {
                                      _messageContexts[messageId] = ctx;
                                    }
                                    return Column(
                                      crossAxisAlignment: isSentByMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (showDate)
                                          DateSeparator(
                                              dateTime:
                                                  _parseTime(message['time'])),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                          child: GroupedMediaWidget(
                                              isSelectionMode: _isSelectionMode,
                                              onLongPress: () {
                                                final grouped =
                                                    _getGroupedMessages(
                                                        groupedMessages,
                                                        realIndex);
                                                _selectGroupedMessages(grouped);
                                              },
                                              selectedMessageColor: Colors.blue,
                                              isSelected: _getGroupedMessages(
                                                      groupedMessages, realIndex)
                                                  .any((m) => _selectedMessageKeys.contains(
                                                      _generateMessageKey(m))),
                                              recentEmojis: recentEmojis,
                                              onEmojiUpdated: (list) {
                                                setState(
                                                    () => recentEmojis = list);
                                              },
                                              buildReactionsBar:
                                                  (msg, sentByMe) =>
                                                      _buildReactionsBar(
                                                          msg, sentByMe),
                                              onReact: (msg, emoji) {
                                                setState(() {
                                                  _handleReactionTap(
                                                      msg, emoji);
                                                  _showSearchAppBar = false;
                                                  _isSelectionMode = false;
                                                  _selectedMessages.clear();
                                                  _selectedMessageKeys.clear();
                                                });
                                              },
                                              emojpicker: () =>
                                                  ReactionDialog.show(
                                                    context: context,
                                                    messageId:
                                                        message['message_id']
                                                                ?.toString() ??
                                                            '',
                                                    reactions: message[
                                                                'reactions']
                                                            as List<
                                                                Map<String,
                                                                    dynamic>>? ??
                                                        [],
                                                    currentUserId:
                                                        currentUserId,
                                                    convoId: widget.convoId,
                                                    receiverId:
                                                        widget.receiverId ?? "",
                                                    firstName:
                                                        widget.firstname ?? "",
                                                    lastName:
                                                        widget.lastname ?? "",
                                                  ),
                                              message: message,
                                              isForwarded: isForwarded,
                                              isReaction: isReaction,
                                              isHighlighted: isHighlighted,
                                              messageId: groupAnchorMessageId,
                                              media: groupMedia,
                                              caption: message['content']
                                                  ?.toString(),
                                              isSentByMe: isSentByMe,
                                              time: TimeUtils.formatUtcToIst(
                                                  message['time']),
                                              messageStatus:
                                                  message['messageStatus']
                                                          ?.toString() ??
                                                      'sent',
                                              buildStatusIcon: (status) =>
                                                  MessageStatusIcon(
                                                    status: status,
                                                    isStatus: true,
                                                  ),
                                              onImageTap: (tappedIndex) {
                                                final conversationMedia =
                                                    buildConversationMedia(
                                                        groupedMessages);
                                                print(
                                                    "tappedIndex $tappedIndex");
                                                final tappedItem =
                                                    groupMedia[tappedIndex];

                                                final startIndex =
                                                    conversationMedia
                                                        .indexWhere(
                                                  (m) =>
                                                      m.mediaUrl ==
                                                      tappedItem.mediaUrl,
                                                );

                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    transitionDuration:
                                                        const Duration(
                                                            milliseconds: 300),
                                                    pageBuilder: (_, __, ___) =>
                                                        MixedMediaViewer(
                                                      items: conversationMedia,

                                                      initialIndex: startIndex < 0 ? 0 : startIndex,
                                                      currentUserId: currentUser,



                                                    ),
                                                  ),
                                                );
                                              },
                                              onForwardTap: () {
                                                print("realIndexss $realIndex");
                                                log("combinedMessages ${groupedMessages.length}");
                                                final forwardMessages =
                                                    _getGroupedMessages(
                                                        groupedMessages,
                                                        realIndex);

                                                print(
                                                    "forwardMessagessss ${forwardMessages.length}");
                                                for (final m
                                                    in forwardMessages) {
                                                  print(
                                                      "ITEM TYPE => ${m.runtimeType}");
                                                  log("ITEM VALUE => $m");
                                                }

                                                MyRouter.pushReplace(
                                                  screen: ForwardMessageScreen(
                                                    messages: forwardMessages,
                                                    currentUserId:
                                                        message['senderId'] ??
                                                            '',
                                                    conversionalid: "",
                                                    username:
                                                        message['senderName'] ??
                                                            '',
                                                    isForward: isSentByMe,
                                                  ),
                                                );
                                              },
                                              onRightSwipe: (details) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  if (!mounted) return;

                                                  final grouped =
                                                      _getGroupedMessages(
                                                          groupedMessages,
                                                          realIndex);

                                                  final replyPreview =
                                                      buildReplyPreviewFromGroup(
                                                    grouped,
                                                    isSentByMe,
                                                    currentUserId,
                                                  );

                                                  setState(() {
                                                    _replyMessage =
                                                        grouped.first;
                                                    _replyPreview =
                                                        replyPreview;
                                                  });
                                                  log("_replyPreview $_replyPreview");
                                                  log("_replyPreview $_replyMessage");

                                                  // ⌨️ open keyboard AFTER gesture completes
                                                  _focusNode.requestFocus();
                                                });
                                              }),
                                        ),
                                      ],
                                    );
                                  });
                                }
                              }
                              final bool hasReaction =
                                  message['reactions'] != null &&
                                      (message['reactions'] as List).isNotEmpty;
                              final hasReply = _hasReplyForMessage(message);
                              final String? bubbleSenderId =
                                  _getMessageSenderId(message);
                              final bool correctIsSentByMe =
                                  bubbleSenderId == currentUserId &&
                                      bubbleSenderId != null &&
                                      bubbleSenderId.isNotEmpty;

                              return Builder(builder: (ctx) {
                                final messageId = _anyId(message).toString();
                                if (messageId.isNotEmpty) {
                                  _messageContexts[messageId] = ctx;
                                }
                                final bool isDeleted =
                                    message['is_deleted'] == true ||
                                        message['messageStatus'] == 'deleted';
                                return SwipeToReply(
                                  onReply: isDeleted
                                      ? null
                                      : () {
                                          final resolved =
                                              _resolveReplySource(message);
                                          _replyToMessage(resolved,
                                              isSendMe: isSentByMe);
                                        },
                                  child: AnimatedContainer(
                                    key: ValueKey(messageId),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOut,
                                    margin: EdgeInsets.only(
                                      top: hasReply ? 4 : 0,
                                      bottom: hasReaction
                                          ? (hasReply ? 20 : 5)
                                          : (hasReply ? 10 : 0),
                                    ),
                                    color: isHighlighted
                                        ? Colors.blueAccent
                                            .withValues(alpha: 0.3)
                                        : Colors.transparent,
                                    child: !hasReply
                                        ? _buildMessageBubble(message,
                                            correctIsSentByMe, hasReply,
                                            length: groupMedia.length)
                                        : Align(
                                            alignment: correctIsSentByMe
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Column(
                                              crossAxisAlignment:
                                                  correctIsSentByMe
                                                      ? CrossAxisAlignment.end
                                                      : CrossAxisAlignment
                                                          .start,
                                              children: [
                                                if (showDate)
                                                  DateSeparator(
                                                      dateTime: _parseTime(
                                                          message['time'])),
                                                Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 0),
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 160),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: _selectedMessageKeys
                                                                .contains(
                                                                    _generateMessageKey(
                                                                        message))
                                                            ? Colors.blue
                                                            : Colors
                                                                .transparent,
                                                        width: 2),
                                                    color: (isSentByMe
                                                        ? const Color(
                                                            0xFFD8E1FE)
                                                        : Colors.white),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft: isSentByMe
                                                          ? const Radius
                                                              .circular(18)
                                                          : const Radius
                                                              .circular(18),
                                                      topRight: isSentByMe
                                                          ? const Radius
                                                              .circular(18)
                                                          : const Radius
                                                              .circular(18),
                                                      bottomLeft: isSentByMe
                                                          ? const Radius
                                                              .circular(18)
                                                          : Radius.zero,
                                                      bottomRight: isSentByMe
                                                          ? Radius.zero
                                                          : const Radius
                                                              .circular(16),
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.05),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      _buildMessageBubble(
                                                          message,
                                                          correctIsSentByMe,
                                                          hasReply,
                                                          length: groupMedia
                                                              .length),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        voiceRecordingUI: const SizedBox(),
        messageInputBuilder: (isKeyboardVisible) =>
            _buildMessageInputField(isKeyboardVisible, isSentMe),
        isRecording: false,
        bloc: _messagerBloc,
      ),
    );
  }

  void _sendAudioMessage(String path, int duration) {
    debugPrint("Sending audio message: $path, duration: $duration");

    // Ensure SendAudioMessageEvent exists in your BLoC events
    _messagerBloc.add(
      SendAudioMessageEvent(
        senderId: currentUserId,
        receiverId: widget.receiverId ?? '',
        audioPath: path,
        duration: duration.toString(),
        convoId: widget.convoId,
      ),
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

    // 🔥 SORT BY TIME (LIKE WEB)
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
        if (eid == id) return true;

        // 🔥 AGGRESSIVE DEDUPLICATION:
        // If IDs differ, check if it's potentially the same message
        // (Same sender, same content/fileName, and very close time)
        final eIsTemp = e['_isTempMessage'] == true;
        final mIsTemp = m['_isTempMessage'] == true;

        if (eIsTemp != mIsTemp) {
          final eSender = (e['senderId'] ?? e['from'])?.toString();
          final mSender = (m['senderId'] ?? m['from'])?.toString();

          if (eSender == mSender && eSender != null) {
            final eContent = (e['content'] ?? '').toString();
            final mContent = (m['content'] ?? '').toString();
            final eFileName = (e['fileName'] ?? '').toString();
            final mFileName = (m['fileName'] ?? '').toString();

            final bool contentMatch =
                eContent.isNotEmpty && eContent == mContent;
            final bool fileMatch =
                eFileName.isNotEmpty && eFileName == mFileName;

            if (contentMatch || fileMatch) {
              try {
                final te = _parseTime(e['time']);
                final tm = _parseTime(m['time']);
                // Within 5 seconds (to account for server time skew)
                if (te.difference(tm).inSeconds.abs() < 5) {
                  return true;
                }
              } catch (_) {}
            }
          }
        }
        return false;
      });

      if (existingIndex == -1) {
        result.add(m);
      } else {
        final existing = result[existingIndex];

        // Preference logic: keep server message over temp message
        final existingIsTemp = existing['_isTempMessage'] == true;
        final newIsTemp = m['_isTempMessage'] == true;

        if (existingIsTemp && !newIsTemp) {
          // Replace temp with real
          result[existingIndex] = m;
        } else if (!existingIsTemp && newIsTemp) {
          // Keep the existing real message, skip new temp
        } else {
          // Both real or both temp, keep latest info
          final existingHasReply = _hasReplyForMessage(existing);
          final newHasReply = _hasReplyForMessage(m);

          if (newHasReply && !existingHasReply) {
            result[existingIndex] = m;
          } else {
            result[existingIndex] = m;
          }
        }
      }
    }

    // 🔥 RESOLVE REPLIES AFTER MERGE
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
                (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ==
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
        } catch (_) {}
      }
    }
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

  Widget _buildMessageInputField(bool isKeyboardVisible, bool isSentByMe) {
    return MessageInputField(
      messageController: _messageController,
      focusNode: _focusNode,
      conversionId: widget.convoId,
      onSendPressed: _sendMessage,
      onEmojiPressed: () {
        setState(() {});
      },
      onAttachmentPressed: () => ShowAltDialog.showOptionsDialog(context,
          conversationId: widget.convoId,
          senderId: currentUserId,
          receiverId: widget.receiverId!,
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
      }),
      onCameraPressed: _openCamera,
      onRecordPressed: _isRecording
          ? recorderHelper.stopRecording
          : recorderHelper.startRecording,
      isRecording: _isRecording,
      replyText: _replyPreview,
      onCancelReply: () {
        recorderHelper.cancelReply();
        _replyPreview = null;
        _replyMessage = null;

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
      isRecordingLocked: _isRecordingLocked,
      onLockRecording: () {
        // Attempt to stop the initial recording to release mic
        recorderHelper.stopRecording();
        setState(() {
          _isRecordingLocked = true;
          // Ensure _isRecording is true so the widget renders
          _isRecording = true;
        });
      },
      onCancelRecording: () {
        setState(() {
          _isRecordingLocked = false;
          _isRecording = false;
        });
        // Stop actual recording if needed
        recorderHelper.stopRecording();
      },
      onSendRecording: (path, duration) {
        setState(() {
          _isRecordingLocked = false;
          _isRecording = false;
        });
        // Send the file
        _sendAudioMessage(path, duration);
      },
    );
  }
}
