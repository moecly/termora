import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('termora_jsonstore');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('missing file returns null', () async {
    final store = JsonStore(File('${dir.path}/missing.json'));
    expect(await store.read(), isNull);
  });

  test('write then read round-trips', () async {
    final file = File('${dir.path}/data.json');
    final store = JsonStore(file);
    await store.write({'schemaVersion': 1, 'name': 'prod'});
    final read = await store.read();
    expect(read, {'schemaVersion': 1, 'name': 'prod'});
    expect(file.readAsStringSync(), contains('"prod"'));
  });

  test('corrupt JSON is quarantined and returns null', () async {
    final file = File('${dir.path}/broken.json');
    await file.writeAsString('{ not valid json');
    final store = JsonStore(file);

    expect(await store.read(), isNull);
    expect(await file.exists(), isFalse);

    final quarantined = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('.corrupt-'))
        .toList();
    expect(quarantined, hasLength(1));
    expect(quarantined.first.readAsStringSync(), '{ not valid json');
  });

  test('atomic write leaves no temporary file behind', () async {
    final store = JsonStore(File('${dir.path}/data.json'));
    await store.write({'a': 1});
    final leftovers = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.tmp'))
        .toList();
    expect(leftovers, isEmpty);
  });

  test('empty file returns null without quarantining', () async {
    final file = File('${dir.path}/empty.json');
    await file.writeAsString('');
    expect(await JsonStore(file).read(), isNull);
    expect(await file.exists(), isTrue);
  });

  test('jsonEncode/decode handles nested structures', () async {
    final store = JsonStore(File('${dir.path}/nested.json'));
    await store.write({
      'servers': [
        {'id': 'srv_1', 'port': 22},
      ],
    });
    final read = await store.read();
    expect(jsonEncode(read), jsonEncode({
      'servers': [
        {'id': 'srv_1', 'port': 22},
      ],
    }));
  });
}
