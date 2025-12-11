import 'package:nde_email/presantation/drive/model/starred/starred_model.dart';

abstract class StarredState {}

class StarredInitial extends StarredState {}

class StarredLoading extends StarredState {}

class StarredError extends StarredState {
  final String message;
  StarredError(this.message);
}

class StarredLoaded extends StarredState {
  final List<StarredFolder> folders;
  final bool hasMore;
  final String? errorMessage;

  StarredLoaded(this.folders, this.hasMore, {this.errorMessage});

  @override
  List<Object?> get props => [folders, hasMore, errorMessage];
}
