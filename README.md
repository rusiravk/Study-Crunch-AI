# Study Crunch AI

**Agentic Academic Crunch & Study Planning Assistant** built using the **Jaclang / Jaseci** ecosystem.

Designed specifically for Engineering and STEM students facing heavy assignment deadlines, lab reports, and exam study sessions. Features an autonomous **"Crisis Triage Mode"** that reads syllabus difficulty, marks weightage, and available slots to resolve scheduling conflicts with zero hassle.

---

## 1. Multi-Interface Architecture

The workspace follows the official Jac multi-interface pattern sharing a unified core data model and graph persistence layer:

```
Study Crunch AI/
├── jac.toml            # Project configuration, serve definitions & scripts
├── main.jac            # Master application entry point & architecture verification
├── core/               # Shared business logic, graph archetypes & walkers
│   ├── __init__.jac
│   └── models.jac      # Task, ScheduleSlot, StudyBlock, and UserContext archetypes
├── cli/                # Terminal CLI interface for rapid engineering workflows
│   ├── __init__.jac
│   └── main.jac        # CLI parser supporting triage, add, and status commands
├── web/                # Web dashboard interface (calendar & triage visualization)
│   ├── __init__.jac
│   └── main.jac
├── mobile/             # Mobile client interface (quick glance & study timer)
│   ├── __init__.jac
│   └── main.jac
└── ignore/
    └── PROJECT_SPEC.md # Master project requirements specification
```

---

## 2. Core Data Archetypes (`core/models.jac`)

* **`Task`**: Academic task tracking `id`, `title`, `module`, `deadline`, `estimated_hours`, `weight_score` (1-10), and `status`.
* **`ScheduleSlot`**: Timetable slot with `id`, `task_id`, `start_time`, `end_time`, and `is_locked`.
* **`StudyBlock`**: Dedicated crunch block tracking `id`, `task_id`, `module`, `start_time`, `end_time`, `duration_hours`, and `is_completed`.
* **`UserContext`**: Student preferences for `daily_study_capacity`, `wake_time`, and `sleep_time`.

---

## 3. Quick Start & Execution

### System Verification & Workspace Boot
Run from the repository root:
```bash
jac run
```

### Type Check Entire Workspace
```bash
jac check .
```

### CLI Interface Commands

#### 1. Crisis Triage Mode (Emergency Deadline Allocation)
```bash
jac run cli/main.jac triage --task "Lab 03" --due "tomorrow 18:00" --est 4h
```

#### 2. Add New Task to Schedule
```bash
jac run cli/main.jac add --task "DSP Revision" --prio high --module "EC401"
```

#### 3. Inspect Current Schedule & Study Blocks
```bash
jac run cli/main.jac status
```

#### 4. View CLI Help & Available Options
```bash
jac run cli/main.jac --help
```

### Web & Mobile Interfaces
```bash
# Web entry
jac run web/main.jac

# Mobile entry
jac run mobile/main.jac
```
