"""Web Interface Entry Point for Study Crunch AI.

Hosts the FastAPI web service on port 8000, serving:
- REST API endpoints for state, modules, triage, and task management.
- Desktop Web Dashboard (/ and /calendar, /modules, /triage).
- Mobile View (/mobile).
"""

import from fastapi { FastAPI }
import from fastapi.responses { HTMLResponse, JSONResponse }
import uvicorn;
import json;
import os;
import sys;
import from core.models {
    Task,
    StudyBlock,
    Module,
    UserContext,
    HasTask,
    HasBlock,
    HasModule,
    HasContext
}
import from core.persistence {
    LoadStateFromFile,
    SaveStateToFile
}
import from core.triage_agent {
    CrisisTriageAgent
}

# Route Handlers
def get_dashboard() -> HTMLResponse {
    html_path = os.path.join(os.path.dirname(__file__), "index.html");
    if os.path.exists(html_path) {
        with open(html_path, "r", encoding="utf-8") as f {
            content = f.read();
            return HTMLResponse(content=content, status_code=200);
        }
    }
    return HTMLResponse(content="<h1>Study Crunch AI Dashboard</h1>", status_code=200);
}

def get_mobile_view() -> HTMLResponse {
    root_dir = os.path.dirname(os.path.dirname(__file__));
    mobile_html_path = os.path.join(root_dir, "mobile", "index.html");
    if os.path.exists(mobile_html_path) {
        with open(mobile_html_path, "r", encoding="utf-8") as f {
            content = f.read();
            return HTMLResponse(content=content, status_code=200);
        }
    }
    return HTMLResponse(content="<h1>Study Crunch AI Mobile</h1>", status_code=200);
}

def get_api_status() -> JSONResponse {
    root spawn LoadStateFromFile();
    tasks = [root ->:HasTask:->];
    blocks = [root ->:HasBlock:->];
    modules = [root ->:HasModule:->];
    contexts = [root ->:HasContext:->];

    task_list: list[dict[str, str | int | float | bool]] = [];
    for t in tasks {
        task_list.append({
            "id": t.id,
            "title": t.title,
            "module": t.module,
            "deadline": t.deadline,
            "estimated_hours": t.estimated_hours,
            "weight_score": t.weight_score,
            "priority": t.priority,
            "status": t.status
        });
    }

    block_list: list[dict[str, str | int | float | bool]] = [];
    for b in blocks {
        block_list.append({
            "id": b.id,
            "task_id": b.task_id,
            "module": b.module,
            "start_time": b.start_time,
            "end_time": b.end_time,
            "duration_hours": b.duration_hours,
            "is_completed": b.is_completed,
            "is_crunch": b.is_crunch
        });
    }

    module_list: list[dict[str, str | int | float | bool]] = [];
    for m in modules {
        module_list.append({
            "code": m.code,
            "title": m.title,
            "difficulty_score": m.difficulty_score,
            "credit_weight": m.credit_weight
        });
    }

    user_cap = 6.0;
    wake = "07:00";
    sleep = "23:00";
    if len(contexts) > 0 {
        user_cap = contexts[0].daily_study_capacity;
        wake = contexts[0].wake_time;
        sleep = contexts[0].sleep_time;
    }

    data: dict[str, str | int | float | bool | list[dict[str, str | int | float | bool]]] = {
        "status": "success",
        "daily_study_capacity": user_cap,
        "wake_time": wake,
        "sleep_time": sleep,
        "tasks": task_list,
        "blocks": block_list,
        "modules": module_list
    };

    return JSONResponse(content=data, status_code=200);
}

def get_api_modules() -> JSONResponse {
    root spawn LoadStateFromFile();
    modules = [root ->:HasModule:->];
    m_list: list[dict[str, str | int | float | bool]] = [];
    for m in modules {
        m_list.append({
            "code": m.code,
            "title": m.title,
            "difficulty_score": m.difficulty_score,
            "credit_weight": m.credit_weight
        });
    }
    return JSONResponse(content=m_list, status_code=200);
}

