import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> login() async => await _auth.signInAnonymously();

  static Future<String> createGame() async {
    await login();
    int code = Random().nextInt(900000) + 100000;
    final doc = await _db.collection('games').add({
      'code': code,
      'status': 'waiting',
      'currentQuestionIndex': 0,
      'questions': [
        {'q': '¿Cuál es el planeta más cercano al Sol?', 'options': ['Venus', 'Tierra', 'Mercurio', 'Marte'], 'correct': 2},
        {'q': '¿Cuánto es 8 x 7?', 'options': ['54', '56', '64', '48'], 'correct': 1},
        {'q': '¿Qué lenguaje usamos en Flutter?', 'options': ['Java', 'Swift', 'Kotlin', 'Dart'], 'correct': 3}
      ]
    });
    return doc.id;
  }

  static Stream<QuerySnapshot> playersStream(String gameId) {
    //Ordena a los alumnos por puntuación de mayor a menor
    return _db.collection('games').doc(gameId).collection('players').orderBy('score', descending: true).snapshots();
  }

  static Stream<DocumentSnapshot> gameStream(String gameId) => _db.collection('games').doc(gameId).snapshots();

  static Future<void> startGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({'status': 'playing'});
  }

  //Acaba el tiempo y revela la respuesta
  static Future<void> revealAnswer(String gameId) async {
    await _db.collection('games').doc(gameId).update({'status': 'reveal'});
  }

  static Future<void> nextQuestion(String gameId, int currentIndex, int totalQuestions) async {
    if (currentIndex + 1 < totalQuestions) {
      await _db.collection('games').doc(gameId).update({
        'currentQuestionIndex': currentIndex + 1,
        'status': 'playing',
      });
    } else {
      await _db.collection('games').doc(gameId).update({'status': 'podium'});
    }
  }
  //Añadir pregunta a la partida
  static Future<void> addQuestion(String gameId, String question, List<String> options, int correctIndex) async {
    await _db.collection('games').doc(gameId).update({
      'questions': FieldValue.arrayUnion([
        {'q': question, 'options': options, 'correct': correctIndex}
      ])
    });
  }
}