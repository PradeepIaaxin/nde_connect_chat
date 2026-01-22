import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:gallery_saver_plus/files.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/GroupRepliedMessagePreview.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/api_servicer.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_state.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MediaPreviewScreen.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MixedMediaViewer.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/commonfuntion.dart';
import 'package:nde_email/presantation/chat/widget/custom_appbar.dart';
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/presantation/chat/widget/scaffold.dart';
import 'package:nde_email/presantation/chat/widget/voicerec_ui.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_widget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/message_caption.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/AudioMessageWidget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/grp_showbottom_sheet.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:objectid/objectid.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/whatsapp_swipe_to_reply.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/respiratory.dart';
import '../../../utils/simmer_effect.dart/chat_simmerefect.dart';
import '../../widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import '../../widgets/chat_widgets/messager_Wifgets/buildMessageInputField_widgets.dart';
import '../Socket/socket_service.dart';
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
  late List<String> groupMembers;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> socketMessages = [];
  final SocketService socketService = SocketService();

  StreamSubscription<String>? _messageDeletedSubscription;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _hasLeftGroup = false;
  int _currentPage = 1;

  File? _fileUrl;
  final FocusNode _focusNode = FocusNode();
  late final GroupChatBloc _groupBloc;
  late final ChatListBloc _chatListBloc;
  bool _hasNextPage = false;

  File? _imageFile;
  bool _isLoadingMore = false;
  bool _isPaused = false;
  bool _isRecording = false;
  bool _isSelectionMode = false;

  final int _limit = 40;
  Timer? _timer;

  // Locked Recording State
  bool _isRecordingLocked = false;

  final MentionTextEditingController _messageController =
      MentionTextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _recordedFilePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
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
  List<String> _searchMatchIds = [];
  int _currentSearchMatchIndex = -1;
  bool _permissionChecked = false;

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

  @override
  void dispose() {
    SocketService().clearActiveConversation();
    _messageDeletedSubscription?.cancel();
    final unsentText = _messageController.text.trim();
    if (unsentText.isNotEmpty) {
      _saveDraft(unsentText);
    } else {
      _clearDraft();
    }
    _recorder.closeRecorder();

    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    _timer?.cancel();
    _recordingTimer?.cancel();
    _recordTimer?.cancel();
    _highlightTimer?.cancel();
    _messageContexts.clear();
    _reactionSubscription?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _blocStateSubscription?.cancel();
    _connSub?.cancel();
    _searchController.dispose();

    _clearSessionImagePath();
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

  dynamic _anyId(Map<String, dynamic> m) {
    return m['message_id'] ?? m['messageId'] ?? m['id'] ?? '';
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

    SocketService().setActiveConversation(widget.conversationId);
    currentUserId = widget.currentUserId;
    SocketService().joinChatRoom(
      senderId: currentUserId,
      receiverId: widget.datumId,
      isGroupChat: true,
    );

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
    _chatListBloc = context.read<ChatListBloc>();
    _initializeSocket();

    _loadCurrentUserId();

    if (!_permissionChecked) {
      _groupBloc.add(PermissionCheck(widget.datumId));
      _permissionChecked = true;
    }

    // _fetchMessages2();

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
          debugPrint(
              '📤 Message sent successfully: $serverMessageId with status: $serverStatus');
          _updateMessageStatus(serverMessageId, serverStatus);
        }
      } else if (state is GrpMessageAckReceived) {
        debugPrint(
            '✅ ACK Received: ${state.tempId} -> ${state.realId} (${state.status})');
        _replaceTempMessageWithReal(
          tempId: state.tempId,
          realId: state.realId,
          status: state.status,
        );
      } else if (state is GroupDetailsLoaded) {
        _updateGroupMembers(state.groupDetails);
      } else if (state is GroupChatLoaded) {
        debugPrint(
            "📨 GroupChatLoaded received in initState! knownMemberIds: ${_knownMemberIds.length}");
      }
    });

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    // Open the audio session for FlutterSoundRecorder
    await _recorder.openRecorder();
    // Configure usage for voice recording (optional but good practice)
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
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
      log('❌ Error opening camera: $e');
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

  void onMessageReceived(Map<String, dynamic> rawData) {
    /// 1️⃣ Extract message safely
    Map<String, dynamic> msg;
    if (rawData['data'] is Map) {
      msg = Map<String, dynamic>.from(rawData['data']);
    } else {
      msg = Map<String, dynamic>.from(rawData);
    }

    print(widget.conversationId);
    log("log message daa ${widget.conversationId}");

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

    /// 6️⃣ Normalize message for UI
    final Map<String, dynamic> newMessage = {
      'message_id': messageId,
      'content': (msg['content'] ?? '').toString(),
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
      'repliedMessage': msg['reply'] ?? msg['repliedMessage'],
      'duration': msg['duration']?.toString(),
    };

    if (!mounted) return;

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
        log("🔄 UPDATED existing message in socketMessages: $messageId");
      } else {
        // Add as new message
        socketMessages.add(newMessage);
        _scrollToBottom();
        if (_visibleCount > 0) _visibleCount++;
        log("➕ ADDED new message to socketMessages: $messageId");
      }

      final combined = _getCombinedMessages();
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);

      _updateNotifier();
    });

    log(
      "✅ GROUP MESSAGE SHOWN → ${newMessage['content']} | sender=${newMessage['userName']}",
    );
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
      log("🗑️ Received message_deleted event for: $messageId");
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
    GrpLocalChatStorage.saveMessages(widget.conversationId, combined);

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
        ? (() {
            // Extract URLs and fileName for extension check
            final String mediaUrl = reply["originalUrl"]?.toString() ??
                reply["imageUrl"]?.toString() ??
                reply["fileUrl"]?.toString() ??
                "";
            final String fileName = reply["fileName"]?.toString() ?? "";

            // Get extension
            String ext = "";
            if (mediaUrl.isNotEmpty) {
              final uri = Uri.tryParse(mediaUrl);
              ext = uri?.path.split('.').last.toLowerCase() ?? "";
            } else if (fileName.isNotEmpty) {
              ext = fileName.split('.').last.toLowerCase();
            }

            // Guess type by extension if not provided
            String mimeType = reply["mimeType"]?.toString() ??
                reply["fileType"]?.toString() ??
                "";
            String contentType = reply["ContentType"]?.toString() ??
                reply["contentType"]?.toString() ??
                "";

            if (mimeType.isEmpty || contentType.isEmpty) {
              if (["jpg", "jpeg", "png", "gif", "webp"].contains(ext)) {
                mimeType = "image/$ext";
                contentType = "image";
              } else if (["mp4", "mov", "mkv", "avi", "webm"].contains(ext)) {
                mimeType = "video/$ext";
                contentType = "video";
              } else if (["mp3", "wav", "aac", "m4a", "flac", "ogg", "opus"]
                  .contains(ext)) {
                mimeType = "audio/$ext";
                contentType = "audio";
              } else if ([
                "pdf",
                "doc",
                "docx",
                "xls",
                "xlsx",
                "ppt",
                "pptx",
                "txt"
              ].contains(ext)) {
                mimeType = "application/$ext";
                contentType = "document";
              } else if (mediaUrl.isNotEmpty) {
                mimeType = "application/octet-stream";
                contentType = "file";
              }
            }

            return {
              "userId": reply["userId"] ?? reply["senderId"],
              "id": reply["id"] ?? reply["message_id"] ?? reply["messageId"],
              "mimeType": mimeType,
              "fileType": mimeType,
              "ContentType": contentType,
              "contentType": contentType,
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
              "duration": reply["duration"] ?? reply["videoDuration"],
              "videoDuration": reply["videoDuration"] ?? reply["duration"],
              'profile_pic_path': message['sender']?['profile_pic_path'] ??
                  message['sender']?['profilePic'] ??
                  message['profile_pic_path'] ??
                  '',
            };
          })()
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

    final bool isDeleted =
        message['is_deleted'] == true || message['isDeleted'] == true;

    final conversationId = message['conversationId'] ??
        message['convoId'] ??
        message['conversation_id'];

    return {
      'conversationId': conversationId,
      'message_id': messageId,
      'messageId': messageId,
      'content': isDeleted ? '🚫 This message was deleted' : content,
      'userName': userName,
      'sender': message['sender'],
      'receiver': message['receiver'],
      'messageStatus': isDeleted
          ? 'deleted'
          : (messageStatus.isEmpty ? 'sent' : messageStatus),
      'time': message['time'],
      'imageUrl': isDeleted ? null : imageUrl,
      'fileName': isDeleted ? null : fileName,
      'ContentType': contentType,
      'contentType': contentType,
      'fileUrl': isDeleted ? null : fileUrl,
      'fileType': isDeleted ? null : fileType,
      'isForwarded': isForwarded,
      'isReplyMessage': isReplyMessage,
      'repliedMessage': normalizedReply,
      'reactions': normalizedReactions,
      'profile_pic_path': profilePic,
      'isDeleted': isDeleted,
      'is_deleted': isDeleted,
      'duration': message['duration']?.toString() ??
          message['videoDuration']?.toString(),
    };
  }

  bool isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    final media = buildConversationMedia(
      _allMessages,
      currentUserId: currentUserId,
    );
    final index = media.indexWhere((m) => m.mediaUrl == imageUrl);
    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MixedMediaViewer(
            items: media,
            initialIndex: index,
          ),
        ),
      );
    } else {
      ImageViewer.show(context, imageUrl);
    }
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

  // Future<void> _initMessages() async {
  //   final savedMessages =
  //       await GrpLocalChatStorage.loadMessages(widget.conversationId);

  //   setState(() {
  //     dbMessages = savedMessages
  //         .map<Map<String, dynamic>>((msg) => normalizeMessage(msg))
  //         .where((m) => m.isNotEmpty)
  //         .toList();

  //     for (var m in dbMessages) {
  //       final id = (m['message_id'] ?? m['id'])?.toString();
  //       if (id != null && id.isNotEmpty) _seenMessageIds.add(id);
  //     }
  //   });
  //   _updateNotifier();
  // }
  Future<void> _initMessages() async {
    // Clear current messages first
    setState(() {
      dbMessages.clear();
      messages.clear();
      socketMessages.clear();
      _seenMessageIds.clear();
    });

    // Load from local storage
    final savedMessages =
        await GrpLocalChatStorage.loadMessages(widget.conversationId);

    if (savedMessages.isNotEmpty) {
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

      // Also fetch fresh messages from server
      _groupBloc.add(
        FetchGroupMessages(
          convoId: widget.conversationId,
          page: 1,
          limit: _limit,
        ),
      );
    } else {
      // If no local messages, fetch from server
      _groupBloc.add(
        FetchGroupMessages(
          convoId: widget.conversationId,
          page: 1,
          limit: _limit,
        ),
      );
    }
  }

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

  // void _fetchMessages2() {
  //   _groupBloc.add(
  //     FetchGroupMessages(
  //       convoId: widget.conversationId,
  //       page: _currentPage,
  //       limit: _limit,
  //     ),
  //   );
  // }

  // void _fetchMessages() {
  //   _groupBloc.add(
  //     FetchGroupMessages(
  //       convoId: widget.conversationId,
  //       page: _currentPage,
  //       limit: _limit,
  //     ),
  //   );

  //   // _checkingPersmmion();
  // }

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
        });
      }

      print("✅ User has permission to chat: $_hasLeftGroup");
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
            'imageCount': _replyPreview?['imageCount'],
            'videoCount': _replyPreview?['videoCount'],
            'group_message_id': _replyPreview?['group_message_id'],
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
      if (_visibleCount > 0) _visibleCount++;

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
      log('❌ Send message error: $e');
      _updateMessageStatus(tempId, 'failed');
    }
  }

