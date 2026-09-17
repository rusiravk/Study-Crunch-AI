"""Core Data Models for Study Crunch AI.

Defines base archetypes for Tasks, ScheduleSlots, StudyBlocks,
and UserContext, along with graph edges and traversal walkers.
"""

# Graph Persistent Nodes

node Task {
    has id: str,
        title: str;
    has module: str = "",
        deadline: str = "",
        estimated_hours: float = 1.0,
        weight_score: int = 5,
        status: str = "pending";
}

node ScheduleSlot {
    has id: str;
    has task_id: str = "",
        start_time: str = "",
        end_time: str = "",
        is_locked: bool = False;
}

node StudyBlock {
    has id: str;
    has task_id: str = "",
        module: str = "",
        start_time: str = "",
        end_time: str = "",
        duration_hours: float = 1.0,
        is_completed: bool = False;
}

node UserContext {
    has daily_study_capacity: float = 6.0,
        wake_time: str = "07:00",
        sleep_time: str = "23:00";
}

# Graph Edges connecting Root to entities with typed endpoints

edge HasTask: Root --> Task {}
edge HasSlot: Root --> ScheduleSlot {}
edge HasBlock: Root --> StudyBlock {}
edge HasContext: Root --> UserContext {}

# Graph Walkers

walker AddTask {
    has id: str,
        title: str,
        module: str = "",
        deadline: str = "",
        estimated_hours: float = 1.0,
        weight_score: int = 5,
        status: str = "pending";

    can add_task with Root entry {
        task_node = here +>:HasTask:+> Task(
            id=self.id,
            title=self.title,
            module=self.module,
            deadline=self.deadline,
            estimated_hours=self.estimated_hours,
            weight_score=self.weight_score,
            status=self.status
        );
        report task_node[0];
    }
}

walker ListTasks {
    can list_tasks with Root entry {
        tasks = [here ->:HasTask:->];
        report tasks;
    }
}

walker AddSlot {
    has id: str,
        task_id: str = "",
        start_time: str = "",
        end_time: str = "",
        is_locked: bool = False;

    can add_slot with Root entry {
        slot_node = here +>:HasSlot:+> ScheduleSlot(
            id=self.id,
            task_id=self.task_id,
            start_time=self.start_time,
            end_time=self.end_time,
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
        is_completed: bool = False;

    can add_block with Root entry {
        block_node = here +>:HasBlock:+> StudyBlock(
            id=self.id,
            task_id=self.task_id,
            module=self.module,
            start_time=self.start_time,
            end_time=self.end_time,
            duration_hours=self.duration_hours,
            is_completed=self.is_completed
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
