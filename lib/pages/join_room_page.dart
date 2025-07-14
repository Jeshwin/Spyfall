import 'package:flutter/material.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _roomCodeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  void _joinRoom() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement room joining logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joining room...')),
      );
    }
  }

  void _createRoom() {
    if (_playerNameController.text.isNotEmpty) {
      // TODO: Implement room creation logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating room...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Spyfall Game'),
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
              const Text(
                'Enter Game Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomCodeController,
                decoration: const InputDecoration(
                  labelText: 'Room Code',
                  hintText: 'Enter room code to join',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _joinRoom,
                  child: const Text('Join Room'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('or'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _createRoom,
                  child: const Text('Create New Room'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}