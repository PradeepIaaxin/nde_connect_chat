// presantation/chat/chat_userprofile_screen/bloc/profile_screen_event.dart

import 'package:equatable/equatable.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();
  @override
  List<Object?> get props => [];
}

class FetchMedia extends MediaEvent {
  final String userId;
  final String type;
  const FetchMedia({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}

class FetchContact extends MediaEvent {
  final String grpId;
  const FetchContact({required this.grpId});

  @override
  List<Object?> get props => [grpId];
}

class FetchgrpOrNot extends MediaEvent {
  final String recvId;
  const FetchgrpOrNot({required this.recvId});

  @override
  List<Object?> get props => [recvId];
}

// Add this inside your existing events file
class UpdateGroupLocally extends MediaEvent {
  final String groupId;
  final String? newName;
  final String? newDescription;
  final String? newAvatar; 

  const UpdateGroupLocally({
    required this.groupId,
    this.newName,
    this.newDescription,
    this.newAvatar,
  });

  @override
  List<Object?> get props =>
      [groupId, newName, newDescription, newAvatar];
}


class RemoveUserFromGroupEvent extends MediaEvent {
  final String groupId;
  final String userId;
  const RemoveUserFromGroupEvent({required this.groupId, required this.userId});

  @override
  List<Object?> get props => [groupId, userId];
}

class ExitGroup extends MediaEvent {
  final String grpId;
  const ExitGroup({required this.grpId});

  @override
  List<Object?> get props => [grpId];
}

class MakeAdmin extends MediaEvent {
  final String groupId;
  final List<Map<String, dynamic>> updates;
  const MakeAdmin({required this.groupId, required this.updates});

  @override
  List<Object?> get props => [groupId, updates];
}

class ToggleFavourite extends MediaEvent {
  final String targetId;
  final bool isFavourite;
  final bool grp;

  const ToggleFavourite({
    required this.targetId,
    required this.isFavourite,
    this.grp = false,
  });

  @override
  List<Object?> get props => [targetId, isFavourite, grp];
}

// NEW: Local instant update for group name
class UpdateGroupNameLocally extends MediaEvent {
  final String groupId;
  final String newName;

  const UpdateGroupNameLocally({
    required this.groupId,
    required this.newName,
  });

  @override
  List<Object?> get props => [groupId, newName];
}