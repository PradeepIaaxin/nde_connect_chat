import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_event.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_state.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/online_user_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/usermedia_screen.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/group_action_sheet.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/group_contact_list.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/group_profile_header.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/grp_create_screen.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/GroupChatScreen.dart';
import 'package:nde_email/presantation/chat/contact_new_group/add_member_screen.dart';
import 'package:nde_email/presantation/chat/contact_new_group/new_group.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';

class UserProfileScreen extends StatefulWidget {
  final String profileAvatarUrl;
  final String userName;
  final String mailName;
  final String? country;
  final String? lastname;
  final String conversionalId;
  final String? grpId;
  final bool isGrp;
  final String reciverId;
  final bool favourite;

  final bool hasLeftGroup;

  const UserProfileScreen(
      {super.key,
      required this.profileAvatarUrl,
      required this.userName,
      required this.mailName,
      this.country,
      this.lastname,
      required this.conversionalId,
      this.grpId,
      required this.isGrp,
      required this.reciverId,
      required this.favourite,
      this.hasLeftGroup = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final String fullName;
  late final MediaBloc _mediaBloc;
  bool _isFavourite = false;
  bool _favInitialized = false;

  @override
  void initState() {
    super.initState();
    fullName = '${widget.userName} ${widget.lastname ?? ''}'.trim();
    _mediaBloc = context.read<MediaBloc>();

    logConversationDetails(
      profileAvatarUrl: widget.profileAvatarUrl,
      userName: widget.userName,
      mailName: widget.mailName,
      country: widget.country,
      lastname: widget.lastname,
      conversionalId: widget.conversionalId,
      grpId: widget.grpId,
      isGrp: widget.isGrp,
      reciverId: widget.reciverId,
      favourite: widget.favourite,
      hasLeftGroup: widget.hasLeftGroup,
    );

    SocketService().setOnFavouriteUpdated((
        {required String conversationId, required bool isFavourite}) {
      // ✅ compare by conversationId
      if (conversationId == widget.conversionalId) {
        log('⭐ Profile favourite updated via socket → $isFavourite');

        if (mounted) {
          setState(() {
            _isFavourite = isFavourite;
          });
        }
      }
    });

    _initializeData();
  }

  void _initializeData() {
    if (!widget.isGrp) {
      _mediaBloc.add(FetchgrpOrNot(recvId: widget.reciverId));
      log(widget.reciverId);
    } else {
      if (widget.grpId != null) {
        _mediaBloc.add(FetchContact(grpId: widget.grpId!));
        log(widget.reciverId);
      }
    }
  }

  @override
  void dispose() {
    SocketService().setOnFavouriteUpdated(({
      required String conversationId,
      required bool isFavourite,
    }) {});
    super.dispose();
  }

  void logConversationDetails({
    required String profileAvatarUrl,
    required String userName,
    required String mailName,
    String? country,
    String? lastname,
    required String conversionalId,
    String? grpId,
    required bool isGrp,
    required String reciverId,
    required bool favourite,
    required bool hasLeftGroup,
  }) {
    log('''
🧾 Conversation Details
-----------------------
profileAvatarUrl : $profileAvatarUrl
userName         : $userName
mailName         : $mailName
country          : ${country ?? 'N/A'}
lastname         : ${lastname ?? 'N/A'}
conversionalId   : $conversionalId
grpId            : ${grpId ?? 'N/A'}
isGrp            : $isGrp
reciverId        : $reciverId
favourite        : $favourite
hasLeftGroup     : $hasLeftGroup
-----------------------
''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') {
                MyRouter.push(
                  screen: GroupNameEditScreen(
                    initialValue: widget.userName,
                    keyToEdit: "group_name",
                    groupId: widget.grpId ?? "",
                    groupImage: widget.profileAvatarUrl,
                  ),
                );
              } else if (value == 'share') {
                // Handle share action
              } else if (value == 'edit') {
                // Handle edit action
              }
            },
            itemBuilder: (context) {
              if (widget.isGrp == true) {
                return const [
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      title: Text('Change Group name'),
                    ),
                  ),
                ];
              } else {
                return const [
                  PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      title: Text('Share'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      title: Text('Edit'),
                    ),
                  ),
                ];
              }
            },
          ),
        ],
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        final contact = state is ContactLoaded && state.contacts.isNotEmpty
            ? state.contacts.first
            : null;

        if (contact != null && !_favInitialized) {
          _isFavourite = contact.isFavourite;
          _favInitialized = true;
        }

        final displayName = contact?.groupName ?? widget.userName;
        final avatar = contact?.groupAvatar ?? widget.profileAvatarUrl;

        return SingleChildScrollView(
          child: Column(
            children: [
              GroupProfileHeader(
                groupId: widget.grpId ?? "",
                profileAvatarUrl: avatar,
                userName: displayName,
                mailName: widget.mailName,
                fullName: displayName,
                grpChat: widget.isGrp,
                groupMembers: contact?.groupMembers.map((m) {
                      return ChatUserlist(
                        userId: m.memberId ?? "",
                        firstName: m.firstName ?? "",
                        lastName: m.lastName ?? "",
                        email: m.memberEmail ?? '',
                        conversationId: widget.conversionalId,
                        profilePic: m.profilePic ?? '',
                      );
                    }).toList() ??
                    [],
                onAddMember: () async {
                  final bool? added = await MyRouter.push(
                    screen: AddMembersScreen(
                      groupId: widget.grpId!,
                      isAdmin: true,
                      groupMembers: contact?.groupMembers.map((m) {
                            return ChatUserlist(
                              userId: m.memberId ?? "",
                              firstName: m.firstName ?? "",
                              lastName: m.lastName ?? "",
                              email: m.memberEmail ?? '',
                              conversationId: widget.conversionalId,
                              profilePic: m.profilePic ?? '',
                            );
                          }).toList() ??
                          [],
                    ),
                  );

                  if (added == true) {
                    _mediaBloc.add(FetchContact(grpId: widget.grpId!));
                  }
                },
              ),
              _buildUserInfoSection(),
              if (!widget.isGrp) _buildCommonGroupsSection(),
              if (widget.isGrp && widget.grpId != null)
                GroupContactList(
                  groupId: widget.grpId!,
                  conversionId: widget.conversionalId,
                  initialFavourite: widget.favourite,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommonGroupsSection() {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CommonDataLoaded) {
          return _buildCommonGroupsList(state.commongrp);
        } else if (state is MediaError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Please try again later',
              style: const TextStyle(color: Colors.black),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCommonGroupsList(List<OnlineUserModel> groupModelList) {
    final allUsers =
        groupModelList.expand((model) => model.sharedGroups).toList();

    final isCurrentlyFavourite = _isFavourite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 9, top: 8),
          child: Text(
            allUsers.isEmpty
                ? "No users found in common groups"
                : "${allUsers.length} Group${allUsers.length > 1 ? 's' : ''} in common",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildCreateGroupTile(),
        ...allUsers.map((user) => _buildUserTile(user)).toList(),
        GroupActionSheet(
          onAddToFavorites: () async {
            final next = !_isFavourite;

            setState(() {
              _isFavourite = next;
            });

            SocketService().emitFavorites(
              conversationId: widget.conversionalId,
              isFavourite: next,
            );
          },
          onAddToList: () => debugPrint('List pressed'),
          onExitGroup: () {
            if (widget.grpId != null) {
              _mediaBloc.add(ExitGroup(grpId: widget.grpId!));
            }
          },
          onReportGroup: () => debugPrint('Report pressed'),
          isGroupChat: widget.isGrp,
          fullName: fullName,
          isFavorite: isCurrentlyFavourite,
        ),
      ],
    );
  }

  Widget _buildUserTile(SharedGroupModel group) {
    final List<SampleMember> members = group.sampleMembers;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: group.groupAvatar.isEmpty
            ? ColorUtil.getColorFromAlphabet(
                group.groupName.isNotEmpty ? group.groupName.trim() : 'A',
              )
            : Colors.transparent,
        child: group.groupAvatar.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  group.groupAvatar,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      group.groupName.isNotEmpty
                          ? group.groupName
                              .trim()
                              .characters
                              .first
                              .toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    );
                  },
                ),
              )
            : Text(
                group.groupName.isNotEmpty
                    ? group.groupName.trim().characters.first.toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
      ),
      title: Text(
        group.groupName,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              members
                  .map((member) =>
                      "${member.firstName} ${member.lastName}".trim())
                  .join(', '),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: () {
        final SampleMember? firstMember =
            members.isNotEmpty ? members.first : null;

        MyRouter.push(
          screen: GroupChatScreen(
            groupName: group.groupName,
            conversationId: group.id,
            datumId: group.id,
            favorite: false,
            grpChat: true,
            currentUserId: firstMember?.lastName ?? '',
            groupAvatarUrl: group.groupAvatar,
            groupMembers: [],
            groupId: group.id,
          ),
        );
      },
    );
  }

  Widget _buildCreateGroupTile() {
    return ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.group_add, color: Colors.white),
        ),
        title: Text(
          "Create group with $fullName",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          print(widget.reciverId);
          final currentUser = ChatUserlist(
              userId: widget.reciverId,
              firstName: widget.userName,
              lastName: widget.lastname ?? "",
              email: widget.mailName,
              conversationId: widget.conversionalId,
              profilePic: widget.profileAvatarUrl);
          MyRouter.push(
              screen: NewGroup(
            isCreating: true,
            initialSelectedUsers: [currentUser],
          ));
        });
  }

  Widget _buildUserInfoSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: Column(
        children: [
          _buildInfoTile('Status', 'Offline'),
          _buildInfoTile('Email', widget.mailName),
          _buildInfoTile(
              'Local time', DateFormat('hh:mm a').format(DateTime.now())),
          _buildMediaTile(),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMediaTile() {
    return ListTile(
      onTap: () => MyRouter.push(
        screen: UsermediaScreen(
          username: fullName,
          userId: widget.conversionalId,
        ),
      ),
      title: const Text(
        'Media, links, and docs',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
