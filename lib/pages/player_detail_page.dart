import 'package:flutter/material.dart';
import 'package:bench/database/database_helper.dart';


class PlayerDetailPage extends StatefulWidget { 
  final int playerId;
  const PlayerDetailPage({super.key, required this.playerId});

  @override
  State<StatefulWidget> createState() => _PlyerDetailPageState();
}


class _PlyerDetailPageState extends State<PlayerDetailPage> {
  Player? player;
  List<PlayerAttendance> attendance = [];

  @override
  void initState() {
    super.initState();
    loadPlayer();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final loadedAttendance = await getPlayerAttendance(widget.playerId);

    setState(() {
      attendance = loadedAttendance;
    });
  }

  Future<void> loadPlayer() async {
    final loadedPlayer = await getPlayer(widget.playerId);

    setState(() {
      player = loadedPlayer;
    });
  }

  Future<void> editPosition() async {
    String? selectedPosition = player!.ruolo;

    const positions = [
      "Palleggiatore",
      "Opposto",
      "Centrale",
      "Schiacciatore",
      "Libero",
      "Nessun Ruolo"
    ];

    final newPosition = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Inserisci Ruolo"),

              content: DropdownButtonFormField<String>(
                initialValue: selectedPosition,
                decoration: const InputDecoration(
                  labelText: "Ruolo",
                ),
                items: positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedPosition = value;
                  });
                },
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Annulla"),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      selectedPosition,
                    );
                  },
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPosition == null) return;

    player!.ruolo = newPosition;

    await editPlayer(player!);

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalSessions = attendance.length;
    final presentSessions =
        attendance.where((a) => a.present == 1).length;

    final attendancePercentage = totalSessions == 0
        ? 0.0
        : presentSessions / totalSessions;

    return Scaffold(
      appBar: AppBar(
        title: Text(player!.name),
      ),

      backgroundColor: const Color(0xFFF5F5F0),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // PLAYER NAME
            Center(
              child: Text(
                player!.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2845),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // POSITION
            GestureDetector(
              onTap: editPosition,
              child: Text(
                player!.ruolo ?? "Inserisci Ruolo",
                style: TextStyle(
                  fontSize: 18,
                  color: player!.ruolo == null
                      ? Colors.grey
                      : const Color(0xFF2C3E50),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ATTENDANCE GRAPH
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: attendancePercentage,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    color: const Color(0xFF4ECDC4),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(attendancePercentage * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2845),
                      ),
                    ),

                    const Text(
                      "Presenze",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ATTENDANCE TITLE
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Presenze",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2845),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ATTENDANCE LIST
            Expanded(
              child: ListView.builder(
                itemCount: attendance.length,

                itemBuilder: (context, index) {
                  final record = attendance[index];

                  final isPresent = record.present == 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),

                    decoration: BoxDecoration(
                      color: isPresent
                          ? const Color(0xFF4ECDC4)
                          : const Color(0xFFE63946),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: ListTile(
                      leading: Icon(
                        isPresent
                            ? Icons.check
                            : Icons.close,

                        color: Colors.white,
                      ),

                      title: Text(
                        "${record.date.day.toString().padLeft(2, '0')}-"
                        "${record.date.month.toString().padLeft(2, '0')}-"
                        "${record.date.year}",

                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      trailing: Text(
                        isPresent
                            ? "PRESENTE"
                            : "ASSENTE",

                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}