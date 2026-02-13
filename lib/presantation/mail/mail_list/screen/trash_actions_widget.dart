import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class TrashActionsWidget extends StatelessWidget {
  final bool show;
  final bool isTrashMailbox;
  final bool isEmptyingBin;
  final VoidCallback? onEmptyBin;

  const TrashActionsWidget({
    super.key,
    required this.show,
    required this.isTrashMailbox,
    required this.isEmptyingBin,
    required this.onEmptyBin,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTrashMailbox || !show) {
      return const SizedBox.shrink();
    }

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
                  children: const [
                    Icon(
                      Icons.delete_outline,
                      color: Color(0xFF0B57D0),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
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
                    onTap: isEmptyingBin ? null : onEmptyBin,
                    child: Text(
                      "Empty Bin now",
                      style: TextStyle(
                        color: isEmptyingBin
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
}
