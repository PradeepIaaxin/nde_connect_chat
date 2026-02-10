import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/GroupMessageBubbleWidget.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/file_opener_utils.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_offline_message_handling.dart';

import 'package:nde_email/presantation/chat/chat_group_Screen/api_servicer.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_media_grouping_utils.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_message_utils.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_normalize_utils.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_reaction_utils.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_separators.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_reply_data.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_text_utils.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_state.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/mention_text_editing_controller.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MediaPreviewScreen.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MixedMediaViewer.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/audio_reuable.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/commonfuntion.dart';
import 'package:nde_email/presantation/chat/widget/custom_appbar.dart';
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/presantation/chat/widget/scaffold.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_viewer.dart'
    as viewer;
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_widget.dart';

import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/reaction_bar.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/whatsapp_swipe_to_reply.dart';
import '../../../data/respiratory.dart';
import '../../../utils/simmer_effect.dart/chat_simmerefect.dart';
import '../../widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import '../../widgets/chat_widgets/messager_Wifgets/buildMessageInputField_widgets.dart';
import '../Socket/Socket_Service.dart';

import '../chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';
import '../chat_list/chat_session_storage/chat_session.dart';
import '../chat_list/chat_bloc.dart';
import '../chat_list/chat_event.dart';

import '../model/emoj_model.dart';
import 'package:nde_email/presantation/chat/chat_ userprofile_screen/bloc/profile_screen_bloc.dart';
import 'package:nde_email/presantation/chat/chat_ userprofile_screen/bloc/profile_screen_event.dart';

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
    this.groupId,
  });

  final String conversationId;
  final String currentUserId;
  final String datumId;
  final String groupAvatarUrl;
  final String groupName;
  final List<String>? groupMembers;
  final bool grpChat;
  final bool favorite;
  final String? groupId;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  String currentUserId = '';
  List<Map<String, dynamic>> dbMessages = [];

  final ValueNotifier<bool> isLongPressed = ValueNotifier<bool>(false);
  List<String> recentEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
  late List<String> groupMembers;
  final recorderHelper = AudioRecorderHelper();
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> socketMessages = [];
  final SocketService socketService = SocketService();

  StreamSubscription<String>? _messageDeletedSubscription;

  bool _hasLeftGroup = false;
  int _currentPage = 1;

  File? _fileUrl;
  final FocusNode _focusNode = FocusNode();
  late final GroupChatBloc _groupBloc;
  late final ChatListBloc _chatListBloc;
  late final GroupOfflineMessageHandler _offlineHandler;
  bool _hasNextPage = false;

  File? _imageFile;
  bool _isLoadingMore = false;
  bool _isRecording = false;
  bool _isSelectionMode = false;

  final int _limit = 40;
  Timer? _timer;
  bool _messagesFetched = false;


  // Locked Recording State
  bool _isRecordingLocked = false;

  final MentionTextEditingController _messageController =
      MentionTextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _recordTimer;

  Timer? _recordingTimer;
  Map<String, dynamic>? _replyMessage;
  Map<String, dynamic>? _replyPreview;
  final ScrollController _scrollController = ScrollController();
  // 🔥 Highlight Logic
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Map<String, BuildContext> _messageContexts = {};
  final Set<String> _selectedMessageIds = {};
  final Set<String> _selectedMessageKeys = {};
  final List<Map<String, dynamic>> _selectedMessages = [];
  bool _showEmoji = false;
  bool _showSearchAppBar = false;
  List<String> _searchMatchGroupIds = [];

  int _currentSearchMatchIndex = -1;
  bool _permissionChecked = false;
  bool _showScrollToBottomButton = false;

  // Pagination / Windowing
  final List<Map<String, dynamic>> _allMessages = [];
  int _visibleCount = 0;
  final int _pageStep = 40;
  final int _initialVisible = 40;
  final ValueNotifier<List<Map<String, dynamic>>> _messagesNotifier =
      ValueNotifier([]);
  StreamSubscription<MessageReaction>? _reactionSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<GroupChatState>? _blocStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  final Set<String> _seenMessageIds = {};

  // Status & Connectivity
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final Set<String> _alreadyRead = {};
  final List<Map<String, dynamic>> _offlineQueue = [];
  final Map<String, String> _pendingStatusUpdates =
      {}; // Buffer for race conditions

  Timer? _saveMessagesDebounce;
  List<Map<String, dynamic>>? _pendingSaveMessages;

  Timer? _readMarkDebounce;
  List<Map<String, dynamic>> _latestGroupedMessages = const [];

