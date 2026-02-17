import 'package:nde_email/utils/reusbale/common_import.dart';

class MySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String hintText;
  final String? userName;
  final String? profilePicUrl;

  const MySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.userName,
    this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),

              /// ☰ MENU ICON (same UI)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),

              /// 🔍 TEXT FIELD
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search in $hintText',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              /// ❌ CLEAR BUTTON (UI only addition)
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged();
                    FocusScope.of(context).unfocus();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),

              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
