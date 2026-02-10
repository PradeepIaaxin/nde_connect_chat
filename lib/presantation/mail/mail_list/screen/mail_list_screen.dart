import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/mail_list_widget/mail_list_widget.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import '../bloc/mail_list_event.dart';
import '../bloc/mail_list_state.dart';
import '../../compose/bloc/send_mail_bloc/send_mail_bloc.dart';
import '../../compose/bloc/send_mail_bloc/send_mail_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:nde_email/utils/custom/custom_alret_box.dart';

class MailListScreen extends StatefulWidget {
  final String mailboxId;
  final String? mailboxName;

  const MailListScreen({super.key, required this.mailboxId, this.mailboxName});

  @override
  State<MailListScreen> createState() => _MailListScreenState();
}

class _MailListScreenState extends State<MailListScreen> {
  late MailListBloc _bloc;
  bool _canLoad = true;

  final ScrollController _controller = ScrollController();
  bool _isEmptyingBin = false;
  bool get _isTrashMailbox {
    final name = widget.mailboxName?.trim().toLowerCase() ?? '';
    return name == 'trash' || name == 'bin';
  }

  Future<void> _emptyBin() async {
    if (_isEmptyingBin) return;

    final result = await CustomConfirmationDialog.show(
      context: context,
      title: 'Empty bin?',
      message: 'This will permanently remove the Trash mailbox.',
      confirmText: 'Empty',
      onConfirm: () async {
        setState(() => _isEmptyingBin = true);
        try {
          final message =
              await FetchMailBoxesApi().deleteMailbox(widget.mailboxId);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        } finally {
          if (mounted) setState(() => _isEmptyingBin = false);
        }
      },
    );

    if (result == true && mounted) {
      MyRouter.pushNamedAndRemoveUntil('/home');
    }
  }

