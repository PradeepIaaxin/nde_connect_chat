import 'package:nde_email/presantation/call/call_model.dart';

abstract class CallState {}

class CallInitial extends CallState {}

class CallLoading extends CallState {}

class CallLoaded extends CallState {
  final List<CallHistory> callHistory;

  CallLoaded(this.callHistory);
}

class CallError extends CallState {
  final String message;

  CallError(this.message);
}
