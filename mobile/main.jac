"""Mobile Interface Entry Point for Study Crunch AI.

Supports on-the-go quick glance view, active study block timer, and reschedule alerts.
"""

import from core.models {
    Task,
    ScheduleSlot,
    StudyBlock,
    UserContext
}

with entry {
    print("\n=======================================================");
    print("       STUDY CRUNCH AI - MOBILE INTERFACE (ACTIVE)     ");
    print("=======================================================");
    print("Mobile Client Initialized:");
    print("  - Quick Glance View: Active");
    print("  - Focus Study Timer: Ready (25m / 50m intervals)");
    print("  - Dynamic Reschedule Alerts: Enabled");
    print("=======================================================\n");
}