  Widget _trashActions({required bool show}) {
    if (!_isTrashMailbox || !show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Bin",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Color(0xFF0B57D0),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Items that have been in the bin for more than 30 days will be automatically deleted.",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: GestureDetector(
                    onTap: _isEmptyingBin ? null : _emptyBin,
                    child: Text(
                      "Empty Bin now",
                      style: TextStyle(
                        color: _isEmptyingBin
                            ? AppColors.secondaryText
                            : AppColors.profile,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emptyTitle() {
    final name = widget.mailboxName?.toLowerCase() ?? '';

    switch (name) {
      case 'inbox':
        return 'No inbox mails';

      case 'archive':
        return 'No archive mails';

      case 'drafts':
        return 'No draft mails';

      case 'junk':
      case 'spam':
        return 'No spam mails';

      case 'sent':
        return 'No sent mails';

      case 'trash':
      case 'bin':
        return 'No trash mails';

      default:
        break;
    }

    // FILTER VIEWS
    switch (widget.mailboxId) {
      case 'unread':
        return 'No unread mails';

      case 'flagged':
        return 'No starred mails';

      case 'all':
        return 'No mails yet';

      default:
        return 'No mails available';
    }
  }

  String _emptySubtitle() {
    final name = widget.mailboxName?.toLowerCase() ?? '';

    switch (name) {
      case 'inbox':
        return 'All incoming mails will appear here';

      case 'archive':
        return 'Archived mails will appear here';

      case 'drafts':
        return 'Saved drafts will appear here';

      case 'junk':
      case 'spam':
        return 'Spam mails will appear here';

      case 'sent':
        return 'Sent mails will appear here';

      case 'trash':
      case 'bin':
        return 'Deleted mails will appear here';

      default:
        break;
    }

    switch (widget.mailboxId) {
      case 'unread':
        return 'You’re all caught up 🎉';

      case 'flagged':
        return 'Starred mails will appear here';

      case 'all':
        return 'Incoming mails will appear here';

      default:
        return 'Mails will appear here';
    }
  }

  bool get _isFilteredView =>
      widget.mailboxId == 'unread' ||
      widget.mailboxId == 'flagged' ||
      widget.mailboxId == 'all';

  @override
  void initState() {
    super.initState();

    debugPrint("🟢 MailListScreen initState → ${widget.mailboxId}");

    _bloc = context.read<MailListBloc>();
    _controller.addListener(_onScroll);

    _load();
  }

  @override
  void didUpdateWidget(covariant MailListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mailboxId != widget.mailboxId) {
      debugPrint("🔁 Mailbox changed → ${widget.mailboxId}");
      _load();
    }
  }

  void _load() {
    if (!_canLoad || !mounted) {
      debugPrint("⛔ Load blocked (screen disposed)");
      return;
    }

    final state = _bloc.state;

    // 🚫 Do NOT fetch if app is logging out / bloc reset
    if (state.status == MailListStatus.loading &&
        state.mails.isEmpty &&
        state.nextCursor == null) {
      debugPrint("⛔ Load skipped — bloc resetting");
      return;
    }

    if (!_isFilteredView) {
      _bloc.add(ResetMailListEvent(widget.mailboxId));
    }

    _fetch();
  }

  void _fetch() {
    if (!_canLoad || !mounted) {
      debugPrint("⛔ Fetch blocked");
      return;
    }

    debugPrint("📡 FETCH → ${widget.mailboxId}");

    if (_isFilteredView) {
      _bloc.add(FetchFilteredMailEvent(widget.mailboxId));
    } else {
      _bloc.add(FetchMailListEvent(widget.mailboxId));
    }
  }

  void _onScroll() {
    final state = _bloc.state;

    if (state.nextCursor == null || state.isPaginating) return;

    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 300) {
      _bloc.add(
        FetchMailListEvent(
          widget.mailboxId,
          cursor: state.nextCursor,
          isLoadMore: true,
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    debugPrint("🔄 Pull-to-refresh triggered for ${widget.mailboxId}");

    // Clear cache for current mailbox to force fresh API fetch
    _bloc.add(ResetMailListEvent(widget.mailboxId));

    // Small delay to allow reset state to emit
    await Future.delayed(const Duration(milliseconds: 50));

    // Fetch fresh data from API
    _fetch();
  }

  @override
  void dispose() {
    _canLoad = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendMailBloc, SendMailState>(
      listener: (context, sendState) {
        if (sendState is MailSent) {
          debugPrint(
              "✅ Mail sent successfully! Refreshing list for $widget.mailboxId");

          // Trigger silent refresh to update UI without loading spinner
          _bloc.add(RefreshMailListEvent(widget.mailboxId));
        }
      },
      child: BlocBuilder<MailListBloc, MailListState>(
        builder: (context, state) {
          if (state.status == MailListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MailListStatus.loaded ||
              state.status == MailListStatus.refreshing) {
            final bool isSelectionActive = state.selectedMailIds.isNotEmpty;

            return isSelectionActive
                // ❌ NO REFRESH WHEN SELECTING
                ? Column(
                    children: [
                      _SelectAllCheckbox(state: state),
                      Expanded(
                        child: MailListWidget(
                          key: ValueKey(
                              "${widget.mailboxId}-${state.mails.length}"),
                          mails: state.mails,
                          mailboxId: widget.mailboxId,
                          controller: _controller,
                          itemCount:
                              state.mails.length + (state.isPaginating ? 1 : 0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          isPaginating: state.isPaginating,
                        ),
                      ),
                    ],
                  )

                // ✅ NORMAL MODE → REFRESH ENABLED
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: Column(
                      children: [
                        _trashActions(show: state.mails.isNotEmpty),
                        Expanded(
                          child: MailListWidget(
                            key: ValueKey(
                                "${widget.mailboxId}-${state.mails.length}"),
                            mails: state.mails,
                            mailboxId: widget.mailboxId,
                            controller: _controller,
                            itemCount: state.mails.length +
                                (state.isPaginating ? 1 : 0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            isPaginating: state.isPaginating,
                          ),
                        ),
                      ],
                    ),
                  );
          }

          if (state.status == MailListStatus.empty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/empty_mailbox.png',
                          width: 300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _emptyTitle(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _emptySubtitle(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.status == MailListStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ErrorDisplay(
                    message: state.errorMessage ?? 'Something went wrong',
                    type: ErrorType.somethingwrong,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SelectAllCheckbox extends StatelessWidget {
  final MailListState state;

  const _SelectAllCheckbox({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = state.mails.isNotEmpty &&
        state.selectedMailIds.length == state.mails.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.bg,
      child: Row(
        children: [
          Checkbox(
            value: isAllSelected,
            activeColor: chatColor,
            checkColor: Colors.white,
            side: const BorderSide(
              color: AppColors.secondaryText,
              width: 1.5,
            ),
            onChanged: (_) {
              if (isAllSelected) {
                context.read<MailListBloc>().add(ClearSelectionEvent());
              } else {
                context.read<MailListBloc>().add(SelectAllMailsEvent());
              }
            },
          ),
          const Text(
            "Select all",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}