// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'transactions.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            isExpense INTEGER,
            amount REAL,
            note TEXT,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert('transactions', txn.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }
}
