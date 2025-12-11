import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'floating_action_bloc.dart';
import 'floating_action_state.dart';




class FloatingActionButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingActionButtonWidget({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FabBloc, FabState>(
      builder: (context, state) {
        if (state is FabVisible && state.isVisible) {
          return FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: const Color.fromARGB(255, 3, 40, 162),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.create, color: Colors.white),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
