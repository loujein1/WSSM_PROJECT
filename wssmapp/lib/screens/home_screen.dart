import 'package:flutter/material.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Image en haut à droite
            Positioned(
              right: -30,
              top: 50,
              child: Image.asset(
                'assets/images/person1.png',
                width: 150,
              ),
            ),
            // Image en bas à gauche
            Positioned(
              left: -30,
              bottom: 50,
              child: Image.asset(
                'assets/images/person2.png',
                width: 150,
              ),
            ),
            // Contenu principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "WELCOME TO WSSM",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  Row(
                    children: [
                      const Spacer(),
                      Expanded(
                        flex: 8,
                        child: SvgPicture.asset(
                          "assets/icons/chat.svg",
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  Row(
                    children: [
                      const Spacer(),
                      Expanded(
                        flex: 8,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            elevation: 8,
                            shadowColor: kPrimaryColor.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding * 2,
                              vertical: defaultPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(buttonBorderRadius),
                            ),
                          ),
                          child: Text(
                            "GO TO SIGN IN".toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}