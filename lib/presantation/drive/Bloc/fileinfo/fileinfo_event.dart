abstract class FileDetailEvent {}

class FetchInfoDetails extends FileDetailEvent {
  final String fileID;

  FetchInfoDetails({required this.fileID});
}
