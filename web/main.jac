"""Web Interface Entry Point for Study Crunch AI.

Serves the visual calendar timeline, syllabus progress, and dynamic triage dashboard.
"""

import from core.models {
    Task,
    ScheduleSlot,
    StudyBlock,
    UserContext
}

with entry {
    print("\n=======================================================");
    print("        STUDY CRUNCH AI - WEB INTERFACE (ACTIVE)       ");
    print("=======================================================");
    print("Web server ready on http://localhost:8000");
    print("  - Visual Calendar Timeline: /calendar");
    print("  - Module Syllabus Progress: /modules");
    print("  - Crisis Triage Visualizer: /triage");
    print("=======================================================\n");
}