@override
void dispose() {
  // 🔥 Immediate safe cancels (must run instantly)
  _draftDebounce?.cancel();
  _saveMessagesDebounce?.cancel();
  _readMarkDebounce?.cancel();

  _messageDeletedSubscription?.cancel();
  _reactionSubscription?.cancel();
  _messageSubscription?.cancel();
  _statusSubscription?.cancel();
  _blocStateSubscription?.cancel();
  _connSub?.cancel();

  _timer?.cancel();
  _recordingTimer?.cancel();
  _recordTimer?.cancel();
  _highlightTimer?.cancel();

  _scrollController.removeListener(_scrollListener);
  _scrollController.dispose();

  _messageController.dispose();
  _focusNode.dispose();
  _searchController.dispose();

  _messageContexts.clear();

  // 🕒 Delay heavy cleanup (0.1 sec)
  Future.delayed(const Duration(milliseconds: 100), () {
    SocketService().clearActiveConversation();

    _scheduleClearSessionImagePath();
  });

  super.dispose();
}

  // void dispose() {
  //   _draftDebounce?.cancel();
  //   _saveMessagesDebounce?.cancel();
  //   _readMarkDebounce?.cancel();
  //   SocketService().clearActiveConversation();
  //   _messageDeletedSubscription?.cancel();
  //   _messageController.text.trim();

  //   _messageController.dispose();
  //   _focusNode.dispose();
  //   _scrollController.removeListener(_scrollListener);
  //   _scrollController.dispose();

  //   _timer?.cancel();
  //   _recordingTimer?.cancel();
  //   _recordTimer?.cancel();
  //   _highlightTimer?.cancel();
  //   _messageContexts.clear();
  //   _reactionSubscription?.cancel();
  //   _messageSubscription?.cancel();
  //   _statusSubscription?.cancel();
  //   _blocStateSubscription?.cancel();
  //   _connSub?.cancel();
  //   _searchController.dispose();

  //   unawaited(_scheduleClearSessionImagePath());
  //   super.dispose();
  // }

  Future<void> _scheduleClearSessionImagePath() {
    return Future<void>(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('chat_image_path');
        await prefs.remove('chat_file_path');
      } catch (_) {}
    });
  }

  void _scheduleSaveMessages(List<Map<String, dynamic>> combined) {
    _pendingSaveMessages = combined;
    _saveMessagesDebounce?.cancel();
    _saveMessagesDebounce = Timer(const Duration(milliseconds: 600), () {
      final pending = _pendingSaveMessages;
      if (pending == null) return;
      _pendingSaveMessages = null;
      unawaited(
          GrpLocalChatStorage.saveMessages(widget.conversationId, pending));
    });
  }

  void _scheduleMarkReadAfterScrollStops() {
    _readMarkDebounce?.cancel();
    _readMarkDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_latestGroupedMessages.isEmpty) return;
      _markVisibleMessagesAsRead(_latestGroupedMessages);
    });
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchMatchGroupIds.clear(); // stores MESSAGE IDs
        _currentSearchMatchIndex = 0;
        _highlightedMessageId = null;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final combined = _getCombinedMessages();

    final List<String> matchIds = [];

    for (final msg in combined) {
      final content = (msg['content'] ?? '').toString().toLowerCase();

      final isDeleted =
          msg['is_deleted'] == true || msg['messageStatus'] == 'deleted';

      final isSystem =
          msg['contentType'] == 'system' || msg['ContentType'] == 'system';

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
      if (isDocument && contentText.isEmpty) {
        continue;
      }
      if (hasLink) continue; // Any message containing a URL

      // Only search in text content (not file names for media)
      if (content.contains(lowerQuery)) {
        final msgId = GroupChatMessageUtils.anyId(msg);
        if (msgId.isNotEmpty) {
          matchIds.add(msgId);
        }
      }
    }

    // 🔥 Expand visible window to OLDEST match
    int oldestIndex = combined.length;
    for (final id in matchIds) {
      final idx =
          combined.indexWhere((m) => GroupChatMessageUtils.anyId(m) == id);
      if (idx != -1 && idx < oldestIndex) {
        oldestIndex = idx;
      }
    }

    if (oldestIndex < combined.length) {
      final neededVisible = combined.length - oldestIndex;
      if (_visibleCount < neededVisible) {
        setState(() {
          _visibleCount = neededVisible + 5;
          if (_visibleCount > combined.length) {
            _visibleCount = combined.length;
          }
        });
        _updateNotifier();
        await WidgetsBinding.instance.endOfFrame;
      }
    }

    setState(() {
      _searchMatchGroupIds = matchIds.reversed.toList();
      _currentSearchMatchIndex = 0;
      _highlightedMessageId =
          _searchMatchGroupIds.isNotEmpty ? _searchMatchGroupIds.first : null;
    });

    if (_highlightedMessageId != null) {
      _scrollToMessaageById(_highlightedMessageId!, fetchIfMissing: false);
    } else {
      Messenger.alert(msg: "No results found");
    }
  }

  void _onSearchUp() {
    if (_searchMatchGroupIds.isEmpty) return;

    // Up arrow = go to next/newer message (increment index)
    if (_currentSearchMatchIndex < _searchMatchGroupIds.length - 1) {
      setState(() {
        _currentSearchMatchIndex = _currentSearchMatchIndex + 1;
        _highlightedMessageId = _searchMatchGroupIds[_currentSearchMatchIndex];
      });

      _scrollToMessaageById(_highlightedMessageId!, fetchIfMissing: false);
    }
  }

  void _onSearchDown() {
    if (_searchMatchGroupIds.isEmpty) return;

    // Down arrow = go to previous/older message (decrement index)
    if (_currentSearchMatchIndex > 0) {
      setState(() {
        _currentSearchMatchIndex = _currentSearchMatchIndex - 1;
        _highlightedMessageId = _searchMatchGroupIds[_currentSearchMatchIndex];
      });

      _scrollToMessaageById(_highlightedMessageId!, fetchIfMissing: false);
    }
  }

  Future<bool> _scrollToMessaageById(
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

      // Increased delay for better stability
      await Future.delayed(const Duration(milliseconds: 150));

      final targetCtx = _messageContexts[messageId];
      if (targetCtx != null && targetCtx.mounted) {
        _highlightAndScrollToContext(targetCtx, messageId);
        return true;
      }

      double currentEstimate = estimatedOffset;
      // Increased retries and delay
      for (int attempt = 0; attempt < 5; attempt++) {
        await Future.delayed(const Duration(milliseconds: 100));

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
            correction += _estimateMessageHeight(k, combinedMessages);
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
      //  _triggerServerFetch();
      await Future.delayed(const Duration(milliseconds: 300));
      return _scrollToMessageById(messageId);
    }

    return false;
  }

  void _hideSearchAppBar() {
    setState(() {
      _showSearchAppBar = false;
      _searchController.clear();

      _searchMatchGroupIds.clear();
      _currentSearchMatchIndex = 0;
    });
  }

  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();

    SocketService().setActiveConversation(widget.conversationId);
    currentUserId = widget.currentUserId;
    _groupBloc = GroupChatBloc(socketService, GrpMessagerApiService());
    _chatListBloc = context.read<ChatListBloc>();
    _offlineHandler = GroupOfflineMessageHandler(
      getContext: () => context,
      getSocketMessages: () => socketMessages,
      getMessages: () => messages,
      getDbMessages: () => dbMessages,
      getSeenMessageIds: () => _seenMessageIds,
      getPendingStatusUpdates: () => _pendingStatusUpdates,
      getOfflineQueue: () => _offlineQueue,
      isOnline: () => _isOnline,
      getSocketService: () => socketService,
      getGroupBloc: () => _groupBloc,
      getConversationId: () => widget.conversationId,
      getCurrentUserId: () => currentUserId,
      getDatumId: () => widget.datumId,
      setState: (fn) {
        if (mounted) setState(fn);
      },
      refreshMessages: _refreshMessages,
      getCombinedMessages: _getCombinedMessages,
      updateMessageStatus: _updateMessageStatus,
    );
    SocketService().joinChatRoom(
      senderId: currentUserId,
      receiverId: widget.datumId,
      isGroupChat: true,
    );

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
          _offlineHandler.flushOfflinePendingMessages();
        }
      }
    });

    _initializeSocket();

    _loadCurrentUserId();

    if (!_permissionChecked) {
      _groupBloc.add(PermissionCheck(widget.datumId));
      _permissionChecked = true;
    }

    _scrollController.addListener(_scrollListener);
 
    _setupMessageListener();

    _messageController.addListener(() {
      _draftDebounce?.cancel();
      _draftDebounce = Timer(const Duration(milliseconds: 400), () {
        final text = _messageController.text.trim();
        if (text.isEmpty) {
          _clearDraft();
        } else {
          _saveDraft(text);
        }
      });
    });

    // Load draft after initialization
    _loadDraft();
    groupMembers = widget.groupMembers ?? [];

    // Fetch fresh group details to ensure we have all members
    _groupBloc
        .add(FetchGroupDetails(groupId: widget.groupId ?? widget.datumId));
    _loadCurrentUserName();

    // Listen to BLoC states for instant status updates
    _groupBloc.stream.listen((state) {
      if (state is GrpMessageSentSuccessfully) {
        final serverMessageId = state.sentMessage.messageId;
        final serverStatus = state.sentMessage.messageStatus;

        if (serverMessageId.isNotEmpty) {
          _updateMessageStatus(serverMessageId, serverStatus);
        }
      } else if (state is GrpMessageAckReceived) {
        _offlineHandler.replaceTempMessageWithReal(
          tempId: state.tempId,
          realId: state.realId,
          status: state.status,
        );
      } else if (state is GroupDetailsLoaded) {
        _updateGroupMembers(state.groupDetails);
      } else if (state is GroupChatLoaded) {}
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

      if (file == null) return;

      // Open preview screen (like Gallery does)
      final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _groupBloc,
            child: MediaPreviewScreen(
              files: [file],
              conversationId: widget.conversationId,
              senderId: currentUserId,
              receiverId: widget.datumId,
              isGroupChat: true,
            ),
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      Messenger.alert(msg: "Could not open camera.");
    }
  }

  void toggleSearchAppBar() {
    setState(() {
      _showSearchAppBar = !_showSearchAppBar;
    });
  }

  void onMessageReceived(Map<String, dynamic> rawData) {
    /// 1️⃣ Extract message safely
    Map<String, dynamic> msg;
    if (rawData['data'] is Map) {
      msg = Map<String, dynamic>.from(rawData['data']);
    } else {
      msg = Map<String, dynamic>.from(rawData);
    }

    // ✅ Filter by conversationId (GROUP SAFETY)
    final String? incomingConvoId =
        (msg['conversationId'] ?? msg['convoId'])?.toString();

    if (incomingConvoId != widget.conversationId) return;

    if (msg['isGroupChat'] != true) return;

    if (incomingConvoId == null || incomingConvoId != widget.conversationId) {
      return; // ❌ Message NOT for this open group
    }

    // ✅ Ensure GROUP CHAT ONLY
    if (msg['isGroupChat'] != true) {
      return; // ❌ Private chat message → IGNORE
    }

    /// 2️⃣ Reaction-only event
    if (msg['event'] == 'updated_reaction') {
      _handleReactionUpdate(msg['data']);
      return;
    }

    /// 3️⃣ Message ID (dedupe)
    final String? messageId =
        (msg['message_id'] ?? msg['messageId'] ?? msg['_id'])?.toString();

    if (messageId == null || _seenMessageIds.contains(messageId)) return;
    _seenMessageIds.add(messageId);

    /// 4️⃣ Resolve REAL sender (GROUP SAFE)
    Map<String, dynamic> sender = {};

    if (msg['properties'] is List) {
      for (final p in msg['properties']) {
        if (p is Map && p['type_of_user'] == 'sender' && p['user'] is Map) {
          sender = Map<String, dynamic>.from(p['user']);
          break;
        }
      }
    }

    // Fallback only if properties missing
    if (sender.isEmpty && msg['sender'] is Map) {
      sender = Map<String, dynamic>.from(msg['sender']);
    }

    /// 5️⃣ Normalize sender name
    final String normalizedUserName = [
      sender['first_name'],
      sender['last_name'],
      sender['name'],
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(' ')
        .trim();

    // 🔥 NEW: Extract and normalize reply data including grouped media info
    Map<String, dynamic>? normalizedReply;
    final replyRaw = msg['reply'] ?? msg['repliedMessage'];
    if (replyRaw is Map<String, dynamic>) {
      normalizedReply = _extractReplyDataFromIncoming(replyRaw);
    }

    /// 6️⃣ Normalize message for UI
    final Map<String, dynamic> newMessage = {
      'message_id': messageId,
      // 'content': (msg['content'] ?? '').toString(),
      'content': sanitizeString((msg['content'] ?? '').toString()),
      'sender': sender,
      'senderId': sender['_id']?.toString(),
      'receiver': msg['receiver'] is Map
          ? Map<String, dynamic>.from(msg['receiver'])
          : {},
      'userName':
          normalizedUserName.isNotEmpty ? normalizedUserName : 'Unknown',
      'messageStatus': msg['messageStatus'] ?? 'delivered',
      'time':
          DateTime.tryParse(msg['time']?.toString() ?? '') ?? DateTime.now(),
      'imageUrl': msg['thumbnailUrl'] ?? msg['originalUrl'],
      'fileUrl': msg['originalUrl'] ?? msg['fileUrl'],
      'fileName': msg['fileName'],
      'fileType': msg['mimeType'] ?? msg['fileType'],
      'ContentType': msg['ContentType'] ?? 'text',
      'isForwarded': msg['isForwarded'] ?? false,
      'reactions': msg['reactions'] ?? [],
      'repliedMessage': normalizedReply,
      'duration': msg['duration']?.toString(),
    };

    if (!mounted) return;

    List<Map<String, dynamic>>? combinedToSave;
    setState(() {
      // Check if message already exists in socketMessages (optimistic update)
      int existingIndex = socketMessages.indexWhere((m) {
        final mid = (m['message_id'] ?? m['messageId'] ?? m['_id'])?.toString();
        return mid == messageId;
      });

      // If not found by ID, but it's from me, attempt heuristic match with pending messages
      if (existingIndex == -1 &&
          (sender['_id']?.toString() == currentUserId ||
              newMessage['senderId'] == currentUserId)) {
        existingIndex = socketMessages.indexWhere((m) {
          final isPending = m['messageStatus'] == 'sending' ||
              m['messageStatus'] == 'pending_offline' ||
              m['messageStatus'] == 'sent';
          if (!isPending) return false;

          // Match by content for text
          if (newMessage['ContentType'] == 'text') {
            return m['content']?.toString().trim() ==
                newMessage['content']?.toString().trim();
          }
          // Match by fileName for media
          if (newMessage['fileName'] != null &&
              m['fileName'] == newMessage['fileName']) {
            return true;
          }
          return false;
        });
      }

      if (existingIndex != -1) {
        // Update existing message with server data
        socketMessages[existingIndex] = newMessage;
      } else {
        // Add as new message
        socketMessages.add(newMessage);
        _scrollToBottom();
        if (_visibleCount > 0) _visibleCount++;
      }

      final combined = _getCombinedMessages();
      combinedToSave = combined;

      _updateNotifier();
    });

    if (combinedToSave != null) {
      _scheduleSaveMessages(combinedToSave!);
    }
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
    } catch (e) {
      log(e.toString());
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

  void _setupMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription =
        socketService.messageStream.listen((Map<String, dynamic> data) {
      onMessageReceived(data);
    });

    // delete message listner
    _messageDeletedSubscription?.cancel();
    _messageDeletedSubscription =
        socketService.messageDeletedStream.listen((messageId) {
      _markMessagesAsDeleted([messageId], deleteFor: 'everyone');
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
          }
          break;
        }
      }
    }

    List<Map<String, dynamic>>? combinedToSave;
    setState(() {
      updateInList(dbMessages, 'dbMessages');
      updateInList(messages, 'messages');
      updateInList(socketMessages, 'socketMessages');

      if (updated) {
        final combined = _getCombinedMessages();
        combinedToSave = combined;
      } else {
        _pendingStatusUpdates[messageId] = status;
      }
      _updateNotifier();
      _refreshMessages();
    });

    if (combinedToSave != null) {
      _scheduleSaveMessages(combinedToSave!);
    }
  }

  /// 🔥 NEW: Extract and normalize reply data from incoming message
  Map<String, dynamic>? _extractReplyDataFromIncoming(
      Map<String, dynamic> replyRaw) {
    return GroupReplyData.extractReplyDataFromIncoming(replyRaw);
  }

  /// Ensure reply payloads are a stable, sanitized Map for UI & sending.
  Map<String, dynamic> _mergeReplyData(dynamic replyData) {
    return GroupReplyData.mergeReplyData(replyData, _allMessages);
  }

  /// Actually apply reaction change to in-memory lists and save
  void _updateMessageWithReaction(MessageReaction reaction) {
    if (!mounted) return;
    String normalizeId(dynamic id) => id?.toString().trim() ?? '';

    bool updated = false;
    final targetId = normalizeId(reaction.messageId);

    void updateReactions(List<Map<String, dynamic>> list, String listName) {
      for (var msg in list) {
        final msgId = normalizeId(
            msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? msg['id']);
        if (msgId == targetId) {
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
      setState(() {
        // _reactionRebuildCounter++; // Force rebuild - Removed
        _updateNotifier();
      });
      final combined = _getCombinedMessages();
      _scheduleSaveMessages(combined);
    } else {}
  }

  // ------------------ Reaction Helpers ------------------

  void _sendAudioMessage(String path, int duration) {
    if (path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) return;

    final messageId = ObjectId().toString();

    // 1. Create optimistic local message for instant UI update
    final localAudioMessage = {
      'content': '',
      'message_id': messageId,
      'senderId': currentUserId,
      'sender': {'_id': currentUserId},
      'messageStatus': 'sending',
      'time': DateTime.now().toIso8601String(),
      'fileName': file.path.split('/').last,
      'fileType': 'audio/m4a',
      'fileUrl': path, // Local file path
      'isLocal': true,
      'contentType': 'audio',
      'duration': duration.toString(),
    };

    // 2. Add to socketMessages for instant display
    setState(() {
      socketMessages.add(localAudioMessage);
    });

    // 3. Update UI and save
    _refreshMessages();
    final combined = _getCombinedMessages();
    _scheduleSaveMessages(combined);

    _scrollToBottom();

    context.read<GroupChatBloc>().add(
          GrpUploadFileEvent(
            file: file,
            convoId: widget.conversationId,
            senderId: currentUserId,
            receiverId: widget.datumId,
            groupId: widget.datumId,
            messageId: messageId,
            message: "",
            isGroupMessage: false,
            groupMessageId: null,
            contentType: 'audio',
            duration: duration.toString(),
          ),
        );

    _replyMessage = null;
  }

  void _updateLocalReactions(String targetMessageId, String? newEmoji) {
    if (targetMessageId.trim().isEmpty) return;

    String normalizeId(dynamic id) => id?.toString().trim() ?? '';
    final apiTargetId =
        GroupChatMessageUtils.normalizeMessageIdForApi(targetMessageId);

    bool changed = false;

    void updateList(List<Map<String, dynamic>> list, String listName) {
      for (int i = 0; i < list.length; i++) {
        final msg = list[i];
        final rawMsgId = normalizeId(
          msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? msg['_id'],
        );
        final normalizedMsgId =
            GroupChatMessageUtils.normalizeMessageIdForApi(rawMsgId);

        // Check both exact match and normalized match
        if (rawMsgId != targetMessageId && normalizedMsgId != apiTargetId) {
          continue;
        }

        // Normalize existing reactions
        final reactions =
            GroupChatReactionUtils.extractReactions(msg['reactions']);

        // remove my old reaction (if any)
        reactions.removeWhere((r) {
          final uid = (r['userId'] ?? r['user']?['_id'])?.toString();
          return uid == currentUserId;
        });

        // add new reaction if not null/empty
        if (newEmoji != null && newEmoji.isNotEmpty) {
          final nameParts = currentUserName.split(" ");
          final firstName = nameParts.isNotEmpty ? nameParts.first : "";
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
        // We need to ensure _getCombinedMessages will pick up the changes.
        // Since we modified the source lists in place (with new maps), it should work.
        final combined = _getCombinedMessages();
        _scheduleSaveMessages(combined);
      } else {}
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
        return;
      }

      final apiMessageId =
          GroupChatMessageUtils.normalizeMessageIdForApi(rawId);

      // normalize reactions for this message
      final List<Map<String, dynamic>> reactions =
          GroupChatReactionUtils.extractReactions(message['reactions']);

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
    } catch (e) {
      log(e.toString());
    }
  }

  bool isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  void _showFullImage(BuildContext context, String imageUrl,
      {Map<String, dynamic>? message}) {
    final media = buildConversationMedia(
      _allMessages,
      currentUserId: currentUserId,
    );
    int index = media.indexWhere((m) {
      // Handle local file vs network url mismatch if possible
      if (m.mediaUrl == imageUrl) return true;
      if (imageUrl.startsWith('http') &&
          m.mediaUrl.endsWith(imageUrl.split('/').last)) {
        return true; // weak match on filename
      }
      return false;
    });

    // Fallback: Match by message ID if available
    if (index == -1 && message != null) {
      final msgId =
          (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '')
              .toString();
      if (msgId.isNotEmpty) {
        index = media.indexWhere((m) {
          final mId = (m.message?['message_id'] ??
                  m.message?['messageId'] ??
                  m.message?['id'] ??
                  '')
              .toString();
          return mId == msgId;
        });
      }
    }

    // Double Fallback: Add the item manually if missing (e.g. optimistic update or filtered out)
    if (index == -1 && message != null) {
      try {
        final senderData = message['sender'] is Map ? message['sender'] : {};
        final senderName = message['userName'] ??
            senderData['name'] ??
            senderData['first_name'] ??
            'Unknown';

        final newItem = viewer.GroupMediaItem(
          previewUrl: imageUrl,
          mediaUrl: imageUrl,
          isVideo: false,
          senderName: senderName,
          senderId: (senderData['_id'] ?? senderData['id'] ?? '').toString(),
          time: message['time']?.toString(),
          message: message,
        );
        media.add(newItem);
        index = media.length - 1;
      } catch (e) {
        debugPrint("Error creating fallback media item: $e");
      }
    }

    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MixedMediaViewer(
            items: media,
            initialIndex: index,
            conversionalId: widget.conversationId,
            fullName: widget.groupName,
            isGroup: true,
            receiverId: widget.groupId,
          ),
        ),
      );
    }
  }
  Future<void> _initMessages() async {
  if (_messagesFetched) return;   
  _messagesFetched = true;

  await Future.delayed(Duration.zero);

  if (mounted) {
    setState(() {
      dbMessages.clear();
      messages.clear();
      socketMessages.clear();
      _seenMessageIds.clear();
    });
  }

  final savedMessages =
      await GrpLocalChatStorage.loadMessages(widget.conversationId);

  if (savedMessages.isNotEmpty) {
    if (mounted) {
      setState(() {
        dbMessages = savedMessages
            .map<Map<String, dynamic>>(
                (msg) => GroupChatNormalizeUtils.normalizeMessage(msg))
            .where((m) => m.isNotEmpty)
            .toList();

        for (var m in dbMessages) {
          final id = (m['message_id'] ?? m['id'])?.toString();
          if (id != null && id.isNotEmpty) _seenMessageIds.add(id);
        }
      });

      _updateNotifier();
    }
  }

  // 🔥 API CALL ONLY ONCE
  _groupBloc.add(
    FetchGroupMessages(
      convoId: widget.conversationId,
      page: 1,
      limit: _limit,
    ),
  );
}


  // Future<void> _initMessages() async {
  //   // 🟢 OPTIMIZATION: Yield to event loop to allow navigation animation to finish smoothly
  //   await Future.delayed(Duration.zero);

  //   // Clear current messages first
  //   if (mounted) {
  //     setState(() {
  //       dbMessages.clear();
  //       messages.clear();
  //       socketMessages.clear();
  //       _seenMessageIds.clear();
  //     });
  //   }

  //   // Load from local storage
  //   final savedMessages =
  //       await GrpLocalChatStorage.loadMessages(widget.conversationId);

  //   if (savedMessages.isNotEmpty) {
  //     if (mounted) {
  //       setState(() {
  //         dbMessages = savedMessages
  //             .map<Map<String, dynamic>>(
  //                 (msg) => GroupChatNormalizeUtils.normalizeMessage(msg))
  //             .where((m) => m.isNotEmpty)
  //             .toList();

  //         for (var m in dbMessages) {
  //           final id = (m['message_id'] ?? m['id'])?.toString();
  //           if (id != null && id.isNotEmpty) _seenMessageIds.add(id);
  //         }
  //       });

  //       _updateNotifier();
  //     }

  //     _groupBloc.add(
  //       FetchGroupMessages(
  //         convoId: widget.conversationId,
  //         page: 1,
  //         limit: _limit,
  //       ),
  //     );
  //   } else {
  //     _groupBloc.add(
  //       FetchGroupMessages(
  //         convoId: widget.conversationId,
  //         page: 1,
  //         limit: _limit,
  //       ),
  //     );
  //   }
  // }

