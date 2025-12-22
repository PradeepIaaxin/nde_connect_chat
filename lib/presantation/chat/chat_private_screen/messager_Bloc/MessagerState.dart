// import '../messager_model.dart';

// abstract class MessagerState {}

// class MessagerInitial extends MessagerState {}

// class MessagerLoading extends MessagerState {}

// class MessagerLoaded extends MessagerState {
//   final AuthResponse response;

//   MessagerLoaded(this.response);
// }

// class MessagerLoadingMore extends MessagerState {}

// class MessagerError extends MessagerState {
//   final String message;

//   MessagerError(this.message);
// }

// class MessageSentSuccessfully extends MessagerState {
//   final Message sentMessage;

//   MessageSentSuccessfully(this.sentMessage);

//   List<Object?> get props =>
//       [sentMessage.messageId, sentMessage.message, sentMessage.time];

//   @override
//   String toString() =>
//       'MessageSentSuccessfully(messageId: ${sentMessage.messageId})';
// }

// class NewMessageReceivedState extends MessagerState {
//   final Map<String, dynamic> message;
//   NewMessageReceivedState(this.message);
// }

// class TemporaryMessageAdded extends MessagerState {
//   final Message message;

//   TemporaryMessageAdded(this.message);
// }

// ///.... Add these new state classes to your MessagerState file
// class AudioRecordingStarted extends MessagerState {}

// class AudioRecordingStopped extends MessagerState {
//   final String audioPath;

//   AudioRecordingStopped(this.audioPath);
// }

// class AudioMessageSending extends MessagerState {}

// class AudioMessageSent extends MessagerState {
//   final String audioUrl;

//   AudioMessageSent(this.audioUrl);
// }

// class AudioMessageError extends MessagerState {
//   final String message;

//   AudioMessageError(this.message);
// }

// class UploadInitial extends MessagerState {}

// class UploadInProgress extends MessagerState {
//   final int progress;
//   UploadInProgress(this.progress);

//   List<Object?> get props => [progress];
// }

// class UploadSuccess extends MessagerState {
//   final Map<String, dynamic> response;

//   UploadSuccess(this.response);

//   List<Object?> get props => [response];
// }

// class UploadFailure extends MessagerState {
//   final String message;

//   UploadFailure(this.message);

//   List<Object?> get props => [message];
// }

// /// ImageMessageSending...............................
// class ImageMessageSending extends MessagerState {}

// class ImageMessageSent extends MessagerState {
//   final String imagePath;
//   ImageMessageSent(this.imagePath);
// }

// /// VideoMessageSending...............................
// class VideoMessageSending extends MessagerState {}

// class VideoMessageSent extends MessagerState {
//   final String videoPath;
//   VideoMessageSent(this.videoPath);
// }

// /// DocumentMessageSending...........................
// class DocumentMessageSending extends MessagerState {}

// class DocumentMessageSent extends MessagerState {
//   final String documentPath;
//   DocumentMessageSent(this.documentPath);
// }

// class ReactionUpdated extends MessagerState {
//   final String messageId;
//   final List<Map<String, dynamic>> reactions;

//   ReactionUpdated({
//     required this.messageId,
//     required this.reactions,
//   });

//   List<Object> get props => [messageId, reactions];
// }

// class ReactionError extends MessagerState {
//   final String error;

//   ReactionError(this.error);

//   List<Object?> get props => [error];
// }
// class MessageForwardedSuccess extends MessagerState {
//   final List<Map<String, dynamic>> results;

//   MessageForwardedSuccess(this.results);

//   @override
//   List<Object?> get props => [results];
// }

// class MessageForwardedPartialSuccess extends MessagerState {
//   final List<Map<String, dynamic>> successes;
//   final List<Map<String, dynamic>> failures;

//   MessageForwardedPartialSuccess({
//     required this.successes,
//     required this.failures,
//   });

//   @override
//   List<Object?> get props => [successes, failures];
// }

import '../messager_model.dart';

abstract class MessagerState {}

class MessagerInitial extends MessagerState {}

class MessagerLoading extends MessagerState {}


class MessagerLoaded extends MessagerState {
  final MessageListResponse response;

  MessagerLoaded(this.response);
}

class MessagerLoadingMore extends MessagerState {}

class MessagerError extends MessagerState {
  final String message;

  MessagerError(this.message);
}

class MessageSentSuccessfully extends MessagerState {
  final Message sentMessage;

  MessageSentSuccessfully(this.sentMessage);

  List<Object?> get props =>
      [sentMessage.messageId, sentMessage.message, sentMessage.time];

  @override
  String toString() =>
      'MessageSentSuccessfully(messageId: ${sentMessage.messageId})';
}

class NewMessageReceivedState extends MessagerState {
  final Map<String, dynamic> message;
  NewMessageReceivedState(this.message);
}

class TemporaryMessageAdded extends MessagerState {
  final Message message;

  TemporaryMessageAdded(this.message);
}

/// Audio message states
class AudioRecordingStarted extends MessagerState {}

class AudioRecordingStopped extends MessagerState {
  final String audioPath;

  AudioRecordingStopped(this.audioPath);
}

class AudioMessageSending extends MessagerState {}

class AudioMessageSent extends MessagerState {
  final String audioUrl;

  AudioMessageSent(this.audioUrl);
}

class AudioMessageError extends MessagerState {
  final String message;

  AudioMessageError(this.message);
}

/// Upload states
class UploadInitial extends MessagerState {}

class UploadInProgress extends MessagerState {
  final int progress;
  UploadInProgress(this.progress);

  List<Object?> get props => [progress];
}

class UploadSuccess extends MessagerState {
  final Map<String, dynamic> response;

  UploadSuccess(this.response);

  List<Object?> get props => [response];
}

class UploadFailure extends MessagerState {
  final String message;

  UploadFailure(this.message);

  List<Object?> get props => [message];
}

/// Image upload
class ImageMessageSending extends MessagerState {}

class ImageMessageSent extends MessagerState {
  final String imagePath;
  ImageMessageSent(this.imagePath);
}

/// Video upload
class VideoMessageSending extends MessagerState {}

class VideoMessageSent extends MessagerState {
  final String videoPath;
  VideoMessageSent(this.videoPath);
}

/// Document upload
class DocumentMessageSending extends MessagerState {}

class DocumentMessageSent extends MessagerState {
  final String documentPath;
  DocumentMessageSent(this.documentPath);
}

/// Reaction states
class ReactionUpdated extends MessagerState {
  final String messageId;
  final List<Map<String, dynamic>> reactions;

  ReactionUpdated({
    required this.messageId,
    required this.reactions,
  });

  List<Object> get props => [messageId, reactions];
}

class ReactionError extends MessagerState {
  final String error;

  ReactionError(this.error);

  List<Object?> get props => [error];
}

/// Forward message states
class MessageForwardedSuccess extends MessagerState {
  final List<Map<String, dynamic>> results;

  MessageForwardedSuccess(this.results);

  @override
  List<Object?> get props => [results];
}

class MessageForwardedPartialSuccess extends MessagerState {
  final List<Map<String, dynamic>> successes;
  final List<Map<String, dynamic>> failures;

  MessageForwardedPartialSuccess({
    required this.successes,
    required this.failures,
  });

  @override
  List<Object?> get props => [successes, failures];
}

class MessageAckReceived extends MessagerState {
  final String tempId;
  final String realId;
  final String status;

  MessageAckReceived({
    required this.tempId,
    required this.realId,
    required this.status,
  });
}

