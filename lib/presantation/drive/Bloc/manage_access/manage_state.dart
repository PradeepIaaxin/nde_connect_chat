import 'package:nde_email/presantation/drive/model/send/send_model.dart';

abstract class ManageAccessState {}

class ManageAccessInitial extends ManageAccessState {}

class ManageAccessLoading extends ManageAccessState {}

class ManageAccessLoaded extends ManageAccessState {
  final SendData shareDetails;

  ManageAccessLoaded(this.shareDetails);
}

class ManageAccessError extends ManageAccessState {
  final String message;

  ManageAccessError(this.message);
}
