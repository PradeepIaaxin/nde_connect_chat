import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/login/login_api.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'login_screen_bloc.dart';
import 'login_screen_event.dart';
import 'login_screen_state.dart';
import 'password_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
        body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.success) {
            MyRouter.push(
              screen: PasswordScreen(
                email: emailController.text.trim(),
              ),
            );
            context.read<LoginBloc>().add(LoginStatusReset());
          } else if (state.status == LoginStatus.errorScreen) {
            Messenger.alert(msg: state.message);
            context.read<LoginBloc>().add(LoginStatusReset());
          }
        },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/login_logo.svg',
              ),
              const SizedBox(height: 35),
              BlocBuilder<LoginBloc, LoginState>(
                buildWhen: (previous, current) =>
                      previous.email != current.email ||
                      previous.status != current.status,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          label: RichText(
                            text: const TextSpan(
                              text: "Enter your email address",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: "*",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          hintText: "Email",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 12.0,
                          ),
                          suffixIcon: emailController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.grey),
                                  onPressed: () {
                                    emailController.clear();
                                    context
                                        .read<LoginBloc>()
                                        .add(EmailChanged(email: ''));
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          context
                              .read<LoginBloc>()
                              .add(EmailChanged(email: value));
                        },
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ElevatedButton(
                          onPressed:state.status == LoginStatus.loading
                                ? null
                                : () {
                                    final email = emailController.text.trim();
                                    if (email.isEmpty) {
                                      Messenger.alert(
                                          msg: "Please enter your email");
                                    } else if (!isValidEmail(email)) {
                                      Messenger.alert(
                                          msg:
                                              "Please enter a valid email address.");
                                    } else {
                                      context
                                          .read<LoginBloc>()
                                          .add(EmailSubmit(email: email));
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF4752EB),
                            foregroundColor: Colors.white,
                          ),
                          child: state.status == LoginStatus.loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Next"),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
        )
    );
  }
}
