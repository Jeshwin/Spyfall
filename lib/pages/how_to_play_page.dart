import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/location_card.dart';
import '../widgets/sticky_note.dart';

enum DemoPlayerMark { none, suspicious, cleared }

class HowToPlayPage extends StatefulWidget {
  const HowToPlayPage({super.key});

  @override
  State<HowToPlayPage> createState() => _HowToPlayPageState();
}

class _HowToPlayPageState extends State<HowToPlayPage> {
  // Interactive demo state
  final Map<String, DemoPlayerMark> _demoPlayerMarks = {};
  final Set<String> _demoCrossedOutLocations = {};

  // Sample data for demos
  final List<String> _demoPlayers = ['Alice', 'Bob'];
  final List<String> _demoLocations = ['School', 'Hospital'];
  final String _demoQuestion = 'What time do you usually arrive here?';

  void _toggleDemoPlayerMark(String playerId) {
    setState(() {
      final currentMark = _demoPlayerMarks[playerId] ?? DemoPlayerMark.none;
      switch (currentMark) {
        case DemoPlayerMark.none:
          _demoPlayerMarks[playerId] = DemoPlayerMark.suspicious;
          break;
        case DemoPlayerMark.suspicious:
          _demoPlayerMarks[playerId] = DemoPlayerMark.cleared;
          break;
        case DemoPlayerMark.cleared:
          _demoPlayerMarks[playerId] = DemoPlayerMark.none;
          break;
      }
    });
  }

  Color _getDemoPlayerMarkColor(DemoPlayerMark mark) {
    switch (mark) {
      case DemoPlayerMark.suspicious:
        return Theme.of(context).colorScheme.error;
      case DemoPlayerMark.cleared:
        return Colors.green;
      case DemoPlayerMark.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play Spyfall'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Overview
            _buildSection(
              title: 'Game Overview',
              content: [
                _buildParagraph(
                  'Spyfall is a social deduction game where everyone receives a location card except one person - the spy. The spy doesn\'t know the location and must figure it out through asking and answering questions.',
                ),
                _buildParagraph(
                  'Players take turns asking each other questions about the location. The spy tries to blend in while gathering clues, and other players try to identify the spy without being too obvious about the location.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // How to Win
            _buildSection(
              title: 'How to Win',
              content: [
                _buildBulletPoint(
                  '🕵️ **Spy wins if:** They correctly guess the location OR avoid being caught',
                ),
                _buildBulletPoint(
                  '👥 **Others win if:** They successfully identify the spy',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Features
            _buildSection(
              title: 'App Features',
              content: [
                _buildParagraph(
                  'This app includes several helpful features to enhance your Spyfall experience:',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Interactive Player Demo
            _buildInteractiveSection(
              title: '1. Player Tracking',
              description:
                  'Tap on player names to mark them as suspicious (red) or cleared (green). This helps you keep track of your suspicions during the game.',
              demo: _buildDemoPlayersGrid(),
            ),

            const SizedBox(height: 24),

            // Interactive Locations Demo
            _buildInteractiveSection(
              title: '2. Location Notes',
              description:
                  'Tap on locations to cross them out as you eliminate possibilities. This helps narrow down potential locations.',
              demo: _buildDemoLocationsGrid(),
            ),

            const SizedBox(height: 24),

            // Question Suggestions Demo
            _buildInteractiveSection(
              title: '3. Question Suggestions',
              description:
                  'Use the sticky note at the bottom for sample questions when you\'re stuck. Great for breaking awkward silences!',
              demo: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: StickyNote(text: _demoQuestion)),
              ),
            ),

            const SizedBox(height: 24),

            // Game Tips
            _buildSection(
              title: 'Tips for Success',
              content: [
                _buildBulletPoint(
                  '🤔 **Ask open-ended questions** that could apply to multiple locations',
                ),
                _buildBulletPoint(
                  '🎭 **Be subtle** - don\'t make the location too obvious to the spy',
                ),
                _buildBulletPoint(
                  '👂 **Listen carefully** to other players\' answers for inconsistencies',
                ),
                _buildBulletPoint(
                  '⏰ **Watch the timer** - use your time wisely during discussions',
                ),
                _buildBulletPoint(
                  '🤝 **Have fun** - Spyfall is about creativity and social interaction!',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Get Started Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.play),
                label: const Text('Start Playing!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...content,
      ],
    );
  }

  Widget _buildInteractiveSection({
    required String title,
    required String description,
    required Widget demo,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            demo,
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    // Parse markdown-style bold text
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final Match match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }

      // Add the bold part
      spans.add(
        TextSpan(
          text: match.group(1),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: RichText(text: TextSpan(children: spans)),
    );
  }

  Widget _buildDemoPlayersGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _demoPlayers.length,
      itemBuilder: (context, index) {
        final player = _demoPlayers[index];
        final mark = _demoPlayerMarks[player] ?? DemoPlayerMark.none;

        return GestureDetector(
          onTap: () => _toggleDemoPlayerMark(player),
          child: Card(
            color: _getDemoPlayerMarkColor(mark),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  player,
                  style: TextStyle(
                    color: mark == DemoPlayerMark.none
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoLocationsGrid() {
    return Row(
      children: [
        Expanded(
          child: LocationCard(
            location: _demoLocations[0],
            isCurrentLocation: false,
            isCrossedOut: _demoCrossedOutLocations.contains(_demoLocations[0]),
            onTap: () {
              setState(() {
                if (_demoCrossedOutLocations.contains(_demoLocations[0])) {
                  _demoCrossedOutLocations.remove(_demoLocations[0]);
                } else {
                  _demoCrossedOutLocations.add(_demoLocations[0]);
                }
              });
            },
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: LocationCard(
            location: _demoLocations[1],
            isCurrentLocation: false,
            isCrossedOut: _demoCrossedOutLocations.contains(_demoLocations[1]),
            onTap: () {
              setState(() {
                if (_demoCrossedOutLocations.contains(_demoLocations[1])) {
                  _demoCrossedOutLocations.remove(_demoLocations[1]);
                } else {
                  _demoCrossedOutLocations.add(_demoLocations[1]);
                }
              });
            },
          ),
        ),
      ],
    );
  }
}
