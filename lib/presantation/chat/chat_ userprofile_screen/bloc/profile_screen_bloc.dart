import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_event.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_state.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/data/view_deatilsrepo.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final MediaRepository repository;

  MediaBloc(this.repository) : super(MediaInitial()) {
    on<FetchMedia>(_onFetchMedia);
    on<FetchContact>(_onFetchContact);
    on<FetchgrpOrNot>(_onfetchCommonPeople);
    on<RemoveUserFromGroupEvent>(_onRemoveUser);
    on<ExitGroup>(_onExitgrp);
    on<MakeAdmin>(_onMakeAdmin);
    on<ToggleFavourite>(_onToggleFavourite);
  }

  Future<void> _onFetchMedia(FetchMedia event, Emitter<MediaState> emit) async {
    emit(MediaLoading());
    try {
      final items = await repository.fetchItems(event.userId, event.type);
      emit(MediaLoaded(items));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _onFetchContact(
      FetchContact event, Emitter<MediaState> emit) async {
    emit(MediaLoading());
    try {
      final contacts = await repository.fetchContact(event.grpId);
      emit(ContactLoaded([contacts]));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _onfetchCommonPeople(
      FetchgrpOrNot event, Emitter<MediaState> emit) async {
    try {
      final contacts = await repository.fetchCommongrp(event.recvId);

      emit(CommonDataLoaded([contacts]));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _onExitgrp(ExitGroup event, Emitter<MediaState> emit) async {
    try {
      await repository.exitGroup(event.grpId);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _onRemoveUser(
    RemoveUserFromGroupEvent event,
    Emitter<MediaState> emit,
  ) async {
    try {
      final success = await MediaRepository.removeUserFromGroup(
        groupId: event.groupId,
        userId: event.userId,
      );

      if (success) {
        final contacts = await repository.fetchContact(event.groupId);
        emit(ContactLoaded([contacts]));
      } else {
        emit(RemoveUserErrorState("Failed to remove user from group."));
      }
    } catch (e) {
      emit(RemoveUserErrorState("Error removing user: ${e.toString()}"));
    }
  }

  Future<void> _onMakeAdmin(
    MakeAdmin event,
    Emitter<MediaState> emit,
  ) async {
    try {
      await repository.updateAdmins(
        groupId: event.groupId,
        updates: event.updates,
      );

      final contacts = await repository.fetchContact(event.groupId);

      emit(ContactLoaded([contacts]));
    } catch (e, stacktrace) {
      log('❌ Error in _onMakeAdmin: $e\n📍$stacktrace');
    }
  }

  Future<void> _onToggleFavourite(
    ToggleFavourite event,
    Emitter<MediaState> emit,
  ) async {
    try {
      await repository.updateFavourite(
        targetId: event.targetId,
        isFavourite: event.isFavourite,
      );

      if (event.grp == true) {
        final contacts = await repository.fetchContact(event.targetId);
        emit(ContactLoaded([contacts]));
      } else {
        final contacts = await repository.fetchCommongrp(event.targetId);

        emit(CommonDataLoaded([contacts]));
      }
    } catch (e, stacktrace) {
      log("❌ Error in _onToggleFavourite: $e\n📍$stacktrace");
    }
  }
}
