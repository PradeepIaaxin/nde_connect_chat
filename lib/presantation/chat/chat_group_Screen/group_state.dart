import 'package:equatable/equatable.dart';
import 'group_model.dart';

abstract class GroupChatState extends Equatable {
  const GroupChatState();

  @override
  List<Object?> get props => [];
}

class GroupChatInitial extends GroupChatState {}

class GroupChatLoading extends GroupChatState {}

class GroupChatMessageSent extends GroupChatState {}

class GroupChatMessageDeletedSuccessfully extends GroupChatState {
  final List<String> deletedMessageIds;
  const GroupChatMessageDeletedSuccessfully({required this.deletedMessageIds});
}

class PermissionState extends GroupChatState {
  final Map<String, dynamic>? response;
  
  PermissionState(this.response);
}

class GroupChatMessagesDeleted extends GroupChatState {}

class GroupChatMessagesStarred extends GroupChatState {}

class GroupChatError extends GroupChatState {
  final String message;

  const GroupChatError(this.message);

  @override
  List<Object> get props => [message];
}

class GrpMessageSentSuccessfully extends GroupChatState {
  final GrpMessage sentMessage;

  const GrpMessageSentSuccessfully(this.sentMessage);

  @override
  List<Object?> get props =>
      [sentMessage.messageId, sentMessage.message, sentMessage.time];

  @override
  String toString() =>
      'MessageSentSuccessfully(messageId: ${sentMessage.messageId})';
}

class GroupPermissionLoaded extends GroupChatState {
  final String role;
  final Map<String, dynamic> permissions;
  final String status;

  const GroupPermissionLoaded({
    required this.role,
    required this.permissions,
    required this.status,
  });
}

class GroupChatLoaded extends GroupChatState {
  final GroupMessageResponse response;

  const GroupChatLoaded(this.response);
}

class UploadInitial extends GroupChatState {}

class UploadInProgress extends GroupChatState {
  final int progress;
  const UploadInProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class UploadSuccess extends GroupChatState {
  final Map<String, dynamic> response;

  const UploadSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UploadFailure extends GroupChatState {
  final String message;

  const UploadFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupLeftState extends GroupChatState {}

class PermissionAllowedState extends GroupChatState {}

class GroupChatErrorState extends GroupChatState {
  final String message;
  const GroupChatErrorState(this.message);
}

class GroupPermissionCheckedState extends GroupChatState {
  final Map<String, dynamic> permissions;

  const GroupPermissionCheckedState(this.permissions);
}

class GroupChatLoadedWithError extends GroupChatState {
  final GroupMessageResponse response;
  final String errorMessage;
  const GroupChatLoadedWithError(this.response, this.errorMessage);
  @override
  List<Object> get props => [response, errorMessage];
}
class GroupDetailsLoaded extends GroupChatState {
  final Map<String, dynamic> groupDetails;
  const GroupDetailsLoaded(this.groupDetails);
  @override
  List<Object> get props => [groupDetails];
}