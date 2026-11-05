/// Represents a completed BiGuess game round stored in Cloudflare D1.
class GameRecord {
  final int? id;
  final String topic;
  final String pack;
  final String winner;
  final int totalTurns;
  final int durationSeconds;
  final DateTime? createdAt;

  const GameRecord({
    this.id,
    required this.topic,
    required this.pack,
    required this.winner,
    required this.totalTurns,
    this.durationSeconds = 0,
    this.createdAt,
  });

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final rawTurns = json['total_turns'] ?? json['totalTurns'];
    final totalTurns = rawTurns is int ? rawTurns : int.tryParse(rawTurns?.toString() ?? '') ?? 0;

    final rawDuration = json['duration_seconds'] ?? json['durationSeconds'];
    final durationSeconds =
        rawDuration is int ? rawDuration : int.tryParse(rawDuration?.toString() ?? '') ?? 0;

    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString());
    }

    return GameRecord(
      id: id,
      topic: json['topic'] as String? ?? '',
      pack: json['pack'] as String? ?? '',
      winner: json['winner'] as String? ?? '',
      totalTurns: totalTurns,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'topic': topic,
      'pack': pack,
      'winner': winner,
      'totalTurns': totalTurns,
      'durationSeconds': durationSeconds,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
