"""CLI Interface for Study Crunch AI.

Provides terminal-native command routing for engineering and STEM workflows,
handling task additions, crisis triage planning, and schedule status checks.
"""

import argparse;
import sys;
import from core.models {
    Task,
    StudyBlock,
    Module,
    UserContext,
    HasTask,
    HasBlock,
    HasModule,
    HasContext
}
import from core.persistence {
    LoadStateFromFile,
    SaveStateToFile
}
import from core.triage_agent {
    CrisisTriageAgent
}

def parse_priority(prio_str: str) -> int {
    cleaned = prio_str.strip().lower();
    if cleaned == "high" {
        return 9;
    } elif cleaned == "medium" or cleaned == "med" {
        return 5;
    } elif cleaned == "low" {
        return 2;
    } elif cleaned == "critical" or cleaned == "urgent" {
        return 10;
    }
    try {
        val = int(cleaned);
        if val < 1 { return 1; }
        if val > 10 { return 10; }
        return val;
    } except ValueError {
        return 5;
    }
}

def parse_est_hours(est_str: str) -> float {
    cleaned = est_str.strip().lower().replace("h", "").replace("hrs", "");
    try {
        return float(cleaned);
    } except ValueError {
        return 1.0;
    }
}

def render_ascii_timeline(blocks: list[StudyBlock]) {
    print("-------------------------------------------------------------------------");
    print(" Time Window       | Module   | Duration | Allocation Type | Status       ");
    print("-------------------+----------+----------+-----------------+---------------");
    if len(blocks) == 0 {
        print(" (No study blocks allocated. Timeline is completely open.)               ");
    } else {
        for b in blocks {
            tag = "[!] CRUNCH " if b.is_crunch else "[~] ROUTINE";
            stat = "COMPLETED" if b.is_completed else "ACTIVE   ";
            print(f" {b.start_time} - {b.end_time} | {b.module:<8} | {b.duration_hours:>4.1f}h  | {tag}     | {stat}   ");
        }
    }
    print("-------------------------------------------------------------------------");
}

def handle_triage(task_title: str, due: str, est: str, prio: str, module: str) {
    prio_val = parse_priority(prio) if prio else 8;
    est_val = parse_est_hours(est) if est else 2.0;
    mod_code = module if module else "GEN101";
    due_date = due if due else "tomorrow 18:00";

    print("\n=========================================================================");
    print("                 STUDY CRUNCH AI - CRISIS TRIAGE ENGINE                  ");
    print("=========================================================================");
    print(f"[*] Crunch Task: '{task_title}'");
    print(f"[*] Module: {mod_code} | Deadline: {due_date} | Est: {est_val}h | Weight: {prio_val}/10");
    print("[*] Spawning CrisisTriageAgent on planning graph...\n");

    root spawn LoadStateFromFile();

    agent = root spawn CrisisTriageAgent(
        task_title=task_title,
        deadline=due_date,
        estimated_hours=est_val,
        weight_score=prio_val,
        module=mod_code
    );

    if agent.decision is not None {
        for step in agent.decision.reasoning {
            print(f"  {step}");
        }
        if agent.decision.success {
            slot_str = f"{agent.decision.allocated_start} -> {agent.decision.allocated_end}";
            print(f"\n[SUCCESS] '{task_title}' scheduled into slot: {slot_str}");
            print(f"[STATUS] Outcome: {agent.decision.summary}");
            if len(agent.decision.deferred_tasks) > 0 {
                print(f"[ACTION] Deferred Lower-Priority Tasks: {agent.decision.deferred_tasks}");
            }
        } else {
            print(f"\n[NOTICE] Allocation deferred: {agent.decision.summary}");
        }
    }
    print("=========================================================================\n");
}

