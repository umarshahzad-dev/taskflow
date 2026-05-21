# TaskFlow CLI

![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Tests](https://img.shields.io/badge/tests-23%20passed-success)

A professional command‑line task manager built entirely in **Dart**.  
Manage tasks with priorities, due dates, tags, search, undo, colored output, an interactive shell, and full JSON persistence – all from your terminal.

---

## ✨ Features

- **Task Management** – add, list, complete, undo, and delete tasks.
- **Priorities** – `low` / `medium` / `high` (enhanced Dart enum).
- **Due Dates** – set deadlines and filter overdue tasks.
- **Tags** – organize tasks with custom tags and filter by them.
- **Search** – find tasks by title (case‑insensitive, multi‑word).
- **Sorting** – sort by id, title, priority, creation date, or due date.
- **Undo** – restore the last deleted task.
- **Colored Output** – priorities displayed in red, yellow, green.
- **Statistics** – total, completed, pending, overdue counts.
- **CSV Export** – runs in a separate isolate to keep the UI responsive.
- **Config** – view/set default priority and data file path at runtime.
- **Interactive Shell** – REPL mode with live command processing.
- **Full Test Suite** – 23+ unit tests covering models and repository.

---

## 📋 Requirements

- Dart SDK **≥3.2.0** (developed with 3.11.4)

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/your-username/taskflow.git
cd taskflow

# Install dependencies
dart pub get

# Generate JSON serialisation code
dart run build_runner build
```

## 🖥️ Usage

```bash
# Add tasks
dart run bin/taskflow.dart add "Learn Dart" --priority high
dart run bin/taskflow.dart add "Buy milk"
dart run bin/taskflow.dart add "Submit report" --priority high --due 2026-12-31 --tags work,urgent

# List tasks
dart run bin/taskflow.dart list
dart run bin/taskflow.dart list --done
dart run bin/taskflow.dart list --overdue --sort due
dart run bin/taskflow.dart list --tag bug

# Mark as done / undone
dart run bin/taskflow.dart done 1
dart run bin/taskflow.dart undone 1

# Delete & undo
dart run bin/taskflow.dart delete 2
dart run bin/taskflow.dart undo

# Search
dart run bin/taskflow.dart search "Dart"

# Statistics
dart run bin/taskflow.dart stats

# Export to CSV
dart run bin/taskflow.dart export

# Config
dart run bin/taskflow.dart config default_priority high
dart run bin/taskflow.dart config filepath

# Interactive shell
dart run bin/taskflow.dart shell

# Help
dart run bin/taskflow.dart help
```

## ✅ Testing

```bash
dart test
```

Example output:
```
00:03 +23: All tests passed!
```

Tests cover:
- Task serialisation / deserialisation
- Task `copyWith` and equality
- Repository CRUD (add, complete, uncomplete, delete, restore)
- Filtering by completion, priority, and combination
- CSV export
- Config management

## 📁 Project Structure

```
taskflow/
├── bin/
│   └── taskflow.dart              # Entry point
├── lib/
│   └── src/
│       ├── commands/
│       │   └── command_handler.dart
│       ├── models/
│       │   ├── task.dart
│       │   └── task.g.dart        # Generated JSON serialisation
│       ├── services/
│       │   ├── task_logger.dart
│       │   └── task_repository.dart
│       └── utils/
│           └── extensions.dart
├── test/
│   ├── task_test.dart
│   └── task_repository_test.dart
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
└── README.md
```

## 🔧 Configuration

The app uses two JSON files:
- `tasks.json` – stores the task list (created automatically)
- `config.json` – stores user preferences (default priority, custom file path)

You can change the data file location with:
```bash
dart run bin/taskflow.dart config filepath my_tasks.json
```

## 📄 License

MIT – feel free to use, modify, and distribute.

---
