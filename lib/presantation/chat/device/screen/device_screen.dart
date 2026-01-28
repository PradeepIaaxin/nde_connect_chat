import 'package:nde_email/presantation/chat/device/bloc/device_bloc.dart';
import 'package:nde_email/presantation/chat/device/bloc/device_event.dart';
import 'package:nde_email/presantation/chat/device/bloc/device_state.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  @override
  void initState() {
    super.initState();
    // 🔥 Call API
    context.read<LinkedDeviceBloc>().add(LoadLinkedDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            const Text("Linked devices", style: TextStyle(color: Colors.black)),
        leading: BackButton(color: Colors.black),
      ),
      body: BlocBuilder<LinkedDeviceBloc, LinkedDeviceState>(
        builder: (context, state) {
          print("DEVICE STATE = $state");

          // ================= LOADING =================
          if (state is LinkedDeviceLoading) {
            return const Center(
              child: CircularProgressIndicator(color: chatColor),
            );
          }

          // ================= ERROR =================
          if (state is LinkedDeviceError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // ================= SUCCESS =================
          if (state is LinkedDeviceLoaded) {
            final devices = state.devices;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/gif/LinkDevice.gif",
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),

                  // 🔥 DEVICE STATUS TITLE
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "DEVICE STATUS",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ================= EMPTY STATE =================
                  if (devices.isEmpty)
                    Column(
                      children: const [
                        SizedBox(height: 40),
                        Icon(Icons.devices_other, size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No linked devices found",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    )
                  else

                    // ================= DEVICE LIST =================
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final d = devices[index];

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(getDeviceIcon(d.deviceInfo.platform),
                                color: chatColor, size: 26),
                          ),
                          title: Text(
                            d.deviceInfo.platform.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Last active: ${d.lastSeenAt}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          // ================= DEFAULT =================
          return const Center(child: Text("No Data"));
        },
      ),
    );
  }

  // ================= DEVICE ICON =================
  IconData getDeviceIcon(String platform) {
    switch (platform.toLowerCase()) {
      case "web":
        return Icons.laptop;
      case "android":
        return Icons.phone_android;
      case "ios":
        return Icons.phone_iphone;
      case "windows":
        return Icons.desktop_windows;
      case "macos":
        return Icons.laptop_mac;
      default:
        return Icons.devices;
    }
  }
}
