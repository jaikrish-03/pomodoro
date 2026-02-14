import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const FocusFlow());
}

class FocusFlow extends StatelessWidget {
  const FocusFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PomodoroScreen(),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // ---------------- SETTINGS ----------------
  int focusDuration = 25;
  int sessionsUntilLongBreak = 4;
  int completedSessions = 0;

  // ---------------- TIMER ----------------
  late int remainingSeconds;
  bool isRunning = false;
  Timer? timer;

  // ---------------- MUSIC ----------------
  final AudioPlayer player = AudioPlayer();
  bool isMusicPlaying = false;
  double volume = 0.5;

  final List<String> playlist = [
    "Anegan.mp3",
    "enna vilai azhage.mp3",
    "Kanmoodi Thirakumbothu.mp3",
    "Paiya.mp3",
  ];

  int currentSongIndex = 0;

  @override
  void initState() {
    super.initState();
    remainingSeconds = focusDuration * 60;
    player.setVolume(volume);

    player.onPlayerComplete.listen((event) async {
      if (isRunning && isMusicPlaying) {
        currentSongIndex =
            (currentSongIndex + 1) % playlist.length;

        await player.play(
          AssetSource("music/${playlist[currentSongIndex]}"),
        );
        player.setVolume(volume);
        setState(() {});
      }
    });
  }

  // ---------------- TIMER ----------------

  String formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  void startPause() async {
    if (isRunning) {
      timer?.cancel();
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (remainingSeconds > 0) {
          setState(() => remainingSeconds--);
        } else {
          timer?.cancel();
          await stopMusic();
          setState(() {
            isRunning = false;
            completedSessions++;
          });
        }
      });

      if (!isMusicPlaying) {
        await startMusic();
      }
    }

    setState(() => isRunning = !isRunning);
  }

  void reset() async {
    timer?.cancel();
    await stopMusic();

    setState(() {
      remainingSeconds = focusDuration * 60;
      isRunning = false;
    });
  }

  // ---------------- MUSIC ----------------

  Future<void> toggleMusic() async {
    if (isMusicPlaying) {
      await player.pause();
      isMusicPlaying = false;
    } else {
      await player.play(
        AssetSource("music/${playlist[currentSongIndex]}"),
      );
      player.setVolume(volume);
      isMusicPlaying = true;
    }
    setState(() {});
  }

  Future<void> startMusic() async {
    await player.play(
      AssetSource("music/${playlist[currentSongIndex]}"),
    );
    player.setVolume(volume);
    isMusicPlaying = true;
  }

  Future<void> stopMusic() async {
    await player.stop();
    isMusicPlaying = false;
  }

  Future<void> nextSong() async {
    currentSongIndex =
        (currentSongIndex + 1) % playlist.length;

    if (isMusicPlaying) {
      await startMusic();
    }

    setState(() {});
  }

  Future<void> previousSong() async {
    currentSongIndex =
        (currentSongIndex - 1 + playlist.length) %
            playlist.length;

    if (isMusicPlaying) {
      await startMusic();
    }

    setState(() {});
  }

  // ---------------- SETTINGS DIALOG ----------------

  void openSettings() {
    TextEditingController focusController =
    TextEditingController(text: focusDuration.toString());
    TextEditingController sessionController =
    TextEditingController(text: sessionsUntilLongBreak.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: focusController,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: "Focus Duration (minutes)"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: sessionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Sessions Until Long Break"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  focusDuration = 25;
                  sessionsUntilLongBreak = 4;
                  remainingSeconds = focusDuration * 60;
                  completedSessions = 0;
                });
                Navigator.pop(context);
              },
              child: const Text("Reset to Default"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  focusDuration =
                      int.tryParse(focusController.text) ?? 25;
                  sessionsUntilLongBreak =
                      int.tryParse(sessionController.text) ?? 4;
                  remainingSeconds = focusDuration * 60;
                  completedSessions = 0;
                });
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    player.dispose();
    super.dispose();
  }

  // ---------------- RESPONSIVE BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: width > 900
            ? Row(
          children: [
            Expanded(child: leftSection()),
            const SizedBox(width: 60),
            Expanded(child: musicCard()),
          ],
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              leftSection(),
              const SizedBox(height: 40),
              musicCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- LEFT SECTION ----------------

  Widget leftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Focus Flow",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings,
                  color: Colors.white, size: 30),
              onPressed: openSettings,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text("Pomodoro Timer + Focus Music",
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 40),
        Text(
          formatTime(remainingSeconds),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 100,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: startPause,
              icon:
              Icon(isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(isRunning ? "Pause" : "Start"),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: reset,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset"),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- MUSIC CARD ----------------

  Widget musicCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playlist[currentSongIndex]
                .replaceAll(".mp3", ""),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: Colors.white),
                  onPressed: previousSong),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                      isMusicPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.deepPurple),
                  onPressed: toggleMusic,
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white),
                  onPressed: nextSong),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.volume_up,
                  color: Colors.white70),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: (val) {
                    setState(() {
                      volume = val;
                      player.setVolume(volume);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
