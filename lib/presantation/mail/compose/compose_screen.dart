import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/presantation/contact/contact_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'send_mail_bloc.dart';
import 'send_mail_event.dart';
import 'fatchname_event.dart';
import 'fatchname_bloc.dart';
import 'fatchname_state.dart';
import 'save_draft_bloc.dart';
import 'save_dratf_event.dart';
import 'save_draft_state.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_state.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_bloc.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_event.dart';
import 'package:nde_email/presantation/mail/tosection/email_suggestions_model.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_model.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/attachment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:nde_email/presantation/mail/compose/upload_files_api.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

enum ComposeAction {
  reply,
  replyAll,
  forward,
}

class ComposeScreen extends StatefulWidget {
  final Map<String, dynamic>? draftData;
  final MailDetailModel? mailDetail;
  final ComposeAction? action;

  final String? mailboxId;

  ComposeScreen(
      {Key? key, this.draftData, this.mailDetail, this.mailboxId, this.action})
      : super(key: key);

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

  List<String> toEmails = [];
  List<String> ccEmails = [];
  List<String> bccEmails = [];
  List<UploadedAttachment> attachments = [];
  bool isExpanded = false;
  String? fromEmail;
  bool showSuggestions = false;
  File? _image;
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

  @override
  void initState() {
    super.initState();

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
    } else {
      _loadDraftData();
    }

    toCont.addListener(() {
      setState(() {
        showSuggestions = toCont.text.isNotEmpty;
      });
    });
  }

//  Future<void> _pickImage() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch $url';
    }
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

  void _onTextChanged() => setState(() {});

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
                "bcc": bccCont.text.isNotEmpty
                    ? [
                        {"address": bccCont.text}
                      ]
                    : [],
                "from": {"name": "Your Name", "address": fromEmail},
                "headers": [
                  {"key": "message-id", "value": ""}
                ],
                "to": toCont.text.isNotEmpty
                    ? [
                        {"address": toCont.text}
                      ]
                    : [],
                "cc": ccCont.text.isNotEmpty
                    ? [
                        {"address": ccCont.text}
                      ]
                    : [],
                "subject": subjectCont.text,
                "text": composeMailCont.text,
                "html": "<p>${composeMailCont.text}</p>",
              },
            ),
          );

      log(" Attachment data in draft: $attachmentIds");
    } else {
      Messenger.alert(msg: "Draft mailbox ID or sender email is missing");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showPopupMenu,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                if (fromEmail == null) {
                  Messenger.alert(msg: "Sender email not loaded. Please wait");

                  return;
                }

                String? draftMailboxId =
                    await MailboxStorage.getDraftsMailboxId();
                if (draftMailboxId == null || draftMailboxId.isEmpty) {
                  Messenger.alert(msg: "No drafts mailbox ID found");

                  return;
                }

                context.read<SendMailBloc>().add(SendMailRequest(
                      fromEmail: fromEmail!,
                      to: toCont.text,
                      subject: subjectCont.text,
                      body: composeMailCont.text,
                      cc: ccCont.text.isNotEmpty ? ccCont.text : null,
                      bcc: bccCont.text.isNotEmpty ? bccCont.text : null,
                    ));

                MyRouter.pop();
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String result) {
                if (result == "save draft") {
                  _saveDraft();
                } else if (result == "discard") {
                  MyRouter.pop();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                    value: "save draft", child: Text("Save Draft")),
                const PopupMenuItem<String>(
                    value: "discard", child: Text("Discard")),
              ],
            ),
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

                  Messenger.alertSuccess("Draft saved successfully");
                } else if (state is DraftError) {
                  Navigator.pop(context);

                  Messenger.alert(msg: "state.message");
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
                  HtmlWidget(
                    widget.mailDetail!.html,
                    onTapUrl: (url) => launchUrl(Uri.parse(url)),
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
                          children:
                              widget.mailDetail!.attachments.map((attachment) {
                            return AttachmentWidget(
                              attachment: attachment,
                              mailboxId: widget.mailboxId ?? '',
                              messageId: widget.mailDetail?.id.toString() ?? '',
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                //  _image != null
                //             ? Image.file(
                //                 _image!,
                //                 width: 250,
                //                 height: 250,
                //                 fit: BoxFit.cover,
                //               )
                //             : Center(child: Text("")),
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
                            Text(inline.fileName),
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
        ));
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

  Widget _buildEmailField(
      String label, TextEditingController controller, List<String> emailList) {
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
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    context
                        .read<EmailSuggestionsBloc>()
                        .add(FetchEmailSuggestions(value));
                    setState(() => showSuggestions = true);
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: AppColors.iconDefault),
              onPressed: () => setState(() => isExpanded = !isExpanded),
            ),
            IconButton(
              icon: const Icon(Icons.contacts,
                  color: AppColors.iconActive, size: 20),
              onPressed: () {
                MyRouter.push(screen: ContactsScreen());
              },
            ),
          ],
        ),
        Wrap(
          spacing: 4.0,
          runSpacing: 2.0,
          children: [
            ...emailList.take(3).map((email) => Chip(
                  avatar: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.profile,
                    child: Text(
                      _getInitial(email),
                      style: const TextStyle(
                          color: AppColors.bg,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
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
                )),
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
        if (showSuggestions)
          BlocBuilder<EmailSuggestionsBloc, EmailSuggestionsState>(
            builder: (context, state) {
              if (state is EmailSuggestionsLoading) {
                return const CircularProgressIndicator();
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
                              : '?',
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
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  Widget _buildCCBCCFields() {
    return Column(
      children: [
        _buildCCBCCField("Cc", ccCont),
        _buildCCBCCField("Bcc", bccCont),
      ],
    );
  }

  Widget _buildCCBCCField(String label, TextEditingController controller) {
    return Row(
      children: [
        /// 🛠️ Apply proper gray color with full opacity
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
            onChanged: (value) {
              context
                  .read<EmailSuggestionsBloc>()
                  .add(FetchEmailSuggestions(value));
            },
          ),
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
      onChanged: (value) => _onTextChanged(),
    );
  }

  Widget _buildBodyField() {
    return TextFormField(
      controller: composeMailCont,
      minLines: 5,
      maxLines: 100,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
          hintText: 'Compose email',
          border: InputBorder.none,
          fillColor: AppColors.headingText),
      onChanged: (value) => _onTextChanged(),
    );
  }
}

class UploadedAttachment {
  final String? id;
  final String fileName;
  final String filePath;
  final bool isInline;
  final String? mimeType;

  UploadedAttachment({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.isInline,
    this.mimeType,
  });
}