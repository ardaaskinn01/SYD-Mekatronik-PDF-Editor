import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'formModel.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'forms_2.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE forms_2(num TEXT PRIMARY KEY, pdfFilePath TEXT, musteriAdSoyad TEXT, tarih TEXT)',
        );
      },
    );
  }

  Future<void> insertForm(FormModel form) async {
    final db = await database;

    await db.insert(
      'forms_2',
      form.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FormModel>> getForms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('forms_2');

    return List.generate(maps.length, (i) {
      return FormModel(
        num: maps[i]['num'],
        pdfFilePath: maps[i]['pdfFilePath'],
        musteriAdSoyad: maps[i]['musteriAdSoyad'],
        tarih: maps[i]['tarih'],
      );
    });
  }
}