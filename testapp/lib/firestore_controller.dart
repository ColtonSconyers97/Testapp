import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String generateGameCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<String> createGame() async {
    String gameCode = generateGameCode();
    await firestore.collection('games').doc(gameCode).set({
      'players': [],
      'state': 'waiting',
    });
    return gameCode; // Return the generated game code
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
