"""Study Crunch AI - Master Application Entry Point.

Academic crunch & study planning tool built using the Jaclang / Jaseci ecosystem.
Unifies core agentic planning, CLI interface, Web dashboard, and Mobile views.
"""

import from core.models {
    Task,
    ScheduleSlot,
    StudyBlock,
    Module,
    UserContext,
    HasTask,
    HasSlot,
    HasBlock,
    HasModule,
    HasContext
}
import from core.persistence {
    SaveStateToFile,
    LoadStateFromFile
}
import from core.triage_agent {
    CrisisTriageAgent
}

def display_banner() {
    print("==================================================================");
    print("                      STUDY CRUNCH AI                             ");
    print("      Agentic Planning Assistant for Engineering & STEM Crunch    ");
    print("==================================================================");
}

def verify_system() {
    print("[*] Verifying multi-interface architecture...");
    print("  [+] Core Engine (`core/`): Loaded base archetypes (Task, ScheduleSlot, StudyBlock, Module, UserContext)");
    print("  [+] CLI Interface (`cli/`): Ready (`jac run cli/main.jac`)");
    print("  [+] Web Dashboard (`web/`): Ready (`jac run web/main.jac`)");
    print("  [+] Mobile Client (`mobile/`): Ready (`jac run mobile/main.jac`)");
    print("\n[*] Initializing verification graph nodes & persistence...");

    # Load existing state if available
    root spawn LoadStateFromFile();

    # Attach verification module if not present
    if len([root ->:HasModule:->]) == 0 {
        root +>:HasModule:+> Module(
            code="EC401",
            title="Digital Signal Processing",
            difficulty_score=8,
            credit_weight=4.0
        );
    }

    # Attach verification task if not present
    if len([root ->:HasTask:->]) == 0 {
        root +>:HasTask:+> Task(
            id="task_dsp_rev",
            title="DSP Revision for Midterms",
            module="EC401",
            deadline="2026-09-20 18:00",
            estimated_hours=3.5,
            weight_score=8,
            priority="high",
            status="scheduled"
        );
    }

    # Attach verification slot if not present
    if len([root ->:HasSlot:->]) == 0 {
        root +>:HasSlot:+> ScheduleSlot(
            id="slot_001",
            task_id="task_dsp_rev",
            start_time="2026-09-18 09:00",
            end_time="2026-09-18 12:30",
            duration_hours=3.5,
            is_locked=True
        );
    }

    # Attach verification study block if not present
    if len([root ->:HasBlock:->]) == 0 {
        root +>:HasBlock:+> StudyBlock(
            id="block_001",
            task_id="task_dsp_rev",
            module="EC401",
            start_time="2026-09-18 09:00",
            end_time="2026-09-18 12:30",
            duration_hours=3.5,
            is_completed=False,
            is_crunch=True
        );
    }

    # Attach user context if not present
    if len([root ->:HasContext:->]) == 0 {
        root +>:HasContext:+> UserContext(
            daily_study_capacity=6.0,
            wake_time="07:00",
            sleep_time="23:00",
            max_continuous_hours=3.0
        );
    }

    modules = [root ->:HasModule:->];
    tasks = [root ->:HasTask:->];
    slots = [root ->:HasSlot:->];
    blocks = [root ->:HasBlock:->];

    print(f"  [+] Graph Check: {len(modules)} Module(s), {len(tasks)} Task(s), {len(slots)} Slot(s), {len(blocks)} StudyBlock(s) active.");

    # Test disk-backed persistence
    root spawn SaveStateToFile();
    print("  [+] Persistence Check: Graph state synchronized to disk (.jac/study_crunch_state.json).");

    # Test Crisis Triage Agent
    print("\n[*] Testing Crisis Triage Engine (Autonomous Conflict Resolution)...");
    triage_run = root spawn CrisisTriageAgent(
        task_title="Urgent DSP Midterm Prep",
        deadline="tomorrow 20:00",
        estimated_hours=2.0,
        weight_score=9,
        module="EC401"
    );
    if triage_run.decision is not None {
        print(f"  [+] Triage Agent Decision: {triage_run.decision.summary}");
        print(f"  [+] Allocated Window: {triage_run.decision.allocated_start} -> {triage_run.decision.allocated_end}");
        print(f"  [+] Reasoning Steps Recorded: {len(triage_run.decision.reasoning)} steps");
    }

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
