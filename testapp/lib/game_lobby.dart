import 'package:flutter/material.dart';
import 'firestore_controller.dart' as firestore;
import 'swipe_game.dart';

class GameLobby extends StatefulWidget {
  @override
  _GameLobbyState createState() => _GameLobbyState();
}

class _GameLobbyState extends State<GameLobby> {
  final firestore.FirestoreController firestoreController =
      firestore.FirestoreController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? _gameCode;

  void _createGame() async {
    String gameCode = await firestoreController.createGame();
    setState(() {
      _gameCode = gameCode;
    });
  }

  void _joinGame() async {
    String code = _codeController.text;
    String name = _nameController.text;

    if (code.isNotEmpty && name.isNotEmpty) {
      try {
        await firestoreController.joinGame(code, name);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SwipeGame(gameCode: code, playerName: name)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both game code and your name')),
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
