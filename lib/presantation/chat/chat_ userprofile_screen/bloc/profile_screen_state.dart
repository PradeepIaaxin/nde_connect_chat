// presantation/chat/chat_userprofile_screen/bloc/profile_screen_state.dart

import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/contact_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/doc_links_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/online_user_model.dart';

abstract class MediaState extends Equatable {
  const MediaState();
  @override
  List<Object?> get props => [];
}

class MediaInitial extends MediaState {}

class MediaLoading extends MediaState {}

class MediaLoaded extends MediaState {
  final List<MediaItem> items;
  const MediaLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class MediaError extends MediaState {
  final String message;
  const MediaError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContactLoaded extends MediaState {
  final List<ContactModel> contacts; 
  const ContactLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

class CommonDataLoaded extends MediaState {
  final List<OnlineUserModel> commongrp;
  const CommonDataLoaded(this.commongrp);

  @override
  List<Object?> get props => [commongrp];
}

class RemoveUserSuccessState extends MediaState {}

class RemoveUserErrorState extends MediaState {
  final String error;
  const RemoveUserErrorState(this.error);

  @override
  List<Object?> get props => [error];
}