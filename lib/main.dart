import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyFlowApp());
}

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'StudyFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5BD6)),
          scaffoldBackgroundColor: const Color(0xFFF7F7FC),
        ),
        home: const HomePage(),
      );
}

class StudyTask {
  StudyTask({required this.title, required this.subject, required this.dueDate, this.isDone = false});
  final String title;
  final String subject;
  final DateTime dueDate;
  bool isDone;

  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'dueDate': dueDate.toIso8601String(),
        'isDone': isDone,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        title: json['title'] as String,
        subject: json['subject'] as String,
        dueDate: DateTime.parse(json['dueDate'] as String),
        isDone: json['isDone'] as bool? ?? false,
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storageKey = 'studyflow_tasks';
  final List<StudyTask> _tasks = [];
  bool _loading = true;

  int get _completed => _tasks.where((task) => task.isDone).length;
  int get _pending => _tasks.length - _completed;
  double get _progress => _tasks.isEmpty ? 0 : _completed / _tasks.length;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      final decoded = jsonDecode(saved) as List<dynamic>;
      _tasks.addAll(decoded.map((item) => StudyTask.fromJson(item as Map<String, dynamic>)));
    } else {
      _tasks.addAll([
        StudyTask(title: 'Revise sorting algorithms', subject: 'Data Structures', dueDate: DateTime.now().add(const Duration(days: 1))),
        StudyTask(title: 'Complete DBMS assignment', subject: 'DBMS', dueDate: DateTime.now().add(const Duration(days: 2))),
        StudyTask(title: 'Practice Flutter layouts', subject: 'Mobile Development', dueDate: DateTime.now(), isDone: true),
      ]);
      await _saveTasks();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_tasks.map((task) => task.toJson()).toList()));
  }

  Future<void> _addTask(String title, String subject, DateTime dueDate) async {
    setState(() => _tasks.insert(0, StudyTask(title: title, subject: subject, dueDate: dueDate)));
    await _saveTasks();
  }

  Future<void> _toggleTask(StudyTask task) async {
    setState(() => task.isDone = !task.isDone);
    await _saveTasks();
  }

  Future<void> _deleteTask(StudyTask task) async {
    setState(() => _tasks.remove(task));
    await _saveTasks();
  }

  Future<void> _showAddTaskSheet() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a task', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Task title', hintText: 'e.g. Revise chapter 3')),
              const SizedBox(height: 12),
              TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Mathematics')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Due date'),
                subtitle: Text('\${selectedDate.day}/\${selectedDate.month}/\${selectedDate.year}'),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) refreshSheet(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final subject = subjectController.text.trim();
                    if (title.isEmpty || subject.isEmpty) return;
                    Navigator.pop(sheetContext);
                    _addTask(title, subject, selectedDate);
                  },
                  child: const Text('Save task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    subjectController.dispose();
  }

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (date.year == today.year && date.month == today.month && date.day == today.day) return 'Today';
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) return 'Tomorrow';
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFF5B5BD6)), SizedBox(width: 9), Text('StudyFlow', style: TextStyle(fontWeight: FontWeight.w800))]),
          actions: [IconButton(tooltip: 'About StudyFlow', onPressed: () => showAboutDialog(context: context, applicationName: 'StudyFlow', applicationVersion: '1.0.0'), icon: const Icon(Icons.info_outline))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    Text('YOUR STUDY SPACE', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.5, color: Colors.black54, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7),
                    Text('Make today count.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    _ProgressCard(completed: _completed, total: _tasks.length, progress: _progress),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: _StatCard(label: 'To do', value: '$_pending', icon: Icons.pending_actions_rounded, color: const Color(0xFFE99B39))),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Completed', value: '$_completed', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF299B76))),
                    ]),
                    const SizedBox(height: 26),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Your tasks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text('\${_tasks.length} total', style: Theme.of(context).textTheme.bodySmall),
                    ]),
                    const SizedBox(height: 12),
                    if (_tasks.isEmpty) const _EmptyState() else ..._tasks.map((task) => _TaskTile(task: task, dateLabel: _dateLabel(task.dueDate), onToggle: () => _toggleTask(task), onDelete: () => _deleteTask(task))),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _showAddTaskSheet, icon: const Icon(Icons.add), label: const Text('Add task')),
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total, required this.progress});
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5B5BD6), Color(0xFF8585E8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily progress', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('\${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
          const SizedBox(height: 10),
          Text('$completed of $total tasks completed', style: const TextStyle(color: Colors.white)),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.dateLabel, required this.onToggle, required this.onDelete});
  final StudyTask task;
  final String dateLabel;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ObjectKey(task),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Checkbox(value: task.isDone, onChanged: (_) => onToggle(), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            const SizedBox(width: 5),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: task.isDone ? TextDecoration.lineThrough : null, color: task.isDone ? Colors.black45 : Colors.black87)),
              const SizedBox(height: 4),
              Text(task.subject, style: Theme.of(context).textTheme.bodySmall),
            ])),
            const SizedBox(width: 8),
            Text(dateLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF5B5BD6), fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Column(children: [
          Icon(Icons.event_note_rounded, size: 42, color: Color(0xFF8585E8)),
          SizedBox(height: 12),
          Text('No tasks yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          SizedBox(height: 5),
          Text('Add your first task and make a plan for today.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ]),
      );
}
