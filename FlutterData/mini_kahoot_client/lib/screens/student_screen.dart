import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  
  String? _gameId;
  String? _playerId;
  int _answeredQuestionIndex = -1;
  bool _wasCorrect = false;
  int _pointsEarned = 0;
  DateTime? _questionStartTime;
  int _currentQuestionTracker = -1;

  void _join() async {
    if (_codeController.text.isEmpty || _nameController.text.isEmpty) return;
    final result = await FirebaseService.joinGame(int.parse(_codeController.text), _nameController.text);
    if (result != null) {
      setState(() { _gameId = result['gameId']; _playerId = result['playerId']; });
    }
  }

  void _submitAnswer(int selectedIndex, Map<String, dynamic> gameData) async {
    final currentIndex = gameData['currentQuestionIndex'];
    final correctIndex = gameData['questions'][currentIndex]['correct'];
    
    _wasCorrect = (selectedIndex == correctIndex);
    
    // --- LÓGICA DE PUNTOS POR TIEMPO ---
    if (_wasCorrect && _questionStartTime != null) {
      // Calculamos cuántos segundos tardó
      final double secondsElapsed = DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0;
      double remaining = 10.0 - secondsElapsed;
      if (remaining < 0) remaining = 0;
      
      // Mínimo 500 puntos si acierta. Bonus de hasta 500 más según la rapidez.
      _pointsEarned = 500 + ((remaining / 10.0) * 500).round();
    } else {
      _pointsEarned = 0; // Si falla, 0 puntos
    }

    setState(() { _answeredQuestionIndex = currentIndex; });

    if (_wasCorrect) await FirebaseService.addPoints(_gameId!, _playerId!, _pointsEarned);
  }

  Widget _colorButton(Color c, String t, int index, Map<String, dynamic> gameData) {
    final options = gameData['questions'][gameData['currentQuestionIndex']]['options'];
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => _submitAnswer(index, gameData),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t, style: const TextStyle(fontSize: 18, color: Colors.white70)),
              Text(options[index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(title: const Text('Alumno - Kahoot Auto'), backgroundColor: Colors.deepPurple),
        body: _gameId == null
            ? Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gamepad, size: 80, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 20),
                    TextField(controller: _codeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN del Juego', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tu Nombre', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, minimumSize: const Size(double.infinity, 50)),
                      onPressed: _join, 
                      child: const Text('Entrar', style: TextStyle(fontSize: 20, color: Colors.white))
                    ),
                  ],
                ),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseService.gameStream(_gameId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final gameData = snapshot.data!.data() as Map<String, dynamic>;
                  final status = gameData['status'];
                  final currentIndex = gameData['currentQuestionIndex'];
                  final currentQ = gameData['questions'][currentIndex];

                  if (status == 'waiting') {
                    return const Center(child: Text('¡Estás dentro!\nEsperando al profesor...', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)));
                  } 
                  else if (status == 'playing') {
                    // --- ¡INICIAMOS EL CRONÓMETRO INTERNO AQUÍ! ---
                    if (_currentQuestionTracker != currentIndex) {
                      _questionStartTime = DateTime.now();
                      _currentQuestionTracker = currentIndex;
                    }

                    if (_answeredQuestionIndex == currentIndex) {
                      return const Center(child: Text('¡Respuesta enviada!\nEsperando el resultado...', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Colors.amber)));
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(currentQ['q'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                        TweenAnimationBuilder<double>(
                          key: ValueKey('student_timer_$currentIndex'), 
                          tween: Tween(begin: 10.0, end: 0.0),
                          duration: const Duration(seconds: 10),
                          builder: (context, value, child) => LinearProgressIndicator(value: value / 10, minHeight: 10, color: value < 3 ? Colors.red : Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: Row(children: [_colorButton(Colors.red, 'Rojo', 0, gameData), _colorButton(Colors.blue, 'Azul', 1, gameData)])),
                        Expanded(child: Row(children: [_colorButton(Colors.orange, 'Amarillo', 2, gameData), _colorButton(Colors.green, 'Verde', 3, gameData)])),
                      ],
                    );
                  } 
                  else if (status == 'reveal') {
                    final correctText = currentQ['options'][currentQ['correct']];
                    
                    if (_answeredQuestionIndex != currentIndex) {
                      return Container(
                        color: Colors.grey[800], width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_off, color: Colors.white, size: 80),
                            const Text('¡TIEMPO AGOTADO!', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            const Text('La correcta era:', style: TextStyle(fontSize: 18, color: Colors.white70)),
                            Text(correctText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }
                    
                    return Container(
                      color: _wasCorrect ? Colors.green : Colors.red, width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_wasCorrect ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 100),
                          Text(_wasCorrect ? '¡CORRECTO!' : '¡INCORRECTO!', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('+ $_pointsEarned pts', style: const TextStyle(fontSize: 24, color: Colors.white)),
                          
                          const SizedBox(height: 20),
                          
                          // ¡NUEVO! Cajita con la puntuación total acumulada
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseService.playerStream(_gameId!, _playerId!),
                            builder: (context, playerSnap) {
                              if (!playerSnap.hasData) return const SizedBox();
                              final totalScore = playerSnap.data!['score'] ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Total acumulado: $totalScore pts', 
                                  style: const TextStyle(fontSize: 20, color: Colors.amberAccent, fontWeight: FontWeight.bold)
                                ),
                              );
                            }
                          ),

                          if (!_wasCorrect) ...[
                            const SizedBox(height: 40),
                            const Text('La respuesta correcta era:', style: TextStyle(fontSize: 18, color: Colors.white70)),
                            Text(correctText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    );
                  }
                  else if (status == 'podium') {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🏆\n¡Fin del Juego!\nMira el podio en la pantalla del profe', 
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 50),
                          //Botón para volver al inicio
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent, 
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                            ),
                            icon: const Icon(Icons.replay, color: Colors.white),
                            label: const Text('Unirse a otra partida', style: TextStyle(fontSize: 20, color: Colors.white)),
                            onPressed: () {
                              // Esto "limpia" la partida actual y te devuelve al inicio
                              setState(() {
                                _gameId = null;
                                _playerId = null;
                                _answeredQuestionIndex = -1;
                                _wasCorrect = false;
                                _pointsEarned = 0;
                                _currentQuestionTracker = -1;
                                _questionStartTime = null;
                                _codeController.clear(); // Borramos el PIN viejo
                                //No borramos _nameController para que no tengas que volver a escribir tu nombre
                              });
                            },
                          )
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
      ),
    );
  }
}