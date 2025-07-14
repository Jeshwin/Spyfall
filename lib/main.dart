import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'pages/join_room_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
  void _createRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const JoinRoomPage(),
      ),
    );
  }

  void _joinExistingGame() {
    showDialog(
      context: context,
      builder: (context) => _JoinGameDialog(),
    );
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
              const SizedBox(height: 32),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // Navigation Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createRoom,
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Create Room'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _joinExistingGame,
                  icon: const Icon(LucideIcons.logIn),
                  label: const Text('Join Existing Game'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 48),
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
      // TODO: Implement join game logic
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joining game...')),
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
        ElevatedButton(
          onPressed: _joinGame,
          child: const Text('Join Game'),
        ),
      ],
    );
  }
}
