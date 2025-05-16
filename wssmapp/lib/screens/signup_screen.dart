// signup_screen.dart

import 'package:flutter/material.dart';
import '../responsive.dart';
import '../components/background.dart';
import 'components/signup_form.dart';
import 'components/signup_screen_top_image.dart';
import '../constants.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Background(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileSignupScreen(),
          desktop: Row(
            children: [
              Expanded(child: SignUpScreenTopImage()),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 450,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: SignUpForm(),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MobileSignupScreen extends StatelessWidget {
  const MobileSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SignUpScreenTopImage(),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: SignUpForm(),
        ),
      ],
    );
  }
}
