// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _insertFakeTransactions(BuildContext context) async {
    final db = DatabaseHelper();
    final random = Random();

    final expenseCategories = ['Food', 'Transport', 'Entertainment', 'Grocery', 'Others'];
    final incomeCategories = ['薪資', '投資', '獎金', '其他'];

    final List<TransactionModel> fakeExpenses = List.generate(30, (index) {
      final category = expenseCategories[random.nextInt(expenseCategories.length)];
      final amount = 50 + random.nextInt(200) + random.nextDouble();
      final note = '模擬支出 $index';
      final date = DateTime(2025, 3, random.nextInt(28) + 1);

      return TransactionModel(
        category: category,
        isExpense: true,
        amount: double.parse(amount.toStringAsFixed(2)),
        note: note,
        date: date,
      );
    });

    final List<TransactionModel> fakeIncomes = List.generate(10, (index) {
      final category = incomeCategories[random.nextInt(incomeCategories.length)];
      final amount = 500 + random.nextInt(1500) + random.nextDouble();
      final note = '模擬收入 $index';
      final date = DateTime(2025, 3, random.nextInt(28) + 1);

      return TransactionModel(
        category: category,
        isExpense: false,
        amount: double.parse(amount.toStringAsFixed(2)),
        note: note,
        date: date,
      );
    });

    final allFakeData = [...fakeExpenses, ...fakeIncomes];
    for (var txn in allFakeData) {
      await db.insertTransaction(txn);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已產生 40 筆假記帳資料（含收入與支出，2025 年 3 月）'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton.icon(
            onPressed: () => _insertFakeTransactions(context),
            icon: const Icon(Icons.data_array),
            label: const Text('Input記帳資料'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
