import 'package:flutter/material.dart';
import 'package:bench/database/database_helper.dart';

class AttendanceSheet extends StatefulWidget {
  final int sessionId;
  final int teamId;

  const AttendanceSheet({
    super.key,
    required this.sessionId,
    required this.teamId,
  });

  @override
  State<AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<AttendanceSheet> {
  List<Player> players = [];
  List<Attendance> attendance = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final loadedPlayers = await getPlayers(widget.teamId);
    final loadedAttendance = await getAttendance(widget.sessionId);

    setState(() {
      players = loadedPlayers;
      attendance = loadedAttendance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [

          const Text(
            "Attendance",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // PUT IT HERE
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {

                final player = players[index];

                final playerAttendance = attendance.firstWhere(
                  (a) => a.playerId == player.id,
                );

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(player.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          playerAttendance.present = 0;

                          await editAttendance(playerAttendance);
                          await loadData();
                        },
                        icon: Icon(
                          Icons.close,
                          color: playerAttendance.present == 0
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),

                      IconButton(
                        onPressed: () async {
                          playerAttendance.present = 1;

                          await editAttendance(playerAttendance);
                          await loadData();
                        },
                        icon: Icon(
                          Icons.check,
                          color: playerAttendance.present == 1
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}