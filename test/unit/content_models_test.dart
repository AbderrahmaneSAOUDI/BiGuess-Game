import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/domain/models/card.dart' as domain;
import 'package:gdg_guess_game/domain/models/content_validator.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';

Map<String, dynamic> topicJson() => {
      'id': 'topic-01',
      'name': 'Original shapes',
      'published': true,
      'deleted': false,
      'revision': 3,
    };

Map<String, dynamic> packJson() => {
      'id': 'pack-01',
      'topicId': 'topic-01',
      'name': 'Paper shapes',
      'published': true,
      'deleted': false,
      'revision': 2,
    };

Map<String, dynamic> cardJson() => {
      'id': 'card-01',
      'packId': 'pack-01',
      'name': 'Étoile 紙',
      'imageReference': 'assets/Original shapes/Étoile 紙.webp',
      'difficulty': 2,
    };

Map<String, dynamic> roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

domain.Card card(String id, {String packId = 'pack-01'}) => domain.Card(
      id: id,
      packId: packId,
      name: 'Paper shape',
      imageReference: 'images/$id.webp',
      difficulty: Difficulty.easy,
    );

void main() {
  group('Canonical serialization and value equality', () {
    test('Topic and Pack preserve operational state', () {
      final topic = Topic.fromJson(topicJson());
      final pack = Pack.fromJson(packJson());
      expect(topic.toJson(), topicJson());
      expect(pack.toJson(), packJson());
      final topicCopy = Topic.fromJson(roundTrip(topic.toJson()));
      final packCopy = Pack.fromJson(roundTrip(pack.toJson()));
      expect(topicCopy, topic);
      expect(topicCopy.hashCode, topic.hashCode);
      expect(packCopy, pack);
      expect(packCopy.hashCode, pack.hashCode);
      expect({topic, topicCopy}, hasLength(1));
      expect({pack, packCopy}, hasLength(1));
    });

    test('Card round trip has only ID and the four canonical product fields',
        () {
      final original = domain.Card.fromJson(cardJson());
      expect(
          original.toJson().keys,
          unorderedEquals([
            'id',
            'packId',
            'name',
            'imageReference',
            'difficulty',
          ]));
      expect(original.toJson(), cardJson());
      final copy = domain.Card.fromJson(roundTrip(original.toJson()));
      expect(copy, original);
      expect(copy.hashCode, original.hashCode);
      expect({original, copy}, hasLength(1));
      expect(copy.name, 'Étoile 紙');
      expect(copy.imageReference, 'assets/Original shapes/Étoile 紙.webp');
    });

    test('every field participates in equality', () {
      final topic = Topic.fromJson(topicJson());
      final pack = Pack.fromJson(packJson());
      final originalCard = domain.Card.fromJson(cardJson());
      for (final entry in <String, dynamic>{
        'id': 'other-topic',
        'name': 'Other name',
        'published': false,
        'deleted': true,
        'revision': 4,
      }.entries) {
        expect(Topic.fromJson({...topicJson(), entry.key: entry.value}),
            isNot(topic),
            reason: entry.key);
      }
      for (final entry in <String, dynamic>{
        'id': 'other-pack',
        'topicId': 'other-topic',
        'name': 'Other name',
        'published': false,
        'deleted': true,
        'revision': 4,
      }.entries) {
        expect(
            Pack.fromJson({...packJson(), entry.key: entry.value}), isNot(pack),
            reason: entry.key);
      }
      for (final entry in <String, dynamic>{
        'id': 'other-card',
        'packId': 'other-pack',
        'name': 'Other name',
        'imageReference': 'other.webp',
        'difficulty': 3,
      }.entries) {
        expect(domain.Card.fromJson({...cardJson(), entry.key: entry.value}),
            isNot(originalCard),
            reason: entry.key);
      }
      expect(topic == Object(), isFalse);
      expect(pack == Object(), isFalse);
      expect(originalCard == Object(), isFalse);
    });

    test('input and serialized map mutations cannot change models', () {
      final input = cardJson();
      final original = domain.Card.fromJson(input);
      input['name'] = 'Changed';
      original.toJson()['name'] = 'Also changed';
      expect(original.name, 'Étoile 紙');
      final topic = Topic.fromJson(topicJson());
      final pack = Pack.fromJson(packJson());
      topic.toJson()['revision'] = 50;
      pack.toJson()['published'] = false;
      expect(topic.revision, 3);
      expect(pack.published, isTrue);
    });

    test('opaque IDs survive renames and are not derived from topic names', () {
      const id = 'c91a0470-138e-4f24-8df7-86730c84d233';
      final topic = Topic(id: id, name: 'Original shapes');
      final renamed = Topic(id: id, name: 'Renamed shapes');
      expect(renamed.id, topic.id);
      expect(renamed, isNot(topic));
    });
  });

  group('Difficulty', () {
    test('has exactly Easy=1, Medium=2, Hard=3 with integer round trips', () {
      expect(Difficulty.values, [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
      ]);
      for (var value = 1; value <= 3; value++) {
        final difficulty = Difficulty.fromValue(value);
        expect(difficulty.toJson(), value);
        expect(Difficulty.fromJson(jsonDecode(jsonEncode(value))), difficulty);
        expect(
            domain.Card.fromJson({...cardJson(), 'difficulty': value})
                .difficulty,
            difficulty);
      }
    });

    test('rejects out-of-range levels', () {
      for (final value in [-100, -1, 0, 4, 100]) {
        expect(() => Difficulty.fromValue(value), throwsRangeError);
        expect(() => domain.Card.fromJson({...cardJson(), 'difficulty': value}),
            throwsRangeError);
      }
    });

    test('rejects missing, fractional, string and boolean difficulty', () {
      for (final value in [null, 1.0, 1.5, '1', 'easy', true]) {
        expect(() => Difficulty.fromJson(value), throwsFormatException);
        expect(() => domain.Card.fromJson({...cardJson(), 'difficulty': value}),
            throwsFormatException);
      }
      expect(() => domain.Card.fromJson(cardJson()..remove('difficulty')),
          throwsFormatException);
    });
  });

  group('Field validation at construction and deserialization', () {
    test('invalid IDs and parent IDs are rejected without relying on asserts',
        () {
      for (final id in [
        '',
        ' ',
        ' topic',
        'topic ',
        'a b',
        'a\tb',
        'a\nb',
        'a\u0000b',
        'a\u007fb'
      ]) {
        expect(() => Topic(id: id, name: 'Shapes'), throwsArgumentError);
        expect(() => Pack(id: id, topicId: 'topic-01', name: 'Shapes'),
            throwsArgumentError);
        expect(() => Pack(id: 'pack-01', topicId: id, name: 'Shapes'),
            throwsArgumentError);
        expect(() => card(id), throwsArgumentError);
        expect(() => card('card-01', packId: id), throwsArgumentError);
        expect(() => Topic.fromJson({...topicJson(), 'id': id}),
            throwsArgumentError);
        expect(() => Pack.fromJson({...packJson(), 'topicId': id}),
            throwsArgumentError);
        expect(() => domain.Card.fromJson({...cardJson(), 'packId': id}),
            throwsArgumentError);
      }
    });

    test('names and image references must be nonempty and trimmed', () {
      for (final value in ['', ' ', ' Leading', 'Trailing ']) {
        expect(() => Topic.fromJson({...topicJson(), 'name': value}),
            throwsArgumentError);
        expect(() => Pack.fromJson({...packJson(), 'name': value}),
            throwsArgumentError);
        for (final field in ['name', 'imageReference']) {
          expect(() => domain.Card.fromJson({...cardJson(), field: value}),
              throwsArgumentError);
        }
      }
    });

    test('required strings reject missing and wrong JSON types', () {
      final cases = [
        (topicJson(), Topic.fromJson, ['id', 'name']),
        (packJson(), Pack.fromJson, ['id', 'topicId', 'name']),
        (
          cardJson(),
          domain.Card.fromJson,
          ['id', 'packId', 'name', 'imageReference']
        ),
      ];
      for (final (json, parse, fields) in cases) {
        for (final field in fields) {
          expect(() => parse({...json}..remove(field)), throwsFormatException);
          for (final value in [null, 1, true, <String>[]]) {
            expect(() => parse({...json, field: value}), throwsFormatException);
          }
        }
      }
    });

    test('operational defaults are draft, retained, revision 1', () {
      final topic = Topic(id: 'topic-01', name: 'Shapes');
      final pack = Pack(id: 'pack-01', topicId: topic.id, name: 'Paper');
      for (final json in [topic.toJson(), pack.toJson()]) {
        expect(json['published'], isFalse);
        expect(json['deleted'], isFalse);
        expect(json['revision'], 1);
      }
      expect(Topic.fromJson({'id': topic.id, 'name': topic.name}), topic);
      expect(
          Pack.fromJson({
            'id': pack.id,
            'topicId': topic.id,
            'name': pack.name,
          }),
          pack);
    });

    test('publication and deletion remain independent state', () {
      for (final published in [false, true]) {
        for (final deleted in [false, true]) {
          final topic = Topic.fromJson({
            ...topicJson(),
            'published': published,
            'deleted': deleted,
          });
          final pack = Pack.fromJson({
            ...packJson(),
            'published': published,
            'deleted': deleted,
          });
          expect(topic.published, published);
          expect(topic.deleted, deleted);
          expect(pack.published, published);
          expect(pack.deleted, deleted);
        }
      }
    });

    test('invalid operational JSON types and revisions fail', () {
      for (final parse in [Topic.fromJson, Pack.fromJson]) {
        final json = parse == Topic.fromJson ? topicJson() : packJson();
        for (final field in ['published', 'deleted']) {
          for (final value in [null, 'false', 0]) {
            expect(() => parse({...json, field: value}), throwsFormatException);
          }
        }
        for (final value in [null, '1', 1.0, true]) {
          expect(
              () => parse({...json, 'revision': value}), throwsFormatException);
        }
        for (final value in [0, -1]) {
          expect(() => parse({...json, 'revision': value}), throwsRangeError);
        }
      }
      expect(
          () => Topic(id: 't', name: 'Shapes', revision: 0), throwsRangeError);
      expect(() => Pack(id: 'p', topicId: 't', name: 'Paper', revision: -1),
          throwsRangeError);
    });
  });

  group('Content relationships and playable Pack minimum', () {
    final topic = Topic.fromJson(topicJson());
    final pack = Pack.fromJson(packJson());
    final cards = [card('card-01'), card('card-02')];

    test('accepts a complete hierarchy, regardless of input order', () {
      ContentValidator.validateRelations(
          topics: [topic], packs: [pack], cards: cards.reversed);
      ContentValidator.validatePlayablePack(pack: pack, cards: cards);
    });

    test('rejects orphaned Pack and Card relationships', () {
      expect(
          () => ContentValidator.validateRelations(
              topics: [], packs: [pack], cards: []),
          throwsArgumentError);
      expect(
          () => ContentValidator.validateRelations(
              topics: [topic], packs: [], cards: cards),
          throwsArgumentError);
      expect(
          () => ContentValidator.validateRelations(
              topics: [Topic(id: 'other', name: 'Other')],
              packs: [pack],
              cards: cards),
          throwsArgumentError);
      expect(
          () => ContentValidator.validateRelations(
              topics: [topic],
              packs: [pack],
              cards: [card('c', packId: 'other')]),
          throwsArgumentError);
    });

    test('rejects duplicate IDs within each entity type', () {
      expect(
          () => ContentValidator.validateRelations(topics: [
                topic,
                Topic.fromJson({...topicJson(), 'name': 'Other'})
              ], packs: [
                pack
              ], cards: cards),
          throwsArgumentError);
      expect(
          () => ContentValidator.validateRelations(
              topics: [topic],
              packs: [pack, Pack.fromJson(packJson())],
              cards: cards),
          throwsArgumentError);
      expect(
          () => ContentValidator.validateRelations(
              topics: [topic],
              packs: [pack],
              cards: [...cards, card('card-01')]),
          throwsArgumentError);
    });

    test('empty or one-Card drafts are valid records but not playable', () {
      for (final count in [0, 1]) {
        final draftCards = cards.take(count);
        ContentValidator.validateRelations(
            topics: [topic], packs: [pack], cards: draftCards);
        expect(
            () => ContentValidator.validatePlayablePack(
                pack: pack, cards: draftCards),
            throwsArgumentError);
      }
    });

    test('minimum counts distinct IDs belonging to the correct Pack', () {
      expect(
          () => ContentValidator.validatePlayablePack(
              pack: pack, cards: [cards.first, cards.first]),
          throwsArgumentError);
      expect(
          () => ContentValidator.validatePlayablePack(
              pack: pack,
              cards: [cards.first, card('other', packId: 'other-pack')]),
          throwsArgumentError);
      ContentValidator.validatePlayablePack(pack: pack, cards: cards);
      ContentValidator.validatePlayablePack(
          pack: pack, cards: [...cards, card('card-03')]);
    });
  });
}