def handle_add(task_title: str, due: str, est: str, prio: str, module: str) {
    prio_val = parse_priority(prio) if prio else 5;
    est_val = parse_est_hours(est) if est else 1.0;
    h_val: int = int(abs(hash(task_title)));
    task_hash = str(h_val % 10000);
    task_id = f"task_{task_hash}";
    mod_code = module if module else "GEN101";
    due_date = due if due else "tomorrow 18:00";
    
    print(f"\n[ADD TASK] Adding '{task_title}' to Study Crunch AI...");
    print(f"  - ID: {task_id}");
    print(f"  - Module: {mod_code}");
    print(f"  - Due Date: {due_date}");
    print(f"  - Est. Hours: {est_val}h");
    print(f"  - Priority Weight: {prio_val}/10");

    root spawn LoadStateFromFile();
    root +>:HasTask:+> Task(
        id=task_id,
        title=task_title,
        module=mod_code,
        deadline=due_date,
        estimated_hours=est_val,
        weight_score=prio_val,
        priority="high" if prio_val >= 8 else ("medium" if prio_val >= 5 else "low"),
        status="pending"
    );
    root spawn SaveStateToFile();
    print("[SUCCESS] Task registered in planning graph and saved to disk.\n");
}

def handle_status() {
    root spawn LoadStateFromFile();
    blocks = [root ->:HasBlock:->];
    tasks = [root ->:HasTask:->];
    contexts = [root ->:HasContext:->];

    cap_str = "6.0 hrs/day (07:00 -> 23:00)";
    if len(contexts) > 0 {
        ctx = contexts[0];
        cap_str = f"{ctx.daily_study_capacity} hrs/day ({ctx.wake_time} -> {ctx.sleep_time})";
    }

    print("\n=========================================================================");
    print("                    STUDY CRUNCH AI - SCHEDULE STATUS                    ");
    print("=========================================================================");
    print(f"Active Study Capacity : {cap_str}");
    
    total_study_h = 0.0;
    crunch_count = 0;
    for b in blocks {
        if not b.is_completed {
            total_study_h += b.duration_hours;
            if b.is_crunch { crunch_count += 1; }
        }
    }
    print(f"Scheduled Workload    : {total_study_h:.1f} hrs across {len(blocks)} block(s) ({crunch_count} crunch)");
    print("");
    print("Daily Timetable Grid:");
    render_ascii_timeline(blocks);

    print(f"\nActive Tasks ({len(tasks)} total):");
    active_tasks = 0;
    for t in tasks {
        if t.status != "completed" {
            print(f"  * [{t.module}] {t.title} (Due: {t.deadline}, Est: {t.estimated_hours}h, Prio: {t.priority}, Status: {t.status})");
            active_tasks += 1;
        }
    }
    if active_tasks == 0 {
        print("  All tasks completed or none registered. Add one via 'jac run cli/main.jac add --task ...'");
    }
    print("\nStatus: Schedule synchronized to disk (.jac/study_crunch_state.json).");
    print("=========================================================================\n");
}

def handle_list(filter_status: str) {
    root spawn LoadStateFromFile();
    tasks = [root ->:HasTask:->];

    print("\n=========================================================================");
    print("                       ACADEMIC TASK REPOSITORY                          ");
    print("=========================================================================");
    print(" ID        | Module   | Priority | Due Date         | Est   | Title          ");
    print("-----------+----------+----------+------------------+-------+----------------");

    cleaned_filter = filter_status.strip().lower();
    displayed = 0;
    for t in tasks {
        if cleaned_filter != "" and cleaned_filter != "all" and t.status.lower() != cleaned_filter {
            continue;
        }
        print(f" {t.id:<9} | {t.module:<8} | {t.priority:<8} | {t.deadline:<16} | {t.estimated_hours:>4.1f}h | {t.title} [{t.status.upper()}]");
        displayed += 1;
    }
    if displayed == 0 {
        print(" (No matching tasks found.)                                              ");
    }
    print("=========================================================================\n");
}

