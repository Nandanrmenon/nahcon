import 'package:flutter/material.dart';

import '../services/jellyfin_service.dart';
import 'app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jellyfinService = JellyfinService();
  bool _isLoading = false;
  bool _serverValidated = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final serverUrl = _serverController.text.trim();
        final username = _usernameController.text.trim();
        final password = _passwordController.text;

        final success =
            await _jellyfinService.login(serverUrl, username, password);
        if (success && mounted) {
          await _jellyfinService.saveCredentials(serverUrl, username, password);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => App(service: _jellyfinService)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _validateServer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final serverUrl = _serverController.text.trim();
        final success = await _jellyfinService.validateServer(serverUrl);
        if (success && mounted) {
          setState(() => _serverValidated = true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid server address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final content = CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          expandedHeight: 400.0,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Image.asset('assets/nahCon.png')),
                ),
                Text(
                  'nahCon',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            centerTitle: true,
          ),
        ),
        SliverToBoxAdapter(
          child: Material(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Login to Jellyfin',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    if (!_serverValidated)
                      TextFormField(
                        keyboardType: TextInputType.url,
                        controller: _serverController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.storage),
                          labelText: 'Server URL',
                          hintText: 'http://example.com:8096',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter server URL';
                          }
                          return null;
                        },
                        enabled: !_isLoading && !_serverValidated,
                      ),
                    if (_serverValidated) ...[
                      Card.filled(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: ListTile(
                          leading: const Icon(Icons.dns_outlined),
                          title: Text(
                              _jellyfinService.serverName ?? 'Jellyfin Server'),
                          subtitle: Text(_serverController.text.trim()),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                setState(() => _serverValidated = false),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person)),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter username'
                            : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.password_outlined)),
                        obscureText: true,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter password'
                            : null,
                        enabled: !_isLoading,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : (_serverValidated ? _login : _validateServer),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(),
                              )
                            : Text(_serverValidated ? 'Login' : 'Connect'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: isDesktop
          ? Center(
              child: Card(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: content,
                  ),
                ),
              ),
            )
          : content,
    );
  }
}
