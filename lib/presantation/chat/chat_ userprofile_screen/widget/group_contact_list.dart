import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_event.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_state.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_screen.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/custom_user_alert_dialog.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/group_action_sheet.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/Private_Chat_Screen.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart' show ColorUtil;
import 'package:nde_email/utils/reusbale/common_import.dart';

class GroupContactList extends StatefulWidget {
  const GroupContactList({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupContactList> createState() => _GroupContactListState();
}

class _GroupContactListState extends State<GroupContactList> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading) {
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
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final members = contact.groupMembers;
                  final count = members.length;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$count Member${count == 1 ? '' : 's'}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.search)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...members.asMap().entries.map((entry) {
                          final i = entry.key;
                          final member = entry.value;
                          final isAdmin = member.isAdmin ?? false;

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

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: GestureDetector(
                              onTap: i == 0
                                  ? () {}
                                  : () {
                                      log(nameText);
                                      log(member.firstName.toString());
                                      UserActionDialog.show(
                                        context,
                                        name:
                                            "${member.firstName ?? ''} ${member.lastName ?? ''}"
                                                .trim(),
                                        isAdmin: member.isAdmin ?? false,
                                        onMessage: () {
                                          MyRouter.push(
                                              screen: PrivateChatScreen(
                                                  firstname: member.firstName,
                                                  convoId: "",
                                                  profileAvatarUrl:
                                                      profileAvatarUrl,
                                                  userName: nameText,
                                                  lastSeen: "",
                                                  datumId: member.memberId,
                                                  grpChat: false,
                                                  favourite: false));
                                        },
                                        onView: () {
                                          print(member.memberId);
                                          MyRouter.push(
                                            screen: UserProfileScreen(
                                              profileAvatarUrl:
                                                  profileAvatarUrl,
                                              userName: nameText,
                                              mailName:
                                                  member.memberEmail ?? "",
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
                                        onToggleAdmin: () {
                                          final updatedIsAdmin =
                                              !(member.isAdmin ?? false);

                                          context.read<MediaBloc>().add(
                                                MakeAdmin(
                                                  groupId: widget.groupId,
                                                  updates: [
                                                    {
                                                      "member_id":
                                                          member.memberId ?? "",
                                                      "isAdmin": updatedIsAdmin,
                                                    }
                                                  ],
                                                ),
                                              );
                                        },
                                        onRemove: () {
                                          context.read<MediaBloc>().add(
                                                RemoveUserFromGroupEvent(
                                                  groupId: widget.groupId,
                                                  userId: member.memberId ?? "",
                                                ),
                                              );
                                        },
                                        onVerify: () =>
                                            debugPrint("Verify code"),
                                      );
                                    },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 22,
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
                                title: Text(
                                  i == 0 ? 'You' : nameText,
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
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[700],
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                            ),
                          );
                        }).toList(),
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
                          targetId: widget.groupId ?? "",
                          isFavourite: updatedFavourite,
                          grp: true,
                        ),
                      );
                },
                onAddToList: () => debugPrint('List pressed'),
                onExitGroup: () {
                  if (widget.groupId != null) {
                    context.read<MediaBloc>().add(
                          ExitGroup(grpId: widget.groupId),
                        );
                  }
                },
                onReportGroup: () => debugPrint('Report pressed'),
                isGroupChat: true,
                fullName: contacts.first.groupName,
                isFavorite: contacts.first.isFavourite,
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
