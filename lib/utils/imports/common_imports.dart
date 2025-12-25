export 'dart:developer';

export 'package:flutter_bloc/flutter_bloc.dart';
export 'package:flutter_downloader/flutter_downloader.dart';
export 'package:hive/hive.dart';
export 'package:hive_flutter/adapters.dart';
export 'package:permission_handler/permission_handler.dart';
export 'package:shared_preferences/shared_preferences.dart';

// Constants & Utilities
export 'package:nde_email/utils/const/consts.dart';
export 'package:nde_email/utils/router/router.dart';
export 'package:nde_email/utils/snackbar/snackbar.dart';

// Screens
export 'package:nde_email/splachscreen.dart';
export 'package:nde_email/presantation/home/home_screen.dart';
export 'package:nde_email/presantation/login/carousel_screen.dart';
export 'package:nde_email/presantation/login/login_api.dart';
export 'package:nde_email/presantation/login/login_screen_bloc.dart';

// Calendar

export 'package:nde_email/presantation/calender/data/calender_event_repo.dart';
export 'package:nde_email/presantation/calender/data/task_event_repo.dart';

// Chat
export 'package:nde_email/presantation/chat/chat_list/chat_bloc.dart';
export 'package:nde_email/presantation/chat/chat_list/chat_api.dart';
export 'package:nde_email/presantation/chat/chat_contact_list/UserService.dart';
export 'package:nde_email/presantation/chat/chat_contact_list/user_list_bloc.dart';
export 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
export 'package:nde_email/presantation/chat/chat_group_Screen/api_servicer.dart';
export 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
export 'package:nde_email/presantation/chat/chat_private_screen/messager_api_service.dart';
export 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
export 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
export 'package:nde_email/presantation/chat/Socket/socket_service.dart';

// Mail
export 'package:nde_email/presantation/mail/compose/api_service.dart';
export 'package:nde_email/presantation/mail/compose/fatchname_bloc.dart';
export 'package:nde_email/presantation/mail/compose/save_draft_bloc.dart';
export 'package:nde_email/presantation/mail/compose/send_mail_bloc.dart';
export 'package:nde_email/presantation/mail/mail_list/mail_list_bloc.dart';
export 'package:nde_email/presantation/mail/mail_list/mail_list_api.dart';
export 'package:nde_email/presantation/mail/mail_detail/mail_detail_bloc.dart';
export 'package:nde_email/presantation/mail/mail_detail/mail_detail_api.dart';
export 'package:nde_email/presantation/mail/tosection/email_suggestions_bloc.dart';
export 'package:nde_email/presantation/mail/tosection/email_suggestions_api.dart';
export 'package:nde_email/presantation/mail/socket/websocket_bloc.dart';
export 'package:nde_email/presantation/mail/socket/websocket_event.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_event.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottam_nav_bloc.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_bloc.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/mail_list_widget/loading.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/app_bar/fatchmail_boxes_api.dart';

// Drive
export 'package:nde_email/presantation/drive/Bloc/file_action/file_action_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/file_bloc/my_drive_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/file_bloc/drive_local_storage.dart';
export 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_event.dart';
export 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfo_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfo_event.dart';
export 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_folder_bloc.dart';
export 'package:nde_email/domain/sockets/mail_socket/nottification.dart';
export 'package:nde_email/domain/sockets/mail_socket/socket.dart';
export 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
export 'package:nde_email/presantation/calender/bloc/task_bloc/task_bloc.dart';
export 'package:nde_email/presantation/call/call_bloc.dart';
export 'package:nde_email/presantation/call/call_event.dart';
export 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_bloc.dart';
export 'package:nde_email/presantation/chat/chat_%20userprofile_screen/data/view_deatilsrepo.dart';
export 'package:nde_email/presantation/chat/chat_list/chat_event.dart';
export 'package:nde_email/presantation/drive/Bloc/home_bloc/sugesstion/sugesstion_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/move/move_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/recent_bloc/recent_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/send/send_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_bloc.dart';
export 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_local.dart';
export 'package:nde_email/presantation/drive/Bloc/starred_bloc/stared_local.dart';
export 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_bloc.dart';
export 'package:nde_email/presantation/drive/data/info_repository.dart';
export 'package:nde_email/presantation/drive/data/insidefile_repo.dart';
export 'package:nde_email/presantation/drive/data/my_drive_repository.dart';
export 'package:nde_email/presantation/drive/data/recent_repo.dart';
export 'package:nde_email/presantation/drive/data/sharred_repository.dart';
export 'package:nde_email/presantation/drive/data/starred_reppo.dart';
export 'package:nde_email/presantation/drive/data/sugesstion_repository.dart';
export 'package:nde_email/presantation/drive/data/common_repo.dart';

export 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/message_ui.dart';
export 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/reaction_bar.dart';
export 'package:nde_email/presantation/chat/chat_private_screen/messager_model.dart';
export 'package:nde_email/presantation/chat/model/emoj_model.dart';
export 'package:nde_email/presantation/chat/widget/custom_appbar.dart';
export 'package:nde_email/presantation/chat/widget/scaffold.dart';
export 'package:nde_email/presantation/chat/widget/voicerec_ui.dart';
export 'package:nde_email/utils/imports/common_imports.dart';
export 'package:nde_email/utils/simmer_effect.dart/chat_simmerefect.dart';

export '../../../data/respiratory.dart';
export 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar.dart';
