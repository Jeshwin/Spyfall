import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/constants.dart';
import '../models/player.dart';
import '../models/room.dart';
import '../pages/game_page.dart';
import '../services/app_lifecycle_service.dart';
import '../services/player_service.dart';
import '../services/room_service.dart';

class LobbyPage extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String userId;
  final String name;

  const LobbyPage({
    super.key,
    required this.roomCode,
    this.isHost = false,
    required this.userId,
    this.name = "Player", // Default name
  });

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final TextEditingController _playerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _timerLength = AppConstants.defaultSettings["discussionTime"] as int;
  int _votingTimeLength = AppConstants.defaultSettings["votingTime"] as int;
  bool _startTimerImmediately =
      AppConstants.defaultSettings["startTimerOnGameStart"] as bool;

  PlayerStatus _playerStatus = PlayerStatus.notReady;
  bool _showHostLeftDialog = false;
  int? _lastKnownGameSession;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initializeRoomSettings();
    _watchRoomStatus();
    
    // Set current player info in lifecycle service
    AppLifecycleService().setCurrentPlayer(
      playerId: widget.userId,
      roomCode: widget.roomCode,
      isHost: widget.isHost,
    );
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    // Clear lifecycle service when leaving lobby
    AppLifecycleService().clearCurrentPlayer();
    super.dispose();
  }

  void _initializePlayer() async {
    try {
      final player = await PlayerService.createPlayer(
        gameId: widget.roomCode,
        userId: widget.userId,
        name: widget.name,
        isHost: widget.isHost,
      );

      setState(() {
        _playerStatus = player.status;
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

  void _initializeRoomSettings() async {
    try {
      final room = await RoomService.getRoomByCode(widget.roomCode);
      if (room != null && mounted) {
        setState(() {
          _timerLength = room.settings.discussionTime;
          _votingTimeLength = room.settings.votingTime;
          _startTimerImmediately = room.settings.startTimerOnGameStart;
        });
      }
    } catch (e) {
      // Use default settings if room can't be loaded
      // No need to show error to user as defaults will work
    }
  }

  void _leaveLobby() async {
    await PlayerService.removePlayer(widget.userId);

    // If the host is leaving, mark the room as closed
    if (widget.isHost) {
      try {
        final room = await RoomService.getRoomByCode(widget.roomCode);
        if (room != null) {
          await RoomService.updateRoom(
            room.copyWith(status: RoomStatus.closed),
          );
        }
      } catch (e) {
        // Handle error silently to avoid blocking exit
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _toggleReady() async {
    PlayerStatus newStatus;
    if (_playerStatus == PlayerStatus.ready) {
      newStatus = PlayerStatus.notReady;
    } else if (_playerStatus == PlayerStatus.notReady) {
      newStatus = PlayerStatus.ready;
    } else {
      // If player is somehow in game but can press toggle, do nothing
      return;
    }
    
    await PlayerService.updatePlayerStatus(widget.userId, newStatus);
    setState(() {
      _playerStatus = newStatus;
    });
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

      // Update room status to in_progress, increment game session, and set timer state
      final room = await RoomService.getRoomByCode(widget.roomCode);
      if (room != null) {
        await RoomService.updateRoom(
          room.copyWith(
            status: RoomStatus.inProgress,
            gameSession: room.gameSession + 1,
            // Increment game session for new game
            isTimerPaused: !room.settings.startTimerOnGameStart,
          ),
        );
      }

      // Set all players to in_game status
      await PlayerService.setAllPlayersInGame(widget.roomCode);

      // Assign random location and roles
      RoomService.selectRandomLocation(widget.roomCode).then((
        selectedLocation,
      ) {
        PlayerService.assignRandomRoles(widget.roomCode, selectedLocation);
      });
      await PlayerService.assignRandomSpy(widget.roomCode);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                GamePage(roomCode: widget.roomCode, playerId: widget.userId),
          ),
        );
      }
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
    if (name.isNotEmpty) {
      await PlayerService.updatePlayerName(widget.userId, name);
    }
  }

  Future<void> _updateSettings() async {
    if (!widget.isHost) return;

    try {
      final settings = RoomSettings(
        discussionTime: _timerLength,
        votingTime: _votingTimeLength,
        startTimerOnGameStart: _startTimerImmediately,
      );

      await RoomService.updateRoomSettings(widget.roomCode, settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _watchRoomStatus() {
    if (!widget.isHost) {
      RoomService.watchRoom(widget.roomCode).listen((room) {
        if (room != null &&
            room.status == RoomStatus.closed &&
            mounted &&
            !_showHostLeftDialog) {
          _showHostLeftDialog = true;
          _showHostLeftGameDialog();
        } else if (room != null &&
            room.status == RoomStatus.inProgress &&
            mounted &&
            _playerStatus == PlayerStatus.ready) {
          // Only route to game if player status is ready
          // Check if this is a NEW game session (not an ongoing game)
          if (_lastKnownGameSession == null ||
              room.gameSession > _lastKnownGameSession!) {
            // This is a new game start - navigate to game page
            _lastKnownGameSession = room.gameSession;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GamePage(
                  roomCode: widget.roomCode,
                  playerId: widget.userId,
                ),
              ),
            );
          }
          // If gameSession hasn't changed, this means the game was already
          // in progress and we're a returning player who should stay in lobby
        }
      });
    }
  }

  void _showHostLeftGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Host Left'),
          content: const Text(
            'The host has left the game. The lobby has been closed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit lobby
              },
              child: const Text('Leave Game'),
            ),
          ],
        );
      },
    );
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
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.roomCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Room code ${widget.roomCode} copied to clipboard!',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Text(
                              widget.roomCode,
                              style: GoogleFonts.getFont(
                                'Space Mono',
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.isHost) ..._buildHostSettings(),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 8),
                      Expanded(child: _buildPlayersList()),
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
                    StreamBuilder<List<Player>>(
                      stream: PlayerService.watchPlayersInGame(widget.roomCode),
                      builder: (context, snapshot) {
                        final players = snapshot.data ?? [];
                        final allReady =
                            players.isNotEmpty &&
                            players.every((p) => p.status == PlayerStatus.ready);

                        return ElevatedButton(
                          onPressed: widget.isHost
                              ? (allReady ? _startGame : null)
                              : _toggleReady,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isHost
                                ? Theme.of(context).colorScheme.primary
                                : (_playerStatus == PlayerStatus.ready
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary),
                            foregroundColor: widget.isHost
                                ? Theme.of(context).colorScheme.onPrimary
                                : (_playerStatus == PlayerStatus.ready
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSecondary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onPrimary),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(
                            widget.isHost
                                ? 'Start Game'
                                : (_playerStatus == PlayerStatus.ready ? 'Ready!' : 'Ready Up'),
                          ),
                        );
                      },
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

        if (players.isEmpty) {
          return const Center(child: Text('No players in lobby'));
        }

        return SizedBox(
          height: 200,
          child: Scrollbar(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];

                if (player.id == widget.userId) {
                  return SizedBox();
                }

                return Card.filled(
                  child: ListTile(
                    leading: Icon(
                      player.isHost ? LucideIcons.crown : LucideIcons.user,
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
                          )
                        else if (player.status == PlayerStatus.inGame)
                          Icon(
                            LucideIcons.gamepad2,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        if (player.isHost) const Text('HOST'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildHostSettings() {
    return [
      Column(
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
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
                onChanged: (value) async {
                  setState(() {
                    _timerLength = value!;
                  });
                  await _updateSettings();
                },
              ),
            ],
          ),
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
                onChanged: (value) async {
                  setState(() {
                    _votingTimeLength = value!;
                  });
                  await _updateSettings();
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start Timer Immediately:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Switch(
                value: _startTimerImmediately,
                onChanged: (value) async {
                  setState(() {
                    _startTimerImmediately = value;
                  });
                  await _updateSettings();
                },
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
