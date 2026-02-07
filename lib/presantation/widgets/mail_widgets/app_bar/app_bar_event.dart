import 'package:equatable/equatable.dart';

// appbar Events
abstract class AppBarEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchMailboxesEvent extends AppBarEvent {
  final bool force;
   FetchMailboxesEvent({this.force = false});

  @override
  List<Object> get props => [force];
}

class ClearMailboxesEvent extends AppBarEvent {}
