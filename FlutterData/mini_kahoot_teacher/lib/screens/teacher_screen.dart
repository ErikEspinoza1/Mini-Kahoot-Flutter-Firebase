import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String? gameId;
  int? gameCode;

  final _qController = TextEditingController();
  final _op1Controller = TextEditingController();
  final _op2Controller = TextEditingController();
  final _op3Controller = TextEditingController();
  final _op4Controller = TextEditingController();
  int _correctIndex = 0;

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // ¡EL TRUCO ESTÁ AQUÍ!
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Añadir Pregunta'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _qController, decoration: const InputDecoration(labelText: 'Pregunta')),
                  TextField(controller: _op1Controller, decoration: const InputDecoration(labelText: 'Opción 1 (Roja)')),
                  TextField(controller: _op2Controller, decoration: const InputDecoration(labelText: 'Opción 2 (Azul)')),
                  TextField(controller: _op3Controller, decoration: const InputDecoration(labelText: 'Opción 3 (Amarillo)')),
                  TextField(controller: _op4Controller, decoration: const InputDecoration(labelText: 'Opción 4 (Verde)')),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: _correctIndex,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Correcta: Opción Roja')),
                      DropdownMenuItem(value: 1, child: Text('Correcta: Opción Azul')),
                      DropdownMenuItem(value: 2, child: Text('Correcta: Opción Amarilla')),
                      DropdownMenuItem(value: 3, child: Text('Correcta: Opción Verde')),
                    ],
                    onChanged: (val) {
                      // Usamos el setDialogState interno
                      setDialogState(() => _correctIndex = val!);
                    },
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  FirebaseService.addQuestion(gameId!, _qController.text, [_op1Controller.text, _op2Controller.text, _op3Controller.text, _op4Controller.text], _correctIndex);
                  _qController.clear(); _op1Controller.clear(); _op2Controller.clear(); _op3Controller.clear(); _op4Controller.clear();
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profesor - Kahoot Auto'), backgroundColor: Colors.deepPurple),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (gameId == null)
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.deepPurple),
                    onPressed: () async {
                      final id = await FirebaseService.createGame();
                      final doc = await FirebaseFirestore.instance.collection('games').doc(id).get();
                      setState(() { gameId = id; gameCode = doc['code']; });
                    },
                    child: const Text('Crear Nuevo Kahoot', style: TextStyle(fontSize: 24, color: Colors.white)),
                  ),
                ),
              if (gameId != null)
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseService.gameStream(gameId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final gameData = snapshot.data!.data() as Map<String, dynamic>;
                      final status = gameData['status'];
                      final questions = gameData['questions'] as List<dynamic>;
                      final currentIndex = gameData['currentQuestionIndex'];

                      return Column(
                        children: [
                          Text('PIN: $gameCode', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 10),

                          // --- SALA DE ESPERA ---
                          if (status == 'waiting') ...[
                            Text('Preguntas actuales: ${questions.length}', style: const TextStyle(color: Colors.grey, fontSize: 18)),
                            ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Añadir Pregunta'), onPressed: _showAddQuestionDialog),
                            const Divider(height: 30),
                            const Text('Esperando jugadores...', style: TextStyle(fontSize: 20)),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseService.playersStream(gameId!),
                                builder: (ctx, snap) {
                                  if (!snap.hasData) return const SizedBox();
                                  return ListView(children: snap.data!.docs.map((d) => Card(child: ListTile(leading: const Icon(Icons.person), title: Text(d['name'])))).toList());
                                },
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 60)),
                              onPressed: () => FirebaseService.startGame(gameId!),
                              child: const Text('¡INICIAR PARTIDA!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            )
                          ],

                          // --- ESTADO: JUGANDO (10 segundos) ---
                          if (status == 'playing') ...[
                            Text(questions[currentIndex]['q'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            
                            // Temporizador automático de 10s (Usa ValueKey para reiniciarse en cada pregunta)
                            TweenAnimationBuilder<double>(
                              key: ValueKey('timer_play_$currentIndex'), 
                              tween: Tween(begin: 10.0, end: 0.0),
                              duration: const Duration(seconds: 10),
                              onEnd: () => FirebaseService.revealAnswer(gameId!), // ¡Acaba el tiempo y cambia el estado a Reveal!
                              builder: (context, value, child) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(value: value / 10, strokeWidth: 10, color: value < 3 ? Colors.red : Colors.blue),
                                  Text('${value.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Mostrar opciones (Al profe siempre se le marca la correcta en verde clarito)
                            ...List.generate(questions[currentIndex]['options'].length, (index) => Card(
                              color: index == questions[currentIndex]['correct'] ? Colors.green.withOpacity(0.4) : Colors.grey[800],
                              child: ListTile(
                                leading: index == questions[currentIndex]['correct'] ? const Icon(Icons.star, color: Colors.yellow) : null,
                                title: Text(questions[currentIndex]['options'][index], style: const TextStyle(fontSize: 20))
                              )
                            )),
                          ],

                          // --- ESTADO: REVELAR RESPUESTA (5 segundos y salta solo) ---
                          if (status == 'reveal') ...[
                            const Text('¡Tiempo agotado!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 10),
                            const Text('Saltando a la siguiente pregunta en...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            
                            // Temporizador automático de 5s para avanzar
                            TweenAnimationBuilder<double>(
                              key: ValueKey('timer_reveal_$currentIndex'), 
                              tween: Tween(begin: 5.0, end: 0.0),
                              duration: const Duration(seconds: 5),
                              onEnd: () => FirebaseService.nextQuestion(gameId!, currentIndex, questions.length), // ¡Salta solo a la siguiente!
                              builder: (context, value, child) => Text('${value.toInt()}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const SizedBox(height: 20),

                            ...List.generate(questions[currentIndex]['options'].length, (index) => Card(
                              color: index == questions[currentIndex]['correct'] ? Colors.green : Colors.red.withOpacity(0.3),
                              child: ListTile(title: Text(questions[currentIndex]['options'][index], style: const TextStyle(fontSize: 20, color: Colors.white)))
                            )),
                          ],

                          // --- PODIO ---
                          if (status == 'podium') ...[
                            const Text('🏆 PODIO FINAL 🏆', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseService.playersStream(gameId!),
                                builder: (ctx, snap) {
                                  if (!snap.hasData) return const SizedBox();
                                  final docs = snap.data!.docs;
                                  return ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (ctx, i) => ListTile(
                                      leading: Text('#${i + 1}', style: const TextStyle(fontSize: 24)),
                                      title: Text(docs[i]['name'], style: const TextStyle(fontSize: 20)),
                                      trailing: Text('${docs[i]['score']} pts', style: const TextStyle(fontSize: 20, color: Colors.green)),
                                    ),
                                  );
                                },
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, minimumSize: const Size(double.infinity, 60)),
                              onPressed: () => setState(() { gameId = null; gameCode = null; }),
                              child: const Text('Crear Nueva Partida', style: TextStyle(color: Colors.white, fontSize: 20)),
                            )
                          ]
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}