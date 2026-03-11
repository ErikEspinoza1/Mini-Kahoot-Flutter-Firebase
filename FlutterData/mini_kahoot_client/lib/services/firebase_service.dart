import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> login() async => await _auth.signInAnonymously();

  // Ahora devuelve un Map con el gameId y el playerId
  static Future<Map<String, String>?> joinGame(int code, String name) async {
    await login();
    final query = await _db.collection('games').where('code', isEqualTo: code).where('status', isEqualTo: 'waiting').get();
    if (query.docs.isEmpty) return null;

    final gameId = query.docs.first.id;
    final playerDoc = await _db.collection('games').doc(gameId).collection('players').add({
      'name': name,
      'score': 0, // Empieza con 0 puntos
    });

    return {'gameId': gameId, 'playerId': playerDoc.id}; 
  }

  static Stream<DocumentSnapshot> gameStream(String gameId) => _db.collection('games').doc(gameId).snapshots();

  // ¡NUEVO! Actualiza la puntuación en Firebase
  static Future<void> addPoints(String gameId, String playerId, int points) async {
    await _db.collection('games').doc(gameId).collection('players').doc(playerId).update({
      'score': FieldValue.increment(points)
    });
  }

  //Escuchar los datos del jugador para saber su puntuación total
  static Stream<DocumentSnapshot> playerStream(String gameId, String playerId) {
    return _db.collection('games').doc(gameId).collection('players').doc(playerId).snapshots();
  }
}