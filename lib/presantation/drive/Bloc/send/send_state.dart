// share_state.dart
abstract class ShareState {}

class ShareInitial extends ShareState {}

class ShareLoading extends ShareState {}

class ShareSuccess extends ShareState {}

class ShareFailure extends ShareState {
  final String message;

  ShareFailure(this.message);

  get error => null;
}
