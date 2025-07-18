import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:spyfall/models/player.dart';

// Test widget that mimics the LobbyPage structure without Firebase
class TestLobbyPage extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const TestLobbyPage({super.key, required this.roomCode, this.isHost = false});

  @override
  State<TestLobbyPage> createState() => _TestLobbyPageState();
}

class _TestLobbyPageState extends State<TestLobbyPage> {
  final TextEditingController _playerNameController = TextEditingController(
    text: 'Player',
  );
  final _formKey = GlobalKey<FormState>();

  int _timerLength = 360; // 6 minutes default
  int _votingTimeLength = 120; // 2 minutes default
  bool _startTimerImmediately = true;

  final List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    // Create a mock player for testing
    _players.add(
      Player(
        id: 'test-player-1',
        gameId: widget.roomCode,
        name: 'Player',
        isSpy: false,
        isHost: widget.isHost,
        status: widget.isHost ? PlayerStatus.ready : PlayerStatus.notReady,
        joinedAt: Timestamp.now(),
      ),
    );
  }

  void _updatePlayerName(String name) {
    setState(() {
      if (_players.isNotEmpty) {
        _players[0] = _players[0].copyWith(name: name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Room Code Display
                      Column(
                        children: [
                          Text(
                            'Room Code:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            widget.roomCode,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Host Settings (only visible when isHost is true)
                      if (widget.isHost) ..._buildHostSettings(),
                      const SizedBox(height: 32),
                      // Player Name Field
                      TextFormField(
                        controller: _playerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Player Name',
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          prefixIcon: Icon(LucideIcons.user),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onChanged: _updatePlayerName,
                      ),
                      const SizedBox(height: 32),
                      // Players List
                      _buildPlayersList(),
                    ],
                  ),
                ),
                // Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Leave Lobby'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text(widget.isHost ? 'Start Game' : 'Ready Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHostSettings() {
    return [
      Column(
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timer Length:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              DropdownButton<int>(
                value: _timerLength,
                items: const [
                  DropdownMenuItem(value: 120, child: Text('2 minutes')),
                  DropdownMenuItem(value: 240, child: Text('4 minutes')),
                  DropdownMenuItem(value: 360, child: Text('6 minutes')),
                  DropdownMenuItem(value: 480, child: Text('8 minutes')),
                  DropdownMenuItem(value: 600, child: Text('10 minutes')),
                ],
                onChanged: (value) {
                  setState(() {
                    _timerLength = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voting Time:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              DropdownButton<int>(
                value: _votingTimeLength,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 seconds')),
                  DropdownMenuItem(value: 60, child: Text('1 minute')),
                  DropdownMenuItem(value: 90, child: Text('1.5 minutes')),
                  DropdownMenuItem(value: 120, child: Text('2 minutes')),
                ],
                onChanged: (value) {
                  setState(() {
                    _votingTimeLength = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start Timer Immediately:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Switch(
                value: _startTimerImmediately,
                onChanged: (value) {
                  setState(() {
                    _startTimerImmediately = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _buildPlayersList() {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Players in Lobby (${_players.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _players.isEmpty
                  ? const Center(child: Text('No players in lobby'))
                  : ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final player = _players[index];
                        return ListTile(
                          leading: Icon(
                            player.isHost
                                ? LucideIcons.crown
                                : LucideIcons.user,
                            color: player.isHost
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          title: Text(player.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (player.status == PlayerStatus.ready)
                                Icon(
                                  LucideIcons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              if (player.isHost) const Text('HOST'),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('LobbyPage Widget Tests', () {
    Widget createTestLobbyPage({
      required String roomCode,
      required bool isHost,
    }) {
      return MaterialApp(
        home: TestLobbyPage(roomCode: roomCode, isHost: isHost),
      );
    }

    testWidgets('displays room code correctly', (WidgetTester tester) async {
      const testRoomCode = 'TEST123';

      await tester.pumpWidget(
        createTestLobbyPage(roomCode: testRoomCode, isHost: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Room Code:'), findsOneWidget);
      expect(find.text(testRoomCode), findsOneWidget);
    });

    testWidgets('shows settings when isHost is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Timer Length:'), findsOneWidget);
      expect(find.text('Voting Time:'), findsOneWidget);
      expect(find.text('Start Timer Immediately:'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsNWidgets(2));
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('hides settings when isHost is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsNothing);
      expect(find.text('Timer Length:'), findsNothing);
      expect(find.text('Voting Time:'), findsNothing);
      expect(find.text('Start Timer Immediately:'), findsNothing);
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('shows correct button text for host vs non-host', (
      WidgetTester tester,
    ) async {
      // Test host button
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Ready Up'), findsNothing);

      // Test non-host button
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Game'), findsNothing);
      expect(find.text('Ready Up'), findsOneWidget);
    });

    testWidgets('host name updates in players list when text field changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      // Find the player name text field
      final nameField = find.byType(TextFormField);
      expect(nameField, findsOneWidget);

      // Initially shows default name
      expect(find.text('Player'), findsWidgets);

      // Change the name
      await tester.enterText(nameField, 'HostPlayer');
      await tester.pump();

      // Check that the name appears in the players list
      expect(find.text('HostPlayer'), findsAtLeastNWidgets(1));
      expect(find.text('Player'), findsNothing);
    });

    testWidgets('displays players list with correct information for host', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Players in Lobby (1)'), findsOneWidget);
      expect(find.text('HOST'), findsOneWidget);

      // Check for crown icon for host
      expect(find.byIcon(LucideIcons.crown), findsOneWidget);
      expect(find.byIcon(LucideIcons.user), findsNothing);
    });

    testWidgets('displays players list with correct information for non-host', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Players in Lobby (1)'), findsOneWidget);
      expect(find.text('HOST'), findsNothing);

      // Check for user icon for non-host
      expect(find.byIcon(LucideIcons.user), findsOneWidget);
      expect(find.byIcon(LucideIcons.crown), findsNothing);
    });

    testWidgets('leave lobby button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leave Lobby'), findsOneWidget);
    });

    testWidgets('player name field has correct validation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: false),
      );
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField);
      expect(nameField, findsOneWidget);

      // Get the TextFormField widget
      final textFormField = tester.widget<TextFormField>(nameField);

      // Test validator with empty string
      expect(textFormField.validator?.call(''), 'Please enter your name');
      expect(textFormField.validator?.call(null), 'Please enter your name');

      // Test validator with valid name
      expect(textFormField.validator?.call('ValidName'), null);
    });

    testWidgets('settings dropdown values are correct', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      // Check that timer length dropdown has correct default value
      expect(find.text('6 minutes'), findsOneWidget);

      // Check that voting time dropdown has correct default value
      expect(find.text('2 minutes'), findsOneWidget);

      // Check that switch is on by default
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('can interact with timer length dropdown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      // Test timer length dropdown
      final timerDropdown = find.byType(DropdownButton<int>).first;
      await tester.tap(timerDropdown);
      await tester.pumpAndSettle();

      expect(find.text('4 minutes'), findsOneWidget);
      expect(find.text('8 minutes'), findsOneWidget);
      expect(find.text('10 minutes'), findsOneWidget);

      // Select a different value
      await tester.tap(find.text('4 minutes'));
      await tester.pumpAndSettle();

      // Verify selection - should now show 4 minutes instead of 6
      expect(find.text('4 minutes'), findsOneWidget);
    });

    testWidgets('can toggle switch in settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestLobbyPage(roomCode: 'TEST123', isHost: true),
      );
      await tester.pumpAndSettle();

      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);

      // Initial state should be true
      expect(tester.widget<Switch>(switchWidget).value, true);

      // Toggle the switch
      await tester.tap(switchWidget);
      await tester.pump();

      // Verify it's now false
      expect(tester.widget<Switch>(switchWidget).value, false);
    });
  });
}
