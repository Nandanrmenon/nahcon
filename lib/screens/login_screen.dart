import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/utils/constants.dart';
import 'package:nahcon/widgets/app_logo.dart';
import 'package:super_context_menu/super_context_menu.dart';

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
  final FocusNode _usernameFocusNode = FocusNode();
  late FocusNode _passwordFocusNode;

  List<Map<String, dynamic>> _profiles = [];
  String? _selectedServerForAddUser;

  bool _showLoginForm = false;

  void _enterLoginMode({String? server}) {
    setState(() {
      _showLoginForm = true;
      if (server != null) {
        _serverController.text = server;
        _serverValidated = true;
      } else {
        _serverController.clear();
        _serverValidated = false;
      }
    });
    FocusScope.of(context).requestFocus(_usernameFocusNode);
  }

  void _exitLoginMode() {
    setState(() {
      _showLoginForm = false;
      _serverController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _serverValidated = false;
    });
  }

  @override
  void initState() {
    _loadProfiles();
    _passwordFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _jellyfinService.getProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  Future<void> _switchProfile(Map<String, dynamic> profile) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0,
            children: [
              CircularProgressIndicator(),
              Text('Switching to ${profile['username']}')
            ],
          ),
        ),
      ),
    );
    await _jellyfinService.setCurrentProfile(profile['id']);
    final success = await _jellyfinService.tryAutoLogin();
    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => App(service: _jellyfinService),
          ),
          (Route<dynamic> route) => false);
    }
  }

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

  // Helper to get unique servers from profiles
  List<String> get _uniqueServers =>
      _profiles.map((p) => p['serverUrl'] as String).toSet().toList();

  void _showAddUserDialog() async {
    final servers = _uniqueServers;
    String? selectedServer;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (servers.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedServer,
                  hint: const Text('Choose existing server'),
                  items: servers
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (val) {
                    selectedServer = val;
                  },
                ),
              const Divider(),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Or enter new server URL',
                ),
                onChanged: (val) {
                  selectedServer = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedServer != null && selectedServer!.isNotEmpty) {
                  setState(() {
                    _selectedServerForAddUser = selectedServer;
                    _serverController.text = selectedServer!;
                    _serverValidated = servers.contains(selectedServer);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (_selectedServerForAddUser != null) {
      FocusScope.of(context).requestFocus(_usernameFocusNode);
    }
  }

  Future<void> _confirmAndDeleteProfile(Map<String, dynamic> profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content:
            Text('Are you sure you want to remove "${profile['username']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _jellyfinService.removeProfile(profile['id']);
      await _loadProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: isDesktop
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          AppLogo(
                            height: 48,
                            width: 48,
                            borderRadius: 16,
                          ),
                          Text(
                            kAppName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          )
                              .animate()
                              .moveY(
                                  begin: -10.0,
                                  duration: Duration(milliseconds: 500))
                              .fadeIn(
                                  begin: 0.0,
                                  duration: Duration(milliseconds: 1000)),
                        ],
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      if (_showLoginForm)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Symbols.arrow_back),
                              onPressed: _exitLoginMode,
                            ),
                          ],
                        ),
                      if (!_showLoginForm && _profiles.isNotEmpty)
                        _buildSwitchUser()
                            .animate()
                            .moveY(
                                begin: 30.0,
                                duration: Duration(milliseconds: 500))
                            .fadeIn(
                                begin: 0.0,
                                duration: Duration(milliseconds: 800)),
                      if (_showLoginForm || _profiles.isEmpty)
                        _buildLoginForm(isDesktop)
                            .animate()
                            .moveY(
                                begin: 30.0,
                                duration: Duration(milliseconds: 500))
                            .fadeIn(
                                begin: 0.0,
                                duration: Duration(milliseconds: 800)),
                    ],
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: _profiles.isNotEmpty ? 200 : 400.0,
                  backgroundColor: isDesktop
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  elevation: 0,
                  leading: _showLoginForm
                      ? IconButton(
                          icon: const Icon(Symbols.arrow_back),
                          onPressed: _exitLoginMode,
                        )
                      : null,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        AppLogo(
                          height: 48,
                          width: 48,
                          borderRadius: 16,
                        ),
                        Text(
                          kAppName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        )
                            .animate()
                            .moveY(
                                begin: -10.0,
                                duration: Duration(milliseconds: 500))
                            .fadeIn(
                                begin: 0.0,
                                duration: Duration(milliseconds: 1000)),
                      ],
                    ),
                    centerTitle: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!_showLoginForm && _profiles.isNotEmpty)
                          _buildSwitchUser(),
                        if (_showLoginForm || _profiles.isEmpty)
                          _buildLoginForm(isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSwitchUser() {
    return Column(
      children: [
        Column(
          spacing: 4.0,
          children: [
            Text(
              'Switch Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Choose an existing user',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        ..._uniqueServers.map((server) {
          final serverProfiles =
              _profiles.where((p) => p['serverUrl'] == server).toList();
          return Column(
            children: [
              ListTile(
                leading: const Icon(Symbols.dns),
                title: Text(server),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...serverProfiles.map((profile) {
                    return SizedBox(
                      width: 150,
                      height: 150,
                      child: ContextMenuWidget(
                        menuProvider: (_) {
                          return Menu(
                            children: [
                              MenuAction(
                                  image: MenuImage.icon(
                                      Symbols.compare_arrows_rounded),
                                  title: 'Switch to ${profile['username']}',
                                  callback: () {
                                    _confirmAndDeleteProfile(profile);
                                  }),
                              MenuSeparator(),
                              MenuAction(
                                  image: MenuImage.icon(Symbols.delete),
                                  title: 'Delete',
                                  callback: () {
                                    _confirmAndDeleteProfile(profile);
                                  }),
                            ],
                          );
                        },
                        child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _switchProfile(profile),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 16.0,
                                children: [
                                  FutureBuilder<bool>(
                                    future: _jellyfinService.hasUserImage(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return CircleAvatar(
                                          radius: 20,
                                          backgroundImage: null,
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: _jellyfinService
                                                  .getUserImageUrl(),
                                              httpHeaders: _jellyfinService
                                                  .getVideoHeaders(),
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                          Icons.account_circle,
                                                          size: 40),
                                              placeholder: (context, url) =>
                                                  const Icon(
                                                      Icons.account_circle,
                                                      size: 40),
                                            ),
                                          ),
                                        );
                                      }
                                      return const Icon(Symbols.account_circle,
                                          size: 40);
                                    },
                                  ),
                                  Column(
                                    spacing: 4.0,
                                    children: [
                                      Text(profile['username']),
                                      Text(
                                        profile['serverName'] ??
                                            profile['serverUrl'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _enterLoginMode(server: server),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Symbols.add,
                                size: 48,
                              ),
                              Text(
                                'Add user to this server',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _enterLoginMode(),
                    child: Text('New Server'),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLoginForm(dynamic isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isDesktop)
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
                prefixIcon: Icon(Symbols.storage),
                labelText: 'Server URL',
                hintText: 'http://example.com:8096',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter server URL';
                }
                return null;
              },
              onFieldSubmitted: (value) => _validateServer,
              enabled: !_isLoading && !_serverValidated,
            ),
          if (_serverValidated) ...[
            Card.filled(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListTile(
                leading: const Icon(Symbols.dns_rounded),
                title: Text(_jellyfinService.serverName ?? 'Jellyfin Server'),
                subtitle: Text(_serverController.text.trim()),
                trailing: IconButton(
                  icon: const Icon(Symbols.edit),
                  onPressed: () => setState(() => _serverValidated = false),
                ),
              ),
            ),
            TextFormField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              onFieldSubmitted: (value) {
                _passwordFocusNode.requestFocus();
              },
              decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Symbols.person_rounded)),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter username' : null,
              keyboardType: TextInputType.text,
              enableSuggestions: false,
              spellCheckConfiguration: SpellCheckConfiguration.disabled(),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              focusNode: _passwordFocusNode,
              controller: _passwordController,
              decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Symbols.password_rounded)),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              // validator: (value) =>
              //     value?.isEmpty ?? true ? 'Please enter password' : null,
              onFieldSubmitted: (value) => _login(),
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
    );
  }
}
