import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bench/database/database_helper.dart';
import 'package:bench/pages/player_detail_page.dart';
import 'package:bench/widgets/attendace_sheet.dart';

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';



class TeamDetailPage extends StatefulWidget {
  final int teamId;
  const TeamDetailPage({super.key, required this.teamId});

  @override
  State<StatefulWidget> createState() => _TeamDetailPageState();
}


class _TeamDetailPageState extends State<TeamDetailPage> {
  
  List<Player> players = [];
  List<Session> sessions = [];
  int selectedTab = 0;

  Future<void> loadPlayers() async {
    final loadedPlayers = await getPlayers(widget.teamId);

    setState(() {
      players = loadedPlayers;
    });
  }

  Future<void> loadSessions() async {
    final loadedSessions = await getSessions(widget.teamId);

    setState(() {
      sessions = loadedSessions;
    });
  }

  
  Future<Map<String, String>?> askPlayerInfo() async {
    final nameController = TextEditingController();

    String? selectedPosition;

    const positions = [
      "Palleggiatore",
      "Opposto",
      "Centrale",
      "Schiacciatore",
      "Libero",
    ];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Aggiungi Giocatore"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
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
                ],
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
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    Navigator.pop(context, {
                      "name": name,
                      "position": selectedPosition ?? "",
                    });
                  },
                  child: const Text("Aggiungi"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> exportAttendance() async {
    final attendanceData = await getTeamAttendance(widget.teamId);

    final List<List<dynamic>> rows = [];

    // CSV header
    rows.add([
      "Player",
      "Position",
      "Attendance %",
    ]);

    for (final player in attendanceData) {
      final totalSessions = player["totalSessions"] as int;
      final presentSessions = player["presentSessions"] as int;

      final percentage = totalSessions == 0
          ? 0.0
          : (presentSessions / totalSessions) * 100;

      rows.add([
        player["playerName"],
        player["position"] ?? "",
        percentage.toStringAsFixed(1),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();

    final file = File(
      "${directory.path}/team_attendance.csv",
    );

    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path),
        ],
        title: "Team Attendance",
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    loadPlayers();
    loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: exportAttendance,
            icon: const Icon(Icons.download),
            tooltip: "Esporta presenze",)
        ],
        bottom: TabBar(

          onTap: (index) {
            setState(() {
              selectedTab = index;
            });
          },

          tabs: [
            Tab(
              text: "Allenamenti",
              icon: Icon(Icons.calendar_month)
            ),
            Tab(
              text: "Giocatori",
              icon: Icon(Icons.people),
            )
          ]),
      ),
      backgroundColor: Color(0xFFF5F5F0),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          
          // Il container dentro il sessions tab
          ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8),
                child: Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.2,
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await deleteSession(sessions[index]);
                          await loadSessions();
                        },
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFFE63946),
                        icon: Icons.delete,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),

                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(
                        "${sessions[index].date.day.toString().padLeft(2, '0')}-"
                        "${sessions[index].date.month.toString().padLeft(2, '0')}-"
                        "${sessions[index].date.year}",
                      ),
                      onTap: () {
                        
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return AttendanceSheet(
                              sessionId: sessions[index].id!,
                              teamId: sessions[index].teamId,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),


          // Il container dentro il players tab
          ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8),
                child: Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(), 
                    extentRatio: 0.2,
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await deletePlayer(players[index]);
                          await loadPlayers();
                        },

                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFFE63946),
                        icon: Icons.delete,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ]),

                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ListTile(
                          title: Text(players[index].name,
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontWeight: FontWeight.w500
                          ),),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF4ECDC4),
                            child: Icon(Icons.person, color:Color(0xFF1B2845)),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerDetailPage(
                                  playerId: players[index].id!))
                            );
                          },
                        ), 
                        ),
                    )
                  ),
              );
            }
          ),
        ],   
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B35),
        onPressed: () async {
          if (selectedTab == 1) {
            //add player

            final playerInfo = await askPlayerInfo();
            if (playerInfo == null) return;

            final player = Player(
              name: playerInfo["name"]!,
              ruolo: playerInfo["position"]!.isEmpty
                  ? null
                  : playerInfo["position"],
              teamId: widget.teamId,
            );

            final playerId = await insertPlayer(player);

            await createAttendanceForPlayer(
              playerId,
              widget.teamId,
            );

            await loadPlayers();

          }

          else {
            // add session

            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );

            if (date == null) return;

            Session session = Session(
              teamId: widget.teamId,
              date: date,
            );

            final sessionId = await insertSession(session);

            await createAttendanceForSession(
              sessionId,
              widget.teamId,
            );

            await loadSessions();
          }
        },
        
        child: Icon(
          selectedTab == 1 
            ? Icons.person_add
            : Icons.add,
          color: const Color(0xFFF5F5F0),
        
        ),
        ),
      
      
      
      
      

    
    ),
    );
    
    
    
    
  }
}