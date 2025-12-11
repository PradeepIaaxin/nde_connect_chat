import 'package:equatable/equatable.dart';

abstract class BottomNavigationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SelectTabEvent extends BottomNavigationEvent {
  final int tabIndex;

  SelectTabEvent(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}
