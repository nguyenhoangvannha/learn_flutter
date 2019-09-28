import 'package:flutter/material.dart';
import 'package:moor_db/data/moor_database.dart';
import 'package:moor_db/ui/home_page.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();
    return MultiProvider(
      providers: [
        Provider(builder: (_) => db.taskDao),
        Provider(builder: (_) => db.tagDao),
      ],
      child: MaterialApp(
        title: 'Material App',
        home: HomePage(),
      ),
    );
  }
}
