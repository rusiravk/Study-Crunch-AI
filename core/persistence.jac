"""Disk-backed Persistence Manager for Study Crunch AI.

Ensures that the graph state (Tasks, ScheduleSlots, StudyBlocks, Modules,
and UserContext) survives server and process restarts by persisting to disk
in both Jac's native database and structured JSON state snapshots.
"""

import json;
import os;
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

glob DEFAULT_STATE_FILE: str = ".jac/study_crunch_state.json";

def ensure_storage_dir(filepath: str) {
    dirname = os.path.dirname(filepath);
    if dirname != "" and not os.path.exists(dirname) {
        os.makedirs(dirname, exist_ok=True);
    }
}

walker SaveStateToFile {
    has filepath: str = "";

    can save with Root entry {
        target_path = self.filepath if self.filepath != "" else DEFAULT_STATE_FILE;
        ensure_storage_dir(target_path);

        tasks = [here ->:HasTask:->];
        slots = [here ->:HasSlot:->];
        blocks = [here ->:HasBlock:->];
        modules = [here ->:HasModule:->];
        contexts = [here ->:HasContext:->];

        task_list = [t.to_dict() for t in tasks];
        slot_list = [s.to_dict() for s in slots];
        block_list = [b.to_dict() for b in blocks];
        mod_list = [m.to_dict() for m in modules];
        ctx_list = [c.to_dict() for c in contexts];

        state_data = {
            "version": "1.0",
            "modules": mod_list,
            "tasks": task_list,
            "schedule_slots": slot_list,
            "study_blocks": block_list,
            "user_context": ctx_list[0] if len(ctx_list) > 0 else {}
        };

        with open(target_path, "w", encoding="utf-8") as f {
            json.dump(state_data, f, indent=2);
        }

        report {
            "status": "success",
            "saved_to": target_path,
            "task_count": len(tasks),
            "slot_count": len(slots),
            "block_count": len(blocks),
            "module_count": len(modules)
        };
    }
}

walker LoadStateFromFile {
    has filepath: str = "";

    can load with Root entry {
        target_path = self.filepath if self.filepath != "" else DEFAULT_STATE_FILE;
        if not os.path.exists(target_path) {
            report {
                "status": "not_found",
                "message": f"State file {target_path} does not exist yet."
            };
            disengage;
        }

        with open(target_path, "r", encoding="utf-8") as f {
            raw_data = json.load(f);
        }

        # Check existing nodes to prevent duplicate loads
        existing_tasks = [here ->:HasTask:->];
        existing_task_ids = [t.id for t in existing_tasks];

        existing_modules = [here ->:HasModule:->];
        existing_mod_codes = [m.code for m in existing_modules];

        existing_slots = [here ->:HasSlot:->];
        existing_slot_ids = [s.id for s in existing_slots];

        existing_blocks = [here ->:HasBlock:->];
        existing_block_ids = [b.id for b in existing_blocks];

        loaded_tasks = 0;
        raw_tasks = raw_data.get("tasks", []);
        for t_dict in raw_tasks {
            tid = str(t_dict.get("id", ""));
            if tid != "" and tid not in existing_task_ids {
                here +>:HasTask:+> Task(
                    id=tid,
                    title=str(t_dict.get("title", "")),
                    module=str(t_dict.get("module", "")),
                    deadline=str(t_dict.get("deadline", "")),
                    estimated_hours=float(str(t_dict.get("estimated_hours", "1.0"))),
                    weight_score=int(str(t_dict.get("weight_score", "5"))),
                    priority=str(t_dict.get("priority", "medium")),
                    status=str(t_dict.get("status", "pending"))
                );
                loaded_tasks += 1;
            }
        }

        loaded_mods = 0;
        raw_mods = raw_data.get("modules", []);
        for m_dict in raw_mods {
            code = str(m_dict.get("code", ""));
            if code != "" and code not in existing_mod_codes {
                here +>:HasModule:+> Module(
                    code=code,
                    title=str(m_dict.get("title", "")),
                    difficulty_score=int(str(m_dict.get("difficulty_score", "5"))),
                    credit_weight=float(str(m_dict.get("credit_weight", "3.0")))
                );
                loaded_mods += 1;
            }
        }

        loaded_slots = 0;
        raw_slots = raw_data.get("schedule_slots", []);
        for s_dict in raw_slots {
            sid = str(s_dict.get("id", ""));
            if sid != "" and sid not in existing_slot_ids {
                here +>:HasSlot:+> ScheduleSlot(
                    id=sid,
                    task_id=str(s_dict.get("task_id", "")),
                    start_time=str(s_dict.get("start_time", "")),
                    end_time=str(s_dict.get("end_time", "")),
                    duration_hours=float(str(s_dict.get("duration_hours", "1.0"))),
                    is_locked=bool(s_dict.get("is_locked", False))
                );
                loaded_slots += 1;
            }
        }

        loaded_blocks = 0;
        raw_blocks = raw_data.get("study_blocks", []);
        for b_dict in raw_blocks {
            bid = str(b_dict.get("id", ""));
            if bid != "" and bid not in existing_block_ids {
                here +>:HasBlock:+> StudyBlock(
                    id=bid,
                    task_id=str(b_dict.get("task_id", "")),
                    module=str(b_dict.get("module", "")),
                    start_time=str(b_dict.get("start_time", "")),
                    end_time=str(b_dict.get("end_time", "")),
                    duration_hours=float(str(b_dict.get("duration_hours", "1.0"))),
                    is_completed=bool(b_dict.get("is_completed", False)),
                    is_crunch=bool(b_dict.get("is_crunch", False))
                );
                loaded_blocks += 1;
            }
        }

        ctx_dict = raw_data.get("user_context", {});
        if len([here ->:HasContext:->]) == 0 and ctx_dict {
            here +>:HasContext:+> UserContext(
                daily_study_capacity=float(str(ctx_dict.get("daily_study_capacity", "6.0"))),
                wake_time=str(ctx_dict.get("wake_time", "07:00")),
                sleep_time=str(ctx_dict.get("sleep_time", "23:00")),
                max_continuous_hours=float(str(ctx_dict.get("max_continuous_hours", "3.0")))
            );
        }

        report {
            "status": "success",
            "loaded_tasks": loaded_tasks,
            "loaded_modules": loaded_mods,
            "loaded_slots": loaded_slots,
            "loaded_blocks": loaded_blocks
        };
    }
}