// ------------------ Draft Methods ------------------
  Future<void> _saveDraft(String draft) async {
    if (widget.conversationId.isEmpty) return;
    await GrpLocalChatStorage.saveDraftMessage(widget.conversationId, draft);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.conversationId,
      draftMessage: draft.isEmpty ? null : draft,
    );
    // Trigger UI refresh in chat list
    _chatListBloc.add(UpdateLocalChatList());
  }

  Future<void> _clearDraft() async {
    if (widget.conversationId.isEmpty) return;
    await GrpLocalChatStorage.clearDraftMessage(widget.conversationId);
    ChatSessionStorage.updateDraftMessage(
      convoId: widget.conversationId,
      draftMessage: null,
    );
    // Trigger UI refresh in chat list
    _chatListBloc.add(UpdateLocalChatList());
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

// Add this method to handle permission state changes
  void _handlePermissionResponse(Map<String, dynamic>? response) {
    if (response != null && response['type'] == 'left') {
      if (mounted) {
        setState(() {
          _hasLeftGroup = true;
        });
      }

      // Clear any draft messages
      if (mounted) {
        _messageController.clear();
        _clearDraft();
      }

      // Show a snackbar notification
      if (mounted) {
        Messenger.alertError("You have left this group");
      }
    } else {
      if (mounted) {
        setState(() {
          _hasLeftGroup = false;
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.datumId.isEmpty) {
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // 🔥 CRITICAL: Extract grouped media info BEFORE creating reply payload
    Map<String, dynamic>? groupedMediaInfo;
    if (_replyPreview != null &&
        ((_replyPreview!['imageCount'] ?? 0) > 0 ||
            (_replyPreview!['videoCount'] ?? 0) > 0)) {
      final groupId = _replyPreview!['group_message_id'];
      if (groupId != null && groupId.toString().isNotEmpty) {
        final firstGroupedMsg = _allMessages.firstWhere(
          (m) =>
              m['group_message_id']?.toString() == groupId &&
              m['is_deleted'] != true &&
              ((m['originalUrl'] != null &&
                      m['originalUrl'].toString().isNotEmpty) ||
                  (m['fileUrl'] != null &&
                      m['fileUrl'].toString().isNotEmpty) ||
                  (m['imageUrl'] != null &&
                      m['imageUrl'].toString().isNotEmpty)),
          orElse: () => <String, dynamic>{},
        );

        if (firstGroupedMsg.isNotEmpty) {
          groupedMediaInfo = {
            'originalUrl': firstGroupedMsg['originalUrl'] ??
                firstGroupedMsg['fileUrl'] ??
                firstGroupedMsg['imageUrl'],
            'thumbnailUrl': firstGroupedMsg['imageUrl'] ??
                firstGroupedMsg['thumbnailUrl'] ??
                firstGroupedMsg['originalUrl'],
            'imageUrl': firstGroupedMsg['imageUrl'] ??
                firstGroupedMsg['thumbnailUrl'] ??
                firstGroupedMsg['originalUrl'],
            'fileUrl':
                firstGroupedMsg['fileUrl'] ?? firstGroupedMsg['originalUrl'],
            'fileName': firstGroupedMsg['fileName'],
            'mimeType':
                firstGroupedMsg['mimeType'] ?? firstGroupedMsg['fileType'],
          };
        }
      }
    }

    // 🛠 Construct a clean reply payload (match PrivateChatScreen structure & include snake_case)
    final Map<String, dynamic>? replyPayload = _replyMessage != null
        ? {
            // id variants
            'message_id': _replyMessage!['message_id'] ?? _replyMessage!['id'],
            'reply_message_id':
                _replyMessage!['message_id'] ?? _replyMessage!['id'],
            'replyToMessage':
                _replyMessage!['message_id'] ?? _replyMessage!['id'],
            'id': _replyMessage!['message_id'] ?? _replyMessage!['id'],

            // sender / user
            'sender': _replyMessage!['sender'],
            'replyToUser': _replyMessage!['senderName'] ??
                _replyMessage!['userName'] ??
                (_replyMessage!['sender'] is Map
                    ? _replyMessage!['sender']['name']
                    : ''),
            'replyUserId': (_replyMessage!['sender'] is Map)
                ? (_replyMessage!['sender']['_id'] ??
                    _replyMessage!['sender']['id'])
                : null,

            // content
            'content': sanitizeString(
                _replyPreview?['content'] ?? _replyMessage!['content'] ?? ''),
            'replyContent': sanitizeString(
                _replyPreview?['content'] ?? _replyMessage!['content'] ?? ''),

            // media (prefer grouped media info when replying to grouped)
            'originalUrl': groupedMediaInfo?['originalUrl'] ??
                _replyPreview?['originalUrl'] ??
                _replyMessage!['originalUrl'] ??
                '',
            'thumbnailUrl': groupedMediaInfo?['thumbnailUrl'] ??
                _replyPreview?['imageUrl'] ??
                _replyMessage!['thumbnailUrl'] ??
                '',
            'imageUrl': groupedMediaInfo?['imageUrl'] ??
                _replyPreview?['imageUrl'] ??
                _replyMessage!['imageUrl'] ??
                '',
            'fileUrl': groupedMediaInfo?['fileUrl'] ??
                _replyPreview?['fileUrl'] ??
                _replyMessage!['fileUrl'] ??
                '',
            'fileName': groupedMediaInfo?['fileName'] ??
                _replyPreview?['fileName'] ??
                _replyMessage!['fileName'] ??
                '',
            'fileType': groupedMediaInfo?['mimeType'] ??
                _replyPreview?['fileType'] ??
                _replyMessage!['fileType'] ??
                _replyMessage!['mimeType'] ??
                '',

            // grouped metadata (both camelCase and snake_case)
            'imageCount': _replyPreview?['imageCount'] ?? 0,
            'videoCount': _replyPreview?['videoCount'] ?? 0,
            // Patch for group_message_id null-safety and non-empty check
            ...(() {
              final gmid = _replyPreview?['group_message_id'];
              return {
                'group_message_id': (gmid != null && gmid.toString().isNotEmpty)
                    ? gmid
                    : _replyMessage!['group_message_id'],
              };
            })(),
            'groupMessageIds': _replyPreview?['groupMessageIds'] ?? [],

            'isGroupedReply': (_replyPreview?['imageCount'] ?? 0) > 0 ||
                (_replyPreview?['videoCount'] ?? 0) > 0,
            'isGroupedMessage': (_replyPreview?['imageCount'] ?? 0) > 0 ||
                (_replyPreview?['videoCount'] ?? 0) > 0,
            'is_grouped_message': (_replyPreview?['imageCount'] ?? 0) > 0 ||
                (_replyPreview?['videoCount'] ?? 0) > 0,
            'isGroupedMessageId': _replyPreview?['group_message_id'] ??
                _replyMessage!['group_message_id'],
            'isGroupedMessageId_snake': _replyPreview?['group_message_id'] ??
                _replyMessage!['group_message_id'],

            // mirror under 'reply' for backends that expect that key shape (PrivateChatScreen compatibility)
            'reply': {
              'replyToUser': _replyMessage!['senderName'] ??
                  _replyMessage!['userName'] ??
                  (_replyMessage!['sender'] is Map
                      ? _replyMessage!['sender']['name']
                      : ''),
              'replyToMessage':
                  _replyMessage!['message_id'] ?? _replyMessage!['id'],
              'replyContent':
                  _replyPreview?['content'] ?? _replyMessage!['content'] ?? '',
              'originalUrl': groupedMediaInfo?['originalUrl'] ??
                  _replyMessage!['originalUrl'] ??
                  '',
              'thumbnailUrl': groupedMediaInfo?['thumbnailUrl'] ??
                  _replyMessage!['thumbnailUrl'] ??
                  '',
              'fileName': groupedMediaInfo?['fileName'] ??
                  _replyMessage!['fileName'] ??
                  '',
              'fileType': groupedMediaInfo?['mimeType'] ??
                  _replyMessage!['fileType'] ??
                  '',
              'is_grouped_message': (_replyPreview?['imageCount'] ?? 0) > 0 ||
                  (_replyPreview?['videoCount'] ?? 0) > 0,
              'group_message_id': _replyPreview?['group_message_id'] ??
                  _replyMessage!['group_message_id'],
              'groupMessageIds': _replyPreview?['groupMessageIds'] ?? [],
            },

            // local debug copy (won't hurt server if passed)
            '_local_reply_preview': _replyPreview,
          }
        : null;

    final message = {
      'message_id': tempId,
      'content': sanitizeString(_messageController.text.trim()),
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
      if (_visibleCount > 0) _visibleCount++;

      final combined = [...dbMessages, ...messages, ...socketMessages];
      _scheduleSaveMessages(combined);
      _updateNotifier();
    });

    final String textToSend = _messageController.text.trim();

    setState(() {
      _messageController.clear();
      _replyMessage = null;
      _replyPreview = null;
      _imageFile = null;
    });
    await _clearDraft();

    if (!(_isOnline && socketService.isConnected)) {
      // Offline: Add to queue
      _offlineQueue.add({
        'message_id': tempId,
        'content': textToSend,
        'replyTo': replyPayload,
      });
      return;
    }

    try {
      final completer = Completer<GrpMessage>();
      final subscription = _groupBloc.stream.listen((state) {
        if (state is GrpMessageSentSuccessfully) {
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
          replyGroupMessageCount: _replyPreview?["content"],
          replyMessageId:
              replyPayload != null ? replyPayload['group_message_id'] : null,
        ),
      );

      final sentMsg = await completer.future;
      await subscription.cancel();

      // Swap temp ID with real server ID
      _offlineHandler.replaceTempMessageWithReal(
        tempId: tempId,
        realId: sentMsg.messageId,
        status: 'sent',
      );
    } catch (e) {
      _updateMessageStatus(tempId, 'failed');
    }
  }

// ------------------ Group Members Logic ------------------
  List<Map<String, dynamic>> _groupMembersList = [];
  List<String> _knownMemberIds = [];

  void _updateGroupMembers(Map<String, dynamic> groupDetails) {
    // Try to extract member IDs from various possible keys
    List<dynamic>? memberData;
    if (groupDetails['groupMembers'] is List) {
      memberData = groupDetails['groupMembers'];
    } else if (groupDetails['members'] is List) {
      memberData = groupDetails['members'];
    } else if (groupDetails['participants'] is List) {
      memberData = groupDetails['participants'];
    } else if (groupDetails['users'] is List) {
      memberData = groupDetails['users'];
    } else if (groupDetails['data'] is Map &&
        groupDetails['data']['members'] is List) {
      memberData = groupDetails['data']['members'];
    } else if (groupDetails['group'] is Map &&
        groupDetails['group']['members'] is List) {
      memberData = groupDetails['group']['members'];
    }

    if (memberData != null && memberData.isNotEmpty) {
      final List<String> ids = [];
      final List<Map<String, dynamic>> normalizedMembers = [];

      for (var m in memberData) {
        if (m is String) {
          ids.add(m);
        } else if (m is Map) {
          final id = (m['member_id'] ?? m['id'] ?? m['_id'] ?? "").toString();
          if (id.isNotEmpty) {
            ids.add(id);
            // Extract full details if available
            final String firstName = m['first_name'] ?? m['firstName'] ?? '';
            final String lastName = m['last_name'] ?? m['lastName'] ?? '';
            final String fullName = '$firstName $lastName'.trim();
            normalizedMembers.add({
              '_id': id,
              'first_name': firstName,
              'last_name': lastName,
              'full_name': fullName,
              'username': m['username'] ?? m['name'] ?? m['memberEmail'] ?? '',
              'profile_pic': m['profile_pic'] ?? m['profilePic'] ?? '',
            });
          }
        }
      }

      _knownMemberIds = ids;
      if (normalizedMembers.isNotEmpty) {
        setState(() {
          _groupMembersList = normalizedMembers;
          _messageController.setMembers(_groupMembersList);
        });
      }

      // Always try to supplement/update from messages to get most recent names/pics
      _buildMemberDetailsFromMessages(_knownMemberIds);
    } else {
      // Try to extract from messages as fallback
      _buildMemberDetailsFromMessages(
          _knownMemberIds.isNotEmpty ? _knownMemberIds : null);
    }
  }

  void _buildMemberDetailsFromMessages(List<String>? knownMemberIds) {
    // Extract unique member details from all messages
    final Map<String, Map<String, dynamic>> membersMap = {};

    // 0. Start with existing members from API (if any)
    for (var m in _groupMembersList) {
      final id = m['_id']?.toString();
      if (id != null) membersMap[id] = m;
    }

    // Combine all message sources
    final allMessages = [
      ...dbMessages,
      ...messages,
      ...socketMessages,
    ];

    for (var msg in allMessages) {
      final sender = msg['sender'];
      if (sender is Map && sender['_id'] != null) {
        final userId = sender['_id'].toString();

        // If we have a known list, only include those IDs
        if (knownMemberIds != null && !knownMemberIds.contains(userId)) {
          continue;
        }

        if (!membersMap.containsKey(userId)) {
          final String firstName =
              sender['first_name'] ?? sender['firstName'] ?? '';
          final String lastName =
              sender['last_name'] ?? sender['lastName'] ?? '';
          final String fullName = '$firstName $lastName'.trim();
          membersMap[userId] = {
            '_id': userId,
            'first_name': firstName,
            'last_name': lastName,
            'full_name': fullName,
            'username': sender['username'] ?? sender['name'] ?? '',
            'profile_pic': sender['profile_pic'] ?? sender['profilePic'] ?? '',
          };
        }
      }
    }

    setState(() {
      _groupMembersList = membersMap.values.toList();
      _messageController.setMembers(_groupMembersList);
    });
  }

  List<InlineSpan> _buildMessageTextSpans(String content, bool isDeleted) {
    // Sanitize input before processing for links/mentions to avoid UTF-16 errors
    content = sanitizeString(content);
    final List<InlineSpan> spans = [];
    if (content.isEmpty) return spans;

    if (isDeleted) {
      return [
        TextSpan(
            text: content,
            style: const TextStyle(fontSize: 15, color: Colors.black87))
      ];
    }

    final String query = _searchController.text.toLowerCase();
    final bool hasSearchMatch =
        query.isNotEmpty && content.toLowerCase().contains(query);

    // 1. Prepare mention regex from group members
    final List<String> memberNames = _groupMembersList
        .map((m) => m['full_name']?.toString() ?? "")
        .where((name) => name.isNotEmpty)
        .toList();
    memberNames.sort((a, b) => b.length.compareTo(a.length));

    final String escapedNames = memberNames.map(RegExp.escape).join('|');
    final String mentionPattern =
        memberNames.isEmpty ? r'(?! )' : '@($escapedNames)';

    // 2. Combined regex for URLs and Mentions
    final String urlPattern = r'((https?:\/\/)|(www\.))[^\s]+';

    if (hasSearchMatch) {}

    final RegExp combinedRegExp =
        RegExp('$urlPattern|$mentionPattern', caseSensitive: false);

    final matches = combinedRegExp.allMatches(content);
    int lastAppliedOffset = 0;

    void addTextWithSearchHighlight(String text, TextStyle baseStyle) {
      spans.addAll(buildHighlightSpans(
        text: text,
        baseStyle: baseStyle,
        query: _searchController.text,
      ));
    }

    for (final match in matches) {
      // Add text before the match (with search highlight if applicable)
      if (match.start > lastAppliedOffset) {
        addTextWithSearchHighlight(
          content.substring(lastAppliedOffset, match.start),
          const TextStyle(fontSize: 15, color: Colors.black87),
        );
      }

      final String matchText = content.substring(match.start, match.end);

      if (matchText.startsWith('@')) {
        addTextWithSearchHighlight(
          matchText,
          const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: chatColor,
          ),
        );
      } else {
        // It's a URL
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontSize: 15,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                try {
                  final url = matchText;
                  final uri =
                      Uri.parse(url.startsWith('www.') ? 'https://$url' : url);
                  if (!await launchUrl(uri,
                      mode: LaunchMode.externalApplication)) {
                    throw 'Could not launch $uri';
                  }
                } catch (e) {
                  log(e.toString());
                }
              },
          ),
        );
      }

      lastAppliedOffset = match.end;
    }

    // Add remaining text
    if (lastAppliedOffset < content.length) {
      addTextWithSearchHighlight(
        content.substring(lastAppliedOffset),
        const TextStyle(fontSize: 15, color: Colors.black87),
      );
    }

    return spans;
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

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset < 80;
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;

    // ✅ WhatsApp logic
    final shouldShowArrow = !_isNearBottom();

    if (shouldShowArrow != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = shouldShowArrow;
      });
    }

    // =========================
    // PAGINATION (TOP LOAD)
    // =========================
    final maxExtent = _scrollController.position.maxScrollExtent;

    if (offset < maxExtent - 120) return;

    final total = _allMessages.length;

    if (_visibleCount < total && !_isLoadingMore) {
      _isLoadingMore = true;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        setState(() {
          _visibleCount = (_visibleCount + _pageStep).clamp(0, total);
          _isLoadingMore = false;
        });

        _updateNotifierFromAll();
      });
    } else if (_visibleCount >= total && _hasNextPage && !_isLoadingMore) {
      // _triggerServerFetch();
    }

    _scheduleMarkReadAfterScrollStops();
  }

  void _markMessagesAsDeleted(List<String> messageIds,
      {String deleteFor = 'everyone'}) {
    List<Map<String, dynamic>>? combinedToSave;
    setState(() {
      List<Map<String, dynamic>> updateMessages(
          List<Map<String, dynamic>> list) {
        String? getMessageId(Map<String, dynamic> msg) {
          return msg['message_id']?.toString() ??
              msg['messageId']?.toString() ??
              msg['_id']?.toString() ??
              msg['id']?.toString();
        }

        if (deleteFor == 'me') {
          return list.where((msg) {
            final id = getMessageId(msg);
            return id == null || !messageIds.contains(id);
          }).toList();
        } else {
          return list.map((msg) {
            final id = getMessageId(msg);
            if (id != null && messageIds.contains(id)) {
              return {
                ...msg,
                'content': '🚫 This message was deleted',
                'imageUrl': null,
                'fileUrl': null,
                'fileName': null,
                'fileType': null,
                'isDeleted': true,
                'messageStatus': 'deleted',
                'is_deleted': true,
              };
            }
            return msg;
          }).toList();
        }
      }

      messages = updateMessages(messages);
      dbMessages = updateMessages(dbMessages);
      socketMessages = updateMessages(socketMessages);

      final combined = [...dbMessages, ...messages, ...socketMessages];
      combinedToSave = combined;
      _updateNotifier();
    });

    if (combinedToSave != null) {
      _scheduleSaveMessages(combinedToSave!);
    }
  }

  void _deleteSelectedMessages(String deleteFor) {
    if (_selectedMessageIds.isEmpty) {
      return;
    }

    setState(() {});

    _markMessagesAsDeleted(_selectedMessageIds.toList(), deleteFor: deleteFor);

    _groupBloc.add(DeleteMessagesEvent(
        messageIds: _selectedMessageIds.toList(),
        convoId: widget.conversationId,
        senderId: currentUserId,
        receiverId: widget.datumId,
        message: _selectedMessageKeys.first,
        deleteFor: deleteFor));

    setState(() {
      _selectedMessages.clear();
      _selectedMessageIds.clear();
      _selectedMessageKeys.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleMessageSelection(Map<String, dynamic> msg) {
    final key = GroupChatMessageUtils.generateMessageKey(msg);
    final String? messageId = msg['message_id']?.toString();

    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        _selectedMessageKeys.remove(key);
        _selectedMessages.removeWhere(
            (m) => GroupChatMessageUtils.generateMessageKey(m) == key);
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
        conversionalid: widget.conversationId,
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

  // Helper method to build reply preview for grouped media
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

    final replyPreview = GroupReplyData.buildReplyPreview(
      message: message,
      allMessages: _allMessages,
      currentUserId: currentUserId,
      isSendMe: isSendMe,
    );

    setState(() {
      _replyMessage = Map<String, dynamic>.from(message);
      _replyPreview = replyPreview;
      _focusNode.requestFocus();
    });
  }

  void _onMessageTap(Map<String, dynamic> message) async {
    if (_isSelectionMode) {
      _toggleMessageSelection(message);
      return;
    }

    final bool isDeleted = message['is_deleted'] == true ||
        message['isDeleted'] == true ||
        message['messageStatus'] == 'deleted' ||
        message['content'] == '🚫 This message was deleted';

    if (isDeleted) return;

    // 🔥 Fallback: If message failed, show resend dialog on tap
    final status = message['messageStatus']?.toString() ?? '';
    if (status == 'failed' || status == 'pending_offline') {
      _offlineHandler.showResendDialog(message);
      return;
    }

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

    if (replyId != null && replyId.isNotEmpty) {
      final found = await _scrollToMessageById(replyId, fetchIfMissing: true);
      if (!found) {
        Messenger.alert(
          msg: "Original message not found.",
        );
      }
    }
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

  List<Map<String, dynamic>> _inferGrouping(
      List<Map<String, dynamic>> messages) {
    return GroupChatMediaGroupingUtils.inferGrouping(
      messages,
      _applyGroupingToSource,
    );
  }

  /// Persist grouping info to source message arrays
  void _applyGroupingToSource(String messageId, String groupId) {
    void applyToList(List<Map<String, dynamic>> list) {
      for (var msg in list) {
        final mId =
            (msg['message_id'] ?? msg['messageId'] ?? msg['id'])?.toString();
        if (mId == messageId) {
          msg['is_grouped_message'] = true;
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
  /// Merge all messages (db + messages + socket), sort, dedupe
  List<Map<String, dynamic>> _getCombinedMessages() {
    // 🚀 OPTIMIZED: Use Map for O(1) lookups instead of O(N) list searches.
    // This reduces merging complexity from O(N^2) to O(N).
    final Map<String, Map<String, dynamic>> mergedMap = {};

    // Helper to process a message and merge it into the map
    void mergeMessage(Map<String, dynamic> msg) {
      // 🔥 SAFETY: Filter out messages from other conversations
      final msgConvoId =
          msg['conversationId'] ?? msg['convoId'] ?? msg['conversation_id'];

      if (msgConvoId != null &&
          msgConvoId.toString() != widget.conversationId &&
          msgConvoId.toString() != widget.datumId) {
        return;
      }

      if (msg['content']?.toString().trim() == '' &&
          (msg['imageUrl'] == null || msg['imageUrl'].toString().isEmpty) &&
          (msg['fileUrl'] == null || msg['fileUrl'].toString().isEmpty)) {
        return;
      }

      // 1. Resolve ID
      final msgId =
          msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? msg['id'];

      String? primaryKey;
      if (msgId != null) {
        primaryKey = msgId.toString();
      }

      // 2. If no ID, generate a unique key based on content+time (Fallback)
      if (primaryKey == null) {
        // Only use this recursive fallback if we absolutely can't find an ID.
        // We use a composite key for "content-based" uniqueness.
        final time = msg['time']?.toString() ?? '';
        final content = msg['content']?.toString() ?? '';
        final contentType = msg['ContentType']?.toString() ?? '';
        final isReply = (msg['isReplyMessage'] ?? false).toString();
        // This is not perfect but mimics the previous 'any' check logic efficiently
        primaryKey =
            "fallback_${time}_${content.hashCode}_${contentType}_$isReply";
      }

      // 3. Merge Logic
      if (mergedMap.containsKey(primaryKey)) {
        final existing = mergedMap[primaryKey]!;
        final existingStatus = (existing['messageStatus'] ?? '').toString();
        final newStatus = (msg['messageStatus'] ?? '').toString();

        // Priority: read > delivered > sent > sending > pending > failed
        const statusPriority = {
          'read': 4,
          'delivered': 3,
          'sent': 2,
          'sending': 1,
          'pending': 0,
          'pending_offline': 0,
          'failed': 0,
        };

        final existingPriority = statusPriority[existingStatus] ?? 0;
        final newPriority = statusPriority[newStatus] ?? 0;

        // If new message has better status or more complete data, replace/merge
        if (newPriority > existingPriority ||
            (msg['originalUrl'] != null && existing['originalUrl'] == null) ||
            (msg['fileUrl'] != null && existing['isLocal'] == true)) {
          // Merge: keep any local data, but update with server data
          final merged = Map<String, dynamic>.from(existing);
          msg.forEach((key, value) {
            if (value != null) merged[key] = value;
          });
          mergedMap[primaryKey] = merged;
        }
      } else {
        // New message
        mergedMap[primaryKey] = Map<String, dynamic>.from(msg);
      }
    }

    // Process lists in order. Order matters if we want later lists to override earlier ones
    // (though our merge logic handles priority explicitly).
    // Usually: DB (oldest cache) -> Messages (RAM) -> Socket (Live)
    for (var m in dbMessages) {
      mergeMessage(m);
    }
    for (var m in messages) {
      mergeMessage(m);
    }
    for (var m in socketMessages) {
      mergeMessage(m);
    }

    final combined = mergedMap.values.toList();

    combined.sort(
      (a, b) => parseChatTime(a['time']).compareTo(parseChatTime(b['time'])),
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

    _updateNotifierFromAll();
  }

  /// Updates `_messagesNotifier` with the currently visible slice of `_allMessages`
  void _updateNotifierFromAll() {
    final total = _allMessages.length;
    final count = _visibleCount.clamp(0, total);

    final startIndex = total - count;

    final visibleSlice = (count == 0)
        ? <Map<String, dynamic>>[]
        : _allMessages.sublist(startIndex, total);

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
        final mid =
            (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
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
      final mid =
          (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
      return mid == messageId;
    });
  }

  Future<bool> _scrollToMessageById(
    String messageId, {
    bool fetchIfMissing = true,
  }) async {
    if (messageId.isEmpty) return false;

    final ctx = _messageContexts[messageId];
    if (ctx != null && ctx.mounted) {
      _highlightAndScrollToContext(ctx, messageId);
      return true;
    }

    final combined = _getCombinedMessages();
    final msgIndex = combined.indexWhere(
      (m) => GroupChatMessageUtils.anyId(m) == messageId,
    );

    if (msgIndex == -1) {
      if (fetchIfMissing) {
        final found = await _fetchUntilMessageFound(messageId);
        if (found) {
          // After fetching, ensure visibility and retry
          final updatedCombined = _getCombinedMessages();
          final newMsgIndex = updatedCombined.indexWhere(
            (m) => GroupChatMessageUtils.anyId(m) == messageId,
          );
          if (newMsgIndex != -1) {
            final neededVisible = updatedCombined.length - newMsgIndex;
            if (_visibleCount < neededVisible) {
              setState(() {
                _visibleCount = neededVisible + 5;
                if (_visibleCount > updatedCombined.length) {
                  _visibleCount = updatedCombined.length;
                }
              });
              _updateNotifier();
              await WidgetsBinding.instance.endOfFrame;
            }
            final retryCtx = _messageContexts[messageId];
            if (retryCtx != null && retryCtx.mounted) {
              _highlightAndScrollToContext(retryCtx, messageId);
              return true;
            }
          }
        }
      }

      if (mounted) {
        Messenger.alertError(
            "Original message not found. It may have been deleted or is unavailable.");
      }
      return false;
    }

    final neededVisible = combined.length - msgIndex;
    if (_visibleCount < neededVisible) {
      setState(() {
        _visibleCount = neededVisible + 5;
        if (_visibleCount > combined.length) {
          _visibleCount = combined.length;
        }
      });
      _updateNotifier();
      await WidgetsBinding.instance.endOfFrame;
    }

    final targetCtx = _messageContexts[messageId];
    if (targetCtx != null && targetCtx.mounted) {
      _highlightAndScrollToContext(targetCtx, messageId);
      return true;
    }

    final listIndex = combined.length - 1 - msgIndex;
    final estimatedOffset = _estimateScrollOffset(listIndex, combined);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(estimatedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ));
    }
    await Future.delayed(const Duration(milliseconds: 150));
    final retryCtx = _messageContexts[messageId];
    if (retryCtx != null && retryCtx.mounted) {
      _highlightAndScrollToContext(retryCtx, messageId);
      return true;
    }
    _highlightMessage(messageId);
    return true;
  }

  /// Highlight message and scroll to its context
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

  /// Highlight a message temporarily
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

  /// Estimate message height for scroll calculations
  double _estimateMessageHeight(
      int index, List<Map<String, dynamic>> messages) {
    if (index < 0 || index >= messages.length) return 0.0;
    final message = messages[index];

    // Date separator logic
    double separatorHeight = 0.0;
    final currentTime = parseChatTime(message['time']);
    final prevTime =
        index > 0 ? parseChatTime(messages[index - 1]['time']) : null;
    if (index == 0 || !GroupChatMessageUtils.isSameDay(currentTime, prevTime)) {
      separatorHeight = 40.0;
    }

    // Grouping logic: only the first message in a group has height
    final isGrouped = message['is_grouped_message'] == true;
    final groupId = message['group_message_id']?.toString();
    if (isGrouped && groupId != null && index > 0) {
      final prev = messages[index - 1];
      if (prev['is_grouped_message'] == true &&
          prev['group_message_id']?.toString() == groupId) {
        return 0.0;
      }
    }

    // System message check (voidBox in _buildMessageBubble returns shrink/voidBox)
    final contentType = message['ContentType'] ?? message['contentType'] ?? "";
    final content = (message['content'] ?? '').toString();
    if (content.contains('Group created by') ||
        (contentType == "system" &&
            (content.contains('added') || content.contains('left')))) {
      return 0.0 + separatorHeight;
    }

    final hasMedia =
        (message['fileUrl'] ?? message['imageUrl'] ?? '').toString().isNotEmpty;
    final hasReply = _hasReplyForMessage(message);

    double height = 60.0; // Base height

    if (content.isNotEmpty) {
      final lines = (content.length / 40).ceil();
      height += lines * 20.0;
    }

    if (hasMedia) {
      if (isGrouped) {
        height += 250.0; // Estimate for GroupedMediaWidget
      } else {
        height += 120.0;
      }
    }
    if (hasReply) height += 60.0;

    return height.clamp(60.0, 400.0) + separatorHeight;
  }

  /// Estimate scroll offset for a given list index
  double _estimateScrollOffset(
      int listIndex, List<Map<String, dynamic>> messages) {
    double offset = 0.0;

    // listIndex is distance from bottom (reversed list)
    for (int i = 0; i < listIndex && i < messages.length; i++) {
      final realIndex = messages.length - 1 - i;
      if (realIndex >= 0 && realIndex < messages.length) {
        offset += _estimateMessageHeight(realIndex, messages);
      }
    }

    return offset;
  }

  /// Check if message has a reply
  bool _hasReplyForMessage(Map<String, dynamic>? message) {
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
  // Widget _buildChatBody() {
  //     return GroupChatBody(
  //       data: GroupChatBodyData(
  //         groupBloc: _groupBloc,
  //         messagesNotifier: _messagesNotifier,
  //         scrollController: _scrollController,
  //         searchController: _searchController,
  //         messages: messages,
  //         socketMessages: socketMessages,
  //         dbMessages: dbMessages,
  //         seenMessageIds: _seenMessageIds,
  //         messageContexts: _messageContexts,
  //         allMessages: _allMessages,
  //         currentUserId: currentUserId,
  //         conversationId: widget.conversationId,
  //         datumId: widget.datumId,
  //         groupName: widget.groupName,
  //         highlightedMessageId: _highlightedMessageId,
  //         selectedMessageKeys: _selectedMessageKeys,
  //         limit: _limit,
  //         currentPage: _currentPage,
  //         isLoadingMore: _isLoadingMore,
  //         hasLeftGroup: _hasLeftGroup,
  //         isSelectionMode: _isSelectionMode,
  //         hasNextPage: _hasNextPage,
  //         visibleCount: _visibleCount,
  //       ),
  //       callbacks: GroupChatBodyCallbacks(
  //         onPermissionResponse: _handlePermissionResponse,
  //         onUpdateMessageStatus: _updateMessageStatus,
  //         onSetState: (fn) => setState(fn),
  //         onSetHasNextPage: (value) => setState(() => _hasNextPage = value),
  //         onSetIsLoadingMore: (value) => setState(() => _isLoadingMore = value),
  //         onSetVisibleCount: (count) => setState(() => _visibleCount = count),
  //         onSetDbMessages: (msgs) => dbMessages = msgs,
  //         onAddSeenMessageId: (id) => _seenMessageIds.add(id),
  //         onUpdateNotifier: _updateNotifier,
  //         onUpdateNotifierFromAll: _updateNotifierFromAll,
  //         onMarkVisibleMessagesAsRead: _markVisibleMessagesAsRead,
  //         onReplyToMessage: _replyToMessage,
  //         onToggleMessageSelection: _toggleMessageSelection,
  //         onShowReactionPicker: _showReactionPicker,
  //         onSetSelectionMode: (value) => setState(() => _isSelectionMode = value),
  //         buildMessageBubble: _buildMessageBubble,
  //         buildReactionsBar: _buildReactionsBar,
  //         buildAvatarWithInitial: _buildAvatarWithInitial,
  //         hasReply: _hasReply,
  //         flattenGroupedMessages: flattenGroupedMessages,
  //         onBuildMemberDetailsFromMessages: _buildMemberDetailsFromMessages,
  //         getKnownMemberIds: () => _knownMemberIds,
  //         getGroupMembersList: () => _groupMembersList,
  //       ),
  //     );
  //   }

  Widget _buildChatBody() {
    return BlocListener<GroupChatBloc, GroupChatState>(
      bloc: _groupBloc,
      listener: (context, state) {
        if (state is PermissionState) {
          _handlePermissionResponse(state.response);
        }
        if (state is GrpMessageSentSuccessfully) {
          // Handled by _sendMessage completer
        } else if (state is UploadSuccess) {
          if (state.messageId != null) {
            _updateMessageStatus(state.messageId!, 'sent');
          }
        } else if (state is GroupChatError) {
          setState(() => _isLoadingMore = false);
        } else if (state is GroupChatLoaded) {
          // 🔍 Track every GroupChatLoaded emission

          // ALWAYS update these flags when state arrives, even if data is same
          _hasNextPage = state.response.hasNextPage;
          if (_isLoadingMore) {
            setState(() => _isLoadingMore = false);
          }

          final incomingLoaded = flattenGroupedMessages(state.response.data);

          final incomingNormalized = incomingLoaded
              .map<Map<String, dynamic>>(
                  (msg) => GroupChatNormalizeUtils.normalizeMessage(msg))
              .where((m) => m.isNotEmpty)
              .where((msg) {
            // 🔥 SAFETY: Filter out messages from other conversations
            final cId = msg['conversationId'] ??
                msg['convoId'] ??
                msg['conversation_id'];
            // If ID is missing, we allow it (legacy/compatibility)
            // If ID is present, it MUST match
            if (cId != null &&
                cId.toString() != widget.conversationId &&
                cId.toString() != widget.datumId) {
              return false;
            }
            return true;
          }).toList();

          // Calculate total pages for debugging
          final totalPages = (state.response.total / _limit).ceil();

          setState(() {
            _hasNextPage = _currentPage < totalPages;
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
              if (id.isNotEmpty) {
                messagesMap[id] = m;
                //  log('   ➕ Added/Updated message: $id');
              }
            }

            // 3. Rebuild dbMessages from merged map
            dbMessages = messagesMap.values.toList();
            if (_knownMemberIds.isNotEmpty && _groupMembersList.isEmpty) {
              _buildMemberDetailsFromMessages(_knownMemberIds);
            }
          });

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
          }
        } else if (state is GroupDetailsLoaded) {}
      },
      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _messagesNotifier,
        builder: (context, combinedMessages, child) {
          final groupedMessages =
              GroupChatMediaGroupingUtils.buildGroupedMessages(
                  combinedMessages);
          _latestGroupedMessages = groupedMessages;
          if (groupedMessages.isNotEmpty && _isNearBottom()) {
            _scheduleMarkReadAfterScrollStops();
          }

          return BlocBuilder<GroupChatBloc, GroupChatState>(
            bloc: _groupBloc,
            builder: (context, state) {
              final bool showShimmer = messages.isEmpty &&
                  socketMessages.isEmpty &&
                  groupedMessages
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
                      child:
                          _isLoadingMore ? SizedBox() : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        cacheExtent: 2000,
                        controller: _scrollController,
                        itemCount: groupedMessages.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final int realIndex =
                              groupedMessages.length - 1 - index;

                          if (realIndex < 0 ||
                              realIndex >= groupedMessages.length) {
                            return const SizedBox.shrink();
                          }

                          final message = groupedMessages[realIndex];
                          final senderMap = (message['sender'] is Map)
                              ? Map<String, dynamic>.from(message['sender'])
                              : <String, dynamic>{};

                          final isSentByMe = senderMap['_id'] == currentUserId;
                          final isSystem = message['ContentType'] == "system";
                          final content = message['content']?.toString() ?? '';
                          final bool isDeleted =
                              message['is_deleted'] == true ||
                                  message['messageStatus'] == 'deleted' ||
                                  content == ' This message was deleted';

                          final currentTime = parseChatTime(message['time']);
                          final prevTime = realIndex > 0
                              ? parseChatTime(
                                  groupedMessages[realIndex - 1]['time'])
                              : null;

                          // Grouping Logic
                          final isGroupMessage =
                              message['is_grouped_message'] == true;
                          final groupMessageId =
                              message['group_message_id']?.toString();

                          if (isGroupMessage &&
                              groupMessageId != null &&
                              groupMessageId.isNotEmpty) {
                            // First in group?
                            final isFirstInGroup = realIndex == 0 ||
                                groupedMessages[realIndex - 1]
                                            ['group_message_id']
                                        ?.toString() !=
                                    groupMessageId;

                            if (!isFirstInGroup) {
                              return const SizedBox.shrink();
                            }

                            List<String> groupImages = [];
                            List<Map<String, dynamic>> groupMessagesList = [];
                            for (int i = realIndex;
                                i < groupedMessages.length;
                                i++) {
                              final nextMsg = groupedMessages[i];
                              final nextGrpId =
                                  nextMsg['group_message_id']?.toString();
                              if (nextGrpId == groupMessageId) {
                                final normalizedNext =
                                    GroupChatNormalizeUtils.normalizeMessage(
                                        nextMsg);
                                groupMessagesList.add(normalizedNext);
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
                              final String userName = (message['userName']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true)
                                  ? message['userName']
                                  : (() {
                                      final s = message['sender'];
                                      if (s is Map) {
                                        return [
                                          s['first_name'],
                                          s['last_name'],
                                          s['name'],
                                        ]
                                            .where((e) =>
                                                e != null &&
                                                e.toString().trim().isNotEmpty)
                                            .join(' ')
                                            .trim();
                                      }
                                      return '';
                                    })();

                              final senderData = message['sender'] is Map
                                  ? message['sender']
                                  : {};
                              final String profileImageUrl =
                                  senderData['profile_pic_path']?.toString() ??
                                      senderData['profilePic']?.toString() ??
                                      senderData['avatar']?.toString() ??
                                      message['profile_pic_path']?.toString() ??
                                      "";
                              final messageId =
                                  GroupChatMessageUtils.anyId(message);
                              final bool isHighlighted =
                                  _highlightedMessageId == messageId ||
                                      (isGroupMessage &&
                                          _highlightedMessageId != null &&
                                          groupedMessages.any((m) =>
                                              m['group_message_id']
                                                      ?.toString() ==
                                                  groupMessageId &&
                                              GroupChatMessageUtils.anyId(m) ==
                                                  _highlightedMessageId));

                              final bool isGroupSelected = groupMessagesList
                                  .any((m) => _selectedMessageKeys.contains(
                                      GroupChatMessageUtils.generateMessageKey(
                                          m)));
                              final screenWidth =
                                  MediaQuery.of(context).size.width;

                              // ✅ WhatsApp-like bubble width
                              final double bubbleWidth = screenWidth < 600
                                  ? screenWidth * 0.72
                                  : screenWidth * 0.5;
                              return _hasLeftGroup
                                  ? const SizedBox.shrink()
                                  : AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      color: isHighlighted
                                          ? Colors.blueAccent
                                              .withValues(alpha: 0.3)
                                          : Colors.transparent,
                                      child: Column(
                                        crossAxisAlignment: isSentByMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          if (realIndex == 0 ||
                                              !GroupChatMessageUtils.isSameDay(
                                                  currentTime, prevTime))
                                            buildGroupChatDateSeparator(
                                                currentTime),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 4.0),
                                            child: SwipeToReply(
                                              onReply: isDeleted
                                                  ? null
                                                  : () =>
                                                      _replyToMessage(message),
                                              child: Builder(builder: (ctx) {
                                                final String anchorMessageId =
                                                    GroupChatMessageUtils.anyId(
                                                        groupMessagesList
                                                            .first);
                                                if (anchorMessageId
                                                    .isNotEmpty) {
                                                  _messageContexts[
                                                      anchorMessageId] = ctx;
                                                }

                                                return Align(
                                                  alignment: isSentByMe
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      if (isSentByMe)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8.0),
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                              onTap: () {
                                                                MyRouter
                                                                    .pushReplace(
                                                                  screen:
                                                                      ForwardMessageScreen(
                                                                    messages:
                                                                        groupMessagesList,
                                                                    currentUserId:
                                                                        currentUserId,
                                                                    conversionalid:
                                                                        widget
                                                                            .conversationId,
                                                                    username: widget
                                                                        .groupName,
                                                                  ),
                                                                );
                                                              },
                                                              child:
                                                                  CircleAvatar(
                                                                radius: 16,
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                child:
                                                                    Image.asset(
                                                                  "assets/images/forward.png",
                                                                  height: 20,
                                                                  width: 20,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      Flexible(
                                                        child: Stack(
                                                          clipBehavior:
                                                              Clip.none,
                                                          children: [
                                                            GestureDetector(
                                                              behavior:
                                                                  HitTestBehavior
                                                                      .opaque,
                                                              onTap: () {
                                                                if (_isSelectionMode) {
                                                                  for (final gm
                                                                      in groupMessagesList) {
                                                                    _toggleMessageSelection(
                                                                        gm);
                                                                  }
                                                                }
                                                              },
                                                              onLongPress: () {
                                                                if (!isDeleted) {
                                                                  _showReactionPicker(
                                                                      context,
                                                                      message);
                                                                }
                                                                setState(() {
                                                                  _isSelectionMode =
                                                                      true;
                                                                });
                                                                for (final gm
                                                                    in groupMessagesList) {
                                                                  _toggleMessageSelection(
                                                                      gm);
                                                                }
                                                              },
                                                              child: Padding(
                                                                padding: EdgeInsets.only(
                                                                    left: isSentByMe
                                                                        ? 0
                                                                        : 38),
                                                                child:
                                                                    Container(
                                                                  width:
                                                                      bubbleWidth,
                                                                  margin:
                                                                      EdgeInsets
                                                                          .only(
                                                                    left:
                                                                        isSentByMe
                                                                            ? 0
                                                                            : 0,
                                                                    right: 0,
                                                                    top: 0,
                                                                    bottom: (message['reactions'] !=
                                                                                null &&
                                                                            message['reactions'].isNotEmpty)
                                                                        ? 20
                                                                        : 0,
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          7),
                                                                  constraints:
                                                                      BoxConstraints(
                                                                    maxWidth: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.75,
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: isGroupSelected
                                                                        ? senderColor.withValues(
                                                                            alpha:
                                                                                0.2)
                                                                        : (isSentByMe
                                                                            ? senderColor
                                                                            : receiverColor),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .only(
                                                                      topLeft: const Radius
                                                                          .circular(
                                                                          18),
                                                                      topRight: const Radius
                                                                          .circular(
                                                                          18),
                                                                      bottomLeft: isSentByMe
                                                                          ? const Radius
                                                                              .circular(
                                                                              18)
                                                                          : Radius
                                                                              .zero,
                                                                      bottomRight: isSentByMe
                                                                          ? Radius
                                                                              .zero
                                                                          : const Radius
                                                                              .circular(
                                                                              16),
                                                                    ),
                                                                    border: isGroupSelected
                                                                        ? Border.all(
                                                                            color:
                                                                                Colors.blue,
                                                                            width: 2)
                                                                        : null,
                                                                    boxShadow: const [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black12,
                                                                        blurRadius:
                                                                            4,
                                                                        offset: Offset(
                                                                            0,
                                                                            2),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      if (!isSentByMe &&
                                                                          userName
                                                                              .isNotEmpty)
                                                                        Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              bottom: 4.0),
                                                                          child:
                                                                              Text(
                                                                            userName,
                                                                            style:
                                                                                TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              color: ColorUtil.getColorFromAlphabet(userName),
                                                                              fontSize: 14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      Stack(
                                                                        clipBehavior:
                                                                            Clip.none,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.only(
                                                                              bottom: (message['reactions'] != null && message['reactions'].isNotEmpty) ? 5 : 0,
                                                                            ),
                                                                            child:
                                                                                GroupedMediaWidget(
                                                                              mediaUrls: groupImages,
                                                                              searchText: _searchController.text,
                                                                              caption: message['content'],
                                                                              isSentByMe: isSentByMe,
                                                                              time: message['time'] ?? '',
                                                                              messageStatus: message['messageStatus']?.toString() ?? 'sent',
                                                                              onMediaTap: (index) {
                                                                                log("messagessss $message");
                                                                                final media = buildConversationMedia(
                                                                                  groupedMessages,
                                                                                  currentUserId: currentUserId,
                                                                                );
                                                                                final tappedUrl = groupImages[index];
                                                                                final startIndex = media.indexWhere((m) => m.mediaUrl == tappedUrl);
                                                                                if (startIndex != -1) {
                                                                                  Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                      builder: (_) => MixedMediaViewer(
                                                                                        items: media,
                                                                                        initialIndex: startIndex,
                                                                                        conversionalId: widget.conversationId,
                                                                                        fullName: widget.groupName,
                                                                                        isGroup: true,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                            ),
                                                                          ),
                                                                          if (message['content'] == null ||
                                                                              message['content'].toString().isEmpty)
                                                                            Positioned(
                                                                              bottom: 5,
                                                                              right: 5,
                                                                              child: Container(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.black.withValues(alpha: 0.45),
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
                                                                                        final status = message['messageStatus']?.toString() ?? 'sent';
                                                                                        switch (status) {
                                                                                          case 'sent':
                                                                                            return const Icon(Icons.check, size: 12, color: Colors.white);
                                                                                          case 'delivered':
                                                                                            return const Icon(Icons.done_all_rounded, size: 12, color: Colors.white);
                                                                                          case 'read':
                                                                                            return const Icon(Icons.done_all, size: 12, color: Colors.blueAccent);
                                                                                          default:
                                                                                            return const Icon(Icons.access_time, size: 12, color: Colors.white);
                                                                                        }
                                                                                      }),
                                                                                    ],
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          if (message['reactions'] != null &&
                                                                              message['reactions'].isNotEmpty)
                                                                            Positioned(
                                                                              bottom: _hasReply(message) ? -40 : -28,
                                                                              right: isSentByMe ? 12 : null,
                                                                              left: isSentByMe ? null : 12,
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.only(bottom: 12),
                                                                                child: _buildReactionsBar(message, isSentByMe),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (!isSentByMe)
                                                              Positioned(
                                                                left: 2,
                                                                top: 10,
                                                                child:
                                                                    CircleAvatar(
                                                                  radius: 16,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  child:
                                                                      ClipOval(
                                                                    child: profileImageUrl
                                                                            .isNotEmpty
                                                                        ? CachedNetworkImage(
                                                                            imageUrl:
                                                                                profileImageUrl,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            width:
                                                                                32,
                                                                            height:
                                                                                32,
                                                                            memCacheWidth:
                                                                                480,
                                                                            memCacheHeight:
                                                                                600,
                                                                            errorWidget: (context, url, error) =>
                                                                                _buildAvatarWithInitial(userName),
                                                                          )
                                                                        : _buildAvatarWithInitial(
                                                                            userName),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (!isSentByMe)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                              onTap: () {
                                                                MyRouter
                                                                    .pushReplace(
                                                                  screen:
                                                                      ForwardMessageScreen(
                                                                    messages:
                                                                        groupMessagesList,
                                                                    currentUserId:
                                                                        currentUserId,
                                                                    conversionalid:
                                                                        widget
                                                                            .conversationId,
                                                                    username: widget
                                                                        .groupName,
                                                                  ),
                                                                );
                                                              },
                                                              child:
                                                                  CircleAvatar(
                                                                radius: 16,
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                child:
                                                                    Image.asset(
                                                                  "assets/images/forward.png",
                                                                  height: 20,
                                                                  width: 20,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                            }
                          }

                          List<Widget> children = [];

                          if (isSystem &&
                              (content.contains('Group created by') ||
                                  content.contains('added') ||
                                  content.contains('left'))) {
                            children.add(buildGroupChatTextSeparator(content));
                          }

                          if (realIndex == 0 ||
                              !GroupChatMessageUtils.isSameDay(
                                  currentTime, prevTime)) {
                            children
                                .add(buildGroupChatDateSeparator(currentTime));
                          }

                          children
                              .add(_buildMessageBubble(message, isSentByMe));

                          final messageId = (message['message_id'] ??
                                  message['messageId'] ??
                                  message['id'])
                              ?.toString();
                          final bool isHighlighted =
                              _highlightedMessageId == messageId;

                          return _hasLeftGroup
                              ? SizedBox()
                              : AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  color: isHighlighted
                                      ? Colors.blueAccent.withValues(alpha: 0.3)
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
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              final media = buildConversationMedia(
                _allMessages,
                currentUserId: currentUserId,
              );
              final index = media.indexWhere((m) => m.mediaUrl == fileUrl);

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MixedMediaViewer(
                          items: media,
                          initialIndex: index,
                          conversionalId: widget.conversationId,
                          fullName: widget.groupName,
                          isGroup: true,
                          receiverId: widget.groupId,
                        )),
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
          if ((message['content']?.toString() ?? '').isEmpty)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
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

  int _calculateGroupMediaLength(Map<String, dynamic>? replyData) {
    if (replyData == null) return 0;

    int count = 0;
    final String? replyGroupId = replyData['group_message_id']?.toString();

    if (replyGroupId != null && replyGroupId.isNotEmpty) {
      count = _allMessages
          .where((m) =>
              m['group_message_id']?.toString() == replyGroupId &&
              m['is_deleted'] != true)
          .length;
    }

    if (count == 0) {
      int imgC = int.tryParse(replyData['imageCount']?.toString() ?? '0') ?? 0;
      int vidC = int.tryParse(replyData['videoCount']?.toString() ?? '0') ?? 0;

      if (imgC == 0 && vidC == 0 && replyData['reply'] is Map) {
        final nested = replyData['reply'];
        imgC = int.tryParse(nested['imageCount']?.toString() ?? '0') ?? 0;
        vidC = int.tryParse(nested['videoCount']?.toString() ?? '0') ?? 0;
      }
      count = imgC + vidC;
    }

    // Fallback: Parse from content string (e.g. "Photo x 3")
    if (count <= 1) {
      final content = (replyData['content'] ?? replyData['replyContent'] ?? '')
          .toString()
          .replaceAll('×', 'x');

      if (content.contains('Photo x ')) {
        count = int.tryParse(content.split('Photo x ').last.trim()) ?? count;
      } else if (content.contains('Video x ')) {
        count = int.tryParse(content.split('Video x ').last.trim()) ?? count;
      } else if (content.contains('Media x ')) {
        count = int.tryParse(content.split('Media x ').last.trim()) ?? count;
      }
    }
    return count;
  }

  /// Check if a grouped message contains both images and videos (mixed media)
  bool _hasMixedMediaTypes(Map<String, dynamic>? replyData) {
    if (replyData == null) return false;

    // Try multiple field names for group_message_id (server uses different formats)
    final String? replyGroupId = replyData['group_message_id']?.toString() ??
        replyData['isGroupedMessageId']?.toString() ??
        replyData['groupMessageId']?.toString();

    if (replyGroupId != null && replyGroupId.isNotEmpty) {
      // Find all messages with the same group_message_id
      final groupedMessages = _allMessages
          .where((m) =>
              (m['group_message_id']?.toString() == replyGroupId ||
                  m['groupMessageId']?.toString() == replyGroupId ||
                  m['isGroupedMessageId']?.toString() == replyGroupId) &&
              m['is_deleted'] != true)
          .toList();

      if (groupedMessages.length > 1) {
        bool hasImage = false;
        bool hasVideo = false;

        for (final msg in groupedMessages) {
          final contentType = (msg['ContentType'] ?? msg['contentType'] ?? '')
              .toString()
              .toLowerCase();
          final fileType =
              (msg['mimeType'] ?? msg['fileType'] ?? msg['mimetype'] ?? '')
                  .toString()
                  .toLowerCase();

          // Check if it's an image
          if (contentType == 'image' ||
              fileType.startsWith('image/') ||
              contentType == 'image_group') {
            hasImage = true;
          }

          // Check if it's a video
          if (contentType == 'video' ||
              fileType.startsWith('video/') ||
              contentType == 'video_group') {
            hasVideo = true;
          }

          // Early exit if we found both
          if (hasImage && hasVideo) {
            return true;
          }
        }
      }
    }

    // Fallback: Check imageCount and videoCount (from server response)
    int imgC = int.tryParse(replyData['imageCount']?.toString() ?? '0') ?? 0;
    int vidC = int.tryParse(replyData['videoCount']?.toString() ?? '0') ?? 0;

    // Check nested reply object
    if (imgC == 0 && vidC == 0 && replyData['reply'] is Map) {
      final nested = replyData['reply'];
      imgC = int.tryParse(nested['imageCount']?.toString() ?? '0') ?? 0;
      vidC = int.tryParse(nested['videoCount']?.toString() ?? '0') ?? 0;
    }

    if (imgC > 0 && vidC > 0) return true;

    // 🔥 FINAL FALLBACK: Check the content string itself for "Media x"
    // This handles cases where metadata is lost but the label was saved
    final content = (replyData['replyContent'] ?? replyData['content'] ?? '')
        .toString()
        .replaceAll('×', 'x');

    return content.contains('Media x ');
  }

  List<InlineSpan> _buildHighlightSpans(String content, TextStyle style) {
    if (_searchController.text.isEmpty) {
      return [TextSpan(text: content, style: style)];
    }

    final searchTerm = _searchController.text.toLowerCase();
    final contentLower = content.toLowerCase();
    final spans = <InlineSpan>[];
    int start = 0;
    int indexOfHighlight = contentLower.indexOf(searchTerm);

    while (indexOfHighlight != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: content.substring(start, indexOfHighlight),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: content.substring(
            indexOfHighlight, indexOfHighlight + searchTerm.length),
        style: style.copyWith(
          backgroundColor: Colors.yellow,
          color: Colors.black,
        ),
      ));

      start = indexOfHighlight + searchTerm.length;
      indexOfHighlight = contentLower.indexOf(searchTerm, start);
    }

    if (start < content.length) {
      spans.add(TextSpan(
        text: content.substring(start),
        style: style,
      ));
    }

    return spans;
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isSentByMe) {
    return GroupMessageBubbleWidget(
      message: message,
      isSentByMe: isSentByMe,
      currentUserId: currentUserId,
      isSelectionMode: _isSelectionMode,
      selectedMessageKeys: _selectedMessageKeys,
      searchText: _searchController.text,
      imageFile: _imageFile,
      fileUrl: _fileUrl,
      conversationId: widget.conversationId,
      groupName: widget.groupName,
      messageContexts: _messageContexts,
      // Callbacks
      onMessageTap: _onMessageTap,
      onReplyToMessage: _replyToMessage,
      onShowReactionPicker: _showReactionPicker,
      onToggleMessageSelection: _toggleMessageSelection,
      onShowFullImage: _showFullImage,
      onOpenFilex: FileOpenerUtils.openFile,
      onScrollToMessageById: _scrollToMessageById,
      // Helper functions
      sanitizeString: sanitizeString,
      buildHighlightSpans: _buildHighlightSpans,
      calculateGroupMediaLength: _calculateGroupMediaLength,
      hasMixedMediaTypes: _hasMixedMediaTypes,
      mergeReplyData: _mergeReplyData,
      normalizeMessage: GroupChatNormalizeUtils.normalizeMessage,
      buildStatusIcon: _offlineHandler.buildStatusIcon,
      buildMessageTextSpans: _buildMessageTextSpans,
      buildVideoPreviewTile: _buildVideoPreviewTile,
      buildReactionsBar: _buildReactionsBar,
      buildAvatarWithInitial: _buildAvatarWithInitial,
      generateMessageKey: GroupChatMessageUtils.generateMessageKey,
    );
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
      _replyPreview = null;
    });
  }

  Widget _buildMessageInputField(bool isKeyboardVisible, bool thereORleft) {
    return MessageInputField(
      messageController: _messageController,
      conversionId: widget.conversationId,
      reciverID: widget.datumId,
      focusNode: _focusNode,
      onSendPressed: _sendMessage,
      onEmojiPressed: _toggleEmojiKeyboard,
      onAttachmentPressed: () => ShowAltDialog.showOptionsDialog(context,
          conversationId: widget.conversationId,
          senderId: currentUserId,
          receiverId: widget.datumId,
          isGroupChat: true,
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
      onCancelReply: _cancelReply,
      thereORleft: thereORleft,
      isGroupChat: true,
      isRecordingLocked: _isRecordingLocked,
      onLockRecording: () async {
        recorderHelper.stopRecording();
        setState(() {
          _isRecordingLocked = true;

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

        _sendAudioMessage(path, duration);
      },
      groupMembers: _groupMembersList,
      currentUserId: currentUserId,
    );
  }

  void _showReactionPicker(BuildContext context, Map<String, dynamic> message) {
    if (currentUserId.isEmpty) return;

    final bool isDeleted = message['is_deleted'] == true ||
        message['isDeleted'] == true ||
        message['messageStatus'] == 'deleted' ||
        message['content'] == '🚫 This message was deleted';

    if (isDeleted) return;

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
            children: [
              ...recentEmojis.map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleGroupReactionTap(message, emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  )),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _openFullEmojiPicker(context, message);
                },
                child: const Icon(Icons.add_circle_outline, size: 26),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullEmojiPicker(
      BuildContext context, Map<String, dynamic> message)
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 350,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              final list = List<String>.from(recentEmojis);

              if (!list.contains(emoji.emoji)) {
                if (list.length >= 6) list.removeAt(0);
                list.add(emoji.emoji);
              }

              setState(() {
                recentEmojis = list;
              });

              _handleGroupReactionTap(message, emoji.emoji);

              Navigator.pop(context);
            },
            config: Config(
              height: 256,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28 *
                    (foundation.defaultTargetPlatform == TargetPlatform.iOS
                        ? 1.2
                        : 1.0),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CommonAppBarBuilder.build(
      context: context,
      showSearchAppBar: _showSearchAppBar,
      groupMembers: groupMembers,
      isSelectionMode: _isSelectionMode,
      selectedMessages: _selectedMessages,
      toggleSelectionMode: _hasLeftGroup
          ? () {}
          : () {
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
              if (_hasLeftGroup) return;
              DeleteMessageDialog.show(
                context: context,
                onDeleteForEveryone: () => _deleteSelectedMessages("everyone"),
                onDeleteForMe: () => _deleteSelectedMessages('me'),
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
      onSearchTap: _hasLeftGroup
          ? () {}
          : () {
              setState(() {
                _showSearchAppBar = true;
              });
            },
      onCloseSearch: _hasLeftGroup ? () {} : _hideSearchAppBar,
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      onSearchUp: _onSearchUp,
      onSearchDown: _onSearchDown,
      searchMatchCount: _searchMatchGroupIds.length,
      searchMatchIndex: _searchMatchGroupIds.isEmpty
          ? 0
          : (_searchMatchGroupIds.length - _currentSearchMatchIndex),
      hasLeftGroup: _hasLeftGroup,
      onExitGroup: () {
        if (widget.groupId != null || widget.datumId.isNotEmpty) {
          context
              .read<MediaBloc>()
              .add(ExitGroup(grpId: widget.groupId ?? widget.datumId));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _groupBloc,
      child: Stack(
        children: [
          ReusableChatScaffold(
            appBar: _buildAppBar(),
            chatBody: _buildChatBody(),
            voiceRecordingUI: SizedBox(),
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
                        if (members.isNotEmpty) {}
                        if (members is List) {
                          groupMembers = members.map((m) {
                            if (m is Map) {
                              return (m['member_id'] ??
                                      m['id'] ??
                                      m['_id'] ??
                                      "")
                                  .toString();
                            }
                            return m.toString();
                          }).toList();
                          // CRITICAL FIX: Store member IDs for later rebuild
                          _knownMemberIds = List<String>.from(groupMembers);
                        }
                      });
                    }
                  }
                  if (state is GroupChatError) {}
                },
                child: BlocBuilder<GroupChatBloc, GroupChatState>(
                  bloc: _groupBloc,
                  buildWhen: (previous, current) => current is! GroupLeftState,
                  builder: (context, state) {
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
            isRecording: false,
            bloc: _groupBloc,
          ),
          if (_showScrollToBottomButton)
            Positioned(
              right: 16,
              bottom: 90, // above message input
              child: FloatingActionButton(
                mini: true,
                backgroundColor: chatColor,
                onPressed: () {
                  _scrollToBottom();
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

  Widget _buildAvatarWithInitial(String name) {
    final String initial =
        name.isNotEmpty ? name.trim().characters.first.toUpperCase() : "U";
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            name.isNotEmpty ? ColorUtil.getColorFromAlphabet(name) : Colors.red,
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

  bool _hasReply(Map<String, dynamic> message) {
    return (message['reply'] != null &&
            message['reply'] is Map &&
            (message['reply'] as Map).isNotEmpty) ||
        (message['repliedMessage'] != null &&
            message['repliedMessage'] is Map &&
            (message['repliedMessage'] as Map).isNotEmpty);
  }

  Future<void> _handleGroupReactionTap(
    Map<String, dynamic> message,
    String emoji,
  )
  async {
    try {
      final rawId = (message['message_id'] ??
              message['messageId'] ??
              message['id'] ??
              message['_id'] ??
              '')
          .toString();

      if (rawId.isEmpty) {
        return;
      }

      final apiMessageId =
          GroupChatMessageUtils.normalizeMessageIdForApi(rawId);

      // 🔥 Extract reactions safely
      final List<Map<String, dynamic>> reactions =
          GroupChatReactionUtils.extractReactions(message['reactions']);

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

        _groupBloc.add(GroupRemoveReaction(
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

        _groupBloc.add(GroupRemoveReaction(
          messageId: apiMessageId,
          conversationId: widget.conversationId,
          emoji: oldEmoji ?? '',
          userId: currentUserId,
          receiverId: widget.datumId,
        ));

        _groupBloc.add(GroupAddReaction(
          messageId: apiMessageId,
          conversationId: widget.conversationId,
          emoji: emoji,
          userId: currentUserId,
          receiverId: widget.datumId,
        ));
        return;
      }

      // CASE 3: new reaction
      _updateLocalReactions(rawId, emoji);

      _groupBloc.add(GroupAddReaction(
        messageId: apiMessageId,
        conversationId: widget.conversationId,
        emoji: emoji,
        userId: currentUserId,
        receiverId: widget.datumId,
      ));

      // Clear selection after reaction
      setState(() {
        _isSelectionMode = false;
        _selectedMessages.clear();
        _selectedMessageIds.clear();
        _selectedMessageKeys.clear();
      });
    } catch (e) {
      // log('❌ Error handling reaction tap: $e');
    }
  }

  Widget _buildReactionsBar(Map<String, dynamic> message, bool isSentByMe) {
    return ReactionBar(
      message: message,
      currentUserId: currentUserId,
      recentEmojis: recentEmojis,
      onEmojiUpdated: (list) {
        setState(() {
          recentEmojis = list;
        });
      },
      onReactionTap: (msg, emoji) => _handleGroupReactionTap(msg, emoji),
      onOpenReactors: (msg, emoji) => _showReactionsBottomSheet(msg, emoji),
    );
  }

  Future<void> _showReactionsBottomSheet(
      Map<String, dynamic> message, String initialEmoji)
  async {
    // helper to build normalized reactions list for a message object
    List<Map<String, dynamic>> normalizeFromMap(Map<String, dynamic> msg) {
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
    List<Map<String, dynamic>> allReacts = normalizeFromMap(message);

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
              allReacts = normalizeFromMap(latest);
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
                                  ? Colors.green.withValues(alpha: 0.12)
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
                                          ? Colors.greenAccent
                                              .withValues(alpha: 0.3)
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
                                log(e.toString());
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
                                    final apiMessageId = GroupChatMessageUtils
                                        .normalizeMessageIdForApi(msgId);

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

    socketService.sendReadReceipts(
      messageIds: messageIds,
      conversationId: widget.conversationId,
      roomId: widget.datumId,
    );
  }
}
