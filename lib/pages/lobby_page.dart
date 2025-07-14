import 'package:flutter/material.dart';

class LobbyPage extends StatefulWidget {
  final String roomCode;

  const LobbyPage({
    super.key,
    required this.roomCode,
  });

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final TextEditingController _playerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  void _joinLobby() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement lobby joining logic
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Joining lobby...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby - ${widget.roomCode}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to the Lobby!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Room Code:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.roomCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _playerNameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _joinLobby,
                  child: const Text('Join Lobby'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
