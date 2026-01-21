import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';

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
  const GroupContactList({
    super.key,
    required this.groupId,
    required this.conversionId,
    required this.initialFavourite,
  });

  final String groupId;
  final String conversionId;
  final bool initialFavourite;

  @override
  State<GroupContactList> createState() => _GroupContactListState();
}

class _GroupContactListState extends State<GroupContactList> {
  String _uid = '';

  late bool _isFavourite;
  bool _favInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUid();

    _isFavourite = widget.initialFavourite;
    _favInitialized = true;

    SocketService().setOnFavouriteUpdated(
      ({required String conversationId, required bool isFavourite}) {
        if (conversationId == widget.conversionId && mounted) {
          setState(() {
            _isFavourite = isFavourite;
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant GroupContactList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.groupId != widget.groupId) {
      _favInitialized = false;
    }
  }

  Future<void> _loadUid() async {
    final uid = await UserPreferences.getUserId() ?? '';
    if (!mounted) return;
    setState(() {
      _uid = uid;
    });
  }

  @override
  void dispose() {
    /// cleanup
    SocketService().setOnFavouriteUpdated(({
      required String conversationId,
      required bool isFavourite,
    }) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading || _uid.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ContactLoaded) {
          final contacts = state.contacts;

// ⬇️ ADD THIS BLOCK
          final members = contacts.first.groupMembers;

// 1️⃣ Separate admins & non-admins
          final adminMembers = members.where((m) => m.isAdmin == true).toList();
          final normalMembers =
              members.where((m) => m.isAdmin != true).toList();

// 2️⃣ Optional: keep "You" at correct place
          final myId = _uid;

// Remove "me" temporarily
          final meAdmin =
              adminMembers.where((m) => m.memberId == myId).toList();
          final meNormal =
              normalMembers.where((m) => m.memberId == myId).toList();

          adminMembers.removeWhere((m) => m.memberId == myId);
          normalMembers.removeWhere((m) => m.memberId == myId);

// 3️⃣ Final ordered list
          final sortedMembers = [
            ...meAdmin, // you (admin) first
            ...adminMembers, // other admins
            ...meNormal, // you (normal)
            ...normalMembers, // others
          ];

          if (contacts.isEmpty) {
            return const Center(child: Text('No contacts found.'));
          }

          /// ✅ INIT favourite ONCE FROM API (FIX)
          if (!_favInitialized) {
            _isFavourite = contacts.first.isFavourite;
            _favInitialized = true;
          }

          return Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.transparent),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final members = sortedMembers;
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
                          final member = entry.value;

                          final bool isAdmin = member.isAdmin ?? false;
                          final bool isMe = member.memberId == _uid;

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
                                  ? nameText
                                      .trim()
                                      .characters
                                      .first
                                      .toUpperCase()
                                  : 'U');

                          return GestureDetector(
                            onTap: isMe
                                ? () {}
                                : () {
                                    UserActionDialog.show(
                                      context,
                                      name: nameText,
                                      isAdmin: isAdmin,
                                      onMessage: () {
                                        MyRouter.push(
                                          screen: PrivateChatScreen(
                                            firstname: member.firstName,
                                            convoId: "",
                                            profileAvatarUrl: profileAvatarUrl,
                                            userName: nameText,
                                            lastSeen: "",
                                            datumId: member.memberId,
                                            sharedFiles: [],
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
                                            grpId: member.memberId ?? "",
                                            isGrp: false,
                                            reciverId: member.memberId ?? "",
                                            favourite: false,
                                          ),
                                        );
                                      },
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
                                                          "isAdmin": !isAdmin,
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
                              leading: CircleAvatar(
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
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      isMe ? 'You' : nameText,
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Group Admin',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                member.memberEmail ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              /// ✅ GROUP ACTION SHEET (LOGIC FIXED ONLY)
              GroupActionSheet(
                onAddToFavorites: () {
                  final next = !_isFavourite;

                  setState(() {
                    _isFavourite = next;
                  });
                  SocketService().emitFavorites(
                    conversationId: widget.conversionId,
                    isFavourite: next,
                  );
                },
                onAddToList: () {},
                onExitGroup: () {
                  context
                      .read<MediaBloc>()
                      .add(ExitGroup(grpId: widget.groupId));
                },
                onReportGroup: () {},
                isGroupChat: true,
                fullName: contacts.first.groupName,
                isFavorite: _isFavourite,
              ),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
