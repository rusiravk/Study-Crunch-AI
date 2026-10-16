"""Mobile Interface for Study Crunch AI.

Supports on-the-go quick glance view, active study block focus timer, and dynamic reschedule alerts.
Pairs with http://localhost:8000/mobile for the mobile touch web client.
"""

import sys;
import from core.models {
    Task,
    StudyBlock,
    UserContext,
    HasTask,
    HasBlock,
    HasContext
}
import from core.persistence {
    LoadStateFromFile
}

def display_mobile_glance() {
    root spawn LoadStateFromFile();
    blocks = [root ->:HasBlock:->];
    tasks = [root ->:HasTask:->];
    contexts = [root ->:HasContext:->];

    user_cap = 6.0;
    if len(contexts) > 0 {
        user_cap = contexts[0].daily_study_capacity;
    }

    print("\n=========================================================================");
    print("                STUDY CRUNCH AI - MOBILE ON-THE-GO GLANCE                ");
    print("=========================================================================");
    print(f" Daily Study Budget: {user_cap:.1f} hrs | Graph State: Synchronized");
    print("-------------------------------------------------------------------------");

    active_blocks: list[StudyBlock] = [];
    for b in blocks {
        if not b.is_completed {
            active_blocks.append(b);
        }
    }

    if len(active_blocks) > 0 {
        next_b = active_blocks[0];
        tag = "CRUNCH BLOCK" if next_b.is_crunch else "ROUTINE STUDY";
        print(f"[*] NEXT FOCUS SESSION: [{tag}]");
        print(f"    Module   : {next_b.module}");
        print(f"    Window   : {next_b.start_time} -> {next_b.end_time} ({next_b.duration_hours}h)");
    } else {
        print("[*] NEXT FOCUS SESSION: Schedule is open. No active crunch block pending.");
    }

    print("\n[ACTIVE FOCUS TIMER]");
    print("  [1] 25 min Sprint   (Pomodoro Focus)");
    print("  [2] 50 min Deep Work (Intense Crunch Mode)");
    print("  [3]  5 min Recovery  (Rest Interval)");

    print("\n[TODAY'S TASK CHECKLIST]");
    displayed = 0;
    for t in tasks {
        if displayed < 4 {
            status_box = "[X]" if t.status == "completed" else "[ ]";
            print(f"  {status_box} [{t.module}] {t.title} (Due: {t.deadline})");
            displayed += 1;
        }
    }

    print("\n[MOBILE WEB CLIENT]");
    print("  Interactive Touch App Live at: http://localhost:8000/mobile");
    print("=========================================================================\n");
}

with entry {
    display_mobile_glance();
}
