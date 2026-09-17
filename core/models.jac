"""Core Data Models for Study Crunch AI.

Defines base archetypes for Tasks, ScheduleSlots, StudyBlocks,
Modules, Priorities, and UserContext, along with graph edges and traversal walkers.
"""

type JsonScalar = str | int | float | bool;
type JsonDict = dict[str, JsonScalar];

# Enumerations for strict domain modeling

enum Priority: str {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    CRITICAL = "critical"
}

enum TaskStatus: str {
    PENDING = "pending",
    SCHEDULED = "scheduled",
    IN_PROGRESS = "in_progress",
    COMPLETED = "completed",
    TRIAGED = "triaged",
    DEFERRED = "deferred"
}

# Graph Persistent Domain Nodes

node Module {
    has code: str,
        title: str;
    has difficulty_score: int = 5,   # 1 to 10 syllabus difficulty scale
        credit_weight: float = 3.0;

    def to_dict -> JsonDict {
        return {
            "code": self.code,
            "title": self.title,
            "difficulty_score": self.difficulty_score,
            "credit_weight": self.credit_weight
        };
    }
}

node Task {
    has id: str,
        title: str;
    has module: str = "",
        deadline: str = "",
        estimated_hours: float = 1.0,
        weight_score: int = 5,       # 1 to 10 marks weightage
        priority: str = "medium",
        status: str = "pending";

    def to_dict -> JsonDict {
        return {
            "id": self.id,
            "title": self.title,
            "module": self.module,
            "deadline": self.deadline,
            "estimated_hours": self.estimated_hours,
            "weight_score": self.weight_score,
            "priority": self.priority,
            "status": self.status
        };
    }
}

node ScheduleSlot {
    has id: str;
    has task_id: str = "",
        start_time: str = "",
        end_time: str = "",
        duration_hours: float = 1.0,
        is_locked: bool = False;

    def to_dict -> JsonDict {
        return {
            "id": self.id,
            "task_id": self.task_id,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "duration_hours": self.duration_hours,
            "is_locked": self.is_locked
        };
    }
}

node StudyBlock {
    has id: str;
    has task_id: str = "",
        module: str = "",
        start_time: str = "",
        end_time: str = "",
        duration_hours: float = 1.0,
        is_completed: bool = False,
        is_crunch: bool = False;

    def to_dict -> JsonDict {
        return {
            "id": self.id,
            "task_id": self.task_id,
            "module": self.module,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "duration_hours": self.duration_hours,
            "is_completed": self.is_completed,
            "is_crunch": self.is_crunch
        };
    }
}

node UserContext {
    has daily_study_capacity: float = 6.0,
        wake_time: str = "07:00",
        sleep_time: str = "23:00",
        max_continuous_hours: float = 3.0;

    def to_dict -> JsonDict {
        return {
            "daily_study_capacity": self.daily_study_capacity,
            "wake_time": self.wake_time,
            "sleep_time": self.sleep_time,
            "max_continuous_hours": self.max_continuous_hours
        };
    }
}

# Graph Edges connecting Root to entities with typed endpoints

edge HasModule: Root --> Module {}
edge HasTask: Root --> Task {}
edge HasSlot: Root --> ScheduleSlot {}
edge HasBlock: Root --> StudyBlock {}
edge HasContext: Root --> UserContext {}

# Graph Operations & Traversal Walkers

walker AddModule {
    has code: str,
        title: str,
        difficulty_score: int = 5,
        credit_weight: float = 3.0;

    can add_mod with Root entry {
        existing = [here ->:HasModule:->];
        for m in existing {
            if m.code == self.code {
                report m;
                disengage;
            }
        }
        mod_node = here +>:HasModule:+> Module(
            code=self.code,
            title=self.title,
            difficulty_score=self.difficulty_score,
            credit_weight=self.credit_weight
        );
        report mod_node[0];
    }
}

walker ListModules {
    can list_mods with Root entry {
        modules = [here ->:HasModule:->];
        report modules;
    }
}

