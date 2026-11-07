import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/game_record.dart';
import 'package:biguess/services/cloud_database_service.dart';

void main() {
  group('GameRecord Model', () {
    test('serializes to JSON correctly', () {
      final record = GameRecord(
        id: 1,
        topic: 'Anime',
        pack: 'Naruto',
        winner: 'Player 1',
        totalTurns: 8,
        durationSeconds: 120,
        createdAt: DateTime.parse('2026-11-05T09:00:00Z'),
      );

      final json = record.toJson();
      expect(json['id'], 1);
      expect(json['topic'], 'Anime');
      expect(json['pack'], 'Naruto');
      expect(json['winner'], 'Player 1');
      expect(json['totalTurns'], 8);
      expect(json['durationSeconds'], 120);
      expect(json['created_at'], '2026-11-05T09:00:00.000Z');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 42,
        'topic': 'Geography',
        'pack': 'Flags',
        'winner': 'Player 2',
        'total_turns': 5,
        'duration_seconds': 65,
        'created_at': '2026-11-05 09:15:00',
      };

      final record = GameRecord.fromJson(json);
      expect(record.id, 42);
      expect(record.topic, 'Geography');
      expect(record.pack, 'Flags');
      expect(record.winner, 'Player 2');
      expect(record.totalTurns, 5);
      expect(record.durationSeconds, 65);
      expect(record.createdAt, isNotNull);
    });

    test('handles fallback and string types in JSON gracefully', () {
      final json = {
        'id': '99',
        'topic': 'Anime',
        'pack': 'One Piece',
        'winner': 'Player 1',
        'totalTurns': '14',
        'durationSeconds': '180',
      };

      final record = GameRecord.fromJson(json);
      expect(record.id, 99);
      expect(record.totalTurns, 14);
      expect(record.durationSeconds, 180);
      expect(record.createdAt, isNull);
    });
  });

  group('CloudDatabaseService', () {
    test('initializes with default endpoint', () {
      final service = CloudDatabaseService();
      expect(service, isNotNull);
    });
  });
}
