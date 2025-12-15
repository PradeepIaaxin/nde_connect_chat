import 'package:nde_email/utils/reusbale/common_import.dart';

class PopupMenuItemModel {
  final String value;
  final String label;
  final IconData? icon;

  const PopupMenuItemModel({
    required this.value,
    required this.label,
    this.icon,
  }); 
}


class ReusablePopupMenu extends StatelessWidget {
  final List<PopupMenuItemModel> items;
  final ValueChanged<String> onSelected;

  const ReusablePopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      icon: const Icon(Icons.more_vert, color: Colors.black),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item.value,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18),
                  const SizedBox(width: 10),
                ],
                Text(item.label),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
