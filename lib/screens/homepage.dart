import 'package:expense_tracker/models/enums.dart';
import 'package:expense_tracker/models/record.dart';
import 'package:expense_tracker/services/database.service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  dynamic balance = 100000000;

  List<Map<String, dynamic>> expenses = [
    {'category': 'Food', 'amount': 0},
    {'category': 'Transport', 'amount': 0},
    {'category': 'Entertainment', 'amount': 0},
    {'category': 'Investment', 'amount': 0},
  ];

  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    loadRecordsFromDb();
  }

  String rupiahFormat(int amount) {
    String number = amount.toString();
    String result = '';
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      result = number[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }

  Future<void> loadRecordsFromDb() async {
    final dbRecords = await DatabaseService.db.records.where().findAll();

    setState(() {
      records =
          dbRecords
              .map(
                (r) => {
                  'category':
                      r.category.name[0].toUpperCase() +
                      r.category.name.substring(1),
                  'amount': r.amount,
                },
              )
              .toList();

      // Hitung balance ulang
      balance = 100000000;
      for (var r in dbRecords) {
        balance -= r.amount;
      }

      for (var expense in expenses) {
        expense['amount'] = dbRecords
            .where((r) => r.category.name == expense['category'].toLowerCase())
            .fold(0, (sum, r) => sum + r.amount);
      }
    });
  }

  void addRecord(String category, int amount) async {
    final newRecord = Record(
      amount: amount,
      category: Category.values.firstWhere(
        (c) => c.name.toLowerCase() == category.toLowerCase(),
      ),
    );

    await DatabaseService.db.writeTxn(() async {
      await DatabaseService.db.records.put(newRecord);
    });

    await loadRecordsFromDb();
  }

  void editRecord(int index, String category, int newAmount) async {
    final dbRecords = await DatabaseService.db.records.where().findAll();

    if (index >= dbRecords.length) return;

    final oldRecord = dbRecords[index];
    oldRecord.amount = newAmount;
    oldRecord.category = Category.values.firstWhere(
      (c) => c.name == category.toLowerCase(),
    );

    await DatabaseService.db.writeTxn(() async {
      await DatabaseService.db.records.put(oldRecord);
    });

    await loadRecordsFromDb();
  }

  void deleteRecord(int index) async {
    final dbRecords = await DatabaseService.db.records.where().findAll();

    if (index >= dbRecords.length) return;

    await DatabaseService.db.writeTxn(() async {
      await DatabaseService.db.records.delete(dbRecords[index].id);
    });

    await loadRecordsFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            buildCard(
              'Balance',
              'Rp ${rupiahFormat(balance)}',
              isBalance: true,
            ),
            buildCard(
              'Expenses',
              null,
              items:
                  expenses
                      .map(
                        (expense) => buildExpenseRow(
                          expense['category'],
                          'Rp ${rupiahFormat(expense['amount'])}',
                        ),
                      )
                      .toList(),
            ),
            buildCard(
              'Records',
              null,
              items: List.generate(
                records.length,
                (index) => buildRecordRow(
                  records[index]['category'],
                  'Rp ${rupiahFormat(records[index]['amount'])}',
                  index,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openDialog();
        },
        tooltip: 'Add Record',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future openDialog({int? index}) {
    String selectedCategory =
        index != null ? records[index]['category'] : expenses.first['category'];
    TextEditingController amountController = TextEditingController(
      text: index != null ? records[index]['amount'].toString() : '',
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? 'Tambah Data' : 'Edit Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items:
                    Category.values.map((cat) {
                      String name =
                          cat.name[0].toUpperCase() + cat.name.substring(1);
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                int amount = int.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  if (index == null) {
                    addRecord(selectedCategory, amount);
                  } else {
                    editRecord(index, selectedCategory, amount);
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildRecordRow(String category, String amount, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => openDialog(index: index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => deleteRecord(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCard(
    String title,
    String? balance, {
    List<Widget>? items,
    bool isBalance = false,
  }) {
    return Card(
      color: Colors.amber[400],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isBalance)
              Text(
                balance!,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (items != null) Column(children: items),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget buildExpenseRow(String category, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
