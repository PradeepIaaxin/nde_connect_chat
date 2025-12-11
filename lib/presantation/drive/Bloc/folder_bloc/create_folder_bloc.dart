import 'dart:developer' show log;
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_event.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_state.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class CreateFolderBloc extends Bloc<CreateFolderEvent, CreateFolderState> {
  final Dio dio;

  bool _snackbarShown = false;
  CreateFolderBloc({Dio? dio})
      : dio = dio ?? Dio(),
        super(CreateFolderInitial()) {
    on<CreateFolderPressed>(_onCreateFolderPressed);
    on<UploadFiles>(_uploadFiles);
    on<ReplaceFiles>(_ReplaceFiles);
  }

  Future<void> _onCreateFolderPressed(
    CreateFolderPressed event,
    Emitter<CreateFolderState> emit,
  ) async {
    emit(CreateFolderLoading());

    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final body = {
        'type': 'folder',
        'name': event.name,
        if (event.parentId != null && event.parentId!.isNotEmpty)
          'parentId': event.parentId,
      };

      final response = await dio.post(
        'https://api.nowdigitaleasy.com/drive/v1/folders',
        options: Options(headers: headers),
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('📁 Folder Created: ${response.data}');
        if (!_snackbarShown) {
          Messenger.alertSuccess("Folder created successfully");
          _snackbarShown = true;
        }

        emit(CreateFolderSuccess());
      } else {
        emit(CreateFolderFailure(
            "  Failed: ${response.statusCode} ${response.statusMessage}"));
      }
    } catch (e) {
      log('🚨 Create Folder Error: $e');
      emit(CreateFolderFailure("An error occurred: ${e.toString()}"));
    }
  }

  Future<void> _uploadFiles(
    UploadFiles event,
    Emitter<CreateFolderState> emit,
  ) async {
    emit(CreateFolderLoading());

    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'multipart/form-data',
      };

      MultipartFile toMultipartFile(PlatformFile file) {
        if (file.path != null) {
          return MultipartFile.fromFileSync(file.path!, filename: file.name);
        } else if (file.bytes != null) {
          return MultipartFile.fromBytes(file.bytes!, filename: file.name);
        } else {
          throw Exception('File must have either path or bytes.');
        }
      }

      if (event.file == null) {
        throw Exception('No file provided for upload.');
      }

      final multipartFile = toMultipartFile(event.file!);

      log(event.parentId.toString());
      final formData = FormData.fromMap({
        'file': multipartFile,
        if (event.parentId != null && event.parentId!.isNotEmpty)
          'parentId': event.parentId,
      });

      final dio = Dio();

      final response = await dio.post(
        'https://api.nowdigitaleasy.com/drive/v1/files',
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            // Accept success (200-299) and conflict (409)
            return (status != null && (status >= 200 && status < 300)) ||
                status == 409;
          },
        ),
      );

      log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('File uploaded successfully: ${response.data}');
        uploadFileToS3PresignedUrl(
          presignedUrl: response.data['presignedurl'][0]['presignedUrl'],
          file: event.file!,
        );
        emit(CreateFolderSuccess());
      } else if (response.statusCode == 409) {
        log('Conflict error: File with same name exists');
        emit(CreateFolderConflict("A file with the same name already exists."));
      } else {
        emit(CreateFolderFailure("Failed with status: ${response.statusCode}"));
      }
    } catch (e) {
      log('Error caught in catch: $e');
      emit(CreateFolderFailure(e.toString()));
    }
  }

  Future<void> _ReplaceFiles(
    ReplaceFiles event,
    Emitter<CreateFolderState> emit,
  ) async {
    emit(CreateFolderLoading());

    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'multipart/form-data',
      };

      MultipartFile toMultipartFile(PlatformFile file) {
        if (file.path != null) {
          return MultipartFile.fromFileSync(file.path!, filename: file.name);
        } else if (file.bytes != null) {
          return MultipartFile.fromBytes(file.bytes!, filename: file.name);
        } else {
          throw Exception('File must have either path or bytes.');
        }
      }

      if (event.file == null) {
        throw Exception('No file provided for upload.');
      }

      final multipartFile = toMultipartFile(event.file!);

      final formData = FormData.fromMap({
        'file': multipartFile,
        if (event.parentId != null && event.parentId!.isNotEmpty)
          'parentId': event.parentId,
      });

      final dio = Dio();

      final response = await dio.post(
        'https://api.nowdigitaleasy.com/drive/v1/files?file=${event.selectedOne}',
        data: formData,
        options: Options(
          headers: headers,
        ),
      );

      log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('File uploaded successfully: ${response.data}');
        uploadFileToS3PresignedUrl(
          presignedUrl: response.data['presignedurl'][0]['presignedUrl'],
          file: event.file!,
        );
        emit(CreateFolderSuccess());
      } else {
        emit(CreateFolderFailure("Failed with status: ${response.statusCode}"));
      }
    } catch (e) {
      log('Error caught in catch: $e');
      emit(CreateFolderFailure(e.toString()));
    }
  }

  Future<void> uploadFileToS3PresignedUrl({
    required String presignedUrl,
    required PlatformFile file,
  }) async {
    try {
      List<int> fileBytes;
      log(presignedUrl);
      log(presignedUrl);

      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('File must have either path or bytes.');
      }

      final dio = Dio();
      log(presignedUrl);
      final response = await dio.put(
        presignedUrl,
        data: fileBytes,
        options: Options(headers: {'Content-Type': 'application/octet-stream'}),
      );

      if (response.statusCode == 200) {
        log(' File uploaded successfully');
        if (!_snackbarShown) {
          Messenger.alertSuccess("File uploaded successfully");

          _snackbarShown = true;
        }
      } else {
        log('  Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      log('  Upload error: $e');
    }
  }
}
