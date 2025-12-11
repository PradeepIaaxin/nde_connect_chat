import 'package:flutter_bloc/flutter_bloc.dart';
import 'bottom_nav_event.dart';
import 'bottom_nav_state.dart';


class BottomNavigationBloc extends Bloc<BottomNavigationEvent, BottomNavigationState> {
  BottomNavigationBloc() : super(const BottomNavigationState(selectedIndex: 0)) {
    on<SelectTabEvent>((event, emit) {
      emit(BottomNavigationState(selectedIndex: event.tabIndex));
    });
  }
}
