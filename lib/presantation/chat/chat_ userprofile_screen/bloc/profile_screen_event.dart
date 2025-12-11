abstract class MediaEvent {}

class FetchMedia extends MediaEvent {
  final String userId;
  final String type;

  FetchMedia({required this.userId, required this.type});
}

class FetchContact extends MediaEvent {
  final String grpId;

  FetchContact({required this.grpId});
}

class FetchgrpOrNot extends MediaEvent {
  final String recvId;

  FetchgrpOrNot({required this.recvId});
}

class RemoveUserFromGroupEvent extends MediaEvent {
  final String groupId;
  final String userId;

  RemoveUserFromGroupEvent({required this.groupId, required this.userId});

  List<Object?> get props => [groupId, userId];
}

class ExitGroup extends MediaEvent {
  final String grpId;

  ExitGroup({required this.grpId});
}

class MakeAdmin extends MediaEvent {
  final String groupId;
  final List<Map<String, dynamic>> updates;

  MakeAdmin({required this.groupId, required this.updates});

  List<Object?> get props => [groupId, updates];
}

class ToggleFavourite extends MediaEvent {
  final String targetId;
  final bool isFavourite;
  final bool grp;

  ToggleFavourite(
      {required this.targetId, required this.isFavourite, this.grp = false});

  List<Object?> get props => [targetId, isFavourite, grp];
}
