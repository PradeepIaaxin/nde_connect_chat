import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/presantation/contact/contact_screen.dart';
import 'package:nde_email/presantation/mail/compose/model/composemodel.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import '../bloc/send_mail_bloc/send_mail_bloc.dart';
import '../bloc/send_mail_bloc/send_mail_event.dart';
import '../bloc/send_mail_bloc/send_mail_state.dart';
import '../../mail_list/bloc/mail_list_bloc.dart';
import '../../mail_list/bloc/mail_list_event.dart';
import '../bloc/fetchname_bloc/fatchname_event.dart';
import '../bloc/fetchname_bloc/fatchname_bloc.dart';
import '../bloc/fetchname_bloc/fatchname_state.dart';
import '../bloc/send_draft/save_draft_bloc.dart';
import '../bloc/send_draft/save_dratf_event.dart';
import '../bloc/send_draft/save_draft_state.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_state.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_bloc.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_event.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_model.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_model.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/attachment.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/collapsible_quoted_content.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:nde_email/presantation/mail/compose/api/upload_files_api.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_event.dart';

class ComposeScreen extends StatefulWidget {
  final Map<String, dynamic>? draftData;
  final MailDetailModel? mailDetail;
  final ComposeAction? action;
  final List<UploadedAttachment>? initialAttachments;

  final String? mailboxId;
  final int? draftId;

  const ComposeScreen(
      {super.key,
      this.draftData,
      this.mailDetail,
      this.initialAttachments,
      this.mailboxId,
      this.draftId,
      this.action});

  @override
  _ComposeScreenState createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final TextEditingController from = TextEditingController();
  final TextEditingController toCont = TextEditingController();
  final TextEditingController ccCont = TextEditingController();
  final TextEditingController bccCont = TextEditingController();
  final TextEditingController subjectCont = TextEditingController();
  final TextEditingController composeMailCont = TextEditingController();
  final FocusNode _bodyFocusNode = FocusNode();
  Timer? _draftTimer;

  List<String> toEmails = [];
  List<String> ccEmails = [];
  List<String> bccEmails = [];
  List<UploadedAttachment> attachments = [];

  bool isExpanded = false;
  String? fromEmail;
  bool showSuggestions = false;
  bool showCcBcc = false;

  void _addEmail(
      String email, List<String> emailList, TextEditingController controller) {
    if (!emailList.contains(email)) {
      setState(() {
        emailList.add(email);
        controller.clear();
        showSuggestions = false;
      });
    }
  }

