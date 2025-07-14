import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final String roomCode;
  final String playerName;

  const GamePage({
    super.key,
    required this.roomCode,
    required this.playerName,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _isGameStarted = false;
  bool _isRevealed = false;
  String _location = '';
  String _role = '';
  List<String> _players = [];
  int _timeRemaining = 480; // 8 minutes in seconds

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  void _loadGameData() {
    // TODO: Load game data from Firebase
    setState(() {
      _players = ['Player 1', 'Player 2', 'Player 3', widget.playerName];
      _location = 'Loading...';
      _role = 'Loading...';
    });
  }

  void _startGame() {
    // TODO: Implement game start logic
    setState(() {
      _isGameStarted = true;
      _location = 'School';
      _role = 'Student';
    });
  }

  void _revealRole() {
    setState(() {
      _isRevealed = true;
    });
  }

  void _endGame() {
    // TODO: Implement game end logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('The game has ended!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomCode}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Game Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Player: ${widget.playerName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time: ${_formatTime(_timeRemaining)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Game Content
            if (!_isGameStarted) ...[
              const Text(
                'Waiting for game to start...',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text('Start Game'),
              ),
            ] else ...[
              // Role Card
              Card(
                color: _isRevealed 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _isRevealed ? 'Your Role' : 'Tap to Reveal Role',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_isRevealed) ...[
                        Text(
                          'Location: $_location',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Role: $_role',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ] else ...[
                        const Icon(Icons.visibility_off, size: 48),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _revealRole,
                          child: const Text('Reveal'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Players List
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Players (${_players.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(_players[index]),
                              trailing: _players[index] == widget.playerName
                                  ? const Icon(Icons.star)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Game Actions
            if (_isGameStarted) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _endGame,
                      child: const Text('End Game'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}