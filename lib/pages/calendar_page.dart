import 'package:flutter/material.dart';
import 'package:bench/services/notification_service.dart';
import 'package:bench/database/database_helper.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final List<String> days = [
    "Lunedì",
    "Martedì",
    "Mercoledì",
    "Giovedì",
    "Venerdì",
    "Sabato",
    "Domenica",
  ];

  List<List<ScheduledNotification>> notifications =
      List.generate(7, (_) => []);

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      await debugNotifications();

      final savedNotifications = await getNotifications();

      print("LOADED NOTIFICATIONS: $savedNotifications");

      final loadedNotifications =
          List.generate(7, (_) => <ScheduledNotification>[]);

      for (final notification in savedNotifications) {
        final dayIndex = notification.dayOfWeek - 1;

        if (dayIndex >= 0 && dayIndex < 7) {
          loadedNotifications[dayIndex].add(notification);
        }
      }

      if (!mounted) return;

      setState(() {
        notifications = loadedNotifications;
        loading = false;
      });
    } catch (e) {
      print("ERROR LOADING NOTIFICATIONS: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> addNotification(int dayIndex) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: NotificationService.getCurrentLocalTime(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final dayOfWeek = dayIndex + 1;

    final alreadyExists = notifications[dayIndex].any(
      (notification) =>
          notification.hour == selectedTime.hour &&
          notification.minute == selectedTime.minute,
    );

    if (alreadyExists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Esiste già una notifica a questo orario.",
          ),
        ),
      );

      return;
    }

    try {
      final notification = ScheduledNotification(
        dayOfWeek: dayOfWeek,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );

      // Save to SQLite.
      final databaseId = await insertNotification(notification);

      debugPrint(
        "Notification saved to database with ID: $databaseId",
      );

      if (databaseId <= 0) {
        throw Exception(
          "Database did not return a valid notification ID.",
        );
      }

      // Schedule Android notification.
      await NotificationService.scheduleWeeklyNotification(
        id: databaseId,
        dayOfWeek: dayOfWeek,
        time: selectedTime,
      );

      final savedNotification = ScheduledNotification(
        id: databaseId,
        dayOfWeek: dayOfWeek,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );

      if (!mounted) return;

      setState(() {
        notifications[dayIndex].add(savedNotification);

        notifications[dayIndex].sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;

          return aMinutes.compareTo(bMinutes);
        });
      });
    } catch (e) {
      debugPrint("ERROR adding notification: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Errore: $e",
          ),
        ),
      );
    }
  }

  Future<void> removeNotification(
    int dayIndex,
    int notificationIndex,
  ) async {
    final notification =
        notifications[dayIndex][notificationIndex];

    final id = notification.id;

    if (id == null) return;

    try {
      await NotificationService.cancelNotification(id);

      await deleteNotification(id);

      if (!mounted) return;

      setState(() {
        notifications[dayIndex].removeAt(notificationIndex);
      });
    } catch (e) {
      debugPrint("ERROR removing notification: $e");
    }
  }

  String formatTime(ScheduledNotification notification) {
    return "${notification.hour.toString().padLeft(2, '0')}:"
        "${notification.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Calendario",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2845),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Scegli quando ricevere una notifica per segnare le presenze.",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemCount: days.length,

                        itemBuilder: (context, dayIndex) {
                          final dayNotifications =
                              notifications[dayIndex];

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          days[dayIndex],
                                          style:
                                              const TextStyle(
                                            fontSize: 17,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                Color(0xFF1B2845),
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        onPressed: () {
                                          addNotification(
                                            dayIndex,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add,
                                          color:
                                              Color(0xFFFF6B35),
                                        ),
                                        tooltip:
                                            "Aggiungi notifica",
                                      ),
                                    ],
                                  ),

                                  if (dayNotifications.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Nessuna notifica",
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),

                                  if (dayNotifications.isNotEmpty)
                                    const SizedBox(height: 4),

                                  ...List.generate(
                                    dayNotifications.length,
                                    (notificationIndex) {
                                      final notification =
                                          dayNotifications[
                                              notificationIndex];

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(
                                          top: 6,
                                        ),

                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color: const Color(
                                            0xFFF5F5F0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                            8,
                                          ),
                                        ),

                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .notifications_outlined,
                                              size: 20,
                                              color:
                                                  Color(0xFFFF6B35),
                                            ),

                                            const SizedBox(
                                              width: 10,
                                            ),

                                            Text(
                                              formatTime(
                                                notification,
                                              ),
                                              style:
                                                  const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w500,
                                                color: Color(
                                                  0xFF1B2845,
                                                ),
                                              ),
                                            ),

                                            const Spacer(),

                                            IconButton(
                                              onPressed: () {
                                                removeNotification(
                                                  dayIndex,
                                                  notificationIndex,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
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