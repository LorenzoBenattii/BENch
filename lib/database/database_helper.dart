import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Team {
  final int? id;
  String name;

  Team({this.id, required this.name});

  Map<String, Object?> toMap() {
    return {"name": name};
  }
}

class Player {
  final int? id;
  String name;
  String? ruolo;
  final int teamId;
  String? certificatoScadenza;

  Player({
    this.id,
    required this.name,
    this.ruolo,
    this.certificatoScadenza,
    required this.teamId,
  });

  Map<String, Object?> toMap() {
    return {
      "name": name,
      "ruolo": ruolo,
      "certificatoScadenza": certificatoScadenza,
      "teamId": teamId,
    };
  }
}

class Session {
  final int? id;
  final int teamId;
  final DateTime date;

  Session({
    this.id,
    required this.teamId,
    required this.date,
  });

  Map<String, Object?> toMap() {
    return {
      "teamId": teamId,
      "date": date.toIso8601String().split("T")[0],
    };
  }
}

class Attendance {
  final int? id;
  final int playerId;
  final int sessionId;
  int present;

  Attendance({
    this.id,
    required this.playerId,
    required this.sessionId,
    required this.present,
  });

  Map<String, Object?> toMap() {
    return {
      "playerId": playerId,
      "sessionId": sessionId,
      "present": present,
    };
  }
}

class PlayerAttendance {
  final int sessionId;
  final DateTime date;
  final int present;

  PlayerAttendance({
    required this.sessionId,
    required this.date,
    required this.present,
  });
}


/// Represents a scheduled weekly notification.
class ScheduledNotification {
  final int? id;
  final int dayOfWeek;
  final int hour;
  final int minute;

  ScheduledNotification({
    this.id,
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
  });

  Map<String, Object?> toMap() {
    return {
      "dayOfWeek": dayOfWeek,
      "hour": hour,
      "minute": minute,
    };
  }
}


Future<Database> getDatabase() async {
  final path = await getDatabasesPath();

  return openDatabase(
    join(path, 'teams_database.db'),

    version: 1,

    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE teams(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
      );

      await db.execute('''
        CREATE TABLE players(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          ruolo TEXT,
          teamId INTEGER NOT NULL,
          certificatoScadenza TEXT,
          FOREIGN KEY (teamId) REFERENCES teams(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          teamId INTEGER NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (teamId) REFERENCES teams(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE attendance(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playerId INTEGER NOT NULL,
          sessionId INTEGER NOT NULL,
          present INTEGER NOT NULL,
          FOREIGN KEY (playerId) REFERENCES players(id),
          FOREIGN KEY (sessionId) REFERENCES sessions(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dayOfWeek INTEGER NOT NULL,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          UNIQUE(dayOfWeek, hour, minute)
        )
      ''');
    },
  );
}


Future<void> resetDatabase() async {
  final path = await getDatabasesPath();

  await deleteDatabase(
    join(path, 'teams_database.db'),
  );
}


// ============================================================
// NOTIFICATIONS
// ============================================================

/// Saves a new notification and returns its database ID.
Future<int> insertNotification(
  ScheduledNotification notification,
) async {
  final db = await getDatabase();

  return await db.insert(
    "notifications",
    notification.toMap(),
  );
}

/// Returns all saved notifications.
Future<List<ScheduledNotification>> getNotifications() async {
  final db = await getDatabase();

  final notificationMaps = await db.query(
    "notifications",
    orderBy: "dayOfWeek ASC, hour ASC, minute ASC",
  );

  return [
    for (final notification in notificationMaps)
      ScheduledNotification(
        id: notification["id"] as int,
        dayOfWeek: notification["dayOfWeek"] as int,
        hour: notification["hour"] as int,
        minute: notification["minute"] as int,
      ),
  ];
}

Future<void> debugNotifications() async {
  final db = await getDatabase();

  final result = await db.query("notifications");

  print("================================");
  print("NOTIFICATIONS IN DATABASE:");
  print(result);
  print("================================");
}


/// Deletes a notification from the database.
Future<void> deleteNotification(
  int notificationId,
) async {
  final db = await getDatabase();

  await db.delete(
    "notifications",
    where: "id = ?",
    whereArgs: [notificationId],
  );
}


// ============================================================
// PLAYERS
// ============================================================

Future<int> insertPlayer(Player player) async {
  final db = await getDatabase();

  return await db.insert(
    "players",
    player.toMap(),
  );
}


Future<List<Player>> getPlayers(int teamId) async {
  final db = await getDatabase();

  final List<Map<String, Object?>> playerMaps =
      await db.query(
    "players",
    where: "teamId = ?",
    whereArgs: [teamId],
  );

  return [
    for (final {
      "id": id as int,
      "name": name as String,
      "ruolo": ruolo as String?,
      "teamId": playerTeamId as int
    } in playerMaps)
      Player(
        name: name,
        teamId: playerTeamId,
        ruolo: ruolo,
        id: id,
      )
  ];
}


Future<Player?> getPlayer(int playerId) async {
  final db = await getDatabase();

  final List<Map<String, Object?>> playerMaps =
      await db.query(
    "players",
    where: "id = ?",
    whereArgs: [playerId],
  );

  if (playerMaps.isEmpty) {
    return null;
  }

  final playerMap = playerMaps.first;

  return Player(
    id: playerMap["id"] as int,
    name: playerMap["name"] as String,
    ruolo: playerMap["ruolo"] as String?,
    teamId: playerMap["teamId"] as int,
  );
}


