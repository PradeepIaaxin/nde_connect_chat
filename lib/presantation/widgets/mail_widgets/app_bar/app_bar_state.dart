import 'package:equatable/equatable.dart';
import 'mailbox_model.dart';


abstract class AppBarState extends Equatable {
  const AppBarState();

  @override
  List<Object?> get props => [];
}



// Initial Loading State
class AppBarLoading extends AppBarState {}


// Successfully Loaded State
class AppBarMailboxesLoaded extends AppBarState {
  final List<Mailbox> inbox;
  final List<Mailbox> archive;
  final List<Mailbox> drafts;
  final List<Mailbox> junk;
  final List<Mailbox> sent;
  final List<Mailbox> trash;
  final List<Mailbox> other;

  const AppBarMailboxesLoaded({
    required this.inbox,
    required this.archive,
    required this.drafts,
    required this.junk,
    required this.sent,
    required this.trash,
    required this.other,
  });



  @override
  List<Object?> get props => [inbox, archive, drafts, junk, sent, trash, other];
}



class AppBarError extends AppBarState {
  final String message;
  const AppBarError(this.message);

  @override
  List<Object?> get props => [message];
}



class AppBarNetworkError extends AppBarState {
  const AppBarNetworkError() : super();

  @override
  List<Object?> get props => [];
}

class AppBarUnauthorized extends AppBarState {
  const AppBarUnauthorized() : super();

  @override
  List<Object?> get props => [];
}
