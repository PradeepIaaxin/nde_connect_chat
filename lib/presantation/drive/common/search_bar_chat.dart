import 'package:nde_email/utils/reusbale/common_import.dart';

class MySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String hintText;

  const MySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.grey.shade100,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),

              /// 🔍 SEARCH ICON
              Icon(
                Icons.search,
                size: 20,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 10),

              /// ✏️ TEXT FIELD
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.2, // WhatsApp text baseline
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search in $hintText',
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: 14.5,
                      height: 1.2,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true, // IMPORTANT
                  ),
                ),
              ),

              /// ❌ CLEAR BUTTON
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged();
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
