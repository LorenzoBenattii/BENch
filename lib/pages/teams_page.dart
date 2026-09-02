import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bench/database/database_helper.dart';


class TeamsPage extends StatefulWidget {
  final Function(int) onTeamSelected;

  const TeamsPage({super.key, required this.onTeamSelected});

  @override
  State<StatefulWidget> createState() => _TeamsPageState();
}


class _TeamsPageState extends State<TeamsPage> {
  List<Team> teams = [];

  Future<void> loadTeams() async {
    final loadedTeams =  await getTeams();

    setState(() {
      teams = loadedTeams;
    });
  }

  Future<String> askTeamName() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Inserisci Nome Squadra"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: "Inserisci Nome"
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              }, 
              child: const Text("OK"))
          ],
        );
      });
    return result ?? "";
  }



  @override
  void initState() {
    super.initState();
    loadTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: const Color(0xFFF5F5F0),
      body: ListView.builder(
        itemCount: teams.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(8),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.2, //adjuts thickness
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      await deleteTeam(teams[index]);
                      await loadTeams();

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    onTap: () {
                      widget.onTeamSelected(teams[index].id!);
                    },
                    title: Text(teams[index].name,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4ECDC4),
                    child: Icon(Icons.groups, color:Color(0xFF1B2845)),
                  ),
                  ),
                ),
              ),
            ),
          );
                    
          
        }
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B35),
        onPressed: () async {
          final name = await askTeamName();

          if (name.isEmpty) return;

          Team team = Team(name: name);

          await insertTeam(team);

          await loadTeams();
        },
        child: const Icon(Icons.add, color: Color(0xFFF5F5F0),),),
    );
  }
}