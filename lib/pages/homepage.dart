import 'package:flutter/material.dart';
import 'package:bench/pages/team_detail_page.dart';
import 'package:bench/pages/teams_page.dart';
import 'package:bench/pages/calendar_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? selectedTeamId;

  int selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2845),

        title: const Text(
          "BENch",
          style: TextStyle(
            color: Color(0xFFF5F5F0),
          ),
        ),
      ),

      body: selectedPage == 0
          ? selectedTeamId == null
              ? TeamsPage(
                  onTeamSelected: (teamId) {
                    setState(() {
                      selectedTeamId = teamId;
                    });
                  },
                )
              : TeamDetailPage(
                  teamId: selectedTeamId!,
                )
          : const CalendarPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,

        backgroundColor: const Color(0xFF1B2845),

        indicatorColor: const Color(0xFFFF6B35),

        onDestinationSelected: (index) {
          setState(() {
            selectedPage = index;

            if (index == 0) {
              selectedTeamId = null;
            }
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: Color(0xFFF5F5F0),
            ),
            selectedIcon: Icon(
              Icons.home,
              color: Color(0xFF1B2845),
            ),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFF5F5F0),
            ),
            selectedIcon: Icon(
              Icons.calendar_month,
              color: Color(0xFF1B2845),
            ),
            label: "Calendario",
          ),
        ],

        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.bold,
              );
            }

            return const TextStyle(
              color: Color(0xFFF5F5F0),
            );
          },
        ),
      ),
    );
  }
}