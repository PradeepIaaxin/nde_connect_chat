import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/compose/api_service.dart';
import 'fatchname_event.dart';
import 'fatchname_state.dart';

class FatchnameBloc extends Bloc<FatchnameEvent, FatchnameState> {
  final ApiService apiService;

  FatchnameBloc({required this.apiService}) : super(FatchnameInitial()) {
    on<FetchSenderEmailEvent>(_fetchSenderEmail);
  }

  Future<void> _fetchSenderEmail(FetchSenderEmailEvent event, Emitter<FatchnameState> emit) async {
    emit(FatchnameLoading());
    try {
      final email = await apiService.getSenderEmail();
      emit(FatchnameEmailLoaded(email));  
    } catch (e) {
      emit(FatchnameError("Failed to fetch email")); 
    }
  }
}
