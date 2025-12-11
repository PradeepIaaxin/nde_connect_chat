class PaginationDatamodel {
  final int totalDocs;
  final int page;
  final int limit;
  final int totalPages;
  final int? nextPage;
  final int? prevPage;

  PaginationDatamodel({
    required this.totalDocs,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.nextPage,
    this.prevPage,
  });

  factory PaginationDatamodel.fromJson(Map<String, dynamic> json) {
    return PaginationDatamodel(
      totalDocs: json['totalDocs'],
      page: json['page'],
      limit: json['limit'],
      totalPages: json['totalPages'],
      nextPage: json['nextPage'],
      prevPage: json['prevPage'],
    );
  }
}
