# Master Specification: Study Crunch AI

## 1. Project Overview & Identity

* **Product Name:** Study Crunch AI


* **Goal:** Build an autonomous Agentic Planning Assistant designed to help Engineering and STEM students manage demanding assignment deadlines, lab reports, and exam study sessions.


* **Core Standout Hook:** **"Crisis Triage Mode"** — When an urgent deadline is introduced, the agent inspects syllabus difficulty, grade weightage, and available calendar slots, autonomously rescheduling lower-priority tasks (triage) to produce an optimized, conflict-free schedule through self-correction.


* **Tech Stack:** Jac Language, ByLLM, FastAPI / Web Client, Mobile Client, Terminal CLI.



---

## 2. Core Architecture: The Four-Interface Ecosystem

The system consists of four discrete components sharing a unified core data model and persistence layer:

* **1. Server (`core/`):**
* Persists `Task`, `ScheduleSlot`, `Module`, and `Priority` archetypes.


* Hosts agentic decision walkers and LLM tool execution logic.


* Enforces cross-interface data consistency and state management.




* **2. CLI Interface (`cli/`):**
* Provides native terminal commands tailored for engineering and developer workflows.


* Command suite:
* `jac run cli/main.jac triage --task "Lab 03" --due "tomorrow 18:00" --est 4h`

* `jac run cli/main.jac add --task "DSP Revision" --prio high`

* `jac run cli/main.jac status` (Inspect daily schedule, active blocks, and free time slots)






* **3. Web Frontend (`web/`):**
* Delivers a comprehensive visual calendar timeline, syllabus progress tracking, and dynamic triage visualization.




* **4. Mobile App (`mobile/`):**
* Offers an on-the-go glance view, active study block focus timer, and dynamic reschedule notifications.





---

## 3. The Agentic Workflow Loop

The agent executes a multi-step decision and self-correction loop:

* **Step 1 (Goal Reception):** Ingests the task title, deadline, and estimated duration via CLI or Web interface.


* **Step 2 (Context Retrieval):** Invokes `get_current_schedule()` to retrieve the active timetable, committed slots, and open availability.


* **Step 3 (Reasoning & Tool Execution):**
* Evaluates open time blocks to accommodate the requested duration.


* Invokes `check_conflict(slot, duration)` to validate availability against existing commitments.




* **Step 4 (Reflection & Self-Correction):**
* If insufficient time or a conflict is detected, the agent backtracks, identifies routine tasks with lower grade impact, and shifts them to later dates to free up required capacity.




* **Step 5 (State Mutation):** Persists the updated plan to the database using `commit_schedule()` and triggers state synchronization across CLI, Web, and Mobile clients.



---

## 4. Implementation Roadmap & Agent Instructions

Follow these discrete phases sequentially:

### Phase 1: Environment & Scaffolding

* Reference the multi-interface layout from `jac/examples/jaclang_org/` in the `jaseci` repository.


* Establish the project root with `jac.toml`, `core/`, `cli/`, `web/`, and `mobile/`.


* Verify that the repository root boots cleanly via `jac run`.



### Phase 2: Data Models & Persistence (`core/models.jac`)

* Implement core archetypes in Jac syntax:


* `Task`: `id`, `title`, `module`, `deadline`, `estimated_hours`, `weight_score` (1–10), `status`.


* `ScheduleSlot`: `id`, `task_id`, `start_time`, `end_time`, `is_locked`.


* `UserContext`: `daily_study_capacity`, `wake_time`, `sleep_time`.




* Set up disk-backed persistence to ensure state survives server restarts.



### Phase 3: Agentic Tools & Triage Engine (`core/triage_agent.jac`)

* Construct planning agent walkers powered by ByLLM.


* Implement agent tools:
* `fetch_slots(date)`: Query current schedule availability.


* `evaluate_conflict(proposed_slot)`: Identify time collisions.


* `reschedule_low_priority(needed_hours)`: Defer lower-priority tasks to subsequent periods.


* `save_plan(new_schedule)`: Commit modified schedule state.





### Phase 4: CLI Implementation (`cli/main.jac`)

* Parse terminal arguments (`--task`, `--due`, `--est`) and dispatch execution to the `core/` triage walker.


* Stream agent reasoning logs directly to stdout (e.g., `Slot conflict detected -> deferring Routine Reading -> slot confirmed`).



### Phase 5: Web & Mobile Synchronization (`web/` & `mobile/`)

* Build the interactive calendar view in `web/` and bind it to backend walkers.


* Ensure state changes triggered from the CLI reflect reactively on the Web view.


* Implement a responsive task checklist and focus card for the mobile client.



### Phase 6: Documentation (`README.md`)

* Provide a comprehensive `README.md` covering prerequisites, setup instructions, single-command run validation (`jac run`), architectural component linkage, and agentic context workflow details.