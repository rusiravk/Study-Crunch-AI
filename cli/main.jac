"""CLI Interface for Study Crunch AI.

Provides terminal-native command routing for engineering and STEM workflows,
handling task additions, crisis triage planning, and schedule status checks.
"""

import argparse;
import sys;
import from core.models {
    Task,
    HasTask,
    HasBlock
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

def handle_triage(task_title: str, due: str, est: str, prio: str, module: str) {
    prio_val = parse_priority(prio) if prio else 8;
    est_val = parse_est_hours(est) if est else 2.0;
    mod_code = module if module else "GEN101";
    due_date = due if due else "tomorrow 18:00";

    print("\n=======================================================");
    print("       STUDY CRUNCH AI - CRISIS TRIAGE ENGINE          ");
    print("=======================================================");
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
    print("=======================================================\n");
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

    print("\n=======================================================");
    print("           STUDY CRUNCH AI - SCHEDULE STATUS           ");
    print("=======================================================");
    print("Active User Capacity: 6.0 hrs/day (07:00 -> 23:00)");
    print(f"\nTracked Tasks ({len(tasks)}):");
    if len(tasks) == 0 {
        print("  No tasks registered yet. Add one via 'jac run cli/main.jac add --task ...'");
    } else {
        for t in tasks {
            print(f"  * [{t.module}] {t.title} (Due: {t.deadline}, Est: {t.estimated_hours}h, Prio: {t.priority})");
        }
    }

    print(f"\nUpcoming Study Blocks ({len(blocks)}):");
    if len(blocks) == 0 {
        print("  No active study blocks scheduled.");
    } else {
        idx = 1;
        for b in blocks {
            crunch_tag = "CRUNCH" if b.is_crunch else "ROUTINE";
            print(f"  [{idx}] {b.module} | {b.start_time} - {b.end_time} ({b.duration_hours}h) | [{crunch_tag}]");
            idx += 1;
        }
    }
    print("\nStatus: Schedule is synchronized to disk.");
    print("=======================================================\n");
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
        choices=["triage", "add", "status", "list"],
        help="CLI command to execute (triage, add, status, list)"
    );

    parser.add_argument(
        "--task",
        default="",
        help="Task title or name"
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
        help="Course or module code (e.g. 'CS304')"
    );

    # Allow running when called via `jac run cli/main.jac`
    args = parser.parse_args(sys.argv[1:]);

    cmd: str = str(args.command or "status");
    task_val: str = str(args.task or "");
    due_val: str = str(args.due or "");
    est_val: str = str(args.est or "");
    prio_val: str = str(args.prio or "");
    module_val: str = str(args.module or "");

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
    } elif cmd == "status" or cmd == "list" {
        handle_status();
    }
}
