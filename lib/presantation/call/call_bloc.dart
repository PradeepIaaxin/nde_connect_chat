import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/call/call_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc() : super(CallInitial()) {
    on<FetchCallHistoryEvent>(_onFetchCallHistory);
  }

  Future<void> _onFetchCallHistory(
      FetchCallHistoryEvent event, Emitter<CallState> emit) async {
    emit(CallLoading());

    try {
      final prefs = await SharedPreferences.getInstance();

      // Fetch new data
      final freshList = await fetchCallHistory();

      // Sort by most recent (latest on top)
      freshList.sort((a, b) => DateTime.parse(b.callingTime)
          .compareTo(DateTime.parse(a.callingTime)));

      // Save sorted data to cache
      await prefs.setString(
        'callHistory',
        jsonEncode(freshList.map((e) => e.toJson()).toList()),
      );

      emit(CallLoaded(freshList));
    } catch (e) {
      emit(CallError('Failed to load call history'));
    }
  }
}