  bool _hasUnsavedChanges() {
    return toEmails.isNotEmpty ||
        ccEmails.isNotEmpty ||
        bccEmails.isNotEmpty ||
        subjectCont.text.isNotEmpty ||
        composeMailCont.text.isNotEmpty ||
        attachments.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    context.read<DraftBloc>().add(ResetDraftEvent());

    context.read<FatchnameBloc>().add(FetchSenderEmailEvent());

    if (widget.mailDetail != null && widget.action != null) {
      final mail = widget.mailDetail!;
      final action = widget.action!;
      final formattedDate =
          DateFormat('EEE, d MMM yyyy hh:mm a').format(mail.date.toLocal());

      final allRecipients = <String>{mail.from.address};
      allRecipients.addAll(mail.to.map((e) => e.address));
      allRecipients.remove(fromEmail);

      switch (action) {
        case ComposeAction.reply:
          toCont.text = mail.from.address;
          subjectCont.text = 'Re: ${mail.subject}';
          composeMailCont.text =
              "\n\nOn $formattedDate, ${mail.from.name} <${mail.from.address}> wrote:\n";
          break;

        case ComposeAction.replyAll:
          toCont.text = allRecipients.join(", ");
          subjectCont.text = 'Re: ${mail.subject}';
          composeMailCont.text =
              "\n\nOn $formattedDate, ${mail.from.name} <${mail.from.address}> wrote:\n";
          break;

        case ComposeAction.forward:
          final toList =
              mail.to.map((e) => "${e.name} <${e.address}>").join(", ");
          subjectCont.text = 'Fwd: ${mail.subject}';
          composeMailCont.text = "\n\n---------- Forwarded message ---------\n"
              "From: ${mail.from.name} <${mail.from.address}>\n"
              "Date: $formattedDate\n"
              "Subject: ${mail.subject}\n"
              "To: $toList\n";
          break;
      }

      if (action == ComposeAction.reply || action == ComposeAction.replyAll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _bodyFocusNode.requestFocus();
          composeMailCont.selection = const TextSelection.collapsed(offset: 0);
        });
      }
    } else {
      _loadDraftData();
    }

    if (widget.initialAttachments != null &&
        widget.initialAttachments!.isNotEmpty) {
      attachments = List<UploadedAttachment>.from(widget.initialAttachments!);
    }

    toCont.addListener(() {
      setState(() {
        showSuggestions = toCont.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _loadDraftData() {
    if (widget.draftData != null) {
      toCont.text = widget.draftData?['to'] ?? '';
      ccCont.text = widget.draftData?['cc'] ?? '';
      bccCont.text = widget.draftData?['bcc'] ?? '';
      subjectCont.text = widget.draftData?['subject'] ?? '';
      composeMailCont.text = widget.draftData?['body'] ?? '';
    }
  }

  void _onTextChanged() {
    // _draftTimer?.cancel();

    // _draftTimer = Timer(
    //   const Duration(seconds: 5),
    //   () {
    //     if (_hasUnsavedChanges()) {
    //       log("⏳ Auto-saving draft...");
    //       _saveDraft();
    //     }
    //   },
    // );
  }

  void _showPopupMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(25.0, 25.0, 0.0, 0.0),
      items: const [
        PopupMenuItem<String>(value: '1', child: Text('Attach file')),
        PopupMenuItem<String>(value: '2', child: Text('Insert from Drive')),
        PopupMenuItem<String>(value: '3', child: Text('Insert photo')),
      ],
    ).then((value) {
      if (value == '1') {
        pickAndUploadAttachment(false);
      }
      if (value == '2') {
        pickAndUploadAttachment(false);
      }
      if (value == '3') {
        //  _pickImage();
      }
    });
  }

  Future<void> pickAndUploadAttachment(bool isInline) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      final fileName = file.path.split("/").last;

      try {
        final String? uploadedId =
            await AttachmentRepository().uploadAttachment(
          file,
          contentDisposition: isInline ? "inline" : "attachment",
        );

        if (uploadedId == null) {
          Messenger.alert(msg: "Failed to upload attachment");

          return;
        }

        if (isInline) {
          setState(() {
            attachments.add(
              UploadedAttachment(
                id: uploadedId,
                fileName: fileName,
                filePath: file.path,
                isInline: true,
              ),
            );
          });

          Messenger.alert(msg: "Inline image inserted");
        } else {
          setState(() {
            attachments.add(
              UploadedAttachment(
                id: uploadedId,
                fileName: fileName,
                filePath: file.path,
                isInline: isInline,
              ),
            );
          });

          Messenger.alert(msg: "Attachment uploaded");
        }
      } catch (e) {
        log("Error in pickAndUploadAttachment: $e");
        Messenger.alert(msg: "Error processing attachment");
      }
    }
  }

  IconData getFileIcon(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) return Icons.image;
    if (extension == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(extension)) return Icons.description;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart;
    if (extension == 'txt') return Icons.text_fields;
    return Icons.attach_file;
  }

  void showAttachmentIdsOnly() {
    List<String> uploadedIds = attachments
        .where((attachment) => attachment.id != null)
        .map((attachment) => attachment.id!)
        .toList();

    log(" Only Uploaded IDs: $uploadedIds");

    Messenger.alert(msg: "Attachment IDs: ${uploadedIds.join(', ')}");
  }

  void _saveDraft() async {
    /// 🔥 IMPORTANT — flush chips
    _flushPendingEmail(toCont, toEmails);
    _flushPendingEmail(ccCont, ccEmails);
    _flushPendingEmail(bccCont, bccEmails);

    String? mailboxId = await MailboxStorage.getDraftsMailboxId();

    if (mailboxId != null && fromEmail != null) {
      List<int> attachmentIds = attachments
          .where((att) => att.id != null)
          .map((att) => int.tryParse(att.id!)!)
          .toList();

      context.read<DraftBloc>().add(
            SaveDraftEvent(
              mailboxId: mailboxId,
              draftData: {
                "date": DateTime.now().toIso8601String(),
                "draft": true,
                "files": attachmentIds,
                "to": toEmails
                    .map((e) => {
                          "name": "",
                          "address": e,
                        })
                    .toList(),
                "cc": ccEmails
                    .map((e) => {
                          "name": "",
                          "address": e,
                        })
                    .toList(),
                "bcc": bccEmails
                    .map((e) => {
                          "name": "",
                          "address": e,
                        })
                    .toList(),
                "from": {"name": "Your Name", "address": fromEmail},
                "headers": [
                  {"key": "message-id", "value": ""}
                ],
                "subject": subjectCont.text,
                "text": composeMailCont.text,
                "html": "<p>${composeMailCont.text}</p>",
              },

              // draftData: {
              //   "date": DateTime.now().toIso8601String(),
              //   "draft": true,
              //   "files": attachmentIds,

              //   /// ✅ FIXED
              //   "to": toEmails.map((e) => {"address": e}).toList(),

              //   "cc": ccEmails.map((e) => {"address": e}).toList(),

              //   "bcc": bccEmails.map((e) => {"address": e}).toList(),

              //   "from": {"name": "Your Name", "address": fromEmail},

              //   "headers": [
              //     {"key": "message-id", "value": ""}
              //   ],

              //   "subject": subjectCont.text,
              //   "text": composeMailCont.text,
              //   "html": "<p>${composeMailCont.text}</p>",
              // },
            ),
          );

      log("📎 Attachment data in draft: $attachmentIds");
      log("📤 TO: $toEmails");
      log("📤 CC: $ccEmails");
      log("📤 BCC: $bccEmails");
    } else {
      Messenger.alert(
        msg: "Draft mailbox ID or sender email is missing",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        MyRouter.pop();
        if (_hasUnsavedChanges()) {
          // _saveDraft();
          MyRouter.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _showPopupMenu,
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  /// ✅ FORCE last typed email → chip
                  _flushPendingEmail(toCont, toEmails);
                  _flushPendingEmail(ccCont, ccEmails);
                  _flushPendingEmail(bccCont, bccEmails);

                  log("📤 FINAL TO EMAILS: $toEmails");
                  log("📤 FINAL CC EMAILS: $ccEmails");
                  log("📤 FINAL BCC EMAILS: $bccEmails");

                  if (fromEmail == null) {
                    Messenger.alert(
                        msg: "Sender email not loaded. Please wait");
                    return;
                  }
                  final attachmentIds =
                      attachments.map((e) => e.id).whereType<String>().toList();

                  final sendRequest = SendMailRequest(
                    fromEmail: fromEmail!,
                    to: toEmails.join(','),
                    subject: subjectCont.text,
                    body: composeMailCont.text,
                    attachmentIds: attachmentIds,
                    cc: ccEmails.isNotEmpty ? ccEmails.join(',') : null,
                    bcc: bccEmails.isNotEmpty ? bccEmails.join(',') : null,
                    draftId: widget.draftId,
                    draftMailboxId: widget.mailboxId,
                  );

                  final draftData = <String, dynamic>{
                    'to': toEmails.join(', '),
                    'cc': ccEmails.join(', '),
                    'bcc': bccEmails.join(', '),
                    'subject': subjectCont.text,
                    'body': composeMailCont.text,
                  };

                  final restoredAttachments =
                      List<UploadedAttachment>.from(attachments);

                  bool undone = false;

                  MyRouter.pop();

                  final controller = Messenger.alertAction(
                    msg: "Sending email",
                    color: Colors.green,
                    actionLabel: "UNDO",
                    onAction: () {
                      undone = true;
                      MyRouter.push(
                        screen: ComposeScreen(
                          draftData: draftData,
                          initialAttachments: restoredAttachments,
                          mailboxId: widget.mailboxId,
                          draftId: widget.draftId,
                        ),
                      );
                    },
                    duration: const Duration(seconds: 2),
                  );

                  controller?.closed.then((_) {
                    if (undone) return;
                    final ctx = MyRouter.navigatorKey.currentContext;
                    if (ctx == null) return;
                    ctx.read<SendMailBloc>().add(sendRequest);
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String result) {
                  switch (result) {
                    case "save_draft":
                      _saveDraft();
                      break;

                    case "discard":
                      // MyRouter.pop();
                      break;

                    case "show_suggestions":
                      _showSuggestions();
                      break;

                    case "schedule_send":
                      _scheduleSend();
                      break;

                    case "add_from_contacts":
                      _addFromContacts();
                      break;

                    case "confidential_mode":
                      _openConfidentialMode();
                      break;

                    case "settings":
                      _openSettings();
                      break;

                    case "help_feedback":
                      _openHelpFeedback();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: "save_draft",
                    child: Text("Save draft"),
                  ),
                  const PopupMenuItem(
                    value: "discard",
                    child: Text("Discard"),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: "show_suggestions",
                    child: Text("Show suggestions"),
                  ),
                  const PopupMenuItem(
                    value: "schedule_send",
                    child: Text("Schedule send"),
                  ),
                  const PopupMenuItem(
                    value: "add_from_contacts",
                    child: Text("Add from contacts"),
                  ),
                  const PopupMenuItem(
                    value: "confidential_mode",
                    child: Text("Confidential mode"),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: "settings",
                    child: Text("Settings"),
                  ),
                  const PopupMenuItem(
                    value: "help_feedback",
                    child: Text("Help & feedback"),
                  ),
                ],
              )
            ],
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<FatchnameBloc, FatchnameState>(
                listener: (context, state) {
                  if (state is FatchnameEmailLoaded) {
                    setState(() => fromEmail = state.email);
                  }
                },
              ),
              BlocListener<DraftBloc, DraftState>(
                listener: (context, state) {
                  if (state is DraftSaving) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("Saving draft..."),
                          ],
                        ),
                      ),
                    );
                  } else if (state is DraftSaved) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    // Refresh mailboxes to update draft count in drawer
                    context
                        .read<AppBarBloc>()
                        .add(FetchMailboxesEvent(force: true));

                    // 🔥 Trigger instant refresh of draft list
                    context.read<MailListBloc>().add(RefreshMailListEvent(
                        state.mailboxId)); // Use mailboxId from state

                    Messenger.alertSuccess("Draft saved successfully");
                    MyRouter.pop();
                  } else if (state is DraftError) {
                    Navigator.pop(context);

                    Messenger.alert(msg: "state.message");
                  }
                },
              ),
              BlocListener<SendMailBloc, SendMailState>(
                listener: (context, state) {
                  if (state is MailSending) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("Sending mail..."),
                          ],
                        ),
                      ),
                    );
                  } else if (state is MailSent) {
                    // Remove loading dialog
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    if (widget.draftId != null && widget.mailboxId != null) {
                      context.read<MailListBloc>().add(
                            RemoveMailFromListEvent(
                                widget.draftId!, widget.mailboxId!),
                          );
                    }

                    // Navigate back to the list screen (pop twice: Compose -> Detail -> List)
                    Navigator.pop(context); // Pop Compose
                    Navigator.pop(context); // Pop Detail
                  } else if (state is MailSendError) {
                    // Remove loading dialog
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    Messenger.alertError(state.error);
                  }
                },
              ),
            ],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSenderField(),
                  _buildEmailField("To", toCont, toEmails),
                  if (isExpanded) _buildCCBCCFields(),
                  const Divider(),
                  _buildSubjectField(),
                  const Divider(),
                  _buildBodyField(),
                  if (widget.mailDetail != null &&
                      widget.mailDetail!.html.isNotEmpty)
                    CollapsibleQuotedContent(
                      child: HtmlWidget(
                        widget.mailDetail!.html,
                        onTapUrl: (url) => launchUrl(Uri.parse(url)),
                      ),
                    ),
                  if (widget.mailDetail != null &&
                      widget.mailDetail!.html.isNotEmpty)
                    if (widget.mailDetail != null &&
                        widget.mailDetail!.attachments.isNotEmpty &&
                        widget.action == ComposeAction.forward)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Attachments from original message:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: widget.mailDetail!.attachments
                                .map((attachment) {
                              return AttachmentWidget(
                                attachment: attachment,
                                mailboxId: widget.mailboxId ?? '',
                                messageId:
                                    widget.mailDetail?.id.toString() ?? '',
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attachments.map((inline) {
                        final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(
                          inline.fileName.split('.').last.toLowerCase(),
                        );

                        return Chip(
                          avatar: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: inline.isInline
                                      ? Image.file(
                                          File(inline.filePath),
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(inline.filePath),
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : Icon(
                                  getFileIcon(inline.fileName),
                                  size: 20,
                                ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  inline.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (inline.isInline)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.image,
                                      size: 16, color: Colors.orange),
                                ),
                            ],
                          ),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              attachments.remove(inline);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          )),
    );
  }

  void _flushPendingEmail(
    TextEditingController controller,
    List<String> emailList,
  ) {
    final value = controller.text.trim();

    if (value.isNotEmpty && !emailList.contains(value)) {
      emailList.add(value);
      controller.clear();
    }
  }

  Widget _buildSenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('From', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(fromEmail ?? "Loading...",
                style: const TextStyle(color: AppColors.secondaryText)),
          ],
        ),
        const Divider(),
      ],
    );
  }

  void _showSuggestions() {
    debugPrint("Show suggestions clicked");
  }

  void _scheduleSend() {
    debugPrint("Schedule send clicked");
  }

  void _addFromContacts() {
    debugPrint("Add from contacts clicked");
  }

  void _openConfidentialMode() {
    debugPrint("Confidential mode clicked");
  }

  void _openSettings() {
    debugPrint("Settings clicked");
  }

  void _openHelpFeedback() {
    debugPrint("Help & feedback clicked");
  }

  Widget _buildEmailField(
    String label,
    TextEditingController controller,
    List<String> emailList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),

                /// 🔹 NEW: space / comma / enter → chip
                onChanged: (value) {
                  _handleTypedEmail(value, controller, emailList);

                  if (value.isNotEmpty) {
                    context
                        .read<EmailSuggestionsBloc>()
                        .add(FetchEmailSuggestions(value));
                    setState(() => showSuggestions = true);
                  }
                },

                /// 🔹 ENTER key support
                onFieldSubmitted: (_) {
                  _handleTypedEmail(
                      '${controller.text} ', controller, emailList);
                },
              ),
            ),
            IconButton(
              icon: Icon(
                isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: AppColors.iconDefault,
              ),
              onPressed: () => setState(() => isExpanded = !isExpanded),
            ),
            IconButton(
              icon: const Icon(
                Icons.contacts,
                color: AppColors.iconActive,
                size: 20,
              ),
              onPressed: () {
                MyRouter.push(screen: ContactsScreen());
              },
            ),
          ],
        ),

        /// 🔹 EMAIL CHIPS (OLD UI – UNCHANGED)
        Wrap(
          spacing: 4.0,
          runSpacing: 2.0,
          children: [
            ...emailList.take(3).map(
                  (email) => Chip(
                    avatar: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.profile,
                      child: Text(
                        _getInitial(email),
                        style: const TextStyle(
                          color: AppColors.bg,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(email),
                    onDeleted: () => setState(() => emailList.remove(email)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(
                        color: AppColors.secondaryText,
                        width: 1.0,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),

            /// 🔹 +N MORE CHIP (OLD LOGIC)
            if (emailList.length > 3)
              GestureDetector(
                onTap: () => _showEmailDialog(context, emailList),
                child: Chip(
                  label: Text(
                    '+${emailList.length - 3}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(
                      color: AppColors.secondaryText,
                      width: 1.0,
                    ),
                  ),
                  backgroundColor: AppColors.bg,
                  elevation: 0,
                ),
              ),
          ],
        ),

        /// 🔹 EMAIL SUGGESTIONS (OLD LOGIC – UNCHANGED)
        if (showSuggestions)
          BlocBuilder<EmailSuggestionsBloc, EmailSuggestionsState>(
            builder: (context, state) {
              if (state is EmailSuggestionsLoading) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                );
              } else if (state is EmailSuggestionsLoaded) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.suggestions.length,
                  itemBuilder: (context, index) {
                    final User user = state.suggestions[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.profile,
                        child: Text(
                          user.userName.isNotEmpty
                              ? user.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: AppColors.bg),
                        ),
                      ),
                      title: Text(user.userName),
                      subtitle: Text(user.email),
                      onTap: () {
                        _addEmail(user.email, emailList, controller);
                        setState(() => showSuggestions = false);
                      },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _handleTypedEmail(
    String value,
    TextEditingController controller,
    List<String> emailList,
  ) {
    if (value.endsWith(' ') || value.endsWith(',') || value.endsWith('\n')) {
      final email = value.replaceAll(',', '').trim();

      if (email.isNotEmpty && !emailList.contains(email)) {
        if (_isValidEmail(email)) {
          setState(() {
            emailList.add(email);
            controller.clear();
            showSuggestions = false;
          });
        } else {
          Messenger.alertError("Invalid email: $email");
        }
      }
    }
  }

  void _showEmailDialog(BuildContext context, List<String> emailList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Emails'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: emailList.map((email) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.bg,
                    child: Text(
                      _getInitial(email),
                      style: const TextStyle(
                        color: AppColors.bg,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(email),
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.delete, color: AppColors.iconDefault),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => emailList.remove(email));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getInitial(String email) {
    // Extracts the first letter before '@' or the first character
    if (email.contains('@')) {
      return email.split('@').first[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  Widget _buildCCBCCFields() {
    return Column(
      children: [
        _buildCCBCCField("Cc", ccCont, ccEmails),
        _buildCCBCCField("Bcc", bccCont, bccEmails),
      ],
    );
  }

  Widget _buildCCBCCField(
    String label,
    TextEditingController controller,
    List<String> emailList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),

                /// 🔹 same behavior as TO
                onChanged: (value) {
                  _handleTypedEmail(value, controller, emailList);

                  if (value.isNotEmpty) {
                    context
                        .read<EmailSuggestionsBloc>()
                        .add(FetchEmailSuggestions(value));
                    setState(() => showSuggestions = true);
                  }
                },

                onFieldSubmitted: (_) {
                  _handleTypedEmail(
                    '${controller.text} ',
                    controller,
                    emailList,
                  );
                },
              ),
            ),
          ],
        ),

        /// 🔹 CC / BCC CHIPS (SAME AS TO)
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: emailList.map((email) {
            return Chip(
              avatar: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.profile,
                child: Text(
                  _getInitial(email),
                  style: const TextStyle(
                    color: AppColors.bg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              label: Text(email),
              onDeleted: () {
                setState(() => emailList.remove(email));
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(
                  color: AppColors.secondaryText,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
      controller: subjectCont,
      decoration: const InputDecoration(
          hintText: 'Subject',
          border: InputBorder.none,
          fillColor: AppColors.headingText),
      onChanged: (_) => _onTextChanged(),
    );
  }

  Widget _buildBodyField() {
    return TextFormField(
      controller: composeMailCont,
      focusNode: _bodyFocusNode,
      minLines: 5,
      maxLines: 100,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
          hintText: 'Compose email',
          border: InputBorder.none,
          fillColor: AppColors.headingText),
      onChanged: (_) => _onTextChanged(),
    );
  }
}
