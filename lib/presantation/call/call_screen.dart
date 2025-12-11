import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/call/call_bloc.dart';
import 'package:nde_email/presantation/call/call_event.dart';
import 'package:nde_email/presantation/call/call_state.dart';
import '../../utils/reusbale/colour_utlis.dart';
import '../../utils/const/consts.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallBloc _callBloc;

  String formatDate(String rawDate) {
    DateTime dateTime = DateTime.parse(rawDate).toLocal();
    return DateFormat('dd MMM, hh:mm a').format(dateTime);
  }

  Icon getCallIcon(String callType) {
    switch (callType) {
      case 'missed':
        return const Icon(Icons.call_received_outlined, color: Colors.red);
      case 'outgoing':
        return const Icon(Icons.call_made, color: Colors.green);
      case 'canceled':
        return const Icon(Icons.call_end, color: Colors.orange);
      default:
        return const Icon(Icons.call, color: Colors.grey);
    }
  }

  @override
  void initState() {
    super.initState();
    _callBloc = CallBloc()..add(FetchCallHistoryEvent());
  }

  @override
  void dispose() {
    _callBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _callBloc,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Calls"),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ],
        ),
        body: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            if (state is CallLoading || state is CallInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CallLoaded) {
              final callList = state.callHistory;

              if (callList.isEmpty) {
                return const Center(child: Text("No call history found."));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Recent Calls",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: callList.length,
                      itemBuilder: (context, index) {
                        final call = callList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                ColorUtil.getColorFromAlphabet(call.firstName),
                            child: Text(
                              call.firstName.isNotEmpty
                                  ? call.firstName[0]
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            "${call.firstName} ${call.lastName}",
                            style: TextStyle(
                              color: call.callType == "missed"
                                  ? Colors.red
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              getCallIcon(call.callType),
                              const SizedBox(width: 6),
                              Text(formatDate(call.callingTime)),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              // Add your redial logic
                            },
                            icon: const Icon(Icons.call),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is CallError) {
              return Center(child: Text('Error: ${state.message}'));
            } else {
              return const Center(child: Text("Unknown state"));
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _callBloc.add(FetchCallHistoryEvent()),
          backgroundColor: chatColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.add_ic_call_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
