import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
                child: Column(
          children: [
            SizedBox(height: 50),
            Icon(
              Icons.lock,
              size: 200,
              color: Colors.blue,
            ),
            Text("Welcome back!"),
          ],
        ))));
  }
}