def post_api_triage(req: dict[str, str | int | float | bool]) -> JSONResponse {
    root spawn LoadStateFromFile();

    task_name = str(req.get("task_title", "Emergency Crunch Assignment"));
    mod_code = str(req.get("module", "GEN101"));
    due_date = str(req.get("deadline", "tomorrow 18:00"));
    est_val = float(req.get("estimated_hours", 2.0));
    prio_val = int(req.get("weight_score", 9));

    agent = root spawn CrisisTriageAgent(
        task_title=task_name,
        deadline=due_date,
        estimated_hours=est_val,
        weight_score=prio_val,
        module=mod_code
    );

    if agent.decision is not None {
        dec = agent.decision;
        res_data: dict[str, str | int | float | bool | list[str]] = {
            "success": dec.success,
            "task_id": dec.task_id,
            "task_title": dec.task_title,
            "allocated_start": dec.allocated_start,
            "allocated_end": dec.allocated_end,
            "deferred_tasks": dec.deferred_tasks,
            "reasoning": dec.reasoning,
            "summary": dec.summary
        };
        return JSONResponse(content=res_data, status_code=200);
    }

    return JSONResponse(content={"success": False, "summary": "Triage failed to initialize"}, status_code=400);
}

def post_api_tasks(req: dict[str, str | int | float | bool]) -> JSONResponse {
    root spawn LoadStateFromFile();

    title = str(req.get("title", "New Assignment"));
    mod = str(req.get("module", "GEN101"));
    due = str(req.get("deadline", "tomorrow 18:00"));
    est = float(req.get("estimated_hours", 2.0));
    prio = int(req.get("weight_score", 8));

    h_val = int(abs(hash(title)));
    task_id = f"task_{h_val % 10000:04d}";

    root +>:HasTask:+> Task(
        id=task_id,
        title=title,
        module=mod,
        deadline=due,
        estimated_hours=est,
        weight_score=prio,
        priority="high" if prio >= 8 else ("medium" if prio >= 5 else "low"),
        status="pending"
    );

    root spawn SaveStateToFile();
    return JSONResponse(content={"status": "success", "task_id": task_id}, status_code=200);
}

def post_api_complete(req: dict[str, str | int | float | bool]) -> JSONResponse {
    root spawn LoadStateFromFile();
    target = str(req.get("task", "")).strip().lower();

    tasks = [root ->:HasTask:->];
    blocks = [root ->:HasBlock:->];

    updated = False;
    for t in tasks {
        if target in t.id.lower() or target in t.title.lower() {
            t.status = "completed";
            updated = True;
            for b in blocks {
                if b.task_id == t.id {
                    b.is_completed = True;
                }
            }
        }
    }

    if updated {
        root spawn SaveStateToFile();
        return JSONResponse(content={"status": "success", "message": f"Completed {target}"}, status_code=200);
    }

    return JSONResponse(content={"status": "not_found", "message": f"No task matching {target}"}, status_code=404);
}

def create_app() -> FastAPI {
    web_app = FastAPI(
        title="Study Crunch AI - Web Service",
        description="Agentic Study Planning & Crisis Triage API",
        version="0.1.0"
    );

    web_app.add_api_route("/", get_dashboard, methods=["GET"]);
    web_app.add_api_route("/calendar", get_dashboard, methods=["GET"]);
    web_app.add_api_route("/modules", get_dashboard, methods=["GET"]);
    web_app.add_api_route("/triage", get_dashboard, methods=["GET"]);
    web_app.add_api_route("/mobile", get_mobile_view, methods=["GET"]);

    web_app.add_api_route("/api/status", get_api_status, methods=["GET"]);
    web_app.add_api_route("/api/modules", get_api_modules, methods=["GET"]);
    web_app.add_api_route("/api/triage", post_api_triage, methods=["POST"]);
    web_app.add_api_route("/api/tasks", post_api_tasks, methods=["POST"]);
    web_app.add_api_route("/api/complete", post_api_complete, methods=["POST"]);

    return web_app;
}

with entry {
    print("\n=========================================================================");
    print("                STUDY CRUNCH AI - FASTAPI WEB DASHBOARD                  ");
    print("=========================================================================");
    print("  [+] Web Dashboard  : http://localhost:8000");
    print("  [+] Mobile Client  : http://localhost:8000/mobile");
    print("  [+] API Endpoints  : http://localhost:8000/api/status, /api/triage");
    print("=========================================================================\n");

    app = create_app();

    run_server = True;
    for arg in sys.argv {
        if arg == "--no-serve" or arg == "--test" {
            run_server = False;
        }
    }

    if run_server {
        print("[*] Starting Uvicorn ASGI server on port 8000 (Press Ctrl+C to stop)...");
        uvicorn.run(app, host="127.0.0.1", port=8000, log_level="info");
    } else {
        print("[*] Test mode active: Web endpoints initialized cleanly with zero errors.");
    }
}
