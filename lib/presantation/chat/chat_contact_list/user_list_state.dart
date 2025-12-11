import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';

abstract class UserListState {}

class UserListInitial extends UserListState {}

class UserListLoading extends UserListState {}

class UserListLoaded extends UserListState {
  final UserListResponse userListResponse;

  UserListLoaded({required this.userListResponse});
}

class UserListError extends UserListState {
  final String message;

  UserListError({required this.message});
}
