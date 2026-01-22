import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:linkify/linkify.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class MessageCaption extends StatefulWidget {
  final String content;
  final String time;
  final bool isSentByMe;
  final String messageStatus;
  final Widget Function(String)?
      buildStatusIcon; // Optional custom status icon builder
  final String? searchText;

  const MessageCaption({
    Key? key,
    required this.content,
    required this.time,
    this.isSentByMe = false,
    this.messageStatus = 'sent',
    this.buildStatusIcon,
    this.searchText,
  }) : super(key: key);

  @override
  State<MessageCaption> createState() => _MessageCaptionState();
}

class _MessageCaptionState extends State<MessageCaption> {
  bool isExpanded = false;

  bool _isTextLong(String text) {
    const maxCharsPerLine = 40;
    return (text.length / maxCharsPerLine).ceil() > 9;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final bool hasLinkLocal = content.isNotEmpty &&
        RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false)
            .hasMatch(content);

    final Widget messageContent = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLinkLocal)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnyLinkPreview(
                  link: (() {
                    final match = RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                            caseSensitive: false)
                        .firstMatch(content);
                    if (match == null) return '';
                    String url = match.group(0)!;
                    try {
                      final uri = Uri.parse(
                          url.startsWith('www.') ? 'https://$url' : url);
                      return uri.toString();
                    } catch (e) {
                      return url;
                    }
                  })(),
                  displayDirection: UIDirection.uiDirectionVertical,
                  showMultimedia: true,
                  backgroundColor: Colors.grey.shade100,
                  bodyStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  titleStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  cache: const Duration(hours: 1),
                  borderRadius: 12,
                  errorBody: 'Could not load link preview',
                  errorTitle: 'Link Preview',
                  errorWidget: Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.link_off)),
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              const SizedBox(width: double.infinity, height: 0),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    bottom: 5,
                  ),
                  child: RichText(
                    maxLines: isExpanded ? null : 9,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        ...linkify(
                          content,
                          options: const LinkifyOptions(
                            humanize: true,
                            looseUrl: true,
                            defaultToHttps: true,
                          ),
                          linkifiers: [
                            const EmailLinkifier(),
                            const UrlLinkifier(),
                            CustomPhoneNumberLinkifier(),
                          ],
                        ).map((element) {
                          if (element is LinkableElement) {
                            return TextSpan(
                              text: element.text,
                              style: const TextStyle(color: Colors.blue),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  try {
                                    final uri = Uri.parse(element.url);
                                    if (!await launchUrl(uri,
                                        mode: LaunchMode.externalApplication)) {
                                      throw 'Could not launch $uri';
                                    }
                                  } catch (e) {
                                    debugPrint('Could not launch url: $e');
                                  }
                                },
                            );
                          } else {
                            if (widget.searchText != null &&
                                widget.searchText!.isNotEmpty &&
                                element.text.toLowerCase().contains(
                                    widget.searchText!.toLowerCase())) {
                              final List<TextSpan> highlightedSpans = [];
                              final String text = element.text;
                              final String query =
                                  widget.searchText!.toLowerCase();
                              int start = 0;
                              int indexOfMatch;

                              while ((indexOfMatch = text
                                      .toLowerCase()
                                      .indexOf(query, start)) !=
                                  -1) {
                                if (indexOfMatch > start) {
                                  highlightedSpans.add(TextSpan(
                                    text: text.substring(start, indexOfMatch),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ));
                                }

                                highlightedSpans.add(TextSpan(
                                  text: text.substring(indexOfMatch,
                                      indexOfMatch + query.length),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    backgroundColor: Colors.yellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ));

                                start = indexOfMatch + query.length;
                              }

                              if (start < text.length) {
                                highlightedSpans.add(TextSpan(
                                  text: text.substring(start),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ));
                              }

                              return TextSpan(children: highlightedSpans);
                            }
                            return TextSpan(
                              text: element.text,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black87),
                            );
                          }
                        }),
                        WidgetSpan(
                          child: SizedBox(
                              width: widget.isSentByMe ? 75 : 60, height: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!(!isExpanded && _isTextLong(content)))
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (widget.time.contains('AM') ||
                                widget.time.contains('PM'))
                            ? widget.time
                            : TimeUtils.formatUtcToIst(widget.time),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      if (widget.isSentByMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: widget.buildStatusIcon != null
                              ? widget.buildStatusIcon!(widget.messageStatus)
                              : (widget.messageStatus == 'read'
                                  ? const Icon(Icons.done_all,
                                      size: 15, color: Colors.blue)
                                  : const Icon(Icons.done,
                                      size: 15, color: Colors.black54)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          if (!isExpanded && _isTextLong(content)) ...[
            GestureDetector(
              onTap: () => setState(() => isExpanded = true),
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Read more",
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.time.contains('AM') || widget.time.contains('PM'))
                        ? widget.time
                        : TimeUtils.formatUtcToIst(widget.time),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  if (widget.isSentByMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: widget.buildStatusIcon != null
                          ? widget.buildStatusIcon!(widget.messageStatus)
                          : (widget.messageStatus == 'read'
                              ? const Icon(Icons.done_all,
                                  size: 15, color: Colors.blue)
                              : const Icon(Icons.done,
                                  size: 15, color: Colors.black54)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: messageContent,
    );
  }
}

class CustomPhoneNumberLinkifier extends Linkifier {
  final RegExp _phoneRegex = RegExp(r'(\+?\d{10,15})');

  @override
  List<LinkifyElement> parse(
      List<LinkifyElement> elements, LinkifyOptions options) {
    final List<LinkifyElement> result = [];
    for (final element in elements) {
      if (element is TextElement) {
        final text = element.text;
        int start = 0;
        for (final match in _phoneRegex.allMatches(text)) {
          if (match.start != start) {
            result.add(TextElement(text.substring(start, match.start)));
          }
          result.add(LinkableElement(match.group(0)!, match.group(0)!));
          start = match.end;
        }
        if (start < text.length) {
          result.add(TextElement(text.substring(start)));
        }
      } else {
        result.add(element);
      }
    }
    return result;
  }
}
