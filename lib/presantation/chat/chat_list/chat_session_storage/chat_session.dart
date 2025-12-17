
import 'dart:developer';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';

class ChatSessionStorage {
  /// 🔑 Single source of truth
  /// key = conversationId (preferred) OR id
  static final Map<String, Datu> _chatMap = {};

  /// Prevent duplicate socket message updates
  static final Set<String> processedMessageIds = {};

  static Map<String, dynamic> _paginationData = {};

  // ===============================
  // GETTERS
  // ===============================

  static List<Datu> getChatList() => _chatMap.values.toList();

  static bool get isEmpty => _chatMap.isEmpty;

  // ===============================
  // UPSERT (Hive / API / Loro / Socket)
  // ===============================

  static void upsertChats(List<Datu> incomingChats) {
    for (final chat in incomingChats) {
      final key = chat.conversationId ?? chat.id;
      if (key == null || key.isEmpty) continue;

      final normalized = _normalize(chat);
      final existing = _chatMap[key];

      _chatMap[key] = _merge(existing, normalized);
    }

    log("✅ ChatSessionStorage size: ${_chatMap.length}");
  }

  // ===============================
  // NORMALIZE (CRITICAL)
  // ===============================

  /// Ensures group name is ALWAYS correct
  static Datu _normalize(Datu chat) {
    if (chat.isGroupChat == true) {
      final correctGroupName =
          (chat.groupName != null && chat.groupName!.isNotEmpty)
              ? chat.groupName
              : chat.name;

      return chat.copyWith(
        groupName: correctGroupName,
        name: correctGroupName, // 🔥 force consistency
        firstName: null,
        lastName: null,
      );
    }

    // Private chat
    return chat;
  }

  // ===============================
  // MERGE LOGIC
  // ===============================

  static Datu _merge(Datu? old, Datu incoming) {
    if (old == null) return incoming;

    // --- GROUP CHAT ---
    if (incoming.isGroupChat == true || old.isGroupChat == true) {
      final groupName =
          (incoming.groupName != null && incoming.groupName!.isNotEmpty)
              ? incoming.groupName
              : old.groupName;

      return old.copyWith(
        // identity
        id: incoming.id ?? old.id,
        conversationId: incoming.conversationId ?? old.conversationId,
        datumId: incoming.datumId ?? old.datumId,

        // group rules
        isGroupChat: true,
        groupName: groupName,
        name: groupName,

        // media
        profilePic: incoming.profilePic ?? old.profilePic,

        // last message
        lastMessage: incoming.lastMessage ?? old.lastMessage,
        lastMessageId: incoming.lastMessageId ?? old.lastMessageId,
        lastMessageSender: incoming.lastMessageSender ?? old.lastMessageSender,
        lastMessageTime: incoming.lastMessageTime ?? old.lastMessageTime,

        // state
        unreadCount: incoming.unreadCount ?? old.unreadCount,
        isPinned: incoming.isPinned ?? old.isPinned,
        isArchived: incoming.isArchived ?? old.isArchived,
        isFavorites: incoming.isFavorites ?? old.isFavorites,

        // files
        mimeType: incoming.mimeType ?? old.mimeType,
        contentType: incoming.contentType ?? old.contentType,
        fileName: incoming.fileName ?? old.fileName,

        // draft
        draftMessage: incoming.draftMessage ?? old.draftMessage,

        // participants
        participants: incoming.participants?.isNotEmpty == true
            ? incoming.participants
            : old.participants,
        onlineParticipants: incoming.onlineParticipants?.isNotEmpty == true
            ? incoming.onlineParticipants
            : old.onlineParticipants,
      );
    }

    // --- PRIVATE CHAT ---
    return old.copyWith(
      id: incoming.id ?? old.id,
      conversationId: incoming.conversationId ?? old.conversationId,
      datumId: incoming.datumId ?? old.datumId,
      firstName: incoming.firstName ?? old.firstName,
      lastName: incoming.lastName ?? old.lastName,
      name: incoming.name ?? old.name,
      profilePic: incoming.profilePic ?? old.profilePic,
      lastMessage: incoming.lastMessage ?? old.lastMessage,
      lastMessageId: incoming.lastMessageId ?? old.lastMessageId,
      lastMessageSender: incoming.lastMessageSender ?? old.lastMessageSender,
      lastMessageTime: incoming.lastMessageTime ?? old.lastMessageTime,
      unreadCount: incoming.unreadCount ?? old.unreadCount,
      isPinned: incoming.isPinned ?? old.isPinned,
      isArchived: incoming.isArchived ?? old.isArchived,
      isFavorites: incoming.isFavorites ?? old.isFavorites,
      mimeType: incoming.mimeType ?? old.mimeType,
      contentType: incoming.contentType ?? old.contentType,
      fileName: incoming.fileName ?? old.fileName,
      draftMessage: incoming.draftMessage ?? old.draftMessage,
    );
  }

  // ===============================
  // SOCKET MESSAGE UPDATE
  // ===============================

  static void updateChat({
    required String convoId,
    required String? messageId,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? contentType,
    int unreadIncrement = 0,
  }) {
    if (messageId != null && processedMessageIds.contains(messageId)) {
      return;
    }

    if (messageId != null) {
      processedMessageIds.add(messageId);
    }

    final chat = _chatMap[convoId];
    if (chat == null) {
      log("❌ Chat NOT FOUND for convoId: $convoId");
      return;
    }

    chat.lastMessage = lastMessage ?? chat.lastMessage;
    chat.lastMessageTime = lastMessageTime ?? chat.lastMessageTime;
    chat.contentType = contentType ?? chat.contentType;

    if (unreadIncrement > 0) {
      chat.unreadCount = (chat.unreadCount ?? 0) + unreadIncrement;
    }
  }

  // ===============================
  // DRAFT UPDATE
  // ===============================

  static void updateDraftMessage({
    required String convoId,
    String? draftMessage,
  }) {
    final chat = _chatMap[convoId];
    if (chat == null) {
      log("❌ Chat NOT FOUND for draft update: $convoId");
      return;
    }

    chat.draftMessage = draftMessage;
  }

  // ===============================
  // PAGINATION
  // ===============================

  static void savePagination(Map<String, dynamic> pagination) {
    _paginationData = pagination;
  }

  static int? getNextPage() => _paginationData['nextPage'] as int?;
  static bool get hasMore => _paginationData['nextPage'] != null;

  // ===============================
  // CLEAR (LOGOUT / DB DELETE)
  // ===============================

  static void clear() {
    _chatMap.clear();
    processedMessageIds.clear();
    _paginationData.clear();
    log("🧹 ChatSessionStorage cleared");
  }
}
