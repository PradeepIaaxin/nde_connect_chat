import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'dart:developer';

class ChatSessionStorage {
  static List<Datu> chatList = [];

  static Set<String> processedMessageIds = {};

  static Map<String, dynamic> _paginationData = {};

  static void saveChatList(List<Datu> newChats) {
    chatList = newChats
        .map((chatReq) => Datu(
              id: chatReq.id,
              name: chatReq.name,
              firstName: chatReq.firstName,
              reciverId: chatReq.reciverId,
              lastName: chatReq.lastName,
              profilePic: chatReq.profilePic,
              lastMessage: chatReq.lastMessage,
              conversationId: chatReq.conversationId,
              isPinned: chatReq.isPinned,
              unreadCount: chatReq.unreadCount,
              isGroupChat: chatReq.isGroupChat,
              datumId: chatReq.datumId,
              lastMessageId: chatReq.lastMessageId,
              lastMessageSender: chatReq.lastMessageSender,
              lastMessageTime: chatReq.lastMessageTime,
              fileName: chatReq.fileName,
              mimeType: chatReq.mimeType,
              contentType: chatReq.contentType,
              isArchived: chatReq.isArchived,
              groupName: chatReq.groupName,
              draftMessage: chatReq.draftMessage,
            ))
        .toList();
  }

  static List<Datu> getChatList() {
    return chatList;
  }

  static void savePagination(Map<String, dynamic> pagination) {
    _paginationData = pagination;
    log("Pagination saved: nextPage = ${pagination['nextPage']}");
  }

  static int? getNextPage() => _paginationData['nextPage'] as int?;
  static bool get hasMore => _paginationData['nextPage'] != null;

  /// 🚀 Update chat item with message-based dedupe
  static void updateChat({
    required String convoId,
    required String? messageId,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? contentType,
    int unreadIncrement = 0,
    String? name,
    String? profilePic,
  }) {
    /// ⛔ Skip if no messageId
    if (messageId != null) {
      if (processedMessageIds.contains(messageId)) {
        // Duplicate event → ignore silently
        return;
      }

      // Save ID so it won't be processed again
      processedMessageIds.add(messageId);
    }

    for (var chat in chatList) {
      if (chat.conversationId == convoId || chat.id == convoId) {
        chat.lastMessage = lastMessage ?? chat.lastMessage;
        chat.lastMessageTime = lastMessageTime ?? chat.lastMessageTime;
        chat.contentType = contentType ?? chat.contentType;

        chat.name = name ?? chat.name;
        chat.firstName = name?.split(" ").first ?? chat.firstName;
        chat.lastName = name?.split(" ").skip(1).join(" ") ?? chat.lastName;
        chat.profilePic = profilePic ?? chat.profilePic;

        if (unreadIncrement > 0) {
          chat.unreadCount = (chat.unreadCount ?? 0) + unreadIncrement;
        }

        return;
      }
    }

    log("❌ Chat NOT FOUND for convoId: $convoId");
  }

  static void updateDraftMessage({
    required String convoId,
    String? draftMessage,
  }) {
    for (int i = 0; i < chatList.length; i++) {
      if (chatList[i].conversationId == convoId || chatList[i].id == convoId) {
        chatList[i].draftMessage = draftMessage;
        return;
      }
    }

    log("❌ Chat NOT FOUND for draft update: $convoId");
  }

  static void clear() {
    chatList.clear();
    processedMessageIds.clear();
    log("chat cleared");
  }
}
