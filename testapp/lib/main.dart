import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import your firebase_options.dart
import 'firestore_controller.dart'
    as firestore; // Use alias for FirestoreController
import 'swipe_game.dart'; // Ensure this file exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // Use platform-specific options
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipe Card Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameLobby(), // Entry point of the game lobby
    );
  }
}

class GameLobby extends StatefulWidget {
  @override
  _GameLobbyState createState() => _GameLobbyState();
}

class _GameLobbyState extends State<GameLobby> {
  final firestore.FirestoreController firestoreController =
      firestore.FirestoreController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? _gameCode; // Store the generated game code

  void _createGame() async {
    String gameCode = await firestoreController.createGame();
    setState(() {
      _gameCode = gameCode; // Update state with the new game code
    });
  }

  void _joinGame() async {
    String code = _codeController.text;
    String name = _nameController.text;

    if (code.isNotEmpty && name.isNotEmpty) {
      await firestoreController.joinGame(code, name); // Join the game
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => SwipeGame(gameCode: code, playerName: name)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join or Create Game')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _createGame,
              child: const Text('Create New Game'),
            ),
            if (_gameCode != null) ...[
              SizedBox(height: 20),
              Text('Share this Game Code: $_gameCode',
                  style: TextStyle(fontSize: 18)),
            ],
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Enter Game Code'),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Your Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: _joinGame, child: const Text('Join Game')),
          ],
        ),
      ),
    );
  }
}
