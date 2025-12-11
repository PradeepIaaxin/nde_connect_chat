import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/contact_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/doc_links_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/online_user_model.dart';

abstract class MediaState {}

class MediaInitial extends MediaState {}

class MediaLoading extends MediaState {}

class MediaLoaded extends MediaState {
  final List<MediaItem> items;

  MediaLoaded(this.items);
}

class MediaError extends MediaState {
  final String message;

  MediaError(this.message);
}

class ContactLoaded extends MediaState {
  final List<ContactModel> contacts;

  ContactLoaded(this.contacts);
}

class CommonDataLoaded extends MediaState {
  final List<OnlineUserModel> commongrp;

  CommonDataLoaded(this.commongrp);
}

/// When a user is successfully removed from a group
class RemoveUserSuccessState extends MediaState {}

/// When removing a user fails
class RemoveUserErrorState extends MediaState {
  final String error;

  RemoveUserErrorState(this.error);

  List<Object?> get props => [error];
}

/// When admin role update (add/dismiss) is successful
class AdminRoleUpdatedState extends MediaState {}

/// When admin role update fails
class AdminRoleUpdateErrorState extends MediaState {
  final String error;

  AdminRoleUpdateErrorState(this.error);

  List<Object?> get props => [error];
}
