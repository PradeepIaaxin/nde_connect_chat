  import 'dart:async';
  import 'package:bloc/bloc.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'fatchmail_boxes_api.dart';
  import 'mailbox_model.dart';
  import 'app_bar_event.dart';
  import 'app_bar_state.dart';




class AppBarBloc extends Bloc<AppBarEvent, AppBarState> {
  final FetchMailBoxesApi apiService;

  bool _hasFetched = false; 

  AppBarBloc(this.apiService) : super(AppBarLoading()) {
    on<FetchMailboxesEvent>(_onFetchMailboxes);
  }

  Future<void> _onFetchMailboxes(
      FetchMailboxesEvent event, Emitter<AppBarState> emit) async {
    if (_hasFetched && state is AppBarMailboxesLoaded) {
      
      return;
    }

    emit(AppBarLoading());

    try {
      final List<Mailbox> mailboxes = await apiService.fetchMailboxes();

      if (mailboxes.isEmpty) {
        emit(AppBarMailboxesLoaded(
          inbox: [], archive: [], drafts: [],
          junk: [], sent: [], trash: [], other: [],
        ));
        _hasFetched = true;
        return;
      }

      final inbox = <Mailbox>[];
      final archive = <Mailbox>[];
      final drafts = <Mailbox>[];
      final junk = <Mailbox>[];
      final sent = <Mailbox>[];
      final trash = <Mailbox>[];
      final other = <Mailbox>[];


      for (var mailbox in mailboxes) {
        String normalizedName = mailbox.name.toLowerCase();
        if (normalizedName.contains("inbox")) {
          inbox.add(mailbox);
        } else if (normalizedName.contains("archive")) {
          archive.add(mailbox);
        } else if (normalizedName.contains("draft")) {
          drafts.add(mailbox);
        } else if (normalizedName.contains("junk") || normalizedName.contains("spam")) {
          junk.add(mailbox);
        } else if (normalizedName.contains("sent")) {
          sent.add(mailbox);
        } else if (normalizedName.contains("trash") || normalizedName.contains("deleted")) {
          trash.add(mailbox);
        } else {
          other.add(mailbox);
        }
      }

      emit(AppBarMailboxesLoaded(
        inbox: inbox, archive: archive, drafts: drafts,
        junk: junk, sent: sent, trash: trash, other: other,
      ));


      _hasFetched = true; 
    } catch (e) {
      if (e.toString().contains("Unauthorized")) {
        emit(AppBarUnauthorized());
      } else if (e.toString().contains("No internet")) {
        emit(AppBarNetworkError());
      } else {
        emit(AppBarError("Something went wrong."));
      }
    }
  }
}