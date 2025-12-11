import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'storage_event.dart';
import 'storage_state.dart';

class StorageBloc extends Bloc<StorageEvent, StorageState> {
  StorageBloc() : super(StorageInitial()) {
    on<FetchStorageData>(_onFetch);
  }

  void _onFetch(FetchStorageData event, Emitter<StorageState> emit) async {
    emit(StorageLoading());
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final res = await http.get(
        Uri.parse("https://api.nowdigitaleasy.com/drive/v1/files"),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final response = json.decode(res.body);

        // 🔍 check if data is wrapped
        final data = response['data'] ?? response;
        log(data.toString());

        final items = (data['filesize'] as List? ?? [])
            .map((e) => StorageItem(
                  size: e['size'] ?? 0,
                  order: e['order'] ?? 0,
                  type: e['type'] ?? '',
                ))
            .toList();

        final totalSize = data['totelsize']?['size'] ?? 0;

        emit(StorageLoaded(items: items, totalSize: totalSize));
      } else {
        emit(StorageError("Server error: ${res.statusCode}"));
      }
    } catch (e) {
      emit(StorageError("Failed to load storage data: $e"));
    }
  }
}
