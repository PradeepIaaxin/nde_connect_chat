import 'dart:io';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/message_widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/message_handler.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/audio_reuable.dart';
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/build_messageInputfield_widgets.dart';

import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'messager_Bloc/MessagerEvent.dart';
import 'messager_Bloc/MessagerState.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_chat_funtions.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_2.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_3.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_4.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_5.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_6.dart';
import 'messager_Bloc/widget/privat_common_funtions/privat_funtions_6.dart';

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
  bool _showScrollToBottomButton = false;
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
  int _currentSearchMatchIndex = 0;
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
          flushOfflinePendingMessages(
            currentConversationId: _currentConversationId,
            currentUserId: currentUserId,
            messagerBloc: _messagerBloc,
            offlineQueue: _offlineQueue,
            receiverId: widget.receiverId!,
            replaceTempMessage: (tempId, realId, status) =>
                replaceTempMessageWithReal(
              tempId: tempId,
              realId: realId,
              status: status,
              socketMessages: socketMessages,
              messages: messages,
              dbMessages: dbMessages,
              allMessages: _allMessages,
              seenMessageIds: _seenMessageIds,
              updateNotifierFromAll: () {
                updateNotifierFromAll(
                    allMessages: _allMessages,
                    messagesNotifier: _messagesNotifier);
              },
              scheduleSaveMessages: _scheduleSaveMessages,
            ),
            updateMessageStatus: (localId, status) {
              updateMessageStatus(
                  messageId: localId,
                  status: 'failed',
                  messages: messages,
                  socketMessages: socketMessages,
                  updateNotifier: _updateNotifier,
                  scheduleSaveMessages: _scheduleSaveMessages,
                  dbMessages: dbMessages);
            },
          );
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
      saveDraft(
          draft: unsentText,
          chatListBloc: _chatListBloc,
          conversationId: widget.convoId,
          currentConversationId: _currentConversationId);
    } else {
      clearDraft(
          currentConversationId: _currentConversationId,
          conversationId: widget.convoId,
          chatListBloc: _chatListBloc);
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchMatchIds.clear();
        _currentSearchMatchIndex = 0;
        _highlightedMessageId = null;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final List<String> matches = [];

    for (final msg in _allMessages) {
      final content = (msg['content'] ?? '').toString().toLowerCase();

      final isDeleted = msg['is_deleted'] == true ||
          msg['messageStatus'] == 'deleted' ||
          content.contains('this message was deleted');

      final isSystem = msg['contentType'] == 'system' ||
          msg['ContentType'] == 'system' ||
          content.contains('added') ||
          content.contains('left') ||
          content.contains('created by');

      if (isDeleted || isSystem) continue;

      // 🔥 NEW: Exclude media messages (images, videos, documents, links)
      final hasImageUrl = (msg['imageUrl']?.toString() ?? '').isNotEmpty ||
          (msg['originalUrl']?.toString() ?? '').isNotEmpty ||
          (msg['localImagePath']?.toString() ?? '').isNotEmpty;

      final hasFileUrl = (msg['fileUrl']?.toString() ?? '').isNotEmpty;

      final mimeType =
          (msg['mimeType'] ?? msg['fileType'] ?? '').toString().toLowerCase();
      final isVideo =
          mimeType.startsWith('video/') || mimeType.contains('video');

      final isDocument = hasFileUrl && !hasImageUrl && !isVideo;

      // Check if content contains any URL pattern
      final contentText = (msg['content'] ?? '').toString().trim();
      final hasLink = contentText.contains('http://') ||
          contentText.contains('https://') ||
          contentText.contains('www.');

      // Skip media messages without meaningful text content
      if (hasImageUrl && contentText.isEmpty) continue; // Image without caption
      if (isVideo && contentText.isEmpty) continue; // Video without caption
      if (isDocument && contentText.isEmpty)
        continue; // Document without caption
      if (hasLink) continue; // Any message containing a URL

      // Only search in text content (not file names for media)
      if (content.contains(lowerQuery)) {
        final id =
            (msg['message_id'] ?? msg['messageId'] ?? msg['id'])?.toString();

        if (id != null && id.isNotEmpty) {
          matches.add(id);
        }
      }
    }

    // ✅ 🔥 ADD THIS LINE HERE
    final List<String> orderedMatches = matches.reversed.toList();

    setState(() {
      _searchMatchIds = orderedMatches;
      _currentSearchMatchIndex = 0;
      _highlightedMessageId =
          orderedMatches.isNotEmpty ? orderedMatches.first : null;
    });

    if (_highlightedMessageId != null) {
      scrollToMessageById(_highlightedMessageId!,
          messageContexts: _messageContexts,
          highlightAndScrollToContext: (ctx, messageId) {
            highlightAndScrollToContext(
              ctx,
              messageId,
              _highlightMessage,
            );
          },
          messagesNotifier: _messagesNotifier,
          scrollController: _scrollController,
          estimateScrollOffset: (listIndex, messageId) {
            return estimateScrollOffset(
                listIndex, messageId, _parseTime, isSameDay);
          },
          highlightMessage: _highlightMessage,
          fetchUntilMessageFound: (listIndex) {
            return fetchUntilMessageFound(
                messageId: listIndex,
                mounted: mounted,
                dbMessages: dbMessages,
                messages: messages,
                socketMessages: socketMessages,
                parseTime: _parseTime,
                hasReplyForMessage: hasReplyForMessage,
                hasNextPage: _hasNextPage,
                messagerBloc: _messagerBloc,
                convoId: widget.convoId,
                currentPage: _currentPage,
                initialLimit: _initialLimit);
          },
          estimateMessageHeight: (listIndex, messageId) {
            return estimateMessageHeight(
                listIndex, messageId, _parseTime, isSameDay);
          },
          fetchIfMissing: false);
    } else {
      Messenger.alert(msg: "No results found");
    }
  }

  void _onSearchUp(BuildContext context) {
    if (_searchMatchIds.isEmpty) return;

    // Up arrow = go to next/newer message (increment index)
    if (_currentSearchMatchIndex < _searchMatchIds.length - 1) {
      setState(() {
        _currentSearchMatchIndex = _currentSearchMatchIndex + 1;
        _highlightedMessageId = _searchMatchIds[_currentSearchMatchIndex];
      });
      scrollToMessageById(
        _highlightedMessageId!,
        fetchIfMissing: false,
        messageContexts: _messageContexts,
        highlightAndScrollToContext: (ctx, messageId) {
          highlightAndScrollToContext(
            ctx,
            messageId,
            _highlightMessage,
          );
        },
        messagesNotifier: _messagesNotifier,
        scrollController: _scrollController,
        estimateScrollOffset: (listIndex, messageId) {
          return estimateScrollOffset(
              listIndex, messageId, _parseTime, isSameDay);
        },
        highlightMessage: _highlightMessage,
        fetchUntilMessageFound: (listIndex) {
          return fetchUntilMessageFound(
              messageId: listIndex,
              mounted: mounted,
              dbMessages: dbMessages,
              messages: messages,
              socketMessages: socketMessages,
              parseTime: _parseTime,
              hasReplyForMessage: hasReplyForMessage,
              hasNextPage: _hasNextPage,
              messagerBloc: _messagerBloc,
              convoId: widget.convoId,
              currentPage: _currentPage,
              initialLimit: _initialLimit);
        },
        estimateMessageHeight: (listIndex, messageId) {
          return estimateMessageHeight(
              listIndex, messageId, _parseTime, isSameDay);
        },
      );
    }
  }

  void _onSearchDown() {
    if (_searchMatchIds.isEmpty) return;

    // Down arrow = go to previous/older message (decrement index)
    if (_currentSearchMatchIndex > 0) {
      setState(() {
        _currentSearchMatchIndex = _currentSearchMatchIndex - 1;
        _highlightedMessageId = _searchMatchIds[_currentSearchMatchIndex];
      });
      scrollToMessageById(
        _highlightedMessageId!,
        fetchIfMissing: false,
        messageContexts: _messageContexts,
        highlightAndScrollToContext: (ctx, messageId) {
          highlightAndScrollToContext(
            ctx,
            messageId,
            _highlightMessage,
          );
        },
        messagesNotifier: _messagesNotifier,
        scrollController: _scrollController,
        estimateScrollOffset: (listIndex, messageId) {
          return estimateScrollOffset(
              listIndex, messageId, _parseTime, isSameDay);
        },
        highlightMessage: _highlightMessage,
        fetchUntilMessageFound: (listIndex) {
          return fetchUntilMessageFound(
              messageId: listIndex,
              mounted: mounted,
              dbMessages: dbMessages,
              messages: messages,
              socketMessages: socketMessages,
              parseTime: _parseTime,
              hasReplyForMessage: hasReplyForMessage,
              hasNextPage: _hasNextPage,
              messagerBloc: _messagerBloc,
              convoId: widget.convoId,
              currentPage: _currentPage,
              initialLimit: _initialLimit);
        },
        estimateMessageHeight: (listIndex, messageId) {
          return estimateMessageHeight(
              listIndex, messageId, _parseTime, isSameDay);
        },
      );
    }
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

    // For new conversations, widget.convoId is empty but _currentConversationId gets updated
    final bool isNewChat =
        widget.convoId.isEmpty && _currentConversationId.isEmpty;
    if (!isNewChat &&
        convoId != widget.convoId &&
        convoId != _currentConversationId) {
      return;
    }

    // Update _currentConversationId if this is a new conversation
    if (_currentConversationId.isEmpty && convoId.isNotEmpty) {
      _currentConversationId = convoId;
      debugPrint('📝 Updated _currentConversationId to: $convoId');
    }

    final handler = MessageHandler(
      currentUserId: currentUserId,
      convoId:
          widget.convoId.isNotEmpty ? widget.convoId : _currentConversationId,
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
    updateNotifierFromAll(
        allMessages: _allMessages, messagesNotifier: _messagesNotifier);

    _scheduleSaveMessages();
  }

  Future<void> _initializeChat() async {
    //  log("Initializing chat for convoId: ${widget.convoId}");
    socketMessages.clear();
    messages.clear();
    dbMessages.clear();
    _seenMessageIds.clear();
    _visibleCount = _allMessages.length;

    _initialScrollDone = false;
    final userId = await UserPreferences.getUserId() ?? '';
    currentUserId = userId;
    log("currentUserId>>>>>>>>>>> $currentUserId");
    log("currentUserId>>>>>>>>>>> $currentUserId");
    log("currentUserId>>>>>>>>>>> $currentUserId");
    // 1) initialMessages (from forwarding)
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      log("messssssssssssssssss ${widget.initialMessages}");
      final normalized = widget.initialMessages!
          .map<Map<String, dynamic>>((raw) => normalizeMessage(raw))
          .where((m) => m.isNotEmpty)
          .toList();
      // dbMessages.addAll(normalized);
      _allMessages
        ..clear()
        ..addAll(normalized);
      for (var m in normalized) {
        final id = (m['message_id'] ?? '').toString();
        if (id.isNotEmpty) _seenMessageIds.add(id);
      }
      _visibleCount = _allMessages.length;
      log("messssssssssssssssssnormalized $normalized");
      updateNotifierFromAll(
          allMessages: _allMessages, messagesNotifier: _messagesNotifier);

      _scheduleSaveMessages();
    } else if (widget.convoId.isNotEmpty) {
      // 2) cached local messages

      final loaded = LocalChatStorage.loadMessages(widget.convoId);
      log("messssssssssssssssssloaded $loaded");
      final normalized = loaded
          .where((msg) => msg.isNotEmpty)
          .map((msg) => normalizeMessage(msg, text: "changesss"))
          .toList();

      _allMessages
        ..clear()
        ..addAll(normalized);
      for (var m in normalized) {
        final id = (m['message_id'] ?? '').toString();
        if (id.isNotEmpty) _seenMessageIds.add(id);
      }

      _visibleCount = _allMessages.length;
      updateNotifierFromAll(
          allMessages: _allMessages, messagesNotifier: _messagesNotifier);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialScrollDone) {
          scrollToBottom(
              _scrollController, setState, _showScrollToBottomButton);
          _initialScrollDone = true;
        }
      });
    }

    await Future.wait(
        [initializeSocket(), _loadCurrentUserId(currentUserId: currentUserId)]);

    if (widget.convoId.isNotEmpty) {
      _fetchMessages();
    }
    final draft = LocalChatStorage.getDraftMessage(widget.convoId);
    if (draft != null && draft.isNotEmpty) {
      _messageController.text = draft;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendInitialReadReceiptsIfNeeded(
          mounted: mounted,
          socketService: socketService,
          screenActive: _screenActive,
          dbMessages: dbMessages,
          messages: messages,
          socketMessages: socketMessages,
          currentUserId: currentUserId,
          datumId: widget.datumId ?? "",
          convoId: widget.convoId,
          parseTime: _parseTime,
          hasReplyForMessage: hasReplyForMessage,
          alreadyRead: _alreadyRead,
          updateNotifier: _updateNotifier,
          scheduleSaveMessages: _scheduleSaveMessages);
    });
  }

  void _setupReactionListener() {
    _reactionSubscription = socketService.reactionStream.listen((reaction) {
      updateMessageWithReaction(
          reaction: reaction,
          mounted: mounted,
          currentUserId: currentUserId,
          extractReactions: extractReactions,
          dbMessages: dbMessages,
          messages: messages,
          socketMessages: socketMessages,
          updateNotifier: _updateNotifier,
          scheduleSaveMessages: _scheduleSaveMessages,
          fetchMessages: _fetchMessages);
    });
  }

  // Update the normalizeMessage function to handle LORRO data structure
  Future<void> _loadCurrentUserId({
    required String currentUserId,
  }) async {
    final userId = await UserPreferences.getUserId() ?? '';
    if (userId.isEmpty || (widget.datumId?.isEmpty ?? true)) {
      debugPrint('⚠️ _loadCurrentUserId: missing userId or datumId');
      return;
    }

    currentUserId = userId;
    _messageHandler =
        MessageHandler(currentUserId: currentUserId, convoId: widget.convoId);

    setupMessageListener(
        currentUserId: currentUserId,
        datumId: widget.datumId ?? "",
        receiverId: widget.receiverId ?? "",
        messagerBloc: _messagerBloc,
        dbMessages: dbMessages,
        messages: messages,
        socketMessages: socketMessages,
        statusSubscription: _statusSubscription,
        socketService: socketService,
        mounted: mounted,
        updateNotifier: _updateNotifier,
        scheduleSaveMessages: _scheduleSaveMessages,
        messageDeletedSubscription: null,
        markMessagesAsDeleted: (messageIds, {deleteFor = ''}) {
          markMessagesAsDeleted(
              messageIds: messageIds,
              setState: setState,
              dbMessages: dbMessages,
              messages: messages,
              socketMessages: socketMessages,
              updateNotifier: _updateNotifier,
              scheduleSaveMessages: _scheduleSaveMessages,
              convoId: widget.convoId);
        },
        parseTime: _parseTime,
        hasReplyForMessage: hasReplyForMessage);
    _setupReactionListener();

    if (mounted) setState(() {});
  }

  DateTime _parseTime(dynamic time) {
    ensureMessageHandler(_messageHandler, currentUserId, widget.convoId);
    return _messageHandler!.parseTime(time);
  }

  void _scheduleSaveMessages() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveDebounceDuration, () {
      // Use _currentConversationId for new chats where widget.convoId is empty
      final convoId =
          widget.convoId.isNotEmpty ? widget.convoId : _currentConversationId;
      if (convoId.isEmpty) return;

      // ✅ SAVE SINGLE SOURCE OF TRUTH
      LocalChatStorage.saveMessages(
        convoId,
        List<Map<String, dynamic>>.from(_allMessages),
      );
    });
  }

  void _updateNotifier({bool isInitialLoad = false}) {
    final full = getCombinedMessages(
        dbMessages: dbMessages,
        messages: messages,
        socketMessages: socketMessages,
        parseTime: _parseTime,
        hasReplyForMessage: hasReplyForMessage);
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

    updateNotifierFromAll(
        allMessages: _allMessages, messagesNotifier: _messagesNotifier);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.datumId == null) {
      return;
    }
    log('🔐 private chat screen : ${widget.convoId}');

    final reply = _replyMessage;

    final text = _messageController.text.trim();

    // ---------- READ RECEIPTS ----------
    final visibleMessages = _messagesNotifier.value;
    final unreadIds = getUnreadMessageIds(visibleMessages, currentUserId);
    if (unreadIds.isNotEmpty) {
      sendReadReceipts(
          messageIds: unreadIds,
          dbMessages: dbMessages,
          messages: messages,
          socketMessages: socketMessages,
          parseTime: _parseTime,
          hasReplyForMessage: hasReplyForMessage,
          currentUserId: currentUserId,
          datumId: widget.datumId ?? "",
          convoId: widget.convoId,
          updateNotifier: _updateNotifier,
          scheduleSaveMessages: _scheduleSaveMessages,
          alreadyRead: _alreadyRead);
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
    updateNotifierFromAll(
        allMessages: _allMessages, messagesNotifier: _messagesNotifier);

    //_audioPlayerService.playMessageSentSound();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom(_scrollController, setState, _showScrollToBottomButton);
    });

    _seenMessageIds.add(localId);

    // ---------- RESET INPUT ----------
    _messageController.clear();
    setState(() {});
    await clearDraft(
        currentConversationId: _currentConversationId,
        conversationId: widget.convoId,
        chatListBloc: _chatListBloc);
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
      log(" _replyPreview $_replyPreview");
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
      replaceTempMessageWithReal(
        tempId: localId,
        realId: sent.messageId,
        status: sent.messageStatus,
        socketMessages: socketMessages,
        messages: messages,
        dbMessages: dbMessages,
        allMessages: _allMessages,
        seenMessageIds: _seenMessageIds,
        updateNotifierFromAll: () {
          updateNotifierFromAll(
              allMessages: _allMessages, messagesNotifier: _messagesNotifier);
        },
        scheduleSaveMessages: _scheduleSaveMessages,
      );
    } catch (e, st) {
      log('❌ send message error: $e\n$st');
      updateMessageStatus(
          messageId: localId,
          status: 'failed',
          messages: messages,
          socketMessages: socketMessages,
          updateNotifier: _updateNotifier,
          scheduleSaveMessages: _scheduleSaveMessages,
          dbMessages: dbMessages);
    }
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

  String get roomId =>
      socketService.generateRoomId(currentUserId, widget.datumId ?? '');

  Future<void> _fetchMessages() async {
    _messagerBloc.add(FetchMessagesEvent(
        convoId: widget.convoId, page: _currentPage, limit: _initialLimit));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;

    // ✅ WhatsApp logic
    final shouldShowArrow = !isNearBottom(_scrollController);

    if (shouldShowArrow != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = shouldShowArrow;
      });
    }
    final maxExtent = _scrollController.position.maxScrollExtent;

    if (offset < maxExtent - 120) return;

    final total = _allMessages.length;

    log(
      '🔍 Scroll at top - total: $total, '
      'visible: $_visibleCount, '
      'hasNextPage: $_hasNextPage, '
      'isLoading: $_isLoadingMore',
    );

    if (_visibleCount < total && !_isLoadingMore) {
      _isLoadingMore = true;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        setState(() {
          _visibleCount = (_visibleCount + _pageStep).clamp(0, total);
          _isLoadingMore = false;
        });

        updateNotifierFromAll(
            allMessages: _allMessages, messagesNotifier: _messagesNotifier);
      });
    } else if (_visibleCount >= total && _hasNextPage && !_isLoadingMore) {
      _triggerServerFetch();
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

  Widget _buildReactionsBar(Map<String, dynamic> message, bool sentByMe) {
    final messageId =
        (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '')
            .toString();

    final mergedReactions = messageId.isNotEmpty
        ? collectMergedReactionsForMessage(
            messageId: messageId,
            dbMessages: dbMessages,
            messages: messages,
            socketMessages: socketMessages)
        : <Map<String, dynamic>>[];

    // ✅ CREATE UPDATED MESSAGE
    final msgCopy = Map<String, dynamic>.from(message);
    msgCopy['reactions'] = mergedReactions;

    return ReactionBar(
      message: message, // ✅ THIS IS THE FIX
      currentUserId: currentUserId,
      // onReactionTap: (_, emoji) =>
      //     _handleReactionTap(message, emoji),
      onOpenReactors: (_, emoji) => showReactionsBottomSheet(
          message: message,
          initialEmoji: emoji,
          dbMessages: dbMessages,
          messages: messages,
          socketMessages: socketMessages,
          allMessages: _allMessages,
          context: context,
          parseTime: _parseTime,
          currentUserId: currentUserId,
          messagerBloc: _messagerBloc,
          convoId: widget.convoId,
          firstname: widget.firstname ?? "",
          lastname: widget.lastname ?? "",
          receiverId: widget.receiverId ?? "",
          messagesNotifier: _messagesNotifier,
          setState: setState,
          hasReplyForMessage: hasReplyForMessage),
      recentEmojis: recentEmojis,
      onEmojiUpdated: (list) {
        setState(() => recentEmojis = list);
      },
    );
  }

  void _onReplySelected(
    Map<String, dynamic> replyMessage,
    Map<String, dynamic> replyPreview,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _replyMessage = replyMessage;
        _replyPreview = replyPreview;
      });

      _focusNode.requestFocus();
    });
  }

  void _onReplyRequested(
    Map<String, dynamic> message,
    bool isSentByMe,
  ) {
    final resolved = resolveReplySource(message);

    _replyToMessage(
      resolved,
      isSendMe: isSentByMe,
    );
  }

  void _onReactionSelected(
    Map<String, dynamic> msg,
    String emoji,
  ) {
    setState(() {
      handleReactionTap(
          message: msg,
          emoji: emoji,
          currentUserId: currentUserId,
          messagerBloc: _messagerBloc,
          convoId: widget.convoId,
          receiverId: widget.receiverId ?? "",
          firstname: widget.firstname ?? "",
          lastname: widget.lastname ?? "",
          setState: setState,
          allMessages: _allMessages,
          messagesNotifier: _messagesNotifier); // existing logic
      _showSearchAppBar = false;
      _isSelectionMode = false;
      _selectedMessages.clear();
      _selectedMessageKeys.clear();
    });
  }

  void _onRecentEmojisChanged(List<String> list) {
    setState(() {
      recentEmojis = list;
    });
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
          onDeleteForEveryone: () {
            deleteSelectedMessages(
                deleteFor: 'everyone',
                setState: setState,
                selectedMessageKeys: _selectedMessageKeys,
                selectedMessageIds: _selectedMessageIds,
                isSelectionMode: _isSelectionMode,
                selectedMessages: _selectedMessages,
                generateMessageKey: (msg) {
                  generateMessageKey(
                      msg: {},
                      messageHandler: _messageHandler,
                      currentUserId: currentUserId,
                      convoId: widget.convoId);
                },
                scheduleSaveMessages: _scheduleSaveMessages,
                markMessagesAsDeleted: (messageIds, {deleteFor = ''}) {
                  markMessagesAsDeleted(
                      deleteFor: "everyone",
                      messageIds: messageIds,
                      setState: setState,
                      dbMessages: dbMessages,
                      messages: messages,
                      socketMessages: socketMessages,
                      updateNotifier: _updateNotifier,
                      scheduleSaveMessages: _scheduleSaveMessages,
                      convoId: widget.convoId);
                },
                messagerBloc: _messagerBloc,
                convoId: widget.convoId,
                currentUserId: currentUserId,
                receiverId: widget.receiverId ?? "",
                fetchMessages: _fetchMessages);
          },
          onDeleteForMe: () {
            deleteSelectedMessages(
                deleteFor: 'me',
                setState: setState,
                selectedMessageKeys: _selectedMessageKeys,
                selectedMessageIds: _selectedMessageIds,
                isSelectionMode: _isSelectionMode,
                selectedMessages: _selectedMessages,
                generateMessageKey: (msg) {
                  generateMessageKey(
                      msg: msg,
                      messageHandler: _messageHandler,
                      currentUserId: currentUserId,
                      convoId: widget.convoId);
                },
                scheduleSaveMessages: _scheduleSaveMessages,
                markMessagesAsDeleted: (messageId, {deleteFor = ""}) {
                  markMessagesAsDeleted(
                      deleteFor: "me",
                      messageIds: messageId,
                      setState: setState,
                      dbMessages: dbMessages,
                      messages: messages,
                      socketMessages: socketMessages,
                      updateNotifier: _updateNotifier,
                      scheduleSaveMessages: _scheduleSaveMessages,
                      convoId: widget.convoId);
                },
                messagerBloc: _messagerBloc,
                convoId: widget.convoId,
                currentUserId: currentUserId,
                receiverId: widget.receiverId ?? "",
                fetchMessages: _fetchMessages);
          },
        );
      },
      forwardSelectedMessages: () {
        forwardSelectedMessages(
            selectedMessages: _selectedMessages,
            currentUserId: currentUserId,
            convoId: widget.convoId,
            firstname: widget.firstname ?? "",
            isSentMe: isSentMe,
            setState: setState,
            selectedMessageKeys: _selectedMessageKeys,
            selectedMessageIds: _selectedMessageIds,
            isSelectionMode: _isSelectionMode);
      },
      starSelectedMessages: () {
        starSelectedMessages(
            setState: setState,
            selectedMessageKeys: _selectedMessageKeys,
            selectedMessageIds: _selectedMessageIds,
            isSelectionMode: _isSelectionMode,
            selectedMessages: _selectedMessages);
      },
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
      onSearchUp: () {
        _onSearchUp(context);
      },
      onSearchDown: _onSearchDown,
      searchMatchCount: _searchMatchIds.length,
      searchMatchIndex:
          _searchMatchIds.isEmpty ? 0 : _currentSearchMatchIndex + 1,
      hasLeftGroup: false,
      groupMembers: [],
    );
  }

  void toggleSearchAppBar() =>
      setState(() => _showSearchAppBar = !_showSearchAppBar);

  void _saveAllMessages() {
    if (widget.convoId.isEmpty) return;
    final combined = [...dbMessages, ...messages, ...socketMessages];
    LocalChatStorage.saveMessages(widget.convoId, combined);
  }

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
      child: Stack(
        children: [
          ReusableChatScaffold(
            appBar: _buildAppBar(),
            chatBody: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _messagesNotifier,
              builder: (context, combinedMessages, child) {
                markVisibleMessagesAsRead(
                  screenActive: _screenActive,
                  messages: combinedMessages,
                  alreadyRead: _alreadyRead,
                  getUnreadMessageIds: (messages) {
                    return getUnreadMessageIds(messages, currentUserId);
                  },
                  updateMessageStatus: (messageId, status) {
                    updateMessageStatus(
                        messageId: messageId,
                        status: status,
                        messages: messages,
                        socketMessages: socketMessages,
                        dbMessages: dbMessages,
                        updateNotifier: _updateNotifier,
                        scheduleSaveMessages: _scheduleSaveMessages);
                  },
                  sendReadReceipts: (messageIds) {
                    sendReadReceipts(
                        messageIds: messageIds,
                        dbMessages: dbMessages,
                        messages: messages,
                        socketMessages: socketMessages,
                        parseTime: _parseTime,
                        hasReplyForMessage: hasReplyForMessage,
                        currentUserId: currentUserId,
                        datumId: widget.datumId ?? "",
                        convoId: widget.convoId,
                        updateNotifier: _updateNotifier,
                        scheduleSaveMessages: _scheduleSaveMessages,
                        alreadyRead: _alreadyRead);
                  },
                );
                final groupedMessages =
                    buildGroupedMessages(combinedMessages, _parseTime);

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
                          log("🔥 $_currentConversationId");

                          socketService.setActiveConversation(convoId);

                          log("✅ Conversation created: $convoId");
                        }
                      }
                    }

                    if (state is MessageAckReceived) {
                      replaceTempMessageWithReal(
                        tempId: state.tempId,
                        realId: state.realId,
                        status: state.status,
                        socketMessages: socketMessages,
                        messages: messages,
                        dbMessages: dbMessages,
                        allMessages: _allMessages,
                        seenMessageIds: _seenMessageIds,
                        updateNotifierFromAll: () {
                          updateNotifierFromAll(
                              allMessages: _allMessages,
                              messagesNotifier: _messagesNotifier);
                        },
                        scheduleSaveMessages: _scheduleSaveMessages,
                      );
                    } else if (state is LocalAudioMessageAdded) {
                      // ✅ Handle optimistic audio message - add directly to _allMessages
                      final audioMessage = state.message;
                      final id = audioMessage['message_id']?.toString();

                      if (id != null && id.isNotEmpty) {
                        // ✅ Check if not already in _allMessages (single source of truth)
                        final exists = _allMessages
                            .any((m) => (m['message_id'] ?? '') == id);

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
                          updateNotifierFromAll(
                              allMessages: _allMessages,
                              messagesNotifier: _messagesNotifier);

                          _scheduleSaveMessages();

                          // Scroll to bottom to show new message
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            scrollToBottom(_scrollController, setState,
                                _showScrollToBottomButton);
                          });
                        }
                      }
                    } else if (state is MessageDeletedSuccessfully) {
                      // Handle optimistic deletion UI update
                      markMessagesAsDeleted(
                          messageIds: state.deletedMessageIds,
                          setState: setState,
                          dbMessages: dbMessages,
                          messages: messages,
                          socketMessages: socketMessages,
                          updateNotifier: _updateNotifier,
                          scheduleSaveMessages: _scheduleSaveMessages,
                          convoId: widget.convoId);
                    } else if (state is MessagerLoaded) {
                      final flat = state.response.data
                          .expand((g) => g.messages)
                          .map((e) =>
                              normalizeMessage(e.toJson(), text: "state"))
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
                        (a, b) => _parseTime(a['time'])
                            .compareTo(_parseTime(b['time'])),
                      );

                      updateNotifierFromAll(
                          allMessages: _allMessages,
                          messagesNotifier: _messagesNotifier);

                      _hasNextPage = state.response.hasNextPage;
                      _isLoadingMore = false;

                      // 1) Flatten groups → List<Datum>
                      final allMessages = state.response.data
                          .expand((group) => group.messages)
                          .toList();

                      // 2) Normalize server data
                      var newDbMessages = allMessages
                          .map<Map<String, dynamic>>(
                            (datum) => normalizeMessage(datum.toJson(),
                                text: "newDbMessages"),
                          )
                          .where((m) => m.isNotEmpty)
                          .toList();
                      // log("allMessagesssss $newDbMessages");
                      // newDbMessages = _inferGrouping(newDbMessages);

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
                          final newHasReply = hasReplyForMessage(m);
                          if (!newHasReply) {
                            try {
                              if (prev['_localReply'] != null) {
                                m['reply'] = Map<String, dynamic>.from(
                                    prev['_localReply']);
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
                        try {
                          final prevReply = prev['reply'];
                          final newReply = m['reply'];

                          final prevGrouped =
                              prevReply?['isGroupedMessage'] == true;
                          final newGrouped =
                              newReply?['isGroupedMessage'] == true ||
                                  newReply?['isGroupedMessageId'] != null;

                          // Server upgraded reply → overwrite local reply
                          if (!prevGrouped && newGrouped) {
                            m['reply'] = Map<String, dynamic>.from(newReply);
                            m['isReplyMessage'] = true;
                            m['_localHasReply'] = true; // keep consistency
                            m['_localReply'] = m['reply'];
                          }
                        } catch (_) {}
                        // preserve local reactions if server omitted them
                        final prevReactions =
                            extractReactions(prev['reactions']);
                        final newReactions = extractReactions(m['reactions']);
                        if (newReactions.isEmpty && prevReactions.isNotEmpty) {
                          m['reactions'] = prevReactions;
                        } else if (newReactions.isNotEmpty &&
                            prevReactions.isNotEmpty) {
                          // merge them (union by user)
                          m['reactions'] = mergeReactions(
                              local: prevReactions, incoming: newReactions);
                        }

                        /// preserve local 'read' only if we locally marked it
                        final prevStatus =
                            (prev['messageStatus'] ?? prev['status'] ?? '')
                                .toString();
                        final newStatus =
                            (m['messageStatus'] ?? m['status'] ?? '')
                                .toString();
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
                                    (m['message_id'] ??
                                            m['messageId'] ??
                                            m['id'])
                                        ?.toString() ==
                                    id,
                                orElse: () => {},
                              );

                          // Start with fresh copy we'll store
                          final Map<String, dynamic> merged =
                              Map<String, dynamic>.from(fresh);

                          // ---- Preserve reply info if local had it but server omitted it ----
                          try {
                            final bool prevHasLocalReply =
                                (localPrev.isNotEmpty) &&
                                    (localPrev['_localHasReply'] == true ||
                                        localPrev['reply'] != null ||
                                        localPrev['reply_message_id'] != null);

                            final bool freshHasReply =
                                hasReplyForMessage(merged);

                            if (prevHasLocalReply && !freshHasReply) {
                              // Prefer a locally stored _localReply if present (set when you replaced temp->real)
                              if (localPrev['_localReply'] != null) {
                                merged['reply'] = Map<String, dynamic>.from(
                                    localPrev['_localReply']);
                              } else if (localPrev['reply'] != null) {
                                merged['reply'] = Map<String, dynamic>.from(
                                    localPrev['reply']);
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
                                ? extractReactions(localPrev['reactions'])
                                : <Map<String, dynamic>>[];
                            final newReactions =
                                extractReactions(merged['reactions']);
                            if (newReactions.isEmpty &&
                                prevReactions.isNotEmpty) {
                              merged['reactions'] = prevReactions;
                            }
                          } catch (_) {}

                          // ---- Preserve locally marked read state if we previously flagged it ----
                          try {
                            final prevLocallyMarkedRead =
                                (localPrev.isNotEmpty) &&
                                    localPrev['_localMarkedRead'] == true;
                            final newStatus = (merged['messageStatus'] ??
                                    merged['status'] ??
                                    '')
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
                        scrollToBottom(_scrollController, setState,
                            _showScrollToBottomButton);
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          try {
                            if (_prevScrollExtentBeforeLoad > 0 &&
                                _scrollController.hasClients) {
                              final newMax =
                                  _scrollController.position.maxScrollExtent;
                              final delta =
                                  newMax - _prevScrollExtentBeforeLoad;
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
                      replaceTempMessageWithReal(
                        tempId: state.tempId,
                        realId: state.realId,
                        status: state.status,
                        socketMessages: socketMessages,
                        messages: messages,
                        dbMessages: dbMessages,
                        allMessages: _allMessages,
                        seenMessageIds: _seenMessageIds,
                        updateNotifierFromAll: () {
                          updateNotifierFromAll(
                              allMessages: _allMessages,
                              messagesNotifier: _messagesNotifier);
                        },
                        scheduleSaveMessages: _scheduleSaveMessages,
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
                        scrollToBottom(_scrollController, setState,
                            _showScrollToBottomButton);
                      });
                    } else if (state is NewMessageReceivedState) {
                      if (state.message['isGroupChat'] == true) return;
                      final normalized =
                          normalizeMessage(state.message, text: "normalized");
                      if (normalized.isEmpty) return;

                      handleIncomingRawMessage(
                          raw: normalized,
                          allMessages: _allMessages,
                          currentUserId: currentUserId,
                          parseTime: _parseTime,
                          visibleCount: _visibleCount,
                          updateNotifierFromAll: () {
                            updateNotifierFromAll(
                                allMessages: _allMessages,
                                messagesNotifier: _messagesNotifier);
                          },
                          mounted: mounted,
                          scrollController: _scrollController,
                          setState: setState,
                          showScrollToBottomButton: _showScrollToBottomButton);
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

                    return MessageWidgets(
                      isLoadingMore: _isLoadingMore,
                      groupedMessages: groupedMessages,
                      scrollController: _scrollController,
                      highlightedMessageId: _highlightedMessageId,
                      messageContexts: _messageContexts,
                      currentUser: currentUserId,
                      currentUserId: currentUserId,
                      isSentMe: isSentMe,
                      buildMessageBubble: ({
                        required int length,
                        required Map<String, dynamic> message,
                        required bool isSentByMe,
                        required bool isReply,
                      }) {
                        return buildMessageBubble(
                          length: length,
                          message: message,
                          isSentByMe: isSentByMe,
                          isReply: isReply,
                          mounted: mounted,
                          generateMessageKey: (msg) {
                            return generateMessageKey(
                                msg: msg,
                                messageHandler: _messageHandler,
                                currentUserId: currentUserId,
                                convoId: widget.convoId);
                          },
                          currentUserId: currentUserId,
                          allMessages: _allMessages,
                          messageContexts: _messageContexts,
                          isSelectionMode: _isSelectionMode,
                          selectedMessageKeys: _selectedMessageKeys,
                          showSearchAppBar: _showSearchAppBar,
                          selectedMessages: _selectedMessages,
                          convoId: widget.convoId,
                          receiverId: widget.receiverId ?? "",
                          firstname: widget.firstname ?? "",
                          lastname: widget.lastname ?? "",
                          searchController: _searchController,
                          recentEmojis: recentEmojis,
                          setState: setState,
                          onMessageTap: (message) {
                            onMessageTap(
                                message: message,
                                isSelectionMode: _isSelectionMode,
                                toggleMessageSelection: (msg) {
                                  toggleMessageSelection(
                                    msg: msg,
                                    setState: setState,
                                    selectedMessageKeys: _selectedMessageKeys,
                                    selectedMessageIds: _selectedMessageIds,
                                    isSelectionMode: _isSelectionMode,
                                    selectedMessages: _selectedMessages,
                                    generateMessageKey: (msg) {
                                      return generateMessageKey(
                                          msg: msg,
                                          messageHandler: _messageHandler,
                                          currentUserId: currentUserId,
                                          convoId: widget.convoId);
                                    },
                                  );
                                },
                                messagesNotifier: _messagesNotifier,
                                messageContexts: _messageContexts,
                                highlightMessage: _highlightMessage,
                                scrollController: _scrollController,
                                dbMessages: dbMessages,
                                messages: messages,
                                socketMessages: socketMessages,
                                parseTime: _parseTime,
                                hasReplyForMessage: hasReplyForMessage,
                                hasNextPage: _hasNextPage,
                                messagerBloc: _messagerBloc,
                                convoId: widget.convoId,
                                currentPage: _currentPage,
                                initialLimit: _initialLimit,
                                mounted: mounted,
                                isSameDay: isSameDay);
                          },
                          onMessageLongPress: (message) {
                            onMessageLongPress(
                              message: message,
                              isSelectionMode: _isSelectionMode,
                              setState: setState,
                              toggleMessageSelection: (msg) {
                                toggleMessageSelection(
                                  msg: msg,
                                  setState: setState,
                                  selectedMessageKeys: _selectedMessageKeys,
                                  selectedMessageIds: _selectedMessageIds,
                                  isSelectionMode: _isSelectionMode,
                                  selectedMessages: _selectedMessages,
                                  generateMessageKey: (msg) {
                                    return generateMessageKey(
                                        msg: msg,
                                        messageHandler: _messageHandler,
                                        currentUserId: currentUserId,
                                        convoId: widget.convoId);
                                  },
                                );
                              },
                            );
                          },
                          replyToMessage: _replyToMessage,
                          openFile: (url, type) {
                            openFile(
                                urlOrPath: url,
                                fileType: type,
                                context: context,
                                currentUser: currentUserId,
                                convoId: widget.convoId,
                                userName: widget.userName);
                          },
                          buildReactionsBar: _buildReactionsBar,
                          getCombinedMessages: () {
                            return getCombinedMessages(
                                dbMessages: dbMessages,
                                messages: messages,
                                socketMessages: socketMessages,
                                parseTime: _parseTime,
                                hasReplyForMessage: hasReplyForMessage);
                          },
                          handleReactionTap: (msg, emoji) {
                            handleReactionTap(
                                message: msg,
                                emoji: emoji,
                                currentUserId: currentUserId,
                                messagerBloc: _messagerBloc,
                                convoId: widget.convoId,
                                receiverId: widget.receiverId ?? "",
                                firstname: widget.firstname ?? "",
                                lastname: widget.lastname ?? "",
                                setState: setState,
                                allMessages: _allMessages,
                                messagesNotifier:
                                    _messagesNotifier); // existing logic
                          },
                          highlightMessage: _highlightMessage,
                          highlightAndScrollToContext: (ctx, messageId) {
                            highlightAndScrollToContext(
                              ctx,
                              messageId,
                              _highlightMessage,
                            );
                          },
                          messagesNotifier: _messagesNotifier,
                          scrollController: _scrollController,
                          estimateScrollOffset: (listIndex, messageId) {
                            return estimateScrollOffset(
                                listIndex, messageId, _parseTime, isSameDay);
                          },
                          fetchUntilMessageFound: (listIndex) {
                            return fetchUntilMessageFound(
                                messageId: listIndex,
                                mounted: mounted,
                                dbMessages: dbMessages,
                                messages: messages,
                                socketMessages: socketMessages,
                                parseTime: _parseTime,
                                hasReplyForMessage: hasReplyForMessage,
                                hasNextPage: _hasNextPage,
                                messagerBloc: _messagerBloc,
                                convoId: widget.convoId,
                                currentPage: _currentPage,
                                initialLimit: _initialLimit);
                          },
                          estimateMessageHeight: (listIndex, messageId) {
                            return estimateMessageHeight(
                                listIndex, messageId, _parseTime, isSameDay);
                          },
                          getMessageSenderId: (Map<String, dynamic> p1) {},
                        );
                      },
                      parseTime: _parseTime,
                      isSelectionMode: _isSelectionMode,
                      searchController: _searchController,
                      selectedMessageKeys: _selectedMessageKeys,
                      recentEmojis: recentEmojis,
                      showSearchAppBar: _showSearchAppBar,
                      selectedMessages: _selectedMessages,
                      convoId: widget.convoId,
                      receiverId: widget.receiverId ?? "",
                      firstname: widget.firstname ?? "",
                      lastname: widget.lastname ?? "",
                      selectGroupedMessages: (msg) {
                        selectGroupedMessages(
                            grouped: msg,
                            generateMessageKey: (msg) {
                              return generateMessageKey(
                                  msg: msg,
                                  messageHandler: _messageHandler,
                                  currentUserId: currentUserId,
                                  convoId: widget.convoId);
                            },
                            isSelectionMode: _isSelectionMode,
                            selectedMessageIds: _selectedMessageIds,
                            selectedMessageKeys: _selectedMessageKeys,
                            selectedMessages: _selectedMessages,
                            setState: setState);
                      },
                      setState: setState,
                      buildReactionsBar: _buildReactionsBar,
                      onMessageOwnerResolved: (senderId, isSentByMe) {},
                      onRecentEmojisChanged: _onRecentEmojisChanged,
                      onReactionSelected: _onReactionSelected,
                      onReplySelected: _onReplySelected,
                      buildReplyPreviewFromGroup: buildReplyPreviewFromGroup,
                      onReplyRequested: _onReplyRequested,
                      getMessageSenderId: (Map<String, dynamic> p1) {},
                      generateMessageKey: (msg) {
                        return generateMessageKey(
                            msg: msg,
                            messageHandler: _messageHandler,
                            currentUserId: currentUserId,
                            convoId: widget.convoId);
                      },
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
          if (_showScrollToBottomButton)
            Positioned(
              right: 16,
              bottom: 90, // above message input
              child: FloatingActionButton(
                mini: true,
                backgroundColor: chatColor,
                onPressed: () {
                  scrollToBottom(
                      _scrollController, setState, _showScrollToBottomButton);
                  setState(() => _showScrollToBottomButton = false);
                },
                child: const Icon(
                  Icons.keyboard_double_arrow_down_outlined,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
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
          scrollToBottom(
              _scrollController, setState, _showScrollToBottomButton);
        });
      }),
      onCameraPressed: () {
        openCamera(
          context: context,
          convoId: widget.convoId,
          currentUserId: currentUserId,
          receiverId: widget.receiverId!,
          setState: setState,
          socketMessages: socketMessages,
          seenMessageIds: _seenMessageIds,
          updateNotifier: _updateNotifier,
          scheduleSaveMessages: _scheduleSaveMessages,
          scrollToBottom: () {
            scrollToBottom(
                _scrollController, setState, _showScrollToBottomButton);
          },
        );
      },
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
          saveDraft(
              draft: text,
              chatListBloc: _chatListBloc,
              conversationId: widget.convoId,
              currentConversationId: _currentConversationId);
        } else {
          clearDraft(
              currentConversationId: _currentConversationId,
              conversationId: widget.convoId,
              chatListBloc: _chatListBloc);
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
        sendAudioMessage(
            path: path,
            duration: duration,
            messagerBloc: _messagerBloc,
            currentUserId: currentUserId,
            receiverId: widget.receiverId ?? "",
            convoId: widget.convoId);
      },
    );
  }
}
