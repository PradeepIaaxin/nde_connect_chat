import 'package:flutter_bloc/flutter_bloc.dart';
import 'floating_action_event.dart';
import 'floating_action_state.dart';

class FabBloc extends Bloc<FabEvent, FabState> {
  FabBloc() : super(const FabVisible(true)) {
    on<ShowFab>((event, emit) => emit(const FabVisible(true)));
    on<HideFab>((event, emit) => emit(FabHidden()));
  }
}
