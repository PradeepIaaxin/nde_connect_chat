import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/socket_service.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_event.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_state.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_screen.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/custom_user_alert_dialog.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/group_action_sheet.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/private_chat_screen.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart' show ColorUtil;
import 'package:nde_email/utils/reusbale/common_import.dart';

class GroupContactList extends StatefulWidget {
  const GroupContactList({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupContactList> createState() => _GroupContactListState();
}

class _GroupContactListState extends State<GroupContactList> {
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final uid = await UserPreferences.getUserId() ?? '';
    if (!mounted) return;
    setState(() {
      _uid = uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading || _uid.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ContactLoaded) {
          final contacts = state.contacts;

          if (contacts.isEmpty) {
            return const Center(child: Text('No contacts found.'));
          }

          return Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const Divider(
                  color: Colors.transparent,
                ),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final members = contact.groupMembers;
                  final count = members.length;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$count Member${count == 1 ? '' : 's'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.search),
                            ),
                          ],
                        ),
                     
                        ...members.asMap().entries.map((entry) {
                          final i = entry.key;
                          final member = entry.value;

                          final bool isAdmin = member.isAdmin ?? false;

                          final bool isMe = member.memberId == _uid;
                          final bool isTargetAdmin = member.isAdmin ?? false;

                          final bool loggedUserIsAdmin =
                              contact.groupMembers.any(
                            (m) => m.memberId == _uid && (m.isAdmin ?? false),
                          );

                          final bool canManageMember =
                              loggedUserIsAdmin && !isMe;

                          final profileAvatarUrl =
                              (member.profilePic?.isNotEmpty ?? false)
                                  ? member.profilePic!
                                  : '';

                          final nameText =
                              "${member.firstName ?? ''} ${member.lastName ?? ''}"
                                  .trim();

                          final profileAvatar = profileAvatarUrl.isNotEmpty
                              ? profileAvatarUrl
                              : (nameText.isNotEmpty
                                  ? nameText[0].toUpperCase()
                                  : 'U');

                          return GestureDetector(
                            onTap: isMe
                                ? () {}
                                : () {
                                    UserActionDialog.show(
                                      context,
                                      name: nameText,
                                      isAdmin: isTargetAdmin,

                                      onMessage: () {
                                        MyRouter.push(
                                          screen: PrivateChatScreen(
                                            firstname: member.firstName,
                                            convoId: "",
                                            profileAvatarUrl: profileAvatarUrl,
                                            userName: nameText,
                                            lastSeen: "",
                                            datumId: member.memberId,
                                            grpChat: false,
                                            favourite: false,
                                          ),
                                        );
                                      },

                                      onView: () {
                                        MyRouter.push(
                                          screen: UserProfileScreen(
                                            profileAvatarUrl: profileAvatarUrl,
                                            userName: nameText,
                                            mailName: member.memberEmail ?? "",
                                            lastname: member.lastName,
                                            conversionalId:
                                                member.memberId ?? "",
                                            grpId: '',
                                            isGrp: false,
                                            reciverId: member.memberId ?? "",
                                            favourite: false,
                                          ),
                                        );
                                      },

                                      // ✅ SHOW ONLY IF LOGGED USER IS ADMIN & NOT SELF
                                      onToggleAdmin: canManageMember
                                          ? () {
                                              context.read<MediaBloc>().add(
                                                    MakeAdmin(
                                                      groupId: widget.groupId,
                                                      updates: [
                                                        {
                                                          "member_id":
                                                              member.memberId ??
                                                                  "",
                                                          "isAdmin":
                                                              !isTargetAdmin,
                                                        }
                                                      ],
                                                    ),
                                                  );
                                            }
                                          : null,

                                      onRemove: canManageMember
                                          ? () {
                                              context.read<MediaBloc>().add(
                                                    RemoveUserFromGroupEvent(
                                                      groupId: widget.groupId,
                                                      userId:
                                                          member.memberId ?? "",
                                                    ),
                                                  );
                                            }
                                          : null,

                                      onVerify: () {},
                                    );
                                  },
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: profileAvatarUrl.isEmpty
                                        ? ColorUtil.getColorFromAlphabet(
                                            profileAvatar)
                                        : Colors.transparent,
                                    backgroundImage: profileAvatarUrl.isNotEmpty
                                        ? NetworkImage(profileAvatarUrl)
                                        : null,
                                    child: profileAvatarUrl.isEmpty
                                        ? Text(
                                            profileAvatar,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable:
                                        SocketService().userStatusNotifier,
                                    builder: (context, val, _) {
                                      final isOnline = SocketService()
                                          .onlineUsers
                                          .contains(member.memberId);
                                      if (!isOnline) {
                                        return const SizedBox.shrink();
                                      }
                                      return Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              title: Text(
                                isMe ? 'You' : nameText, // ✅ FIX
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                member.role ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: isAdmin
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[700],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Group Admin',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              GroupActionSheet(
                onAddToFavorites: () {
                  final updatedFavourite = !contacts.first.isFavourite;
                  context.read<MediaBloc>().add(
                        ToggleFavourite(
                          targetId: widget.groupId,
                          isFavourite: updatedFavourite,
                          grp: true,
                        ),
                      );
                },
                onAddToList: () {},
                onExitGroup: () {
                  context.read<MediaBloc>().add(
                        ExitGroup(grpId: widget.groupId),
                      );
                },
                onReportGroup: () {},
                isGroupChat: true,
                fullName: contacts.first.groupName,
                isFavorite: contacts.first.isFavourite,
              ),
            ],
          );
        } else {
          return SizedBox();
        }
      },
    );
  }
}
