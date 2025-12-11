import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/update_screen/update_bloc/update_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

import '../update_repo/update_repo.dart';


class AppUpdateCubit extends Cubit<AppUpdateState> {
  final AppUpdateRepository repository;

  AppUpdateCubit(this.repository) : super(AppUpdateInitial());

  Future<void> checkForUpdate(String appName) async {
    emit(AppUpdateLoading());

    try {
      final appDetails = await repository.fetchAppDetails(appName);
      if (appDetails == null) {
        emit(AppUpdateError("No app details found"));
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;
    print("appversion ${appDetails.appVersion}");
      emit(AppUpdateAvailable(appDetails));

    } catch (e, st) {
      emit(AppUpdateError(e.toString()));
      print("❌ App update check failed: $e\n$st");
    }
  }
}
