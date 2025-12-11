import 'package:equatable/equatable.dart';

abstract class FabEvent extends Equatable {
  const FabEvent();

  @override
  List<Object> get props => [];
}

class ShowFab extends FabEvent {}  

class HideFab extends FabEvent {}
