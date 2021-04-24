import 'package:sqflite/sqflite.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'Word.dart';

class DbWidget extends InheritedWidget {
  final _random = new Random();
  Database _database;
  String _databasesPath;

  DbWidget({Key key, @required Widget child})
      : assert(child != null),
        super(key: key, child: child);

  Future<bool> loadDatabasesPath() async {
    _databasesPath = await getDatabasesPath();
    return true;
  }

  Future<bool> openAndInitDatabase() async {
    _database = await openDatabase(
      join(_databasesPath, 'vocabulary.db'),
      onCreate: (db, version) {
        debugPrint("creating databse...");
        db.execute(
            "CREATE TABLE word(id INTEGER PRIMARY KEY, english TEXT, spanish TEXT, correct INTEGER, incorrect INTEGER)");
        db.execute("INSERT INTO word(english, spanish) VALUES('uncle', 'tio')");
        db.execute(
            "INSERT INTO word(english, spanish) VALUES('reader', 'lector')");
        db.execute(
            "INSERT INTO word(english, spanish) VALUES('to keep vigil over', 'velar')");
        db.execute(
            "INSERT INTO word(english, spanish) VALUES('to remove', 'quitar')");
        db.execute(
            "INSERT INTO word(english, spanish) VALUES('to continue', 'reanudar')");
        db.execute(
            "INSERT INTO word(english, spanish) VALUES('until', 'hasta')");
        debugPrint('done');
      },
      version: 1,
    );
    return true;
  }

  Future<Word> loadNextWord(Word priorWord) async {
    final List<Map<String, dynamic>> words = await _database.query('word');
    final List<Word> list = List.generate(words.length, (i) {
      return Word(words[i]['id'], words[i]['english'], words[i]['spanish']);
    });

    Word nextWord = null;

    do {
      int nextWordIndex = _nextRandom(0, list.length);
      nextWord = list[nextWordIndex];
    } while (nextWord == priorWord);

    return nextWord;
  }

  Future<int> addWord(Word word) async {
    return await _database.insert(
      'word',
      word.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteWord(Word word) async {
    return await _database.delete(
      'word',
      where: "id = ?",
      whereArgs: [word.id],
    );
  }

  static DbWidget of(BuildContext context) {
    // return context.inheritFromWidgetOfExactType(DbWidget) as DbWidget;
    return context.dependOnInheritedWidgetOfExactType<DbWidget>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }

  int _nextRandom(int min, int max) => min + _random.nextInt(max - min);
}