// ------------------ Group Members Logic ------------------
  List<Map<String, dynamic>> _groupMembersList = [];
  List<String> _knownMemberIds = [];

  void _updateGroupMembers(Map<String, dynamic> groupDetails) {
    debugPrint("👥 _updateGroupMembers called with keys: ${groupDetails.keys}");

    // Try to extract member IDs from various possible keys
    List<dynamic>? memberData;
    if (groupDetails['groupMembers'] is List) {
      memberData = groupDetails['groupMembers'];
      debugPrint("✅ Found 'groupMembers' key with ${memberData!.length} items");
    } else if (groupDetails['members'] is List) {
      memberData = groupDetails['members'];
      debugPrint("✅ Found 'members' key with ${memberData!.length} items");
    } else if (groupDetails['participants'] is List) {
      memberData = groupDetails['participants'];
      debugPrint("✅ Found 'participants' key with ${memberData!.length} items");
    } else if (groupDetails['users'] is List) {
      memberData = groupDetails['users'];
      debugPrint("✅ Found 'users' key with ${memberData!.length} items");
    } else if (groupDetails['data'] is Map &&
        groupDetails['data']['members'] is List) {
      memberData = groupDetails['data']['members'];
      debugPrint(
          "✅ Found nested 'data.members' with ${memberData!.length} items");
    } else if (groupDetails['group'] is Map &&
        groupDetails['group']['members'] is List) {
      memberData = groupDetails['group']['members'];
      debugPrint(
          "✅ Found nested 'group.members' with ${memberData!.length} items");
    }

    if (memberData != null && memberData.isNotEmpty) {
      debugPrint("🔍 First element type: ${memberData.first.runtimeType}");

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
            final String fullName = '${firstName} ${lastName}'.trim();
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
        debugPrint(
            "✅ Populated ${_groupMembersList.length} members from API details");
      }

      // Always try to supplement/update from messages to get most recent names/pics
      _buildMemberDetailsFromMessages(_knownMemberIds);

      debugPrint("💾 Stored ${_knownMemberIds.length} member IDs");
    } else {
      log("⚠️ No members found in group details. Keys: ${groupDetails.keys}");
      // Try to extract from messages as fallback
      _buildMemberDetailsFromMessages(
          _knownMemberIds.isNotEmpty ? _knownMemberIds : null);
    }
  }

  void _buildMemberDetailsFromMessages(List<String>? knownMemberIds) {
    debugPrint("🔍 Building member list from messages...");
    debugPrint("   - dbMessages: ${dbMessages.length}");
    debugPrint("   - messages: ${messages.length}");
    debugPrint("   - socketMessages: ${socketMessages.length}");
    debugPrint("   - knownMemberIds: ${knownMemberIds?.length ?? 'null'}");

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
          final String fullName = '${firstName} ${lastName}'.trim();
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

    debugPrint(
        "✅ Built group members list from messages: ${_groupMembersList.length} members");
  }

  List<InlineSpan> _buildMessageTextSpans(String content) {
    final List<InlineSpan> spans = [];
    if (content.isEmpty) return spans;

    // 1. Prepare mention regex from group members
    // Sort by length descending to match longer names first (e.g., "John Doe" before "John")
    final List<String> memberNames = _groupMembersList
        .map((m) => m['full_name']?.toString() ?? "")
        .where((name) => name.isNotEmpty)
        .toList();
    memberNames.sort((a, b) => b.length.compareTo(a.length));

    // Escape special characters in names for regex
    final String escapedNames = memberNames.map(RegExp.escape).join('|');
    // Pattern matches @ followed by one of the member names
    final String mentionPattern =
        memberNames.isEmpty ? r'(?! )' : '@($escapedNames)';

    // 2. Combined regex for URLs and Mentions
    final String urlPattern = r'((https?:\/\/)|(www\.))[^\s]+';
    final RegExp combinedRegExp =
        RegExp('$urlPattern|$mentionPattern', caseSensitive: false);

    final matches = combinedRegExp.allMatches(content);
    int start = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: content.substring(start, match.start),
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        );
      }

      final String matchText = content.substring(match.start, match.end);

      if (matchText.startsWith('@')) {
        // It's a mention
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: chatColor,
            ),
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
                  debugPrint('Could not launch url: $e');
                }
              },
          ),
        );
      }

      start = match.end;
    }

    // Add remaining text
    if (start < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(start),
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      );
    }

    return spans;
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
        'content': '',
        'sender': {'_id': currentUserId},
        'receiver': {'_id': widget.datumId},
        'messageStatus': 'sent',
        'time': nowIso,
        'fileName': file.name,
        'fileType': mimeType,
        'imageUrl': isImage ? file.path : null,
        'fileUrl': !isImage ? file.path : null,
      };

      // 1. Optimistic Update
      setState(() {
        socketMessages.add(message);
        if (_visibleCount > 0) _visibleCount++;
        _updateNotifier();
      });
      context.read<GroupChatBloc>().add(
            GrpUploadFileEvent(
              file: localFile,
              convoId: widget.conversationId,
              senderId: currentUserId,
              receiverId: widget.datumId,
              groupId: widget.datumId,
              messageId: messageId,
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

    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 50) {
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

              setState(() => _isLoadingMore = true);
              _currentPage++;
              log('📡 Server Pagination: Fetching page $_currentPage from server... (hasNextPage: $_hasNextPage)');

              _groupBloc.add(
                FetchGroupMessages(
                  convoId: widget.conversationId,
                  page: _currentPage,
                  limit: _limit,
                ),
              );
            });
          }
        });
      }
      // 2. Server-side pagination: User scrolled with all local messages already shown
      else if (_visibleCount >= total && _hasNextPage && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        _currentPage++;
        log('📡 Server Pagination: Fetching page $_currentPage from server... (hasNextPage: $_hasNextPage)');

        _groupBloc.add(
          FetchGroupMessages(
            convoId: widget.conversationId,
            page: _currentPage,
            limit: _limit,
          ),
        );
      } else {
        log('🛑 Pagination stopped - visibleCount: $_visibleCount, total: $total, hasNextPage: $_hasNextPage, isLoading: $_isLoadingMore');
      }
    }
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

  void _markMessagesAsDeleted(List<String> messageIds,
      {String deleteFor = 'everyone'}) {
    log("Marking messages as deleted: $messageIds (for $deleteFor)");

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
      GrpLocalChatStorage.saveMessages(widget.conversationId, combined);
      _updateNotifier();
    });
  }

  void _deleteSelectedMessages(String deleteFor) {
    if (_selectedMessageIds.isEmpty) {
      log("No messages selected to delete");
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

    debugPrint('📩 tapped message id: ${message['message_id']}');

    // 🔥 Fallback: If message failed, show resend dialog on tap
    final status = message['messageStatus']?.toString() ?? '';
    if (status == 'failed' || status == 'pending_offline') {
      _showResendDialog(message);
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

  Map<String, dynamic> _mergeReplyData(dynamic replyData) {
    Map<String, dynamic> merged = {};

    if (replyData is Map) {
      merged.addAll(Map<String, dynamic>.from(replyData));
    }

    // Ensure we have proper MIME type by checking multiple fields
    if ((merged['fileType'] == null || merged['fileType'].toString().isEmpty) &&
        merged['mimeType'] != null &&
        merged['mimeType'].toString().isNotEmpty) {
      merged['fileType'] = merged['mimeType'];
    }

    return merged;
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
    final String? fileType = message['mimeType'] ??
        message['fileType'] ??
        message['mimetype'] ??
        message['ContentType'];
    final String? originalUrl = message['originalUrl'] ?? fileUrl;

    final String userName = message['senderName'] ??
        message['userName'] ??
        (message['sender']?['name'] ?? '');

    final String ftLower = (fileType ?? '').toLowerCase();
    final bool isVideo = ftLower.startsWith('video/');

    setState(() {
      // 1️⃣ Keep the FULL message as-is for _sendMessage
      _replyMessage = message;
      // Calculate counts if it's a grouped message
      int imageCount = 0;
      int videoCount = 0;
      final String? groupId = message['group_message_id']?.toString();

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

      // 2️⃣ Build a lightweight map only for the input field UI
      _replyPreview = {
        'message_id':
            (message['message_id'] ?? message['messageId'] ?? message['id'])
                ?.toString(),
        'content': content,
        'imageUrl': imageUrl ?? '',
        'fileUrl': fileUrl ?? '',
        'fileName': fileName ?? '',
        'fileType': message['mimeType'] ??
            message['fileType'] ??
            message['mimetype'] ??
            message['ContentType'] ??
            '',
        'originalUrl': originalUrl ?? '',
        'userName': userName,
        'isVideo': isVideo,
        'ContentType': message['ContentType'] ?? message['contentType'] ?? '',
        'duration': message['duration'] ?? '',
        'mimeType': message['mimeType'] ?? message['mimetype'] ?? '',
        'imageCount': imageCount,
        'videoCount': videoCount,
        'group_message_id': groupId,
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

  bool _isGroupableMedia(Map<String, dynamic> msg) {
    if (msg['isDeleted'] == true || msg['is_deleted'] == true) return false;

    final String contentType = (msg['ContentType'] ?? msg['contentType'] ?? '')
        .toString()
        .toLowerCase();
    final String fileType =
        (msg['fileType'] ?? msg['mimeType'] ?? '').toString().toLowerCase();
    final String fileUrl =
        (msg['fileUrl'] ?? msg['originalUrl'] ?? '').toString().toLowerCase();

    // 1. Explicitly NOT audio or common document types
    if (contentType == 'audio' || fileType.startsWith('audio/')) return false;

    // 2. Identify Image
    // More robust image check:
    final bool isRealImage =
        (msg['imageUrl'] != null && msg['imageUrl'].toString().isNotEmpty) &&
            (fileType.startsWith('image/') ||
                contentType == 'image' ||
                ['.jpg', '.jpeg', '.png', '.gif', '.webp']
                    .any((ext) => fileUrl.endsWith(ext)));

    final bool isLocalImage = (msg['localImagePath'] != null &&
        msg['localImagePath'].toString().isNotEmpty);

    // 3. Identify Video
    final bool isRealVideo = fileType.startsWith('video/') ||
        contentType == 'video' ||
        ['.mp4', '.mov', '.mkv', '.avi', '.webm']
            .any((ext) => fileUrl.endsWith(ext));

    return isRealImage || isLocalImage || isRealVideo;
  }

  List<Map<String, dynamic>> _inferGrouping(
      List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return messages;

    for (int i = 0; i < messages.length; i++) {
      final currentMsg = messages[i];

      // Skip if already grouped
      if (currentMsg['is_grouped_message'] == true &&
          currentMsg['group_message_id'] != null) {
        continue;
      }

      final bool isMedia = _isGroupableMedia(currentMsg);
      if (!isMedia) continue;

      // Look ahead for consecutive media from same sender within time threshold
      List<int> groupIndices = [i];
      final currentSender = currentMsg['sender'] is Map
          ? currentMsg['sender']['_id']?.toString()
          : currentMsg['sender']?.toString();
      final currentTime = _parseTime(currentMsg['time']);

      // Check if current message has a caption - don't group if it does
      final bool currentHasCaption =
          (currentMsg['content']?.toString() ?? '').isNotEmpty;

      for (int j = i + 1; j < messages.length; j++) {
        final nextMsg = messages[j];
        final nextSender = nextMsg['sender'] is Map
            ? nextMsg['sender']['_id']?.toString()
            : nextMsg['sender']?.toString();
        final nextTime = _parseTime(nextMsg['time']);

        // Detect media for next message
        // Detect media for next message
        final bool nextIsMedia = _isGroupableMedia(nextMsg);
        final bool nextHasCaption =
            (nextMsg['content']?.toString() ?? '').isNotEmpty;

        if (nextSender != currentSender ||
            !nextIsMedia ||
            nextTime.difference(currentTime).inMinutes.abs() > 1) {
          break;
        }

        // Don't group if either message has a caption
        if (currentHasCaption || nextHasCaption) {
          break;
        }

        // Already grouped by server? Treat as boundary
        if (nextMsg['is_grouped_message'] == true &&
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
          messageToGroup['is_grouped_message'] = true;
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
    final List<Map<String, dynamic>> combined = [];

    void addUnique(Map<String, dynamic> msg) {
      // 🔥 SAFETY: Filter out messages from other conversations
      final msgConvoId =
          msg['conversationId'] ?? msg['convoId'] ?? msg['conversation_id'];

      // Allow if ID is null (legacy) but block if explicit mismatch
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

      // 1. Check by ID first (strongest check)
      final msgId =
          msg['message_id'] ?? msg['messageId'] ?? msg['_id'] ?? msg['id'];
      if (msgId != null) {
        final idString = msgId.toString();

        // Find existing message with same ID
        final existingIndex = combined.indexWhere((m) {
          final mId = m['message_id'] ?? m['messageId'] ?? m['_id'] ?? m['id'];
          return mId != null && mId.toString() == idString;
        });

        if (existingIndex != -1) {
          // Message with this ID already exists - merge/update it
          final existing = combined[existingIndex];
          final existingStatus = (existing['messageStatus'] ?? '').toString();
          final newStatus = (msg['messageStatus'] ?? '').toString();

          // Priority: sent/delivered/read > sending > pending
          final statusPriority = {
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

          // If new message has better status or more complete data, replace
          if (newPriority > existingPriority ||
              (msg['originalUrl'] != null && existing['originalUrl'] == null) ||
              (msg['fileUrl'] != null && existing['isLocal'] == true)) {
            // Merge: keep any local data, but update with server data
            final merged = Map<String, dynamic>.from(existing);
            msg.forEach((key, value) {
              if (value != null) merged[key] = value;
            });
            combined[existingIndex] = merged;
          }
          return; // Don't add duplicate
        }
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
        final copy = Map<String, dynamic>.from(msg);
        combined.add(copy);
      }
    }

    for (var m in socketMessages) {
      addUnique(m);
    }
    for (var m in messages) {
      addUnique(m);
    }
    for (var m in dbMessages) {
      addUnique(m);
    }

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

  Future<bool> _scrollToMessageById(String messageId,
      {bool fetchIfMissing = true}) async {
    if (messageId.isEmpty) return false;

    final ctx = _messageContexts[messageId];
    if (ctx != null && ctx.mounted) {
      _highlightAndScrollToContext(ctx, messageId);
      return true;
    }

    List<Map<String, dynamic>> combined = _getCombinedMessages();

    int msgIndex = combined.indexWhere((m) {
      final mid =
          (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';
      return mid == messageId;
    });

    if (msgIndex == -1 && fetchIfMissing) {
      final found = await _fetchUntilMessageFound(messageId);
      if (!found) return false;

      combined = _getCombinedMessages();
      msgIndex = combined.indexWhere((m) {
        final mid =
            (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';
        return mid == messageId;
      });

      if (msgIndex == -1) return false;
    }

    if (msgIndex != -1) {
      // Ensure message is within visible window
      final int neededVisible = combined.length - msgIndex;
      if (_visibleCount < neededVisible) {
        setState(() {
          _visibleCount = neededVisible + 5; // Add a small buffer
          if (_visibleCount > combined.length) _visibleCount = combined.length;
        });
        _updateNotifier();
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final int listIndex = combined.length - 1 - msgIndex;
      final double estimatedOffset = _estimateScrollOffset(listIndex, combined);

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

      // Try multiple attempts with refined scrolling
      for (int attempt = 0; attempt < 3; attempt++) {
        await Future.delayed(const Duration(milliseconds: 50));

        final targetCtx = _messageContexts[messageId];
        if (targetCtx != null && targetCtx.mounted) {
          _highlightAndScrollToContext(targetCtx, messageId);
          return true;
        }

        // Find closest visible message and refine scroll position
        int? closestVisibleIndex;
        double minDiff = double.infinity;

        for (final entry in _messageContexts.entries) {
          final ctx = entry.value;
          if (ctx.mounted) {
            final idx = combined.indexWhere((m) {
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
            correction += _estimateMessageHeight(combined[k]);
          }

          if (indexDiff < 0) correction = -correction;

          final currentEstimate = estimatedOffset + correction;
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
      _groupBloc.add(
        FetchGroupMessages(
          convoId: widget.conversationId,
          page: _currentPage,
          limit: _limit,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      return _scrollToMessageById(messageId, fetchIfMissing: false);
    }

    return false;
  }

  /// Highlight message and scroll to its context
  void _highlightAndScrollToContext(BuildContext ctx, String messageId) {
    if (!ctx.mounted) return;

    _highlightMessage(messageId);

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
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
  double _estimateMessageHeight(Map<String, dynamic> message) {
    final content = (message['content'] ?? '').toString();
    final hasMedia =
        (message['fileUrl'] ?? message['imageUrl'] ?? '').toString().isNotEmpty;
    final hasReply = _hasReplyForMessage(message);

    double height = 60.0; // Base height

    if (content.isNotEmpty) {
      final lines = (content.length / 40).ceil();
      height += lines * 20.0;
    }

    if (hasMedia) height += 120.0;
    if (hasReply) height += 60.0;

    return height.clamp(60.0, 300.0);
  }

  /// Estimate scroll offset for a given list index
  double _estimateScrollOffset(
      int listIndex, List<Map<String, dynamic>> messages) {
    double offset = 0.0;

    for (int i = 0; i < listIndex && i < messages.length; i++) {
      offset += _estimateMessageHeight(messages[i]);
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
          setState(() {
            _isLoadingMore = false;
          });
        } else if (state is GroupChatLoaded) {
          // 🔍 Track every GroupChatLoaded emission
          log('\ud83d\udea8 GroupChatLoaded RECEIVED - Page: $_currentPage, isLoadingMore: $_isLoadingMore, total on server: ${state.response.total}');

          // ALWAYS update these flags when state arrives, even if data is same
          _hasNextPage = state.response.hasNextPage;
          if (_isLoadingMore) {
            setState(() => _isLoadingMore = false);
          }

          final incomingLoaded = flattenGroupedMessages(state.response.data);

          final incomingNormalized = incomingLoaded
              .map<Map<String, dynamic>>((msg) => normalizeMessage(msg))
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

          log('📊 PAGINATION INFO:');
          log('   📄 Current page: $_currentPage of $totalPages');
          log('   📥 Total messages on server: ${state.response.total}');
          log('   📦 Incoming messages this page: ${incomingNormalized.length}');
          log('   💾 Current local messages: ${dbMessages.length}');
          log('   ⏭️  Has next page: ${state.response.hasNextPage}');
          log('   ⏮️  Has previous page: ${state.response.hasPreviousPage}');

          setState(() {
            // --- ROBUST MERGE STRATEGY ---
            // Overlays incoming messages on top of existing ones by ID
            // This preserves older history when Page 1 is refreshed
            final Map<String, Map<String, dynamic>> messagesMap = {};

            log('🔀 MERGE STRATEGY:');
            log('   📝 Existing dbMessages: ${dbMessages.length}');
            log('   📥 Incoming messages: ${incomingNormalized.length}');

            // 1. Put existing messages into map
            for (var m in dbMessages) {
              final id = (m['message_id'] ?? m['id'] ?? '').toString();
              if (id.isNotEmpty) messagesMap[id] = m;
            }
            log('   🗄️  Messages in map after existing: ${messagesMap.length}');

            // 2. Overlay incoming messages (may override existing or add new)
            for (var m in incomingNormalized) {
              final id = (m['message_id'] ?? m['id'] ?? '').toString();
              if (id.isNotEmpty) {
                messagesMap[id] = m;
                //  log('   ➕ Added/Updated message: $id');
              }
            }
            log('   🗄️  Messages in map after incoming: ${messagesMap.length}');

            // 3. Rebuild dbMessages from merged map
            dbMessages = messagesMap.values.toList();
            log('   ✅ After merge, dbMessages count: ${dbMessages.length}');
            if (_knownMemberIds.isNotEmpty && _groupMembersList.isEmpty) {
              debugPrint(
                  "🔄 Rebuilding member list after dbMessages population");
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
            debugPrint(
                '   - Page $_currentPage: Set _visibleCount to $_visibleCount to show all messages');
          }

          debugPrint(
              '✅ GroupChatLoaded processed: total=${_allMessages.length}, visible=$_visibleCount');
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
            bloc: _groupBloc,
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
                      child:
                          _isLoadingMore ? SizedBox() : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: combinedMessages.length,
                        reverse: true,
                        itemBuilder: (context, index) {
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
                          final bool isDeleted =
                              message['is_deleted'] == true ||
                                  message['messageStatus'] == 'deleted' ||
                                  content == ' This message was deleted';

                          final currentTime = _parseTime(message['time']);
                          final prevTime = realIndex > 0
                              ? _parseTime(
                                  combinedMessages[realIndex - 1]['time'])
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
                                combinedMessages[realIndex - 1]
                                            ['group_message_id']
                                        ?.toString() !=
                                    groupMessageId;

                            if (!isFirstInGroup) {
                              return const SizedBox.shrink();
                            }

                            List<String> groupImages = [];
                            List<Map<String, dynamic>> groupMessagesList = [];
                            for (int i = realIndex;
                                i < combinedMessages.length;
                                i++) {
                              final nextMsg = combinedMessages[i];
                              final nextGrpId =
                                  nextMsg['group_message_id']?.toString();
                              if (nextGrpId == groupMessageId) {
                                final normalizedNext =
                                    normalizeMessage(nextMsg);
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
                                  _anyId(message)?.toString() ?? '';
                              final bool isHighlighted =
                                  _highlightedMessageId == messageId;

                              return _hasLeftGroup
                                  ? const SizedBox.shrink()
                                  : AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      color: isHighlighted
                                          ? Colors.blueAccent.withOpacity(0.1)
                                          : Colors.transparent,
                                      child: Column(
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
                                            child: SwipeToReply(
                                              onReply: isDeleted
                                                  ? null
                                                  : () =>
                                                      _replyToMessage(message),
                                              child: Builder(builder: (ctx) {
                                                for (var msg
                                                    in groupMessagesList) {
                                                  final mId =
                                                      _anyId(msg)?.toString();
                                                  if (mId != null &&
                                                      mId.isNotEmpty) {
                                                    _messageContexts[mId] = ctx;
                                                  }
                                                }

                                                return Align(
                                                  alignment: isSentByMe
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: isSentByMe
                                                                    ? 0
                                                                    : 36),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(7),
                                                          constraints:
                                                              BoxConstraints(
                                                            maxWidth: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.75,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isSentByMe
                                                                ? senderColor
                                                                : receiverColor,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft:
                                                                  const Radius
                                                                      .circular(
                                                                      18),
                                                              topRight:
                                                                  const Radius
                                                                      .circular(
                                                                      18),
                                                              bottomLeft: isSentByMe
                                                                  ? const Radius
                                                                      .circular(
                                                                      18)
                                                                  : Radius.zero,
                                                              bottomRight: isSentByMe
                                                                  ? Radius.zero
                                                                  : const Radius
                                                                      .circular(
                                                                      16),
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.05),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
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
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          bottom:
                                                                              4.0),
                                                                  child: Text(
                                                                    userName,
                                                                    style:
                                                                        TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: ColorUtil
                                                                          .getColorFromAlphabet(
                                                                              userName),
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                ),
                                                              Stack(
                                                                children: [
                                                                  GroupedMediaWidget(
                                                                    mediaUrls:
                                                                        groupImages,
                                                                    caption:
                                                                        message[
                                                                            'content'],
                                                                    isSentByMe:
                                                                        isSentByMe,
                                                                    time: message[
                                                                            'time'] ??
                                                                        '',
                                                                    messageStatus:
                                                                        message['messageStatus']?.toString() ??
                                                                            'sent',
                                                                    onMediaTap:
                                                                        (index) {
                                                                      final media =
                                                                          buildConversationMedia(
                                                                        combinedMessages,
                                                                        currentUserId:
                                                                            currentUserId,
                                                                      );
                                                                      final tappedUrl =
                                                                          groupImages[
                                                                              index];
                                                                      final startIndex = media.indexWhere((m) =>
                                                                          m.mediaUrl ==
                                                                          tappedUrl);

                                                                      if (startIndex !=
                                                                          -1) {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                MixedMediaViewer(
                                                                              items: media,
                                                                              initialIndex: startIndex,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                  if (message['content'] ==
                                                                          null ||
                                                                      message['content']
                                                                          .toString()
                                                                          .isEmpty)
                                                                    Positioned(
                                                                      bottom: 5,
                                                                      right: 5,
                                                                      child:
                                                                          Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                6,
                                                                            vertical:
                                                                                2),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: Colors
                                                                              .black
                                                                              .withOpacity(0.45),
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
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
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (!isSentByMe)
                                                        Positioned(
                                                          left: 2,
                                                          top: 10,
                                                          child: CircleAvatar(
                                                            radius: 16,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            child: ClipOval(
                                                              child: profileImageUrl
                                                                      .isNotEmpty
                                                                  ? CachedNetworkImage(
                                                                      imageUrl:
                                                                          profileImageUrl,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      width: 32,
                                                                      height:
                                                                          32,
                                                                      errorWidget: (context,
                                                                              url,
                                                                              error) =>
                                                                          _buildAvatarWithInitial(
                                                                              userName),
                                                                    )
                                                                  : _buildAvatarWithInitial(
                                                                      userName),
                                                            ),
                                                          ),
                                                        ),
                                                      Positioned(
                                                        top: 0,
                                                        bottom: 0,
                                                        left: isSentByMe
                                                            ? -60
                                                            : null,
                                                        right: isSentByMe
                                                            ? null
                                                            : -50,
                                                        child: Center(
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
                                                                maxRadius: 16,
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
                                      ? Colors.blueAccent.withOpacity(0.1)
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
            top: 0,
            bottom: 0,
            left: isSentByMe ? -60 : null,
            right: isSentByMe ? null : -60,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    MyRouter.pushReplace(
                      screen: ForwardMessageScreen(
                        messages: [normalizeMessage(message)],
                        currentUserId: currentUserId,
                        conversionalid: widget.conversationId,
                        username: widget.groupName,
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
          if ((message['content']?.toString() ?? '').isEmpty)
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
    final bool? isForwarded = message['isForwarded'] ?? false;

    final String userName =
        (message['userName']?.toString().trim().isNotEmpty == true)
            ? message['userName']
            : (() {
                final s = message['sender'];
                if (s is Map) {
                  return [
                    s['first_name'],
                    s['last_name'],
                    s['name'],
                  ]
                      .where((e) => e != null && e.toString().trim().isNotEmpty)
                      .join(' ')
                      .trim();
                }
                return '';
              })();

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

    final bool isAudio = (fileType != null &&
            fileType.toLowerCase().startsWith("audio")) ||
        (fileName != null &&
            RegExp(r'\.(mp3|wav|aac|m4a|flac|ogg|opus)$', caseSensitive: false)
                .hasMatch(fileName));

    final String messageStatus =
        message['messageStatus']?.toString() ?? 'delivered';

    if (content.isEmpty &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (fileUrl == null || fileUrl.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isSelected =
        _selectedMessageKeys.contains(_generateMessageKey(message));
    final bool isDeleted = message['is_deleted'] == true ||
        message['isDeleted'] == true ||
        message['messageStatus'] == 'deleted' ||
        message['content'] == '🚫 This message was deleted';

    final bool hasReply = !isDeleted &&
            (message['repliedMessage'] is Map &&
                (message['repliedMessage']['id'] ??
                        message['repliedMessage']['message_id'] ??
                        message['repliedMessage']['messageId']) !=
                    null) ||
        (message['reply'] is Map &&
            (message['reply']['id'] ??
                    message['reply']['message_id'] ??
                    message['reply']['messageId']) !=
                null);

    final messageId = (message['message_id'] ??
                message['messageId'] ??
                message['id'] ??
                message['_id'])
            ?.toString() ??
        '';

    return message['content'].contains('Group created by')
        ? voidBox
        : (contentType == "system" &&
                (content.contains('added') || content.contains('left')))
            ? voidBox
            : Builder(
                builder: (context) {
                  // Register context for scrolling
                  if (messageId.isNotEmpty) {
                    _messageContexts[messageId] = context;
                  }

                  return SwipeToReply(
                      icon: Icons.reply,
                      iconColor: Colors.grey.shade600,
                      onReply: isDeleted
                          ? null
                          : () {
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
                            } else if (!isDeleted) {
                              _showReactionPicker(context, message);

                              // Enter selection mode
                              setState(() {
                                _isSelectionMode = true;
                              });
                              _toggleMessageSelection(message);
                            } else {
                              // If deleted, only enter selection mode
                              setState(() {
                                _isSelectionMode = true;
                              });
                              _toggleMessageSelection(message);
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Align(
                                alignment: isSentByMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                widthFactor: hasReply ? 1.0 : null,
                                child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 30),
                                        child: Container(
                                          margin: EdgeInsets.only(
                                            left: 5,
                                            right: 5,
                                            top: 0,
                                            bottom:
                                                (message['reactions'] != null &&
                                                        message['reactions']
                                                            .isNotEmpty)
                                                    ? 20
                                                    : 0,
                                          ),
                                          padding: hasReply
                                              ? EdgeInsets.only(
                                                  left: 5, bottom: 3, right: 6)
                                              : const EdgeInsets.only(
                                                  top: 8,
                                                  left: 10,
                                                  right: 6,
                                                  bottom: 8),
                                          constraints: const BoxConstraints(
                                              maxWidth: 250),
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
                                                ? Border.all(
                                                    color: Colors.blue,
                                                    width: 2)
                                                : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (!isSentByMe &&
                                                        userName.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4,
                                                                left: 7,
                                                                right: 6,
                                                                top: 0),
                                                        child: Text(
                                                          userName,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: ColorUtil
                                                                .getColorFromAlphabet(
                                                                    userName),
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),

                                                    if (isForwarded == true)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4.0,
                                                                left: 7,
                                                                right: 6),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Image.asset(
                                                              "assets/images/forward.png",
                                                              height: 14,
                                                              width: 14,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              "Forwarded",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                    // REPLY PREVIEW - opacity trick for measurement
                                                    if (hasReply)
                                                      Opacity(
                                                        opacity: 0,
                                                        child:
                                                            GroupRepliedMessagePreview(
                                                          key: ValueKey(
                                                              '${messageId}_${message['replyContent']}_placeholder'),
                                                          replied: (message[
                                                                          'repliedMessage'] ??
                                                                      message[
                                                                          'reply'])
                                                                  is Map
                                                              ? Map<String,
                                                                  dynamic>.from(message[
                                                                      'repliedMessage'] ??
                                                                  message[
                                                                      'reply'])
                                                              : <String,
                                                                  dynamic>{},
                                                          receiver: message[
                                                                      'receiver']
                                                                  is Map
                                                              ? Map<String,
                                                                      dynamic>.from(
                                                                  message[
                                                                      'receiver'])
                                                              : {},
                                                          isSender: isSentByMe,
                                                          onTap: null,
                                                        ),
                                                      ),

                                                    // Main content with proper padding when reply exists
                                                    Padding(
                                                      padding: hasReply
                                                          ? const EdgeInsets
                                                              .only(
                                                              left: 7,
                                                              right: 0,
                                                              bottom: 0,
                                                              top: 0)
                                                          : EdgeInsets.zero,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (imageUrl !=
                                                                  null &&
                                                              imageUrl
                                                                  .isNotEmpty &&
                                                              (isImage ||
                                                                  imageUrl !=
                                                                      fileUrl))
                                                            content ==
                                                                    "Message Deleted"
                                                                ? const SizedBox
                                                                    .shrink()
                                                                : Stack(
                                                                    clipBehavior:
                                                                        Clip.none,
                                                                    children: [
                                                                      GestureDetector(
                                                                        onTap: () => _showFullImage(
                                                                            context,
                                                                            imageUrl),
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                          child: imageUrl.startsWith('https') || imageUrl.startsWith('http')
                                                                              ? CachedNetworkImage(
                                                                                  imageUrl: imageUrl,
                                                                                  width: 240,
                                                                                  height: 300,
                                                                                  fit: BoxFit.cover,
                                                                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                                                                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                                                                                )
                                                                              : Image.file(File(imageUrl), width: 240, height: 240, fit: BoxFit.cover),
                                                                        ),
                                                                      ),
                                                                      Positioned(
                                                                        top: 0,
                                                                        bottom:
                                                                            0,
                                                                        left: isSentByMe
                                                                            ? -60
                                                                            : null,
                                                                        right: isSentByMe
                                                                            ? null
                                                                            : -60,
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            child:
                                                                                InkWell(
                                                                              borderRadius: BorderRadius.circular(20),
                                                                              onTap: () {
                                                                                MyRouter.pushReplace(
                                                                                  screen: ForwardMessageScreen(
                                                                                    messages: [
                                                                                      normalizeMessage(message)
                                                                                    ],
                                                                                    currentUserId: currentUserId,
                                                                                    conversionalid: widget.conversationId,
                                                                                    username: widget.groupName,
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
                                                                      if (content
                                                                          .isEmpty)
                                                                        Positioned(
                                                                          bottom:
                                                                              5,
                                                                          right:
                                                                              4,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Colors.black.withOpacity(0.2),
                                                                                  blurRadius: 2,
                                                                                  offset: const Offset(0, 1),
                                                                                ),
                                                                              ],
                                                                              color: Colors.black45.withOpacity(0.1),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                Text(
                                                                                  TimeUtils.formatUtcToIst(message['time']),
                                                                                  style: const TextStyle(
                                                                                    fontSize: 10,
                                                                                    color: Colors.white,
                                                                                  ),
                                                                                ),
                                                                                if (isSentByMe) ...[
                                                                                  const SizedBox(width: 4),
                                                                                  Builder(builder: (context) {
                                                                                    switch (messageStatus) {
                                                                                      case 'sent':
                                                                                        return const Icon(Icons.check, size: 12, color: Colors.white);
                                                                                      case 'delivered':
                                                                                        return const Icon(Icons.done_all_rounded, size: 12, color: Colors.white);
                                                                                      case 'read':
                                                                                        return const Icon(Icons.done_all, size: 12, color: Colors.blue);
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
                                                          if (fileUrl != null &&
                                                              fileUrl
                                                                  .isNotEmpty &&
                                                              isVideo)
                                                            _buildVideoPreviewTile(
                                                              context,
                                                              fileUrl,
                                                              fileName ?? "",
                                                              isSentByMe,
                                                              message,
                                                            )
                                                          else if (fileUrl !=
                                                                  null &&
                                                              fileUrl
                                                                  .isNotEmpty &&
                                                              isAudio)
                                                            AudioMessageWidget(
                                                              audioUrl: fileUrl,
                                                              profileAvatarUrl:
                                                                  profileImageUrl,
                                                              isSender:
                                                                  isSentByMe,
                                                              duration: message[
                                                                      'duration']
                                                                  ?.toString(),
                                                              timestamp: TimeUtils
                                                                  .formatUtcToIst(
                                                                      message[
                                                                          'time']),
                                                              status:
                                                                  messageStatus,
                                                              showContainer:
                                                                  false,
                                                            )
                                                          else if (fileUrl !=
                                                                  null &&
                                                              fileUrl
                                                                  .isNotEmpty &&
                                                              !(content ==
                                                                      "Message Deleted" ||
                                                                  isImage || // Use pre-calculated isImage
                                                                  (fileType !=
                                                                          null &&
                                                                      fileType
                                                                          .toLowerCase()
                                                                          .startsWith(
                                                                              "image")) ||
                                                                  (fileName !=
                                                                          null &&
                                                                      RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$',
                                                                              caseSensitive:
                                                                                  false)
                                                                          .hasMatch(
                                                                              fileName))))
                                                            Stack(
                                                              clipBehavior:
                                                                  Clip.none,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    Container(
                                                                      width:
                                                                          300,
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              8),
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .grey[200],
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                              _getFileIcon(fileType),
                                                                              color: chatColor,
                                                                              size: 30),
                                                                          const SizedBox(
                                                                              width: 8),
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              fileName ?? 'Download file',
                                                                              style: const TextStyle(
                                                                                fontWeight: FontWeight.w500,
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          IconButton(
                                                                            icon:
                                                                                const Icon(Icons.download_rounded),
                                                                            onPressed: () =>
                                                                                _openFile(fileUrl, fileType),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    // Only show time/status for documents without caption
                                                                    if (content
                                                                        .isEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                0,
                                                                            right:
                                                                                0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            Text(
                                                                              TimeUtils.formatUtcToIst(message['time']),
                                                                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                                                                            ),
                                                                            const SizedBox(width: 4),
                                                                            if (isSentByMe)
                                                                              _buildStatusIcon(messageStatus, message),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                                Positioned(
                                                                  top: 0,
                                                                  bottom: 0,
                                                                  left:
                                                                      isSentByMe
                                                                          ? -60
                                                                          : null,
                                                                  right:
                                                                      isSentByMe
                                                                          ? null
                                                                          : -60,
                                                                  child: Center(
                                                                    child:
                                                                        Material(
                                                                      color: Colors
                                                                          .transparent,
                                                                      child:
                                                                          InkWell(
                                                                        borderRadius:
                                                                            BorderRadius.circular(20),
                                                                        onTap:
                                                                            () {
                                                                          MyRouter
                                                                              .pushReplace(
                                                                            screen:
                                                                                ForwardMessageScreen(
                                                                              messages: [
                                                                                normalizeMessage(message)
                                                                              ],
                                                                              currentUserId: currentUserId,
                                                                              conversionalid: widget.conversationId,
                                                                              username: widget.groupName,
                                                                            ),
                                                                          );
                                                                        },
                                                                        child:
                                                                            CircleAvatar(
                                                                          maxRadius:
                                                                              16,
                                                                          backgroundColor:
                                                                              Colors.white,
                                                                          child:
                                                                              Image.asset(
                                                                            "assets/images/forward.png",
                                                                            height:
                                                                                20,
                                                                            width:
                                                                                20,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          else
                                                            const SizedBox
                                                                .shrink(),
                                                          if (content
                                                              .isNotEmpty)
                                                            // Use MessageCaption for image/video/document captions to position time/status in the right corner
                                                            if ((isImage &&
                                                                    (imageUrl !=
                                                                            null &&
                                                                        imageUrl
                                                                            .isNotEmpty)) ||
                                                                (isVideo &&
                                                                    fileUrl !=
                                                                        null &&
                                                                    fileUrl
                                                                        .isNotEmpty) ||
                                                                (fileUrl !=
                                                                        null &&
                                                                    fileUrl
                                                                        .isNotEmpty &&
                                                                    !isImage &&
                                                                    !isVideo &&
                                                                    !isAudio))
                                                              MessageCaption(
                                                                content:
                                                                    content,
                                                                time: TimeUtils
                                                                    .formatUtcToIst(
                                                                        message[
                                                                            'time']),
                                                                isSentByMe:
                                                                    isSentByMe,
                                                                messageStatus:
                                                                    messageStatus,
                                                                buildStatusIcon:
                                                                    (status) =>
                                                                        _buildStatusIcon(
                                                                            status,
                                                                            message),
                                                              )
                                                            else
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 0),
                                                                child: Column(
                                                                  crossAxisAlignment: hasReply
                                                                      ? CrossAxisAlignment
                                                                          .start
                                                                      : CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    if (RegExp(
                                                                            r'((https?:\/\/)|(www\.))[^\s]+',
                                                                            caseSensitive:
                                                                                false)
                                                                        .hasMatch(
                                                                            content))
                                                                      Stack(
                                                                        clipBehavior:
                                                                            Clip.none,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 0.0),
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(12),
                                                                              child: AnyLinkPreview(
                                                                                link: (() {
                                                                                  final match = RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false).firstMatch(content);
                                                                                  if (match == null) {
                                                                                    return '';
                                                                                  }
                                                                                  String url = match.group(0)!;
                                                                                  try {
                                                                                    final uri = Uri.parse(url.startsWith('www.') ? 'https://$url' : url);
                                                                                    return uri.toString();
                                                                                  } catch (e) {
                                                                                    return url;
                                                                                  }
                                                                                })(),
                                                                                displayDirection: UIDirection.uiDirectionVertical,
                                                                                showMultimedia: true,
                                                                                backgroundColor: Colors.grey.shade100,
                                                                                bodyStyle: const TextStyle(
                                                                                  color: Colors.black87,
                                                                                  fontSize: 12,
                                                                                  fontWeight: FontWeight.w400,
                                                                                ),
                                                                                titleStyle: const TextStyle(
                                                                                  color: Colors.black,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                                cache: const Duration(hours: 1),
                                                                                borderRadius: 12,
                                                                                errorBody: 'Could not load link preview',
                                                                                errorTitle: 'Link Preview',
                                                                                errorWidget: Container(
                                                                                  height: 100,
                                                                                  color: Colors.grey[200],
                                                                                  child: const Center(child: Icon(Icons.link_off)),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Positioned(
                                                                            top:
                                                                                20,
                                                                            bottom:
                                                                                0,
                                                                            left: isSentByMe
                                                                                ? -60
                                                                                : null,
                                                                            right: isSentByMe
                                                                                ? null
                                                                                : -60,
                                                                            child:
                                                                                Center(
                                                                              child: Material(
                                                                                color: Colors.transparent,
                                                                                child: InkWell(
                                                                                  borderRadius: BorderRadius.circular(20),
                                                                                  onTap: () {
                                                                                    MyRouter.pushReplace(
                                                                                      screen: ForwardMessageScreen(
                                                                                        messages: [
                                                                                          normalizeMessage(message)
                                                                                        ],
                                                                                        currentUserId: currentUserId,
                                                                                        conversionalid: widget.conversationId,
                                                                                        username: widget.groupName,
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
                                                                      ),
                                                                    Stack(
                                                                      children: [
                                                                        StatefulBuilder(
                                                                          builder:
                                                                              (context, setState) {
                                                                            const maxCharsPerLine =
                                                                                30;
                                                                            final bool
                                                                                isTextLong =
                                                                                (content.length / maxCharsPerLine).ceil() > 10;
                                                                            bool
                                                                                isExpanded =
                                                                                (message['isExpanded'] ?? false) == true;
                                                                            return Stack(
                                                                              clipBehavior: Clip.none,
                                                                              children: [
                                                                                Padding(
                                                                                  padding: const EdgeInsets.only(bottom: 3.0, top: 1.0),
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      RichText(
                                                                                        maxLines: !isExpanded && isTextLong ? 9 : null,
                                                                                        overflow: !isExpanded && isTextLong ? TextOverflow.ellipsis : TextOverflow.visible,
                                                                                        text: TextSpan(
                                                                                          children: [
                                                                                            ..._buildMessageTextSpans(content),
                                                                                            WidgetSpan(
                                                                                              child: SizedBox(width: isSentByMe ? 75 : 60, height: 20),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                      if (!isExpanded && isTextLong)
                                                                                        GestureDetector(
                                                                                          onTap: () => setState(() => message['isExpanded'] = true),
                                                                                          child: const Padding(
                                                                                            padding: EdgeInsets.symmetric(vertical: 4),
                                                                                            child: Text(
                                                                                              "Read more",
                                                                                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      if (isExpanded)
                                                                                        GestureDetector(
                                                                                          onTap: () => setState(() => message['isExpanded'] = false),
                                                                                          child: const Padding(
                                                                                            padding: EdgeInsets.symmetric(vertical: 4),
                                                                                            child: Text(
                                                                                              "Read less",
                                                                                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      if (!isExpanded && isTextLong)
                                                                                        Align(
                                                                                          alignment: Alignment.centerRight,
                                                                                          child: Row(
                                                                                            mainAxisSize: MainAxisSize.min,
                                                                                            children: [
                                                                                              Text(
                                                                                                TimeUtils.formatUtcToIst(message['time']),
                                                                                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                                                                                              ),
                                                                                              const SizedBox(width: 4),
                                                                                              if (isSentByMe && content != "Message Deleted") _buildStatusIcon(messageStatus, message),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                    ],
                                                                                  ),
                                                                                ),

                                                                                /// ---- TIMESTAMP & STATUS (Positioned like private chat) ----
                                                                                if (!(!isExpanded && isTextLong) && !hasReply)
                                                                                  Positioned(
                                                                                    bottom: 3,
                                                                                    right: 3,
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        Text(
                                                                                          TimeUtils.formatUtcToIst(message['time']),
                                                                                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                                                                                        ),
                                                                                        const SizedBox(width: 4),
                                                                                        if (isSentByMe && content != "Message Deleted") _buildStatusIcon(messageStatus, message),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        ),
                                                                        Positioned(
                                                                          top:
                                                                              0,
                                                                          bottom:
                                                                              0,
                                                                          left: isSentByMe
                                                                              ? -60
                                                                              : null,
                                                                          right: isSentByMe
                                                                              ? null
                                                                              : -60,
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                Material(
                                                                              color: Colors.transparent,
                                                                              child: InkWell(
                                                                                borderRadius: BorderRadius.circular(20),
                                                                                onTap: () {
                                                                                  MyRouter.pushReplace(
                                                                                    screen: ForwardMessageScreen(
                                                                                      messages: [
                                                                                        normalizeMessage(message)
                                                                                      ],
                                                                                      currentUserId: currentUserId,
                                                                                      conversionalid: widget.conversationId,
                                                                                      username: widget.groupName,
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
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                        ],
                                                      ),
                                                    ),
                                                  ]),

                                              // Positioned reply preview (visible)
                                              if (hasReply)
                                                Positioned(
                                                  top: (!isSentByMe &&
                                                          userName.isNotEmpty)
                                                      ? 25
                                                      : 0,
                                                  left: 0,
                                                  right: 0,
                                                  child:
                                                      GroupRepliedMessagePreview(
                                                    key: ValueKey(
                                                        '${messageId}_${message['replyContent']}'),
                                                    replied: _mergeReplyData(
                                                        message['repliedMessage'] ??
                                                            message['reply']),
                                                    receiver: message[
                                                            'receiver'] is Map
                                                        ? Map<String,
                                                                dynamic>.from(
                                                            message['receiver'])
                                                        : {},
                                                    isSender: isSentByMe,
                                                    groupMediaLength: () {
                                                      int count = 0;
                                                      final replyData = message[
                                                              'repliedMessage'] ??
                                                          message['reply'];
                                                      if (replyData != null) {
                                                        final String?
                                                            replyGroupId =
                                                            replyData[
                                                                    'group_message_id']
                                                                ?.toString();
                                                        if (replyGroupId !=
                                                                null &&
                                                            replyGroupId
                                                                .isNotEmpty) {
                                                          count = _allMessages
                                                              .where((m) =>
                                                                  m['group_message_id']
                                                                          ?.toString() ==
                                                                      replyGroupId &&
                                                                  m['is_deleted'] !=
                                                                      true)
                                                              .length;
                                                        }
                                                        if (count == 0) {
                                                          count = ((replyData[
                                                                      'imageCount'] ??
                                                                  0) as int) +
                                                              ((replyData[
                                                                      'videoCount'] ??
                                                                  0) as int);
                                                        }
                                                      }
                                                      return count;
                                                    }(),
                                                    onTap: () async {
                                                      final replyId = ((message[
                                                                              'repliedMessage'] ??
                                                                          message[
                                                                              'reply'])?[
                                                                      'id'] ??
                                                                  (message['repliedMessage'] ??
                                                                          message[
                                                                              'reply'])?[
                                                                      'message_id'] ??
                                                                  (message['repliedMessage'] ??
                                                                          message[
                                                                              'reply'])?[
                                                                      'messageId'])
                                                              ?.toString() ??
                                                          '';
                                                      if (replyId.isNotEmpty) {
                                                        await _scrollToMessageById(
                                                            replyId,
                                                            fetchIfMissing:
                                                                true);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              // TIMESTAMP & STATUS - Positioned at Container Stack level for replied messages
                                              if (hasReply &&
                                                  content.isNotEmpty)
                                                Positioned(
                                                  bottom: 3,
                                                  right: 3,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
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
                                                            messageStatus,
                                                            message),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ]),
                              ),
                              // Avatar positioned outside the message bubble
                              if (!isSentByMe)
                                Positioned(
                                  left: -2,
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
                              // REACTIONS BAR - Positioned outside the message bubble
                              if (message['reactions'] != null &&
                                  message['reactions'].isNotEmpty)
                                Positioned(
                                  bottom: -12,
                                  left:
                                      isSentByMe ? (hasReply ? null : 312) : 40,
                                  right: isSentByMe && hasReply ? 10 : null,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 10,
                                      left: isSentByMe ? 12 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        debugPrint(
                                            '🔥 Tapped on reacted emoji!');
                                        debugPrint(
                                            '🔥 Message: ${message['message_id']}');
                                        final reactions = _extractReactions(
                                            message['reactions']);
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
                                      child: _buildReactionsBar(
                                          message, isSentByMe),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ));
                },
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
      conversionId: widget.conversationId,
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
        groupBloc: _groupBloc,
        onOptionSelected:
            () {}, // Changed from _sendMessageImage to empty callback to prevent duplicate sending. onMessageSent handles the UI/send logic.
        onMessageSent: (List<Map<String, dynamic>> messages) {
          if (messages.isEmpty) return;

          setState(() {
            for (var msg in messages) {
              _seenMessageIds.add(msg['message_id'] ?? msg['messageId'] ?? '');
              // Add to socketMessages for immediate UI update
              socketMessages.add(msg);
            }
          });

          _updateNotifier();
          _scrollToBottom();
        },
        onFilesSelected: _sendMultipleFiles,
      ),
      onCameraPressed: _openCamera,
      onRecordPressed: _isRecording ? _stopRecordingFs : _startRecordingFs,
      isRecording: _isRecording,
      replyText: _replyPreview,
      onCancelReply: _cancelReply,
      thereORleft: thereORleft,
      isGroupChat: true,
      isRecordingLocked: _isRecordingLocked,
      onLockRecording: () async {
        await _recorder.stopRecorder();
        _timer?.cancel();
        setState(() {
          _isRecordingLocked = true;
        });
      },
      onCancelRecording: () {
        _stopRecordingFs();
        setState(() {
          _isRecordingLocked = false;
          _isRecording = false;
        });
      },
      onSendRecording: (path, duration) {
        setState(() {
          _isRecordingLocked = false;
          _isRecording = false;
        });
        _sendAudioMessage(path, duration);
      },
      groupMembers: _groupMembersList,
    );
  }

  void _showReactionPicker(BuildContext context, Map<String, dynamic> message) {
    final bool isDeleted = message['is_deleted'] == true ||
        message['isDeleted'] == true ||
        message['messageStatus'] == 'deleted' ||
        message['content'] == '🚫 This message was deleted';

    if (isDeleted) return;
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

  PreferredSizeWidget _buildAppBar() {
    print(widget.conversationId);
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
      searchMatchCount: _searchMatchIds.length,
      searchMatchIndex: _currentSearchMatchIndex,
      hasLeftGroup: _hasLeftGroup,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _groupBloc,
      child: ReusableChatScaffold(
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
                    if (members.isNotEmpty) {
                      debugPrint("🔍 First member object: ${members.first}");
                      debugPrint(
                          "🔍 First member type: ${members.first.runtimeType}");
                    }
                    if (members is List) {
                      groupMembers = members.map((m) {
                        if (m is Map) {
                          return (m['member_id'] ?? m['id'] ?? m['_id'] ?? "")
                              .toString();
                        }
                        return m.toString();
                      }).toList();
                      // CRITICAL FIX: Store member IDs for later rebuild
                      _knownMemberIds = List<String>.from(groupMembers);

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
        isRecording: _isRecording,
        bloc: _groupBloc,
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
      setState(() {});
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

class MentionTextEditingController extends TextEditingController {
  List<Map<String, dynamic>> _members = [];

  void setMembers(List<Map<String, dynamic>> members) {
    _members = members;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final List<InlineSpan> children = [];
    final String content = text;

    if (content.isEmpty) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }

    final List<String> memberNames = _members
        .map((m) => m['full_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    memberNames.sort((a, b) => b.length.compareTo(a.length));

    final String escapedNames = memberNames.map(RegExp.escape).join('|');
    final String mentionPattern =
        memberNames.isEmpty ? r'(?! )' : '@($escapedNames)';
    final RegExp mentionRegExp = RegExp(mentionPattern, caseSensitive: false);

    final matches = mentionRegExp.allMatches(content);
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        children.add(TextSpan(
            text: content.substring(start, match.start), style: style));
      }

      children.add(
        TextSpan(
          text: content.substring(match.start, match.end),
          style: style?.copyWith(color: chatColor, fontWeight: FontWeight.bold),
        ),
      );

      start = match.end;
    }

    if (start < content.length) {
      children.add(TextSpan(text: content.substring(start), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}
