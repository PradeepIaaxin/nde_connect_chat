import 'package:nde_email/presantation/drive/model/recent/recent_model.dart';

abstract class RecentState {}

class StarredInitial extends RecentState {}

class StarredLoading extends RecentState {}

class StarredError extends RecentState {
  final String message;
  StarredError(this.message);
}

class StarredLoaded extends RecentState {
  final List<RecentModel> folders;
  final bool hasMore;

  StarredLoaded(this.folders, this.hasMore);
}
