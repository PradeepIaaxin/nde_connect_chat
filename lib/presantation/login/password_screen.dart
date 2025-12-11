import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/domain/error_pages/mail_error_pages/network_error.dart';
import 'package:nde_email/presantation/home/home_screen.dart';
import 'package:nde_email/utils/router/router.dart';
import 'login_screen_bloc.dart';
import 'login_screen_event.dart';
import 'login_screen_state.dart';
import 'package:nde_email/domain/error_pages/mail_error_pages/backend_error.dart';

class PasswordScreen extends StatefulWidget {
  final String email;

  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter =
        widget.email.isNotEmpty ? widget.email[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.success) {
            MyRouter.pushRemoveUntil(screen: HomeScreen());

            context.read<LoginBloc>().add(LoginStatusReset());
          } else if (state.status == LoginStatus.networkErrorScreen) {
            MyRouter.pushReplace(
              screen: ErrorWidgetCustom(
                errorMessage:
                    "No Internet Connection! Please check your network.",
              ),
            );

            context.read<LoginBloc>().add(LoginStatusReset());
          } else if (state.status == LoginStatus.backendErrorScreen) {
            MyRouter.pushReplace(
              screen: ErrorScreen(
                errorMessage: "Server Error! Please try again later.",
              ),
            );

            context.read<LoginBloc>().add(LoginStatusReset());
          } else if (state.status == LoginStatus.errorScreen) {
            MyRouter.pushReplace(
              screen: ErrorScreen(
                errorMessage: "An unexpected error occurred.",
              ),
            );

            context.read<LoginBloc>().add(LoginStatusReset());
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF4752EB),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ///  Welcome Text with Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome ",
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    Text(
                      widget.email,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                BlocBuilder<LoginBloc, LoginState>(
                  buildWhen: (previous, current) =>
                      previous.password != current.password,
                  builder: (context, state) {
                    return TextField(
                      controller: passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        label: RichText(
                          text: const TextSpan(
                            text: "Password",
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        hintText: "Password",
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 12.0,
                        ),
                      ),
                      onChanged: (value) {
                        context
                            .read<LoginBloc>()
                            .add(PasswordChanged(password: value));
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                /// Login Button with BLoC Consumer
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.status == LoginStatus.loading
                            ? null
                            : () {
                                context.read<LoginBloc>().add(
                                      LoginApi(
                                        email: widget.email,
                                        password: passwordController.text,
                                      ),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF2330E7),
                          foregroundColor: Colors.white,
                        ),
                        child: state.status == LoginStatus.loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Sign In"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
