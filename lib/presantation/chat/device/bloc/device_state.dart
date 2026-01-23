import 'package:nde_email/presantation/chat/device/model/device_model.dart';

abstract class LinkedDeviceState {}

class LinkedDeviceInitial extends LinkedDeviceState {}

class LinkedDeviceLoading extends LinkedDeviceState {}

class LinkedDeviceLoaded extends LinkedDeviceState {
  final List<LinkedDevice> devices;
  LinkedDeviceLoaded(this.devices);
}

class LinkedDeviceError extends LinkedDeviceState {
  final String message;
  LinkedDeviceError(this.message);
}
