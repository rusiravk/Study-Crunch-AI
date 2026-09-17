# Agent Directives: Study Crunch AI

## Continuous Verification & Zero-Error Policy

1. **Mandatory Post-Change Verification**:
   - Always run `jac check . -e` immediately after making any code or file modification.
   - Proactively inspect the terminal output for compiler diagnostics, syntax errors, or type warnings.

2. **Zero-Error & Zero-Warning Standard**:
   - Never leave unresolved errors, type diagnostics, or warnings in any `.jac` or workspace file.
   - Verify that all active files pass compilation (`100% passed`) before reporting completion.

3. **Runtime Health Validation**:
   - Ensure the workspace root consistently executes cleanly via `jac run` with exit code `0`.