walker AddTask {
    has id: str,
        title: str,
        module: str = "",
        deadline: str = "",
        estimated_hours: float = 1.0,
        weight_score: int = 5,
        priority: str = "medium",
        status: str = "pending";

    can add_task with Root entry {
        task_node = here +>:HasTask:+> Task(
            id=self.id,
            title=self.title,
            module=self.module,
            deadline=self.deadline,
            estimated_hours=self.estimated_hours,
            weight_score=self.weight_score,
            priority=self.priority,
            status=self.status
        );
        report task_node[0];
    }
}

walker ListTasks {
    has status_filter: str = "";

    can list_tasks with Root entry {
        tasks = [here ->:HasTask:->];
        if self.status_filter != "" {
            filtered: list[Task] = [];
            for t in tasks {
                if t.status == self.status_filter {
                    filtered.append(t);
                }
            }
            report filtered;
        } else {
            report tasks;
        }
    }
}

walker UpdateTaskStatus {
    has task_id: str,
        new_status: str;

    can update_status with Root entry {
        tasks = [here ->:HasTask:->];
        for t in tasks {
            if t.id == self.task_id {
                t.status = self.new_status;
                report t;
                disengage;
            }
        }
        report None;
    }
}

walker AddSlot {
    has id: str,
        task_id: str = "",
        start_time: str = "",
        end_time: str = "",
        duration_hours: float = 1.0,
        is_locked: bool = False;

    can add_slot with Root entry {
        slot_node = here +>:HasSlot:+> ScheduleSlot(
            id=self.id,
            task_id=self.task_id,
            start_time=self.start_time,
            end_time=self.end_time,
            duration_hours=self.duration_hours,
            is_locked=self.is_locked
        );
        report slot_node[0];
    }
}

walker ListSlots {
    can list_slots with Root entry {
        slots = [here ->:HasSlot:->];
        report slots;
    }
}

walker AddStudyBlock {
    has id: str,
        task_id: str = "",
        module: str = "",
        start_time: str = "",
        end_time: str = "",
        duration_hours: float = 1.0,
        is_completed: bool = False,
        is_crunch: bool = False;

    can add_block with Root entry {
        block_node = here +>:HasBlock:+> StudyBlock(
            id=self.id,
            task_id=self.task_id,
            module=self.module,
            start_time=self.start_time,
            end_time=self.end_time,
            duration_hours=self.duration_hours,
            is_completed=self.is_completed,
            is_crunch=self.is_crunch
        );
        report block_node[0];
    }
}

walker ListStudyBlocks {
    can list_blocks with Root entry {
        blocks = [here ->:HasBlock:->];
        report blocks;
    }
}

walker GetScheduleSummary {
    can get_summary with Root entry {
        tasks = [here ->:HasTask:->];
        slots = [here ->:HasSlot:->];
        blocks = [here ->:HasBlock:->];
        modules = [here ->:HasModule:->];
        contexts = [here ->:HasContext:->];

        total_est_hours = 0.0;
        for t in tasks {
            total_est_hours += t.estimated_hours;
        }

        total_scheduled_hours = 0.0;
        crunch_blocks_count = 0;
        for b in blocks {
            total_scheduled_hours += b.duration_hours;
            if b.is_crunch {
                crunch_blocks_count += 1;
            }
        }

        user_cap = 6.0;
        if len(contexts) > 0 {
            user_cap = contexts[0].daily_study_capacity;
        }

        summary: JsonDict = {
            "total_tasks": len(tasks),
            "total_modules": len(modules),
            "total_slots": len(slots),
            "total_study_blocks": len(blocks),
            "crunch_blocks_count": crunch_blocks_count,
            "total_estimated_hours": total_est_hours,
            "total_scheduled_hours": total_scheduled_hours,
            "daily_capacity": user_cap,
            "remaining_capacity": user_cap - total_scheduled_hours
        };

        report summary;
    }
}
