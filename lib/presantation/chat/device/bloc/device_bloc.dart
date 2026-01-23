import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/device/api/device_api.dart';
import 'package:nde_email/presantation/chat/device/bloc/device_event.dart';
import 'package:nde_email/presantation/chat/device/bloc/device_state.dart';

class LinkedDeviceBloc extends Bloc<LinkedDeviceEvent, LinkedDeviceState> {
  final FetchLinkedDeviceApi api;

  LinkedDeviceBloc(this.api) : super(LinkedDeviceInitial()) {
    on<LoadLinkedDevices>((event, emit) async {
      emit(LinkedDeviceLoading());

      try {
        final devices = await api.fetchLinkedDevices();
        emit(LinkedDeviceLoaded(devices.devices));
      } catch (e) {
        emit(LinkedDeviceError(e.toString()));
      }
    });
  }
}
