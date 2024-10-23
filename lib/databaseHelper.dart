import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'formModel.dart';
import 'formModel3.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    try {
      _database = await _initDatabase();
    } catch (e) {
      print('Database initialization error: $e');
    }

    return _database!;
  }
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'my_database.db');

    return await openDatabase(
        path,
        version: 3,
        onCreate: (Database db, int version) async {
          await db.execute(
            'CREATE TABLE forms_4(num TEXT PRIMARY KEY, adSoyad TEXT, adSoyad2 TEXT, adres TEXT, mail TEXT, telefon TEXT, yetkili TEXT, '
                'islemKisaTanim TEXT, islemDetay TEXT, malzeme TEXT, iscilik TEXT, toplam TEXT, '
                'montajChecked INTEGER, bakimChecked INTEGER, tamirChecked INTEGER, revizyonChecked INTEGER, '
                'projeSureciChecked INTEGER, odemeNakitChecked INTEGER, odemeFaturaChecked INTEGER, '
                'odemeCekChecked INTEGER, odemeKartChecked INTEGER, musteriImza TEXT, yetkiliImza TEXT)',
          );
          await db.execute(
            'CREATE TABLE forms_2(num TEXT PRIMARY KEY, pdfFilePath TEXT, musteriAdSoyad TEXT, tarih TEXT)',
          );
        }
    );
  }

  Future<void> insertForm3(FormModel3 form) async {
    final db = await database;
    await db.insert(
      'forms_4',
      {
        'num': form.num,
        'adSoyad': form.adSoyad,
        'adSoyad2': form.adSoyad2,
        'adres': form.adres,
        'mail': form.mail,
        'telefon': form.telefon,
        'yetkili': form.yetkili,
        'islemKisaTanim': form.islemKisaTanim,
        'islemDetay': form.islemDetay,
        'malzeme': form.malzeme,
        'iscilik': form.iscilik,
        'toplam': form.toplam,
        'montajChecked': form.montajChecked ? 1 : 0,
        'bakimChecked': form.bakimChecked ? 1 : 0,
        'tamirChecked': form.tamirChecked ? 1 : 0,
        'revizyonChecked': form.revizyonChecked ? 1 : 0,
        'projeSureciChecked': form.projeSureciChecked ? 1 : 0,
        'odemeNakitChecked': form.odemeNakitChecked ? 1 : 0,
        'odemeFaturaChecked': form.odemeFaturaChecked ? 1 : 0,
        'odemeCekChecked': form.odemeCekChecked ? 1 : 0,
        'odemeKartChecked': form.odemeKartChecked ? 1 : 0,
        'musteriImza': base64Encode(form.musteriImza), // Base64 formatında sakla
        'yetkiliImza': base64Encode(form.yetkiliImza), // Base64 formatında sakla
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertForm(FormModel form) async {
    final db = await database;

    // Formun mevcut olup olmadığını kontrol et
    final existingForms = await db.query(
      'forms_2',
      where: 'num = ?',
      whereArgs: [form.num],
    );

    if (existingForms.isNotEmpty) {
      // Eğer form mevcutsa, güncelle
      await updateForm(form);
    } else {
      // Eğer mevcut değilse, yeni formu ekle
      await db.insert(
        'forms_2',
        form.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, // Çakışma durumunda eski kaydı güncelle
      );
    }
  }

  Future<int> updateForm(FormModel form) async {
    final db = await database;
    return await db.update(
      'forms_2',  // Tablo adı
      form.toMap(),
      where: 'num = ?',
      whereArgs: [form.num],
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

  Future<FormModel3?> getForms2ByNum(String num) async {
    final db = await database;

    // forms_2 tablosunda seri numarasını arayın
    final List<Map<String, dynamic>> forms2Maps = await db.query(
      'forms_2',
      where: 'num = ?',
      whereArgs: [num],
    );

    // Eğer forms_2'de bulunursa, forms_3'te arama yapın
    if (forms2Maps.isNotEmpty) {
      final List<Map<String, dynamic>> forms3Maps = await db.query(
        'forms_4',
        where: 'num = ?',
        whereArgs: [num],
      );

      if (forms3Maps.isNotEmpty) {
        return FormModel3(
          num: forms3Maps[0]['num'],
          adSoyad: forms3Maps[0]['adSoyad'],
          adSoyad2: forms3Maps[0]['adSoyad2'],
          adres: forms3Maps[0]['adres'],
          mail: forms3Maps[0]['mail'],
          telefon: forms3Maps[0]['telefon'],
          yetkili: forms3Maps[0]['yetkili'],
          islemKisaTanim: forms3Maps[0]['islemKisaTanim'],
          islemDetay: forms3Maps[0]['islemDetay'],
          malzeme: forms3Maps[0]['malzeme'],
          iscilik: forms3Maps[0]['iscilik'],
          toplam: forms3Maps[0]['toplam'],
          montajChecked: forms3Maps[0]['montajChecked'] == 1,
          bakimChecked: forms3Maps[0]['bakimChecked'] == 1,
          tamirChecked: forms3Maps[0]['tamirChecked'] == 1,
          revizyonChecked: forms3Maps[0]['revizyonChecked'] == 1,
          projeSureciChecked: forms3Maps[0]['projeSureciChecked'] == 1,
          odemeNakitChecked: forms3Maps[0]['odemeNakitChecked'] == 1,
          odemeFaturaChecked: forms3Maps[0]['odemeFaturaChecked'] == 1,
          odemeCekChecked: forms3Maps[0]['odemeCekChecked'] == 1,
          odemeKartChecked: forms3Maps[0]['odemeKartChecked'] == 1,
          musteriImza: base64Decode(forms3Maps[0]['musteriImza']),
          yetkiliImza: base64Decode(forms3Maps[0]['yetkiliImza']),
        );
      }
    }
    return null; // Eğer form bulunamazsa null döndür
  }
}