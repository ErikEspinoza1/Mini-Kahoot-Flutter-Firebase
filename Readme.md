# 🚀 Mini Kahoot Pro - Arquitectura Cliente/Servidor con Flutter y Firebase

Este repositorio contiene el código fuente completo de una plataforma interactiva de preguntas y respuestas en tiempo real, inspirada en Kahoot. El proyecto está dividido en dos aplicaciones sincronizadas mediante una base de datos NoSQL en la nube.

## 📖 Descripción del Proyecto

El sistema demuestra la implementación de comunicación bidireccional y reactividad en tiempo real. Está compuesto por:
1. **Teacher App (Servidor/Host):** Aplicación web/escritorio para crear la sala, gestionar el estado del juego, añadir preguntas personalizadas y actuar como "cronómetro central" (Autoplay).
2. **Student App (Cliente/Mando):** Aplicación móvil que permite a los alumnos unirse mediante un PIN, recibir feedback visual de sus respuestas y acumular puntos.

## ✨ Características Principales (Mejoras Avanzadas)
* **Sincronización en Tiempo Real:** Uso de `StreamBuilders` y Firebase Firestore para actualizar las interfaces sin recargar la pantalla.
* **Automatización de Flujo (Autoplay):** El servidor controla las fases del juego automáticamente mediante `TweenAnimationBuilder`, saltando de la pregunta a la respuesta y a la siguiente ronda de forma autónoma.
* **Sistema de Puntuación Dinámica:** Algoritmo que premia la velocidad de respuesta, otorgando hasta 1000 puntos al alumno más rápido.
* **Feedback Visual Completo:** Interfaz unificada (Dark Mode) que revela la respuesta correcta en la pantalla del alumno si este falla o agota el tiempo.
* **Rejugabilidad:** Capacidad de reiniciar las partidas y unirse a salas nuevas sin necesidad de reiniciar las aplicaciones.

## 🛠️ Tecnologías Utilizadas
* **Frontend:** Flutter (Dart)
* **Backend as a Service (BaaS):** Firebase
* **Base de Datos:** Cloud Firestore (Región: Europe-West)
* **Autenticación:** Firebase Anonymous Authentication

## 📁 Estructura del Repositorio
* `/mini_kahoot_teacher`: Contiene el código fuente de la aplicación del profesor.
* `/mini_kahoot_client`: Contiene el código fuente de la aplicación del alumno.
* `Configuración de Firebase y Conexión con Flutter.pdf`: Documentación técnica detallada y capturas del desarrollo.

## ▶️ Cómo ejecutar el proyecto localmente

1. Clona este repositorio.
2. Asegúrate de tener el SDK de Flutter instalado y configurado.
3. Abre dos terminales, una en cada carpeta del proyecto.
4. En cada terminal, ejecuta el comando para descargar las dependencias:
   ```bash
   flutter pub get
   
5. Ejecuta la aplicación del profesor (recomendado en web/Chrome):

   ```bash
   cd mini_kahoot_teacher
   flutter run
6. Ejecuta la aplicación del alumno (recomendado en Emulador Android/iOS):

   ```bash
   cd mini_kahoot_client
   flutter run
📺 Demostración en Vídeo
Para entender la arquitectura y ver el proyecto en funcionamiento, revisa el siguiente vídeo demostrativo donde se explica el código y se muestra la ejecución de las dos aplicaciones en tiempo real:

🔗 [Vídeo Demostrativo y Explicación del Proyecto](https://youtu.be/4M3swnHf4nk)
