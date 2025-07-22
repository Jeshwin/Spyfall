# Spyfall - Digital Social Deduction Game

A Flutter-based digital implementation of the popular Spyfall party game, supporting real-time multiplayer gameplay across Android, iOS, and web platforms.

## 📱 App Store Descriptions

### Short Description (80 characters max)
**Classic Spyfall party game - Find the spy or guess the secret location!**

### Long Description (4000 characters max)

**🕵️ Welcome to Spyfall - The Ultimate Social Deduction Experience!**

Bring the excitement of the beloved party game Spyfall to your mobile device! Perfect for friends, family gatherings, or party entertainment, this digital version makes it easier than ever to play the thrilling game of deduction and deception.

**🎮 How to Play:**
One player is secretly assigned as the "spy" while everyone else receives the same location with specific roles. The spy must figure out the secret location through careful questioning, while other players try to identify who among them is the spy - all without revealing too much!

**✨ Key Features:**

🎯 **27 Unique Locations** - From airplane cockpits to pirate ships, each location comes with beautiful hand-drawn style cards and 7 unique roles

🔄 **Real-Time Multiplayer** - Create or join game rooms with simple 4-character codes. Play with friends anywhere!

⏰ **Built-in Timer** - Customizable game timer (2-10 minutes) with retro LED display keeps games moving

📝 **Player Tracking** - Interactive grid to mark suspicious players and eliminate possible locations

💡 **Question Helper** - Over 40 sample questions to spark conversation when you're stuck

🎨 **Beautiful Design** - Stunning polaroid-style location cards with custom fonts and smooth animations

🎪 **Complete Game Management** - Host controls, ready-up system, automatic role assignment, and game results

**🌟 Perfect For:**
- Party entertainment (3-8 players recommended)
- Family game nights
- Friend gatherings
- Team building activities
- Classroom activities
- Virtual hangouts

**📱 Cross-Platform Play:**
Play seamlessly across Android, iOS, and web browsers. Everyone can join regardless of their device!

**🎭 Locations Include:**
Airplane, Bank, Beach, Casino, Hospital, Restaurant, School, Space Station, Submarine, and many more exotic and familiar places!

Whether you're a seasoned Spyfall veteran or new to social deduction games, this digital version provides all the tools you need for an engaging and memorable gaming experience. Download now and start your next spy adventure!

*No ads, no in-app purchases - just pure Spyfall fun!*

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.1)
- Firebase project setup
- Android Studio or Xcode for mobile development

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/spyfall.git
cd spyfall
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
```bash
flutterfire configure
```

4. Run the app:
```bash
flutter run
```

## 🛠️ Development Commands

### Running the App
```bash
flutter run                    # Run on connected device
flutter run -d chrome          # Run on web browser
flutter run -d <device-id>      # Run on specific device
```

### Building
```bash
flutter build apk              # Build Android APK
flutter build ios              # Build iOS app
flutter build web              # Build web version
flutter build appbundle        # Build Android App Bundle
```

### Testing & Quality
```bash
flutter test                   # Run tests
flutter analyze                # Static analysis
dart fix --apply              # Apply suggested fixes
```

## 🎯 Game Features

### Core Gameplay
- **27 unique locations** with custom artwork
- **7 roles per location** for varied gameplay
- **Real-time multiplayer** via Firebase Firestore
- **Automatic spy selection** and role assignment
- **Timer system** with host controls

### User Interface
- **Polaroid-style location cards** with handwritten fonts
- **Interactive player tracking grid** with color-coded marking
- **Digital timer display** with retro LED styling
- **Question helper system** with 40+ sample questions
- **Responsive design** for all screen sizes

### Multiplayer Features
- **Room-based gameplay** with 4-character codes
- **Host management system** with game controls
- **Real-time synchronization** across all devices
- **Player ready-up mechanics** for smooth game flow
- **Cross-platform compatibility** (Android/iOS/Web)

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase init
├── firebase_options.dart     # Firebase configuration
├── models/                   # Game data models
├── screens/                  # UI screens and pages
├── widgets/                  # Reusable UI components
└── services/                 # Game logic and Firebase services

assets/
├── images/                   # Location card artwork
├── fonts/                    # Custom typography
└── data/                     # Game configuration (locations, questions)

test/                         # Unit and widget tests
android/                      # Android build configuration
ios/                          # iOS build configuration  
web/                          # Web deployment files
```

## 🎨 Design System

### Typography
- **Limelight**: Display titles and headers
- **Delicious Handrawn**: Handwritten style text
- **Geist Mono**: Room codes and technical text
- **7-Segment**: Digital timer display

### Visual Elements
- Material 3 design principles
- Custom color palette with warm tones
- Polaroid-inspired card layouts
- Subtle shadows and depth effects

## 🔧 Technologies Used

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore
- **Authentication**: Anonymous Firebase Auth
- **Real-time Updates**: Firestore Streams
- **Image Assets**: Custom illustrated location cards
- **State Management**: Built-in StatefulWidget with Streams
- **Cross-Platform**: Android, iOS, Web

## 🎮 Game Rules

### For Non-Spy Players
1. You receive a location card with your secret role
2. Ask and answer questions to identify the spy
3. Vote to eliminate the spy before time runs out
4. Win by correctly identifying the spy

### For the Spy
1. You only know you're the spy (no location given)
2. Listen to questions and answers carefully
3. Try to blend in without revealing your identity
4. Win by correctly guessing the secret location

### Game Flow
1. **Lobby**: Players join room and mark themselves ready
2. **Setup**: Host starts game, roles are assigned automatically
3. **Discussion**: Players ask questions and discuss (timer runs)
4. **Resolution**: Vote on spy or spy guesses location
5. **Results**: Game reveals spy identity and location

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues, feature requests, or questions:
- Create an issue on GitHub
- Check existing documentation
- Review the How to Play guide in-app

---

**Ready to play? Download Spyfall and start your next spy adventure!** 🕵️‍♀️🕵️‍♂️
