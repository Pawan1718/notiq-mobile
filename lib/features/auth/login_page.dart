import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/api/api_response.dart';
import '../../core/theme/notiq_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('notiq',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: NotiqTheme.violet)),
                const SizedBox(height: 16),
                Text('Welcome to Notiq',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Sign in to your workspace',
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v != null &&
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())
                        ? null
                        : 'Enter a valid email'),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                            tooltip:
                                _obscure ? 'Show password' : 'Hide password',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility
                                : Icons.visibility_off))),
                    validator: (v) =>
                        (v?.length ?? 0) >= 8 ? null : 'Minimum 8 characters'),
                const SizedBox(height: 20),
                if (auth.hasError)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                          auth.error is ApiFailure
                              ? (auth.error as ApiFailure).message
                              : 'Unable to sign in. Please try again.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                FilledButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (!_form.currentState!.validate()) return;
                            await ref
                                .read(authProvider.notifier)
                                .login(_email.text, _password.text);
                          },
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child:
                            Text(auth.isLoading ? 'Signing in…' : 'Sign in'))),
              ],
            )),
      ),
    ))));
  }
}
