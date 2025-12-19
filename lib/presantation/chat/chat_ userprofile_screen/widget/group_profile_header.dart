import 'package:intl/intl.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_state.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/contact_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_image.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/grp_create_screen.dart';
import 'package:nde_email/presantation/chat/contact_new_group/add_member_screen.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class GroupProfileHeader extends StatelessWidget {
  final String groupId;
  final String profileAvatarUrl;
  final String userName;
  final String mailName;
  final String fullName;
  final bool grpChat;

  const GroupProfileHeader({
    super.key,
    required this.groupId,
    required this.profileAvatarUrl,
    required this.userName,
    required this.mailName,
    required this.fullName,
    required this.grpChat,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        final group = _getGroupFromState(state);
        final memberCount = _getMemberCount(group);

        // Use live group name from BLoC, fallback to props if not loaded yet
        final String currentGroupName = group?.groupName?.isNotEmpty == true
            ? group!.groupName!
            : (userName.isNotEmpty ? userName : fullName);

        final String displayLetter = currentGroupName.isNotEmpty
            ? currentGroupName[0].toUpperCase()
            : 'G';

        return Container(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileAvatar(context, displayLetter,currentGroupName ),
              const SizedBox(height: 16),
              _buildProfileTextInfo(currentGroupName),
              const SizedBox(height: 8),
              if (state is ContactLoaded) _buildMemberCountInfo(memberCount),
              const SizedBox(height: 16),
              _buildActionButtons(),
              if (group != null) _buildGroupInfoCard(group),
            ],
          ),
        );
      },
    );
  }

  ContactModel? _getGroupFromState(MediaState state) {
    if (state is! ContactLoaded) return null;
    return state.contacts.firstWhere(
      (contact) => contact.id == groupId,
      orElse: () => ContactModel(),
    );
  }

  int _getMemberCount(ContactModel? group) {
    if (group == null) return 0;
    return group.totalMembers ?? group.groupMembers.length;
  }

  Widget _buildProfileAvatar(BuildContext context, String displayLetter , String fullName) {
    return GestureDetector(
      onTap: () {
        MyRouter.push(
          screen: ViewImage(
            imageurl: profileAvatarUrl,
            username: fullName,
          ),
        );
      },
      child: CircleAvatar(
        radius: 60,
        backgroundColor: profileAvatarUrl.isEmpty
            ? ColorUtil.getColorFromAlphabet(displayLetter)
            : Colors.grey.shade300,
        child: profileAvatarUrl.isNotEmpty
            ? _buildNetworkAvatarImage(displayLetter)
            : _buildAvatarInitial(displayLetter),
      ),
    );
  }

  Widget _buildNetworkAvatarImage(String displayLetter) {
    return ClipOval(
      child: Image.network(
        profileAvatarUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => _buildAvatarInitial(displayLetter),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarInitial(String letter) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: ColorUtil.getColorFromAlphabet(letter),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 40,
        ),
      ),
    );
  }

  Widget _buildProfileTextInfo(String currentGroupName) {
    return Column(
      children: [
        Text(
          currentGroupName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          mailName,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCountInfo(int memberCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Group · ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '$memberCount Members',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.call,
            label: 'Audio',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.videocam,
            label: 'Video',
            onTap: () {},
          ),
          _buildActionButton(
            icon:
                grpChat == false ? Icons.currency_rupee : Icons.person_add_alt,
            label: grpChat == false ? 'Pay' : 'Add',
            onTap: () {
              MyRouter.push(
                screen: AddMembersScreen(
                  groupId: groupId,
                  isAdmin: true,
                ),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.search,
            label: 'Search',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          border: Border.all(
            color: isDisabled ? Colors.grey.shade200 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  isDisabled ? Colors.grey.shade400 : (iconColor ?? chatColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDisabled ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfoCard(ContactModel group) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                MyRouter.push(
                  screen: GroupNameEditScreen(
                    initialValue: group.description ?? "",
                    keyToEdit: "description",
                    groupId: groupId,
                    groupImage: group.groupAvatar,
                  ),
                );
              },
              child: Text(
                group.description?.isNotEmpty == true
                    ? group.description!
                    : "Add group description",
                style: const TextStyle(fontSize: 16, color: chatColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  group.createdBy != null
                      ? "Created by ${group.createdBy?.firstName ?? ''} ${group.createdBy?.lastName ?? ''}, ${_formatDate(group.createdAt ?? "")}"
                      : "Unknown",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return "Unknown date";
    }
  }
}
