import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/player.dart';
import '../services/player_service.dart';

class LobbyPage extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const LobbyPage({super.key, required this.roomCode, this.isHost = false});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final TextEditingController _playerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _timerLength = 360; // 5 minutes default
  int _votingTimeLength = 120; // 1 minute default
  bool _startTimerImmediately = true;

  String? _currentPlayerId;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    try {
      final player = await PlayerService.createPlayer(
        gameId: widget.roomCode,
        name: 'Player', // Default name
        isHost: widget.isHost,
      );

      setState(() {
        _currentPlayerId = player.id;
        _isReady = player.isReady;
        _playerNameController.text = player.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join game: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _leaveLobby() async {
    if (_currentPlayerId != null) {
      await PlayerService.removePlayer(_currentPlayerId!);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _toggleReady() async {
    if (_currentPlayerId != null) {
      final newReadyState = !_isReady;
      await PlayerService.updatePlayerReady(_currentPlayerId!, newReadyState);
      setState(() {
        _isReady = newReadyState;
      });
    }
  }

  void _startGame() async {
    if (!widget.isHost) return;

    try {
      // Check if all players are ready
      final allReady = await PlayerService.areAllPlayersReady(widget.roomCode);
      if (!allReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not all players are ready!')),
          );
        }
        return;
      }

      // Assign random spy
      await PlayerService.assignRandomSpy(widget.roomCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game started! Spy has been assigned.')),
        );
      }

      // TODO: Navigate to game screen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start game: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _updatePlayerName(String name) async {
    if (_currentPlayerId != null && name.isNotEmpty) {
      await PlayerService.updatePlayerName(_currentPlayerId!, name);
    }
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
                      Column(
                        children: [
                          Text(
                            'Room Code:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            widget.roomCode,
                            style: GoogleFonts.getFont(
                              'Space Mono',
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (widget.isHost) ..._buildHostSettings(),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _playerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Player Name',
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          prefixIcon: Icon(LucideIcons.user),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
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
                      _buildPlayersList(),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _leaveLobby,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Leave Lobby'),
                    ),
                    ElevatedButton(
                      onPressed: widget.isHost ? _startGame : _toggleReady,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isHost
                            ? Theme.of(context).colorScheme.primary
                            : (_isReady
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary),
                        foregroundColor: widget.isHost
                            ? Theme.of(context).colorScheme.onPrimary
                            : (_isReady
                                  ? Theme.of(context).colorScheme.onSecondary
                                  : Theme.of(context).colorScheme.onPrimary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        widget.isHost
                            ? 'Start Game'
                            : (_isReady ? 'Ready!' : 'Ready Up'),
                      ),
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

  Widget _buildPlayersList() {
    return StreamBuilder<List<Player>>(
      stream: PlayerService.watchPlayersInGame(widget.roomCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final players = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Players in Lobby (${players.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: players.isEmpty
                  ? const Center(child: Text('No players in lobby'))
                  : Scrollbar(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
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
                                if (player.isReady)
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
        );
      },
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
}
