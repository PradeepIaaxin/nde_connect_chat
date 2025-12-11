import 'package:equatable/equatable.dart';
import 'mail_detail_model.dart';



abstract class MailDetailState extends Equatable {
  @override
  List<Object> get props => [];
}

class MailDetailInitial extends MailDetailState {}

class MailDetailLoading extends MailDetailState {}

class MailDetailLoaded extends MailDetailState {
  final MailDetailModel mailDetail;
  MailDetailLoaded(this.mailDetail);

  @override
  List<Object> get props => [mailDetail];
}


class MailDetailError extends MailDetailState {
  final String message;
  MailDetailError(this.message);

  @override
  List<Object> get props => [message];
}
