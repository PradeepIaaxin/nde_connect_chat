// share_event.dart
abstract class ShareEvent {}

class ShareFileEvent extends ShareEvent {
  final String fileId;
  final List<String> emails;
  final String permission;
  final bool notify;
  final String message;

  ShareFileEvent({
    required this.fileId,
    required this.emails,
    required this.permission,
    required this.notify,
      required this.message,
  });
}