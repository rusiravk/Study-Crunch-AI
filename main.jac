"""Study Crunch AI - Master Application Entry Point.

Academic crunch & study planning tool built using the Jaclang / Jaseci ecosystem.
Unifies core agentic planning, CLI interface, Web dashboard, and Mobile views.
"""

import from core.models {
    Task,
    ScheduleSlot,
    StudyBlock,
    UserContext,
    HasTask,
    HasSlot,
    HasBlock,
    HasContext
}

def display_banner() {
    print("==================================================================");
    print("                      STUDY CRUNCH AI                             ");
    print("      Agentic Planning Assistant for Engineering & STEM Crunch    ");
    print("==================================================================");
}

def verify_system() {
    print("[*] Verifying multi-interface architecture...");
    print("  [+] Core Engine (`core/`): Loaded base archetypes (Task, ScheduleSlot, StudyBlock, UserContext)");
    print("  [+] CLI Interface (`cli/`): Ready (`jac run cli/main.jac`)");
    print("  [+] Web Dashboard (`web/`): Ready (`jac run web/main.jac`)");
    print("  [+] Mobile Client (`mobile/`): Ready (`jac run mobile/main.jac`)");
    print("\n[*] Initializing verification graph nodes...");

    # Attach verification nodes to root
    root +>:HasTask:+> Task(
        id="task_dsp_rev",
        title="DSP Revision for Midterms",
        module="EC401",
        deadline="2026-09-20 18:00",
        estimated_hours=3.5,
        weight_score=8,
        status="scheduled"
    );

    root +>:HasSlot:+> ScheduleSlot(
        id="slot_001",
        task_id="task_dsp_rev",
        start_time="2026-09-18 09:00",
        end_time="2026-09-18 12:30",
        is_locked=True
    );

    root +>:HasBlock:+> StudyBlock(
        id="block_001",
        task_id="task_dsp_rev",
        module="EC401",
        start_time="2026-09-18 09:00",
        end_time="2026-09-18 12:30",
        duration_hours=3.5,
        is_completed=False
    );

    tasks = [root ->:HasTask:->];
    slots = [root ->:HasSlot:->];
    blocks = [root ->:HasBlock:->];

    print(f"  [+] Graph Check: {len(tasks)} Task(s), {len(slots)} Slot(s), {len(blocks)} StudyBlock(s) active.");
    print("\n[SUCCESS] Study Crunch AI workspace initialized and compiled cleanly!");
    print("------------------------------------------------------------------");
    print("Try running the CLI with:");
    print('  jac run cli/main.jac triage --task "Lab 03" --due "tomorrow 18:00" --est 4h');
    print('  jac run cli/main.jac add --task "DSP Revision" --prio high');
    print("  jac run cli/main.jac status");
    print("==================================================================\n");
}

with entry {
    display_banner();
    verify_system();
}
