class FileSizeInfo {
  final int size;
  final int order;
  final String type;
  final String unit;

  FileSizeInfo({
    required this.size,
    required this.order,
    required this.type,
    required this.unit,
  });

  factory FileSizeInfo.fromJson(Map<String, dynamic> json) {
    return FileSizeInfo(
      size: json['size'] ?? 0,
      order: json['order'] ?? 0,
      type: json['type'] ?? '',
      unit: json['unit'] ?? '',
    );
  }
}

class TotalSizeInfo {
  final int size;
  final String unit;

  TotalSizeInfo({
    required this.size,
    required this.unit,
  });

  factory TotalSizeInfo.fromJson(Map<String, dynamic> json) {
    return TotalSizeInfo(
      size: json['size'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

class FileStorageResponse {
  final List<FileSizeInfo> filesize;
  final TotalSizeInfo totelsize;

  FileStorageResponse({
    required this.filesize,
    required this.totelsize,
  });

  factory FileStorageResponse.fromJson(Map<String, dynamic> json) {
    return FileStorageResponse(
      filesize: (json['filesize'] as List<dynamic>? ?? [])
          .map((item) => FileSizeInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      totelsize: json['totelsize'] != null
          ? TotalSizeInfo.fromJson(json['totelsize'] as Map<String, dynamic>)
          : TotalSizeInfo(size: 0, unit: 'B'),
    );
  }
}
