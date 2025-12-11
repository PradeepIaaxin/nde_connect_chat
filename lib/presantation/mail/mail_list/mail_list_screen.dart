import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/mail_list_widget/mail_list_widget.dart';
import 'mail_list_bloc.dart';
import 'mail_list_event.dart';
import 'mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';

class MailListScreen extends StatefulWidget {
  final String mailboxId;

  const MailListScreen({super.key, required this.mailboxId});

  @override
  State<MailListScreen> createState() => _MailListScreenState();
}

class _MailListScreenState extends State<MailListScreen> {
  late MailListBloc _mailListBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mailListBloc = context.read<MailListBloc>();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (["unread", "flagged", "all"].contains(widget.mailboxId)) {
        _mailListBloc.add(FetchFilteredMailEvent(widget.mailboxId));
      } else {
        _mailListBloc.add(FetchMailListEvent(widget.mailboxId));
      }
    });
  }

  void _onScroll() {
    final state = _mailListBloc.state;
    final position = _scrollController.position;

    if (state.nextCursor == null || state.isPaginating) {
      return;
    }

    if (position.pixels >= position.maxScrollExtent - 300 &&
        state.status == MailListStatus.loaded &&
        state.nextCursor?.isNotEmpty == true) {
      _mailListBloc.add(FetchMailListEvent(
        widget.mailboxId,
        cursor: state.nextCursor,
        isLoadMore: true,
      ));
    }
  }

  Future<void> _onRefresh() async {
    if (["unread", "flagged", "all"].contains(widget.mailboxId)) {
      _mailListBloc.add(FetchFilteredMailEvent(widget.mailboxId));
    } else {
      _mailListBloc.add(RefreshMailListEvent(widget.mailboxId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MailListBloc, MailListState>(
      listener: (context, state) {
        if (state.snackbarMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.snackbarMessage!)),
          );
        }
      },
      child: BlocBuilder<MailListBloc, MailListState>(
        builder: (context, state) {
          if (state.status == MailListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MailListStatus.loaded ||
              state.status == MailListStatus.refreshing) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: MailListWidget(
                mails: state.mails,
                mailboxId: widget.mailboxId,
                controller: _scrollController,
                itemCount: state.mails.length + (state.isPaginating ? 1 : 0),
                physics: const AlwaysScrollableScrollPhysics(),
                isPaginating: state.isPaginating,
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
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/empty_mailbox.png',
                              width: 350),
                          const SizedBox(height: 6),
                          const Text(
                            "Your inbox is empty",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "All incoming requests will be listed here.",
                            style: TextStyle(
                                fontSize: 16, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
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
                    type: ErrorType.Somethingwrong,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please try again later.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
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
