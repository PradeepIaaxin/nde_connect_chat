import 'package:equatable/equatable.dart';

abstract class FabState extends Equatable {
  const FabState();

  @override
  List<Object> get props => [];
}

class FabVisible extends FabState {
  final bool isVisible;

  const FabVisible(this.isVisible);

  @override
  List<Object> get props => [isVisible];
}

class FabHidden extends FabState {
  const FabHidden();

  @override
  List<Object> get props => [];
}
