import 'dart:developer' as developer;
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
    on<UpdateGroupNameLocally>(_onUpdateGroupNameLocally);
    on<UpdateGroupLocally>(_onUpdateGroupLocally);
  }

  // === Existing handlers (unchanged) ===
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
      final contact = await repository.fetchContact(event.grpId);
      emit(ContactLoaded([contact]));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _onfetchCommonPeople(
      FetchgrpOrNot event, Emitter<MediaState> emit) async {
    try {
      final data = await repository.fetchCommongrp(event.recvId);
      emit(CommonDataLoaded([data]));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _onExitgrp(ExitGroup event, Emitter<MediaState> emit) async {
    try {
      await repository.exitGroup(event.grpId);
    } catch (e) {
      developer.log('Exit group failed: $e');
    }
  }

  Future<void> _onRemoveUser(
      RemoveUserFromGroupEvent event, Emitter<MediaState> emit) async {
    try {
      final success = await MediaRepository.removeUserFromGroup(
        groupId: event.groupId,
        userId: event.userId,
      );

      if (success) {
        final contact = await repository.fetchContact(event.groupId);
        emit(ContactLoaded([contact]));
      } else {
        emit(const RemoveUserErrorState("Failed to remove user"));
      }
    } catch (e) {
      emit(RemoveUserErrorState(e.toString()));
    }
  }

  Future<void> _onMakeAdmin(MakeAdmin event, Emitter<MediaState> emit) async {
    try {
      await repository.updateAdmins(
          groupId: event.groupId, updates: event.updates);
      final contact = await repository.fetchContact(event.groupId);
      emit(ContactLoaded([contact]));
    } catch (e) {
      developer.log('Make admin error: $e');
    }
  }

  Future<void> _onToggleFavourite(
      ToggleFavourite event, Emitter<MediaState> emit) async {
    try {
      await repository.updateFavourite(
        targetId: event.targetId,
        isFavourite: event.isFavourite,
      );

      if (event.grp) {
        final contact = await repository.fetchContact(event.targetId);
        emit(ContactLoaded([contact]));
      } else {
        final data = await repository.fetchCommongrp(event.targetId);
        emit(CommonDataLoaded([data]));
      }
    } catch (e) {
      developer.log('Toggle favourite error: $e');
    }
  }

  // === OLD: Only updates group name ===
  Future<void> _onUpdateGroupNameLocally(
    UpdateGroupNameLocally event,
    Emitter<MediaState> emit,
  ) async {
    final groupId = event.groupId;
    final newName = event.newName;

    if (state is ContactLoaded) {
      final currentList = (state as ContactLoaded).contacts;
      final updatedList = currentList.map((contact) {
        if (contact.id == groupId) {
          return contact.copyWith(groupName: newName);
        }
        return contact;
      }).toList();
      emit(ContactLoaded(updatedList));
    }

    if (state is CommonDataLoaded) {
      final currentList = (state as CommonDataLoaded).commongrp;
      final updatedOnlineUsers = currentList.map((onlineUser) {
        final updatedSharedGroups = onlineUser.sharedGroups.map((sharedGroup) {
          if (sharedGroup.id == groupId) {
            return sharedGroup.copyWith(groupName: newName);
          }
          return sharedGroup;
        }).toList();
        return onlineUser.copyWith(sharedGroups: updatedSharedGroups);
      }).toList();
      emit(CommonDataLoaded(updatedOnlineUsers));
    }

    _scheduleRefresh(groupId);
  }

  // === NEW: Unified handler for both name AND description ===
  Future<void> _onUpdateGroupLocally(
    UpdateGroupLocally event,
    Emitter<MediaState> emit,
  ) async {
    final groupId = event.groupId;

    if (state is ContactLoaded) {
      final currentList = (state as ContactLoaded).contacts;

      final updatedList = currentList.map((contact) {
        if (contact.id == groupId) {
          return contact.copyWith(
            groupName: event.newName ?? contact.groupName,
            description: event.newDescription ?? contact.description,
            groupAvatar: event.newAvatar ?? contact.groupAvatar, 
          );
        }
        return contact;
      }).toList();

      emit(ContactLoaded(updatedList));
    }

    _scheduleRefresh(groupId);
  }

  // Helper to avoid duplicate refresh code
  void _scheduleRefresh(String groupId) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (groupId.isNotEmpty) {
        add(FetchContact(grpId: groupId));
      }
    });
  }
}
