import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/UserService.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart'
    show FetchUserList, UserListEvent;
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final UserService userService;

  UserListBloc({required this.userService}) : super(UserListInitial()) {
    on<FetchUserList>(_onFetchUserList);
  }

  Future<void> _onFetchUserList(
    FetchUserList event,
    Emitter<UserListState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUsers = prefs.getString('userList');

      // STEP 1: Emit cached data immediately (if available)
      if (cachedUsers != null) {
        final cachedResponse =
            UserListResponse.fromJson(jsonDecode(cachedUsers));
        emit(UserListLoaded(userListResponse: cachedResponse));
      } else {
        emit(UserListLoading());
      }

      // STEP 2: Now fetch fresh data in background
      final Map<String, dynamic> response = await userService.getUserList(
        page: event.page,
        limit: event.limit,
      );

      final newUserListResponse = UserListResponse.fromJson(response);
      final newUserListJson = jsonEncode(newUserListResponse.toJson());

      if (cachedUsers == null || cachedUsers != newUserListJson) {
        // New data is different or no cache, store and emit
        prefs.setString('userList', newUserListJson);

        emit(UserListLoaded(userListResponse: newUserListResponse));
      } else {
        if (event.isRefresh) {
          Messenger.alert(msg: "No new data available");
        }
      }
    } catch (e) {
      emit(UserListError(message: 'Failed to load users: ${e.toString()}'));
    }
  }
}
