import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<User?> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return null;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.code)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.topCenter,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: SingleChildScrollView(
                child: Column(
              children: [
                const SizedBox(height: 32),
                _form(),
              ],
            ))));
  }

  Widget _form() {
    return Form(
        key: _formKey,
        child: Column(children: [
          TextFormField(
            controller: _emailController,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Email', labelStyle: TextStyle(height: 0.1)),
            validator: (val) => val?.isEmpty == true ? 'cannot be empty' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
                labelText: 'Password', labelStyle: TextStyle(height: 0.1)),
            validator: (val) => val?.isEmpty == true ? 'cannot be empty' : null,
            obscureText: true,
          ),
          const SizedBox(height: 32),
          TextButton(onPressed: _submit, child: Text('Login'))
        ]));
  }
}