Future<List<PlayerAttendance>> getPlayerAttendance(
  int playerId,
) async {
  final db = await getDatabase();

  final List<Map<String, Object?>> results =
      await db.rawQuery('''
    SELECT 
      attendance.sessionId,
      attendance.present,
      sessions.date
    FROM attendance
    JOIN sessions
      ON attendance.sessionId = sessions.id
    WHERE attendance.playerId = ?
    ORDER BY sessions.date DESC
  ''', [playerId]);

  return [
    for (final result in results)
      PlayerAttendance(
        sessionId: result["sessionId"] as int,
        date: DateTime.parse(result["date"] as String),
        present: result["present"] as int,
      ),
  ];
}


Future<void> deletePlayer(Player player) async {
  final db = await getDatabase();

  await db.delete(
    "players",
    where: "id = ?",
    whereArgs: [player.id],
  );
}


Future<void> editPlayer(Player player) async {
  final db = await getDatabase();

  await db.update(
    "players",
    player.toMap(),
    where: "id = ?",
    whereArgs: [player.id],
  );
}


// ============================================================
// TEAMS
// ============================================================

Future<void> insertTeam(Team team) async {
  final db = await getDatabase();

  await db.insert(
    "teams",
    team.toMap(),
  );
}


Future<List<Team>> getTeams() async {
  final db = await getDatabase();

  final List<Map<String, Object?>> teamMaps =
      await db.query("teams");

  return [
    for (final {
      "id": id as int,
      "name": name as String
    } in teamMaps)
      Team(
        id: id,
        name: name,
      ),
  ];
}


Future<void> deleteTeam(Team team) async {
  final db = await getDatabase();

  await db.delete(
    "teams",
    where: "id = ?",
    whereArgs: [team.id],
  );
}


Future<void> editTeam(Team team) async {
  final db = await getDatabase();

  await db.update(
    "teams",
    team.toMap(),
    where: "id = ?",
    whereArgs: [team.id],
  );
}


// ============================================================
// SESSIONS
// ============================================================

Future<int> insertSession(Session session) async {
  final db = await getDatabase();

  return await db.insert(
    "sessions",
    session.toMap(),
  );
}


Future<void> createAttendanceForSession(
  int sessionId,
  int teamId,
) async {
  final players = await getPlayers(teamId);

  for (final player in players) {
    final attendance = Attendance(
      playerId: player.id!,
      sessionId: sessionId,
      present: 0,
    );

    await insertAttendance(attendance);
  }
}


Future<void> createAttendanceForPlayer(
  int playerId,
  int teamId,
) async {
  final sessions = await getSessions(teamId);

  for (final session in sessions) {
    final attendance = Attendance(
      playerId: playerId,
      sessionId: session.id!,
      present: 0,
    );

    await insertAttendance(attendance);
  }
}


Future<List<Session>> getSessions(int teamId) async {
  final db = await getDatabase();

  final List<Map<String, Object?>> sessionMaps =
      await db.query(
    "sessions",
    where: "teamId = ?",
    whereArgs: [teamId],
    orderBy: "date DESC",
  );

  return [
    for (final {
      "id": id as int,
      "teamId": sessionTeamId as int,
      "date": date as String
    } in sessionMaps)
      Session(
        id: id,
        teamId: sessionTeamId,
        date: DateTime.parse(date),
      )
  ];
}


Future<void> deleteSession(Session session) async {
  final db = await getDatabase();

  await db.delete(
    "sessions",
    where: "id = ?",
    whereArgs: [session.id],
  );
}


Future<void> editSession(Session session) async {
  final db = await getDatabase();

  await db.update(
    "sessions",
    session.toMap(),
    where: "id = ?",
    whereArgs: [session.id],
  );
}


// ============================================================
// ATTENDANCE
// ============================================================

Future<void> insertAttendance(
  Attendance attendance,
) async {
  final db = await getDatabase();

  await db.insert(
    "attendance",
    attendance.toMap(),
  );
}


Future<List<Attendance>> getAttendance(
  int sessionId,
) async {
  final db = await getDatabase();

  final List<Map<String, Object?>> attendanceMaps =
      await db.query(
    "attendance",
    where: "sessionId = ?",
    whereArgs: [sessionId],
  );

  return [
    for (final {
      "id": id as int,
      "playerId": playerId as int,
      "sessionId": attendanceSessionId as int,
      "present": present as int
    } in attendanceMaps)
      Attendance(
        id: id,
        playerId: playerId,
        sessionId: attendanceSessionId,
        present: present,
      )
  ];
}


Future<void> deleteAttendance(
  Attendance attendance,
) async {
  final db = await getDatabase();

  await db.delete(
    "attendance",
    where: "id = ?",
    whereArgs: [attendance.id],
  );
}


Future<void> editAttendance(
  Attendance attendance,
) async {
  final db = await getDatabase();

  await db.update(
    "attendance",
    attendance.toMap(),
    where: "id = ?",
    whereArgs: [attendance.id],
  );
}


// ============================================================
// TEAM ATTENDANCE
// ============================================================

Future<List<Map<String, dynamic>>> getTeamAttendance(
  int teamId,
) async {
  final db = await getDatabase();

  final results = await db.rawQuery('''
    SELECT
      players.id AS playerId,
      players.name AS playerName,
      players.ruolo AS position,
      COUNT(sessions.id) AS totalSessions,
      SUM(
        CASE
          WHEN attendance.present = 1 THEN 1
          ELSE 0
        END
      ) AS presentSessions
    FROM players

    LEFT JOIN sessions
      ON players.teamId = sessions.teamId

    LEFT JOIN attendance
      ON attendance.playerId = players.id
      AND attendance.sessionId = sessions.id

    WHERE players.teamId = ?

    GROUP BY players.id

    ORDER BY players.name
  ''', [teamId]);

  return results;
}