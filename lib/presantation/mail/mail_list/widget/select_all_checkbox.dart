import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import '../../mail_list/bloc/mail_list_event.dart';
import '../../mail_list/bloc/mail_list_state.dart';

class SelectAllCheckbox extends StatelessWidget {
  final MailListState state;

  const SelectAllCheckbox({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected =
        state.mails.isNotEmpty &&
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
