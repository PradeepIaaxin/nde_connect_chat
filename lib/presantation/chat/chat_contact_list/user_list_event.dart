abstract class UserListEvent {}

class FetchUserList extends UserListEvent {
  final int page;
  final int limit;
  final bool isRefresh;

  FetchUserList({
    required this.page,
    required this.limit,
    this.isRefresh = false,
  });
}
