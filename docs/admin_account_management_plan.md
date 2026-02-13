# Admin Account Management Plan

## Scope
Build a complete admin system for account governance, security operations, support workflows, and compliance traceability.

## Capability Matrix

### 1. Roles & Access Control
- `super_admin`: full global privileges.
- `org_admin`: tenant-scoped account and policy management.
- `support_admin`: support operations without destructive permissions.
- `readonly_auditor`: read-only access to audit and security state.

### 2. Account Search & Profile Inspection
- Search by `user_id`, email, status, role, last login, risk score.
- Full account profile:
  - auth factors
  - session summary
  - recent security events
  - linked providers

### 3. Account Lifecycle Controls
- Invite/create account.
- Disable/enable account.
- Soft delete + retention window + restore.
- Hard delete workflow with approval.

### 4. Session & Auth Security
- Sign out one session / all sessions.
- Force password reset.
- Enforce/clear MFA challenge.
- Lock account temporarily with reason.

### 5. Risk & Detection
- Rule-driven risk scoring:
  - unusual geography
  - rapid failed login attempts
  - suspicious device changes
- Alert generation and queue-based triage.

### 6. Support Console
- Controlled impersonation with:
  - ticket ID requirement
  - time-limited session
  - immutable audit trail
- Guided support actions and rollback hints.

### 7. Bulk Operations
- CSV-driven batch actions:
  - disable/enable
  - force signout
  - role assignment
- Dry-run preview before execution.

### 8. Audit & Compliance
- Immutable admin action log.
- Two-step approvals for destructive actions.
- Exportable compliance reports (date, actor, target, reason, outcome).

### 9. API & Operational Controls
- Admin API with strict RBAC + scope checks.
- Service key isolation and environment partitioning.
- IP allowlist and high-risk action rate limits.

## Delivery Phases

### Phase 1 (Foundation)
- Admin roles and bindings.
- Admin audit log.
- Session control endpoints.
- Read-only account search UI + basic action panel.

### Phase 2 (Security & Workflow)
- Risk rules + alert queue.
- MFA and password enforcement tools.
- Support impersonation with approvals.

### Phase 3 (Scale & Compliance)
- Bulk operations with dry-run.
- Compliance export center.
- Advanced governance (policy packs, delegated scopes).

## Data Model (Summary)
- `admin_roles`: role definitions.
- `admin_role_bindings`: which admin user has what role/scope.
- `admin_audit_logs`: immutable action records.
- `admin_account_blocks`: account blocks with reason and expiry.
- `admin_bulk_jobs`: queued batch operations and status.

## Operational Preconditions
- Supabase project with RLS enabled.
- Secure server-side execution path for privileged admin actions.
- Dedicated admin UI route protected by admin role checks.
