import 'package:equatable/equatable.dart';

abstract class DraftEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SaveDraftEvent extends DraftEvent {
  final String mailboxId;
  final Map<String, dynamic> draftData;

  SaveDraftEvent({required this.mailboxId, required this.draftData});

  @override
  List<Object?> get props => [mailboxId, draftData];
}
