// 記帳(modify)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'ios_success_dialog.dart';
import 'models/transaction_model.dart';
import 'pages/voice_record_page.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  bool isManual = true;
  bool isExpense = true;
  String selectedCategory = '食物';
  DateTime selectedDate = DateTime.now();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final expenseCategories = {
    '食物': Icons.fastfood,
    '交通': Icons.directions_car,
    '娛樂': Icons.movie,
    '生活用品': Icons.shopping_cart,
    '其他': Icons.more_horiz,
  };

  final incomeCategories = {
    '薪資': Icons.attach_money,
    '投資': Icons.trending_up,
    '獎金': Icons.card_giftcard,
    '其他': Icons.account_balance_wallet,
  };

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _submitTransaction() async {
    if (amountController.text.isEmpty) return;

    final newTxn = TransactionModel(
      category: selectedCategory,
      isExpense: isExpense,
      amount: double.parse(amountController.text),
      note: noteController.text,
      date: selectedDate,
    );

    await DatabaseHelper().insertTransaction(newTxn);

    showTransactionSuccessDialog(
      context: context,
      isExpense: isExpense,
      amount: amountController.text,
      category: selectedCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = isExpense ? expenseCategories : incomeCategories;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VoiceRecordPage()),
                        );
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text("語音記帳"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton("支出", isExpense, () {
                      setState(() {
                        isExpense = true;
                        selectedCategory = '食物';
                      });
                    }, activeColor: Colors.redAccent),
                    const SizedBox(width: 12),
                    _buildToggleButton("收入", !isExpense, () {
                      setState(() {
                        isExpense = false;
                        selectedCategory = '薪資';
                      });
                    }, activeColor: Colors.green),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: categories.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedCategory == entry.key ? Colors.brown[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(entry.value, size: 30),
                            const SizedBox(height: 4),
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text("日期：${DateFormat.yMMMd().format(selectedDate)}"),
                    ),
                    IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: "\$ ",
                    labelText: "金額",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "備註",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("確認", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(String label, bool selected, VoidCallback onTap, {required Color activeColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
