

// States
import 'package:equatable/equatable.dart';

import 'MediaLinksDocsDataModel.dart';

abstract class MediaLinksDocsState extends Equatable {
  const MediaLinksDocsState();

  @override
  List<Object> get props => [];
}

class MediaLinksDocsLoading extends MediaLinksDocsState {}

class MediaLinksDocsLoaded extends MediaLinksDocsState {
  final MediaLinksDocsData data;

  const MediaLinksDocsLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class MediaLinksDocsError extends MediaLinksDocsState {
  final String error;

  const MediaLinksDocsError(this.error);

  @override
  List<Object> get props => [error];
}