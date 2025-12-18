import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/login/login_screen.dart';
import 'package:nde_email/rust/api.dart/api.dart';
import 'package:nde_email/utils/router/router.dart';
import 'chat_response_model.dart';

class ChatListApiService {
  final String baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/chats';
  List<Datu> _lastData = [];
  final StreamController<List<Datu>> _chatStreamController =
      StreamController<List<Datu>>.broadcast();
  Timer? _chatRefreshTimer;
  Timer? _tokenRefreshTimer;

  Stream<List<Datu>> getChatStream({required int page, required int limit}) {
    // Initial fetch
    _fetchAndEmitChats(page, limit);

    // Cancel any existing timers
    _chatRefreshTimer?.cancel();
    _tokenRefreshTimer?.cancel();

    // Chat refresh every 5 seconds
    _chatRefreshTimer =
        Timer.periodic(const Duration(minutes: 230), (timer) async {
      try {
        final chats = await fetchChats(page: page, limit: limit);
        if (!_areListsEqual(chats, _lastData)) {
          _lastData = chats;
          _chatStreamController.add(chats);
        }
      } catch (e) {
        // If 401, stop the timer and try refreshing token
        if (e.toString().contains('Authentication failed')) {
          final refreshed = await _onRefreshToken();
          if (refreshed) {
            // Retry fetching chats after token refresh
            try {
              final chats = await fetchChats(page: page, limit: limit);
              _lastData = chats;
              _chatStreamController.add(chats);
            } catch (e) {
              _chatStreamController.addError(e);
            }
          } else {
            // Token refresh failed → stop timers & logout
            _chatRefreshTimer?.cancel();
            _tokenRefreshTimer?.cancel();
            _chatStreamController.addError(Exception('Token refresh failed'));
            MyRouter.pushRemoveUntil(screen: LoginScreen());
          }
        } else {
          _chatStreamController.addError(e);
        }
      }
    });

    return _chatStreamController.stream;
  }

  Future<void> _fetchAndEmitChats(int page, int limit) async {
    try {
      final chats = await fetchChats(page: page, limit: limit);
      _lastData = chats;
      _chatStreamController.add(chats);
    } catch (e) {
      _chatStreamController.addError(e);
    }
  }

  Future<List<Datu>> decodeChatsFromLoro(String snapshotBase64) async {
    final jsonString = await decodeChatSnapshot(snapshotBase64: snapshotBase64);

    final decoded = jsonDecode(jsonString);

    final List data = decoded["chatDataList"] ?? [];

    return data.map((e) => Datu.fromJson(e)).toList();
  }

  Future<bool> _onRefreshToken() async {
    try {
      log("🔄 Refreshing token");
      final refreshToken = await UserPreferences.getrefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse("https://api.nowdigitaleasy.com/auth/v1/auth/refresh-token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await UserPreferences.updateTokens(
            data['accessToken'], data['refreshToken']);
        log("Tokens refreshed successfully");
        return true;
      }
      return false;
    } catch (e) {
      log("Refresh error: $e");
      return false;
    }
  }

  bool _areListsEqual(List<Datu> a, List<Datu> b) {
    if (a.length != b.length) return false;
    final Map<String, Datu> aMap = {for (var item in a) item.id ?? '': item};
    final Map<String, Datu> bMap = {for (var item in b) item.id ?? '': item};
    for (final key in aMap.keys) {
      final aItem = aMap[key];
      final bItem = bMap[key];
      if (bItem == null) return false;
      if (aItem?.lastMessage != bItem.lastMessage ||
          aItem?.lastMessageTime?.millisecondsSinceEpoch !=
              bItem.lastMessageTime?.millisecondsSinceEpoch ||
          aItem?.unreadCount != bItem.unreadCount ||
          aItem?.isPinned != bItem.isPinned ||
          aItem?.isArchived != bItem.isArchived ||
          aItem?.groupName != bItem.groupName ||
          aItem?.name != bItem.name) return false;
    }
    return true;
  }

  Future<List<Datu>> fetchChats({
    required int page,
    required int limit,
    String? filter,
  }) async {
    final accessToken = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || workspace == null) {
      throw Exception("User authentication missing");
    }

    Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (filter != null && filter.isNotEmpty && filter.toLowerCase() != "all") {
      queryParams['filter'] = filter.toLowerCase();
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print("Fetching chats → $uri");

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': workspace,
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // NEW: Check for Loro snapshot
      if (jsonData["snapshot"] != null) {
        final snapshotBase64 = jsonData["snapshot"];
        log("📥 Received Loro Snapshot. Decoding using Rust...");

        final chats = await decodeChatsFromLoro(snapshotBase64);
        ChatSessionStorage.clear();
        ChatSessionStorage.saveChatList(chats);

        return chats;
      }

      // BACKUP: If normal JSON array is sent instead of snapshot
      final List<dynamic> chatJson = jsonData["data"] ?? [];
      final chats = chatJson.map((e) => Datu.fromJson(e)).toList();

      return chats;
    } else if (response.statusCode == 401) {
      final refreshed = await _onRefreshToken();
      if (refreshed) {
        return fetchChats(page: page, limit: limit, filter: filter);
      }
      throw Exception("Authentication failed");
    } else {
      throw Exception("Failed to fetch chats");
    }
  }

  void dispose() {
    _chatRefreshTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    _chatStreamController.close();
  }
}
