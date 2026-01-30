import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';

class ChatApiService {
  static final ChatApiService _instance = ChatApiService._internal();
  factory ChatApiService() => _instance;

  Dio? dio;

  ChatApiService._internal();

  // INIT DIO
  Future<void> init() async {
    final token = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    // log("TOKEN=$token");
    // log("WORKSPACE=$workspace");

    if (token == null || workspace == null) {
      log("❌ Missing token or workspace");
      return;
    }

    dio = Dio(
      BaseOptions(
        baseUrl: "https://api.nowdigitaleasy.com",
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          "Authorization": "Bearer $token",
          "X-WorkSpace": workspace,
          "Content-Type": "application/json",
        },
      ),
    );

    log("✅ DIO Initialized");
  }

  // GENERATE ROOM ID
  String generateRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  // SEND MESSAGE
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    if (dio == null) {
      log("❌ DIO NULL — init() not called");
      return;
    }

    final roomId = generateRoomId(senderId, receiverId);
    log("ROOM ID = $roomId");

    try {
      final res = await dio!.post(
        "/wschat/v1/messages/new/$conversationId",
        data: {
          "senderId": senderId,
          "receiverId": receiverId,
          "content": content,
          "roomId": roomId, 
        },
      );

      log("✅ SUCCESS = ${res.data}");
    } on DioException catch (e) {
      log("❌ STATUS = ${e.response?.statusCode}");
      log("❌ ERROR DATA = ${e.response?.data}");
    } catch (e) {
      log("❌ ERROR = $e");
    }
  }
}
