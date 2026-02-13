import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
};

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'method_not_allowed', message: 'Use POST.' }),
      { status: 405, headers: jsonHeaders },
    );
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const workerToken = Deno.env.get('ADMIN_GOVERNANCE_WORKER_TOKEN');

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: 'missing_env', message: 'Missing Supabase env.' }),
      { status: 500, headers: jsonHeaders },
    );
  }

  if (workerToken) {
    const authHeader = req.headers.get('authorization') ?? '';
    const token = authHeader.replace('Bearer ', '').trim();
    if (token != workerToken) {
      return new Response(
        JSON.stringify({ error: 'unauthorized', message: 'Invalid worker token.' }),
        { status: 401, headers: jsonHeaders },
      );
    }
  }

  const body = await parseJson(req);
  const staleHours = clampInt(body?.staleApprovalHours, 1, 24 * 90, 72);
  const overdueHours = clampInt(body?.overdueApprovalHours, 1, 24 * 90, 24);
  const slaHours = clampInt(body?.slaHours, 1, 24 * 30, 24);
  const escalationChannel = (asString(body?.escalationChannel) ?? 'webhook').toLowerCase();
  const dispatchLimit = clampInt(body?.dispatchLimit, 1, 200, 50);

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const assignedOwners = await admin.rpc('admin_assign_approval_owners', {
    default_owner: null,
    sla_hours: slaHours,
  });
  if (assignedOwners.error) {
    return new Response(
      JSON.stringify({
        error: 'assign_owners_failed',
        detail: assignedOwners.error.message,
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const expireApprovals = await admin.rpc('admin_expire_stale_approval_requests', {
    max_age_hours: staleHours,
  });
  if (expireApprovals.error) {
    return new Response(
      JSON.stringify({
        error: 'expire_approvals_failed',
        detail: expireApprovals.error.message,
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const expireImpersonation = await admin.rpc('admin_expire_impersonation_sessions');
  if (expireImpersonation.error) {
    return new Response(
      JSON.stringify({
        error: 'expire_impersonation_failed',
        detail: expireImpersonation.error.message,
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const raiseOverdue = await admin.rpc('admin_raise_overdue_approval_alerts', {
    overdue_hours: overdueHours,
  });
  if (raiseOverdue.error) {
    return new Response(
      JSON.stringify({
        error: 'raise_overdue_failed',
        detail: raiseOverdue.error.message,
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const queueEscalations = await admin.rpc('admin_enqueue_sla_escalation_notifications', {
    overdue_hours: overdueHours,
    channel: escalationChannel,
  });
  if (queueEscalations.error) {
    return new Response(
      JSON.stringify({
        error: 'queue_escalations_failed',
        detail: queueEscalations.error.message,
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const dispatchResult = await dispatchPendingNotifications(admin, dispatchLimit);

  return new Response(
    JSON.stringify({
      ok: true,
      staleApprovalHours: staleHours,
      overdueApprovalHours: overdueHours,
      slaHours,
      assignedApprovalOwners: assignedOwners.data ?? 0,
      expiredApprovals: expireApprovals.data ?? 0,
      expiredImpersonationSessions: expireImpersonation.data ?? 0,
      createdOverdueAlerts: raiseOverdue.data ?? 0,
      queuedEscalationNotifications: queueEscalations.data ?? 0,
      dispatch: dispatchResult,
      runAt: new Date().toISOString(),
    }),
    { status: 200, headers: jsonHeaders },
  );
});

async function dispatchPendingNotifications(
  admin: ReturnType<typeof createClient>,
  limit: number,
): Promise<Record<string, unknown>> {
  const fetchRows = await admin
    .from('admin_notification_outbox')
    .select('id, channel, destination, subject, body, payload, attempts')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(limit);
  if (fetchRows.error) {
    throw new Error(`fetch_outbox_failed: ${fetchRows.error.message}`);
  }

  const sent: number[] = [];
  const failed: Array<Record<string, unknown>> = [];
  for (const row of fetchRows.data ?? []) {
    try {
      if ((row.channel as string).toLowerCase() !== 'webhook') {
        throw new Error(`unsupported_channel:${row.channel}`);
      }
      const payload = {
        subject: row.subject,
        body: row.body,
        details: row.payload,
      };
      const response = await fetch(String(row.destination), {
        method: 'POST',
        headers: { 'content-type': 'application/json; charset=utf-8' },
        body: JSON.stringify(payload),
      });
      if (!response.ok) {
        throw new Error(`webhook_status_${response.status}`);
      }
      const updateSent = await admin
        .from('admin_notification_outbox')
        .update({
          status: 'sent',
          attempts: Number(row.attempts ?? 0) + 1,
          last_error: '',
          sent_at: new Date().toISOString(),
        })
        .eq('id', row.id);
      if (updateSent.error) {
        throw new Error(`update_sent_failed:${updateSent.error.message}`);
      }
      sent.push(Number(row.id));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await admin
        .from('admin_notification_outbox')
        .update({
          status: 'failed',
          attempts: Number(row.attempts ?? 0) + 1,
          last_error: message,
        })
        .eq('id', row.id);
      failed.push({ id: row.id, error: message });
    }
  }

  return {
    polled: (fetchRows.data ?? []).length,
    sentCount: sent.length,
    failedCount: failed.length,
    failed,
  };
}

function clampInt(
  value: unknown,
  min: number,
  max: number,
  fallback: number,
): number {
  const parsed = Number.parseInt(String(value), 10);
  if (Number.isNaN(parsed)) return fallback;
  return Math.min(max, Math.max(min, parsed));
}

function asString(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

async function parseJson(req: Request): Promise<Record<string, unknown> | null> {
  try {
    const raw = await req.json();
    if (raw && typeof raw === 'object') {
      return raw as Record<string, unknown>;
    }
    return null;
  } catch {
    return null;
  }
}
