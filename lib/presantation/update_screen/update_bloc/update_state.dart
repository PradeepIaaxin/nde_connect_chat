import '../update_repo/update_model.dart';




abstract class AppUpdateState {}

class AppUpdateInitial extends AppUpdateState {}

class AppUpdateLoading extends AppUpdateState {}

class AppUpdateAvailable extends AppUpdateState {
  final AppUpdateModel appDetails;
  AppUpdateAvailable(this.appDetails);
}

class AppUpdateUpToDate extends AppUpdateState {}

class AppUpdateError extends AppUpdateState {
  final String message;
  AppUpdateError(this.message);
}
