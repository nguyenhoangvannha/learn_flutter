import 'package:moor/moor.dart';
import 'package:moor_flutter/moor_flutter.dart';

// Moor works by source gen. This file will all the generated code.
part 'moor_database.g.dart';

// The name of the database table is "tasks"
// By default, the name of the generated data class will be "Task" (without "s")
class Tasks extends Table {
  // autoIncrement automatically sets this to be the primary key
  IntColumn get id => integer().autoIncrement()();

  TextColumn get tagName => text().nullable().customConstraint('REFERENCES tags(name)')();

  // If the length constraint is not fulfilled, the Task will not
  // be inserted into the database and an exception will be thrown.
  TextColumn get name => text().withLength(min: 1, max: 50)();

  // DateTime is not natively supported by SQLite
  // Moor converts it to & from UNIX seconds
  DateTimeColumn get dueDate => dateTime().nullable()();

  // Booleans are not supported as well, Moor converts them to integers
  // Simple default values are specified as Constants
  BoolColumn get completed => boolean().withDefault(Constant(false))();
}

class Tags extends Table {
  TextColumn get name => text().withLength(min: 1, max: 10)();

  IntColumn get color => integer()();

  @override
  Set<Column> get primaryKey => {name};
}

// This annotation tells the code generator which tables this DB works with
@UseMoor(tables: [Tasks, Tags], daos: [TaskDao, TagDao])
// _$AppDatabase is the name of the generated class
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      // Specify the location of the database file
      : super((FlutterQueryExecutor.inDatabaseFolder(
          path: 'db.sqlite',
          // Good for debugging - prints SQL in the console
          logStatements: true,
        )));

  // Bump this when changing tables and columns.
  // Migrations will be covered in the next part.
  @override
  int get schemaVersion => 1;
}

@UseDao(tables: [
  Tasks
], queries: {
  'completedTasksGenerated':
      'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;'
})
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  AppDatabase db;

  TaskDao(this.db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)
          ..orderBy(([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)
          ])))
        .watch();
  }

  Stream<List<Task>> watchCompletedTasks() {
    return (select(tasks)
          ..orderBy(([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)
          ]))
          ..where((t) => t.completed.equals(true)))
        .watch();
  }

  Stream<List<Task>> watchCompletedTasksCustom() {
    return customSelectStream(
        'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;',
        readsFrom: {tasks}).map((rows) {
      return rows.map((row) => Task.fromData(row.data, db)).toList();
    });
  }

  Future<int> insertTask(Insertable<Task> task) => into(tasks).insert(task);

  Future<bool> updateTask(Insertable<Task> task) => update(tasks).replace(task);

  Future<int> deleteTask(Insertable<Task> task) => delete(tasks).delete(task);
}

@UseDao(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  AppDatabase db;

  TagDao(this.db) : super(db);

  Stream<List<Tag>> watchTags() => select(tags).watch();

  Future insertTag(Insertable<Tag> tag) => into(tags).insert(tag);
}