def handle_complete(target: str) {
    if target == "" {
        print("\n[ERROR] Please specify a task name or ID via --task <name/id>\n");
        return;
    }
    root spawn LoadStateFromFile();
    tasks = [root ->:HasTask:->];
    blocks = [root ->:HasBlock:->];

    matched = False;
    cleaned = target.strip().lower();
    for t in tasks {
        if cleaned in t.id.lower() or cleaned in t.title.lower() {
            t.status = "completed";
            matched = True;
            print(f"[+] Marked Task '{t.title}' ({t.id}) as COMPLETED.");
            for b in blocks {
                if b.task_id == t.id {
                    b.is_completed = True;
                    print(f"    - Linked StudyBlock '{b.id}' archived.");
                }
            }
        }
    }

    if matched {
        root spawn SaveStateToFile();
        print("[SUCCESS] Task status updated and persisted to disk.\n");
    } else {
        print(f"[!] No task found matching: '{target}'\n");
    }
}

def handle_modules() {
    root spawn LoadStateFromFile();
    modules = [root ->:HasModule:->];
    tasks = [root ->:HasTask:->];

    print("\n=========================================================================");
    print("                    ENROLLED COURSE MODULES & SYLLABUS                   ");
    print("=========================================================================");
    print(" Code     | Title                        | Difficulty | Credits | Linked Tasks ");
    print("----------+------------------------------+------------+---------+--------------");
    if len(modules) == 0 {
        print(" (No modules registered yet.)                                            ");
    } else {
        for m in modules {
            count = 0;
            for t in tasks {
                if t.module == m.code { count += 1; }
            }
            print(f" {m.code:<8} | {m.title:<28} | {m.difficulty_score:>2d}/10     | {m.credit_weight:>4.1f}cr | {count:>3d} tasks   ");
        }
    }
    print("=========================================================================\n");
}

with entry {
    parser = argparse.ArgumentParser(
        description="Study Crunch AI - Academic Crunch & Study Planning CLI",
        prog="jac run cli/main.jac"
    );

    parser.add_argument(
        "command",
        nargs="?",
        default="status",
        choices=["triage", "add", "status", "list", "complete", "modules"],
        help="CLI command to execute: triage, add, status, list, complete, modules"
    );

    parser.add_argument(
        "--task",
        default="",
        help="Task title or identifier"
    );

    parser.add_argument(
        "--due",
        default="",
        help="Deadline/Due date (e.g. 'tomorrow 18:00')"
    );

    parser.add_argument(
        "--est",
        default="",
        help="Estimated hours required (e.g. '4h' or '2.5')"
    );

    parser.add_argument(
        "--prio",
        default="",
        help="Priority weight (e.g. 'high', 'low', '8')"
    );

    parser.add_argument(
        "--module",
        default="",
        help="Course or module code (e.g. 'CS304', 'EE401')"
    );

    parser.add_argument(
        "--filter",
        default="all",
        help="Filter status for list command: all, pending, scheduled, completed"
    );

    # Allow running when called via `jac run cli/main.jac`
    args = parser.parse_args(sys.argv[1:]);

    cmd: str = str(args.command or "status");
    task_val: str = str(args.task or "");
    due_val: str = str(args.due or "");
    est_val: str = str(args.est or "");
    prio_val: str = str(args.prio or "");
    module_val: str = str(args.module or "");
    filter_val: str = str(args.filter or "all");

    if task_val != "" and cmd == "status" {
        if due_val != "" or est_val != "" {
            cmd = "triage";
        } else {
            cmd = "add";
        }
    }

    if cmd == "triage" {
        task_name = task_val if task_val != "" else "Emergency Crunch Task";
        handle_triage(task_name, due_val, est_val, prio_val, module_val);
    } elif cmd == "add" {
        task_name = task_val if task_val != "" else "New Study Task";
        handle_add(task_name, due_val, est_val, prio_val, module_val);
    } elif cmd == "status" {
        handle_status();
    } elif cmd == "list" {
        handle_list(filter_val);
    } elif cmd == "complete" {
        handle_complete(task_val);
    } elif cmd == "modules" {
        handle_modules();
    }
}
