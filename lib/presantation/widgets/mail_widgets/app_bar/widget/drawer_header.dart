import 'package:nde_email/utils/reusbale/common_import.dart';

class DrawerHeaderWidget extends StatelessWidget {
  final String userName;
  final String moduleName; 

  const DrawerHeaderWidget({
    super.key,
    required this.userName,
    required this.moduleName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 👉 Name + App Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// USER NAME
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    /// APP + MODULE
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: "Nde ",
                            style: TextStyle(color: chatColor),
                          ),
                          TextSpan(
                            text: moduleName,
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// Divider
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}
