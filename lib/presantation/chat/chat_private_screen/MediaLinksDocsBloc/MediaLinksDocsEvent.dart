// Events
import 'package:equatable/equatable.dart';

abstract class MediaLinksDocsEvent extends Equatable {
  const MediaLinksDocsEvent();

  @override
  List<Object> get props => [];
}

class LoadMediaLinksDocs extends MediaLinksDocsEvent {}