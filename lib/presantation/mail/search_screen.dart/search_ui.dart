import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_api.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_bloc.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_event.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';

class SearchMailHit {
  final String id;
  final String mailboxId;
  final String path;
  final List<String> toAddress;
  final List<String> toName;
  final int? dateMs;
  final bool? seen;
  final bool? hasAttachments;
  final String subject;
  final String fromAddress;
  final String fromName;
  final String intro;
  final Map<String, dynamic>? formatted;

  const SearchMailHit({
    required this.id,
    required this.mailboxId,
    required this.path,
    required this.toAddress,
    required this.toName,
    required this.dateMs,
    required this.seen,
    required this.hasAttachments,
    required this.subject,
    required this.fromAddress,
    required this.fromName,
    required this.intro,
    required this.formatted,
  });

  factory SearchMailHit.fromJson(Map<String, dynamic> json) {
    final formatted = json['_formatted'];
    final toAddressRaw = json['toAddress'];
    final toNameRaw = json['toName'];

    List<String> toAddresses = const [];
    if (toAddressRaw is List) {
      toAddresses = toAddressRaw.map((e) => e.toString()).toList();
    }

    List<String> toNames = const [];
    if (toNameRaw is List) {
      toNames = toNameRaw.map((e) => e.toString()).toList();
    }

    if (toAddresses.isEmpty && json['to'] is List) {
      final list = (json['to'] as List).whereType<Map>().toList();
      toAddresses = list
          .map((e) => (e['address'] ?? '').toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      toNames = list
          .map((e) => (e['name'] ?? '').toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return SearchMailHit(
      id: (json['id'] ?? '').toString(),
      mailboxId: (json['mailbox'] ?? json['mailboxId'] ?? json['mailbox_id'] ?? '')
          .toString(),
      path: (json['path'] ?? '').toString(),
      toAddress: toAddresses,
      toName: toNames,
      dateMs: json['date'] is int ? json['date'] as int : int.tryParse('${json['date']}'),
      seen: json['seen'] is bool ? json['seen'] as bool : null,
      hasAttachments:
          json['hasAttachments'] is bool ? json['hasAttachments'] as bool : null,
      subject: (json['subject'] ?? '').toString(),
      fromAddress: (json['fromAddress'] ?? '').toString(),
      fromName: (json['fromName'] ?? '').toString(),
      intro: (json['intro'] ?? json['content'] ?? '').toString(),
      formatted: formatted is Map<String, dynamic> ? formatted : null,
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isReadOnly = true;
  final Dio _dio = Dio();
  Timer? _debounce;
  CancelToken? _cancelToken;
  int _requestSerial = 0;

  bool _filterAttachments = false;
  bool _filter7Days = false;
  bool _filterForMe = false;

  bool _isLoading = false;
  String? _errorMessage;
  List<SearchMailHit> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _buildFilterString({required String? currentUserEmail}) {
    final parts = <String>[];

    if (_filterAttachments) {
      parts.add('hasAttachments = true');
    }

    if (_filter7Days) {
      final ms = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      parts.add('date >= $ms');
    }

    if (_filterForMe &&
        currentUserEmail != null &&
        currentUserEmail.trim().isNotEmpty) {
      final email = currentUserEmail.trim();
      parts.add(
        '(toAddress = "$email" OR ccAddress = "$email" OR bccAddress = "$email")',
      );
    }

    return parts.join(' AND ');
  }

  void _onQueryChanged(String value) {
    final query = value.trim();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      if (query.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _results = const [];
        });
        return;
      }

      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final serial = ++_requestSerial;

    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await UserPreferences.getMeiliTenantToken();
      final workspace = await UserPreferences.getDefaultWorkspace();
      final email = await UserPreferences.getEmail();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      if (workspace != null && workspace.isNotEmpty) {
        headers['x-workspace'] = workspace;
      }

      final payload = {
        'q': query,
        'limit': 6,
        'filter': _buildFilterString(currentUserEmail: email),
        'attributesToHighlight': const [
          'subject',
          'fromAddress',
          'toAddress',
          'content',
          'fromName',
          'toName',
        ],
        'highlightPreTag': '<em>',
        'highlightPostTag': '</em>',
      };

      final response = await _dio.post(
        'https://search.nowdigitaleasy.com/indexes/NdeMailIndex/search',
        options: Options(headers: headers),
        data: payload,
        cancelToken: cancelToken,
      );

      if (!mounted || serial != _requestSerial) return;

      final data = response.data;
      final hitsRaw = (data is Map<String, dynamic>) ? data['hits'] : null;

      final hits = hitsRaw is List
          ? hitsRaw
              .whereType<Map>()
              .map((e) => SearchMailHit.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <SearchMailHit>[];

      setState(() {
        _results = hits;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Search failed. Please try again.';
      });
    }
  }

  TextSpan _highlightedSpan({
    required String? formatted,
    required String fallback,
    required String query,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    final text = (formatted == null || formatted.isEmpty) ? fallback : formatted;
    final matches = RegExp(r'<em[^>]*>(.*?)</em>').allMatches(text).toList();
    if (matches.isEmpty) {
      final stripped = text.replaceAll(RegExp(r'<[^>]*>'), '');
      return _localHighlight(
        text: stripped,
        query: query,
        normalStyle: normalStyle,
        highlightStyle: highlightStyle,
      );
    }

    final spans = <TextSpan>[];
    var index = 0;
    for (final match in matches) {
      if (match.start > index) {
        spans.add(
          TextSpan(
            text: text.substring(index, match.start).replaceAll(RegExp(r'<[^>]*>'), ''),
            style: normalStyle,
          ),
        );
      }
      spans.add(TextSpan(text: match.group(1) ?? '', style: highlightStyle));
      index = match.end;
    }
    if (index < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(index).replaceAll(RegExp(r'<[^>]*>'), ''),
          style: normalStyle,
        ),
      );
    }
    return TextSpan(children: spans);
  }

  TextSpan _localHighlight({
    required String text,
    required String query,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    final q = query.trim();
    if (q.isEmpty) return TextSpan(text: text, style: normalStyle);

    final tokens = q
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    if (tokens.isEmpty) return TextSpan(text: text, style: normalStyle);

    final pattern = tokens.map(RegExp.escape).join('|');
    final matches = RegExp('($pattern)', caseSensitive: false).allMatches(text);
    if (matches.isEmpty) return TextSpan(text: text, style: normalStyle);

    final spans = <TextSpan>[];
    var index = 0;
    for (final m in matches) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start), style: normalStyle));
      }
      spans.add(TextSpan(text: text.substring(m.start, m.end), style: highlightStyle));
      index = m.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index), style: normalStyle));
    }
    return TextSpan(children: spans);
  }

  String? _formattedToText(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      final parts = value.map((e) => e?.toString() ?? '').where((e) => e.trim().isNotEmpty).toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    }
    if (value is Map) {
      final address = value['address']?.toString();
      final name = value['name']?.toString();
      if (name != null && name.trim().isNotEmpty && address != null && address.trim().isNotEmpty) {
        return '$name <$address>';
      }
      if (name != null && name.trim().isNotEmpty) return name;
      if (address != null && address.trim().isNotEmpty) return address;
    }
    final s = value.toString();
    return s.trim().isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: ClipPath(
            child: AppBar(
              backgroundColor: AppColors.bg,
              elevation: 1,
              // automaticallyImplyLeading: false,
              title: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.cancel, color: AppColors.iconDefault),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        readOnly: _isReadOnly,
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: AppColors.iconDefault),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: AppColors.headingText),
                        onTap: () {
                          setState(() {
                            _isReadOnly = false;
                          });
                        },
                        onChanged: _onQueryChanged,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.mic, color: AppColors.iconActive),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'Attachments',
                    selected: _filterAttachments,
                    onSelected: (v) {
                      setState(() => _filterAttachments = v);
                      if (query.isNotEmpty) _performSearch(query);
                    },
                  ),
                  _buildFilterChip(
                    label: '7 days',
                    selected: _filter7Days,
                    onSelected: (v) {
                      setState(() => _filter7Days = v);
                      if (query.isNotEmpty) _performSearch(query);
                    },
                  ),
                  _buildFilterChip(
                    label: 'For me',
                    selected: _filterForMe,
                    onSelected: (v) {
                      setState(() => _filterForMe = v);
                      if (query.isNotEmpty) _performSearch(query);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: query.isEmpty
                    ? const SizedBox.shrink()
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              )
                            : _results.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No results',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _results.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final hit = _results[index];

                                      final subjectFormatted =
                                          hit.formatted?['subject']?.toString();
                                      final fromNameFormatted =
                                          _formattedToText(hit.formatted?['fromName']);
                                      final fromAddressFormatted =
                                          _formattedToText(hit.formatted?['fromAddress']);
                                      final toNameFormatted =
                                          _formattedToText(hit.formatted?['toName']);
                                      final toAddressFormatted =
                                          _formattedToText(hit.formatted?['toAddress']);
                                      final introFormatted =
                                          hit.formatted?['intro']?.toString() ??
                                              hit.formatted?['content']?.toString();

                                      final titleStyle = const TextStyle(
                                        color: AppColors.headingText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      );
                                      final highlightStyle = titleStyle.copyWith(
                                        color: AppColors.iconActive,
                                        fontWeight: FontWeight.w700,
                                      );

                                      final subtitleStyle = const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 12.5,
                                      );
                                      final subtitleHighlightStyle =
                                          subtitleStyle.copyWith(
                                        color: AppColors.iconActive,
                                        fontWeight: FontWeight.w700,
                                      );

                                      bool hasEm(String? s) =>
                                          s != null && s.contains('<em');

                                      bool containsQuery(String s) {
                                        final q = query.trim().toLowerCase();
                                        if (q.isEmpty) return false;
                                        return s.toLowerCase().contains(q);
                                      }

                                      final fromNameRaw = hit.fromName;
                                      final fromAddressRaw = hit.fromAddress;
                                      final toNameRaw =
                                          hit.toName.isNotEmpty ? hit.toName.first : '';
                                      final toAddressRaw = hit.toAddress.isNotEmpty
                                          ? hit.toAddress.first
                                          : '';

                                      final anyToMatches = hit.toName.any(containsQuery) ||
                                          hit.toAddress.any(containsQuery);

                                      final useFrom = hasEm(fromNameFormatted) ||
                                          hasEm(fromAddressFormatted) ||
                                          containsQuery(fromNameRaw) ||
                                          containsQuery(fromAddressRaw) ||
                                          (!anyToMatches &&
                                              (fromNameRaw.isNotEmpty ||
                                                  fromAddressRaw.isNotEmpty));

                                      final showToPrefix = !useFrom &&
                                          (hasEm(toNameFormatted) ||
                                              hasEm(toAddressFormatted) ||
                                              anyToMatches);

                                      final primaryName =
                                          useFrom ? fromNameRaw : toNameRaw;
                                      final primaryAddress =
                                          useFrom ? fromAddressRaw : toAddressRaw;
                                      final primaryNameFormatted =
                                          useFrom ? fromNameFormatted : toNameFormatted;
                                      final primaryAddressFormatted = useFrom
                                          ? fromAddressFormatted
                                          : toAddressFormatted;
                                      final nameSeed = primaryName.isNotEmpty
                                          ? primaryName
                                          : primaryAddress;

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.profile,
                                          child: Text(
                                            nameSeed.isNotEmpty
                                                ? nameSeed[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppColors.bg,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        title: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: _highlightedSpan(
                                            formatted: subjectFormatted,
                                            query: query,
                                            fallback: hit.subject.isNotEmpty
                                                ? hit.subject
                                                : '(No Subject)',
                                            normalStyle: titleStyle,
                                            highlightStyle: highlightStyle,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                style: subtitleStyle,
                                                children: [
                                                  if (showToPrefix)
                                                    const TextSpan(text: 'To: '),
                                                  if (primaryName.isNotEmpty)
                                                    _highlightedSpan(
                                                      formatted:
                                                          primaryNameFormatted,
                                                      query: query,
                                                      fallback: primaryName,
                                                      normalStyle: subtitleStyle,
                                                      highlightStyle:
                                                          subtitleHighlightStyle,
                                                    ),
                                                  if (primaryName.isNotEmpty &&
                                                      primaryAddress.isNotEmpty)
                                                    const TextSpan(text: ' '),
                                                  if (primaryAddress.isNotEmpty)
                                                    _highlightedSpan(
                                                      formatted:
                                                          primaryAddressFormatted,
                                                      query: query,
                                                      fallback: primaryAddress,
                                                      normalStyle: subtitleStyle,
                                                      highlightStyle:
                                                          subtitleHighlightStyle,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if ((hit.intro.isNotEmpty) ||
                                                (introFormatted != null &&
                                                    introFormatted.isNotEmpty))
                                              RichText(
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                text: _highlightedSpan(
                                                  formatted: introFormatted,
                                                  query: query,
                                                  fallback: hit.intro,
                                                  normalStyle: subtitleStyle,
                                                  highlightStyle:
                                                      subtitleHighlightStyle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: hit.hasAttachments == true
                                            ? const Icon(
                                                Icons.attach_file,
                                                size: 18,
                                                color: AppColors.iconDefault,
                                              )
                                            : null,
                                        onTap: hit.mailboxId.isEmpty ||
                                                hit.id.isEmpty
                                            ? null
                                            : () {
                                                FocusScope.of(context).unfocus();
                                                final mailboxId = hit.mailboxId;
                                                MyRouter.push(
                                                  screen: BlocProvider(
                                                    create: (context) =>
                                                        MailDetailBloc(
                                                      apiService:
                                                          Fatchdetailmailapi(),
                                                    )..add(
                                                            FetchMailDetailEvent(
                                                              mailboxId,
                                                              hit.id,
                                                            ),
                                                          ),
                                                    child: MailDetailScreen(
                                                      mailboxId: mailboxId,
                                                      messageId: hit.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                      );
                                    },
                                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.bg : AppColors.headingText,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.iconActive,
      backgroundColor: AppColors.bg,
      onSelected: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}
