import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> createGame(String gameCode) async {
    await firestore.collection('games').doc(gameCode).set({
      'players': [],
      'state': 'waiting', // or 'active'
    });
  }

  Future<void> joinGame(String gameCode, String playerName) async {
    await firestore.collection('games').doc(gameCode).update({
      'players': FieldValue.arrayUnion([playerName]),
    });
  }

  Stream<DocumentSnapshot> getGameStream(String gameCode) {
    return firestore.collection('games').doc(gameCode).snapshots();
  }
}

class SwipeGame extends StatelessWidget {
  final String gameCode;
  final String playerName;

  const SwipeGame({Key? key, required this.gameCode, required this.playerName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWIPE Card Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(gameCode: gameCode, playerName: playerName),
    );
  }
}

class Card {
  final String suit;
  final String value;

  Card(this.suit, this.value);

  @override
  String toString() => '$value of $suit';
}

class Player {
  String name;
  List<Card> hand = [];

  Player(this.name);
}

class GameScreen extends StatefulWidget {
  final String gameCode;
  final String playerName;

  const GameScreen({Key? key, required this.gameCode, required this.playerName})
      : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<Player> players = [];

  List<Card> deck = [];

  List<Card> playedCards = [];

  int currentPlayerIndex =
      -1; // Start with -1 to indicate no player is active yet

  Card? topCard;

  @override
  void initState() {
    super.initState();

    // Listen for changes in the game state from Firestore
    FirestoreController().getGameStream(widget.gameCode).listen((snapshot) {
      if (snapshot.exists) {
        // Cast snapshot.data() to Map<String, dynamic>
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          List<dynamic> playerNames = data['players'] ?? [];
          setState(() {
            players = playerNames.map((name) => Player(name)).toList();

            // Start the game when enough players have joined
            if (players.length >= 2 && deck.isEmpty) {
              startNewGame();
            }
          });
        }
      }
    });

    // Add the current player to the players list
    players.add(Player(widget.playerName));

    // Create a new game in Firestore if it doesn't exist yet
    FirestoreController().createGame(widget.gameCode);

    updatePlayersInFirestore(); // Update Firestore with current players
  }

  void updatePlayersInFirestore() async {
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameCode)
        .update({
      'players': FieldValue.arrayUnion([widget.playerName]),
    });
  }

  void startNewGame() {
    createDeck();
    dealCards();
    topCard = null;
    playedCards.clear();
    currentPlayerIndex =
        players.indexWhere((player) => player.name == widget.playerName);
    setState(() {});
  }

  void createDeck() {
    List<String> suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    List<String> values = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K'
    ];

    deck = [
      for (var suit in suits)
        for (var value in values) Card(suit, value)
    ];

    deck.shuffle(Random());
  }

  void dealCards() {
    for (var player in players) {
      player.hand = deck.take(7).toList();
      deck.removeRange(0, min(7, deck.length));
    }

    updateHandsInFirestore(); // Update hands in Firestore after dealing cards
  }

  void updateHandsInFirestore() async {
    List<Map<String, dynamic>> hands = players
        .map((player) => {
              "name": player.name,
              "hand": player.hand
                  .map((card) => {'suit': card.suit, 'value': card.value})
                  .toList(),
            })
        .toList();

    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameCode)
        .update({
      'hands': hands,
      'state': 'active',
    });
  }

  bool canPlayCard(Card card) {
    if (topCard == null) return true;
    if (card.value == '10') return true;

    int topCardValue = getCardValue(topCard!);
    int playedCardValue = getCardValue(card);

    return playedCardValue <= topCardValue;
  }

  int getCardValue(Card card) {
    switch (card.value) {
      case 'A':
        return 1;
      case 'J':
        return 11;
      case 'Q':
        return 12;
      case 'K':
        return 13;
      default:
        return int.parse(card.value);
    }
  }

  void playCard(Card card) {
    setState(() {
      Player currentPlayer = players[currentPlayerIndex];

      currentPlayer.hand.remove(card);
      playedCards.add(card);
      topCard = card;

      if (card.value == '10') {
        // Burn the played cards including the swipe card
        playedCards.clear();
        topCard = null; // Current player gets to play again
      } else {
        currentPlayerIndex =
            (currentPlayerIndex + 1) % players.length; // Move to next player
      }

      // Check if the next player can play
      if (!canPlayerPlay(players[currentPlayerIndex])) {
        players[currentPlayerIndex].hand.addAll(playedCards);
        playedCards.clear();
        topCard = null;
      }

      // Check for game end condition
      if (currentPlayer.hand.isEmpty) {
        endGame(currentPlayer);
      }

      updateHandsInFirestore(); // Update hands in Firestore after playing a card
    });
  }

  bool canPlayerPlay(Player player) {
    return player.hand.any((card) => canPlayCard(card));
  }

  void endGame(Player winner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('${winner.name} wins!'),
          actions: <Widget>[
            TextButton(
              child: const Text('New Game'),
              onPressed: () {
                Navigator.of(context).pop();
                startNewGame();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SWIPE Card Game')),
      body: Column(
        children: [
          Text('Current Player: ${players[currentPlayerIndex].name}',
              style: const TextStyle(fontSize: 20)),
          Text('Top Card: ${topCard?.toString() ?? "None"}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          if (currentPlayerIndex ==
              players.indexWhere((p) => p.name == widget.playerName))
            Expanded(
              child: ListView.builder(
                itemCount: players[currentPlayerIndex].hand.length,
                itemBuilder: (context, index) {
                  Card card = players[currentPlayerIndex].hand[index];
                  return ListTile(
                    title: Text(card.toString()),
                    onTap: canPlayCard(card) ? () => playCard(card) : null,
                    tileColor: canPlayCard(card)
                        ? Colors.green[100]
                        : Colors.grey[300],
                  );
                },
              ),
            )
          else
            Text('Waiting for ${players[currentPlayerIndex].name} to play...'),
        ],
      ),
    );
  }
}
