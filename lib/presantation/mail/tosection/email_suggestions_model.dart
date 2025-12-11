import 'dart:convert';

SearchResponse searchResponseFromJson(String str) => SearchResponse.fromJson(json.decode(str));

String searchResponseToJson(SearchResponse data) => json.encode(data.toJson());

class SearchResponse {
  List<User> hits;
  String query;
  int processingTimeMs;
  int limit;
  int offset;
  int estimatedTotalHits;

  SearchResponse({
    required this.hits,
    required this.query,
    required this.processingTimeMs,
    required this.limit,
    required this.offset,
    required this.estimatedTotalHits,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        hits: List<User>.from(json["hits"].map((x) => User.fromJson(x))),
        query: json["query"],
        processingTimeMs: json["processingTimeMs"],
        limit: json["limit"],
        offset: json["offset"],
        estimatedTotalHits: json["estimatedTotalHits"],
      );

  Map<String, dynamic> toJson() => {
        "hits": List<dynamic>.from(hits.map((x) => x.toJson())),
        "query": query,
        "processingTimeMs": processingTimeMs,
        "limit": limit,
        "offset": offset,
        "estimatedTotalHits": estimatedTotalHits,
      };
}

class User {
  String id;
  String userName;
  String email;
  String workspaceId;
  String userScope;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.workspaceId,
    required this.userScope,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        userName: json["user_name"],
        email: json["email"],
        workspaceId: json["workspace_id"],
        userScope: json["user_scope"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_name": userName,
        "email": email,
        "workspace_id": workspaceId,
        "user_scope": userScope,
      };
}
