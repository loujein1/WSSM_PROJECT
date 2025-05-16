import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';

class SignUpScreenTopImage extends StatelessWidget {
  const SignUpScreenTopImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: defaultPadding * 2),
        const Text(
          "SIGN UP",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: SvgPicture.asset(
                "assets/icons/signup.svg",
                height: 240,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
} 