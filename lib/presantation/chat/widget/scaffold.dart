import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReusableChatScaffold extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final Widget chatBody;
  final Widget voiceRecordingUI;
  final Widget Function(bool isKeyboardVisible) messageInputBuilder;
  final bool isRecording;
  final BlocBase bloc;

  const ReusableChatScaffold({
    super.key,
    required this.appBar,
    required this.chatBody,
    required this.voiceRecordingUI,
    required this.messageInputBuilder,
    required this.isRecording,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 248, 250),
        resizeToAvoidBottomInset: true,
        appBar: appBar,
        body:
            //  Column(
            //   children: [
            //     Expanded(child: chatBody),
            //     isRecording
            //         ? voiceRecordingUI
            //         : messageInputBuilder(isKeyboardVisible),
            //   ],
            // ),

            Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgback.png',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                Expanded(child: chatBody),
                isRecording
                    ? voiceRecordingUI
                    : messageInputBuilder(isKeyboardVisible),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
