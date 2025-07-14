import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'constants.dart';
import 'firebase_options.dart';
import 'pages/lobby_page.dart';
import 'services/room_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spyfall',
      theme: ThemeData(
        colorScheme: AppConstants.colorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const MyHomePage(title: 'Spyfall'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isCreatingRoom = false;

  void _createRoom() async {
    setState(() {
      _isCreatingRoom = true;
    });

    try {
      final userId = UserService.getCurrentUserId();
      final room = await RoomService.createRoom(
        createdBy: userId,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LobbyPage(roomCode: room.roomCode),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRoom = false;
        });
      }
    }
  }

  void _joinExistingGame() {
    showDialog(context: context, builder: (context) => _JoinGameDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Icon
              Icon(
                LucideIcons.eye,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              // App Title
              Text(
                'Spyfall',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Developer Credit
              Text(
                'developed by Jeshwin Prince',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 16),
              // Navigation Buttons
              Row(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isCreatingRoom ? null : _createRoom,
                    icon: _isCreatingRoom
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.plus),
                    label: Text(
                      _isCreatingRoom ? 'Creating...' : 'Create Room',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _joinExistingGame,
                    icon: const Icon(LucideIcons.logIn),
                    label: const Text('Join Game'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinGameDialog extends StatefulWidget {
  @override
  _JoinGameDialogState createState() => _JoinGameDialogState();
}

class _JoinGameDialogState extends State<_JoinGameDialog> {
  final TextEditingController _gameCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _gameCodeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  void _joinGame() {
    if (_formKey.currentState!.validate()) {
      final roomCode = _gameCodeController.text.trim().toUpperCase();
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LobbyPage(roomCode: roomCode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Existing Game'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _playerNameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(LucideIcons.user),
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
              controller: _gameCodeController,
              decoration: const InputDecoration(
                labelText: 'Game Code',
                hintText: 'Enter game code',
                prefixIcon: Icon(LucideIcons.hash),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a game code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _joinGame, child: const Text('Join Game')),
      ],
    );
  }
}
