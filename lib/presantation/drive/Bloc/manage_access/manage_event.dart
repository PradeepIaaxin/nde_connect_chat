// manage_access_event.dart
abstract class ManageAccessEvent {}

class FetchShareDetailsEvent extends ManageAccessEvent {
  final String fileId;

  FetchShareDetailsEvent(this.fileId);
}