// Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import 'MediaLinksDocsDataModel.dart';
import 'MediaLinksDocsEvent.dart';
import 'MediaLinksDocsState.dart';

class MediaLinksDocsBloc extends Bloc<MediaLinksDocsEvent, MediaLinksDocsState> {
  MediaLinksDocsBloc() : super(MediaLinksDocsLoading()) {
    on<LoadMediaLinksDocs>(_onLoadMediaLinksDocs);
  }

  Future<void> _onLoadMediaLinksDocs(
      LoadMediaLinksDocs event,
      Emitter<MediaLinksDocsState> emit,
      ) async {
    emit(MediaLinksDocsLoading());
    try {
      // Here you would typically fetch data from an API
      // For demonstration, we're using mock data
      final data = MediaLinksDocsData(
        media: [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
          'https://example.com/image3.jpg',
        ],
        links: [
          'https://example.com/link1',
          'https://example.com/link2',
        ],
        docs: [
          'Document1.pdf',
          'Document2.docx',
        ],
      );
      emit(MediaLinksDocsLoaded(data));
    } catch (e) {
      emit(MediaLinksDocsError('Failed to load data'));
    }
  }
}
