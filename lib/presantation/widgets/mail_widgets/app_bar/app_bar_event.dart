import 'package:equatable/equatable.dart';

// appbar Events
abstract class AppBarEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchMailboxesEvent extends AppBarEvent {}
