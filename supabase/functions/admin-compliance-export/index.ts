import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
};

const jsonHeaders = {
  ...corsHeaders,
  'content-type': 'application/json; charset=utf-8',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'method_not_allowed', message: 'Use POST.' }),
      { status: 405, headers: jsonHeaders },
    );
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const workerToken = Deno.env.get('ADMIN_COMPLIANCE_EXPORT_TOKEN');
  const signingKey = Deno.env.get('ADMIN_COMPLIANCE_SIGNING_KEY');

  if (!supabaseUrl || !serviceRoleKey || !signingKey) {
    return new Response(
      JSON.stringify({
        error: 'missing_env',
        message: 'Missing SUPABASE_URL/SERVICE_ROLE/ADMIN_COMPLIANCE_SIGNING_KEY.',
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const authHeader = req.headers.get('authorization') ?? '';
  const bearer = authHeader.replace('Bearer ', '').trim();
  if (!bearer) {
    return new Response(
      JSON.stringify({ error: 'unauthorized', message: 'Missing bearer token.' }),
      { status: 401, headers: jsonHeaders },
    );
  }

  const body = await parseJson(req);
  const days = clampInt(body?.days, 1, 365, 30);
  const format = (asString(body?.format) ?? 'json').toLowerCase();
  let actorUserId: string | null = null;
  if (format !== 'json' && format !== 'csv') {
    return new Response(
      JSON.stringify({ error: 'invalid_format', message: 'format must be json or csv.' }),
      { status: 400, headers: jsonHeaders },
    );
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  if (workerToken && bearer === workerToken) {
    // trusted machine-to-machine path
    actorUserId = asString(Deno.env.get('ADMIN_COMPLIANCE_ACTOR_USER_ID'));
    if (!actorUserId) {
      return new Response(
        JSON.stringify({
          error: 'missing_actor',
          message: 'Set ADMIN_COMPLIANCE_ACTOR_USER_ID env for worker mode.',
        }),
        { status: 400, headers: jsonHeaders },
      );
    }
  } else {
    const userRes = await admin.auth.getUser(bearer);
    const user = userRes.data.user;
    if (userRes.error || !user) {
      return new Response(
        JSON.stringify({ error: 'unauthorized', message: 'Invalid user token.' }),
        { status: 401, headers: jsonHeaders },
      );
    }

    const roleCheck = await admin
      .from('admin_role_bindings')
      .select('id')
      .eq('admin_user_id', user.id)
      .eq('scope_type', 'global')
      .in('role_key', ['super_admin', 'org_admin'])
      .limit(1);
    if (roleCheck.error || !roleCheck.data || roleCheck.data.length === 0) {
      return new Response(
        JSON.stringify({ error: 'forbidden', message: 'Global admin required.' }),
        { status: 403, headers: jsonHeaders },
      );
    }

    actorUserId = user.id;
  }

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
  const [auditRows, approvalRows, impersonationRows, bulkRows] = await Promise.all([
    admin
      .from('admin_audit_logs')
      .select('id, actor_user_id, target_user_id, action, reason, created_at')
      .gte('created_at', since)
      .order('created_at', { ascending: false })
      .limit(1000),
    admin
      .from('admin_approval_requests')
      .select('id, requested_by, owner_admin_user_id, action_type, reason, status, created_at')
      .gte('created_at', since)
      .order('created_at', { ascending: false })
      .limit(1000),
    admin
      .from('admin_impersonation_sessions')
      .select('id, actor_user_id, target_user_id, ticket_id, reason, started_at, ended_at, status')
      .gte('started_at', since)
      .order('started_at', { ascending: false })
      .limit(1000),
    admin
      .from('admin_bulk_jobs')
      .select('id, actor_user_id, job_type, status, summary, created_at')
      .gte('created_at', since)
      .order('created_at', { ascending: false })
      .limit(1000),
  ]);

  if (auditRows.error || approvalRows.error || impersonationRows.error || bulkRows.error) {
    return new Response(
      JSON.stringify({
        error: 'query_failed',
        detail:
          auditRows.error?.message ??
          approvalRows.error?.message ??
          impersonationRows.error?.message ??
          bulkRows.error?.message ??
          'unknown',
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const snapshot = {
    generatedAt: new Date().toISOString(),
    windowDays: days,
    since,
    counts: {
      auditLogs: (auditRows.data ?? []).length,
      approvalRequests: (approvalRows.data ?? []).length,
      impersonationSessions: (impersonationRows.data ?? []).length,
      bulkJobs: (bulkRows.data ?? []).length,
    },
    auditLogs: auditRows.data ?? [],
    approvalRequests: approvalRows.data ?? [],
    impersonationSessions: impersonationRows.data ?? [],
    bulkJobs: bulkRows.data ?? [],
  };

  const generatedAtCompact = snapshot.generatedAt.replaceAll(':', '-');
  const fileName = `admin_compliance_${generatedAtCompact}.${format}`;
  const content = format === 'json' ? JSON.stringify(snapshot, null, 2) : toCsv(snapshot);
  const contentBytes = new TextEncoder().encode(content);
  const signature = await signHmacSha256(contentBytes, signingKey);
  const checksumSha256 = await sha256Hex(contentBytes);
  if (!actorUserId) {
    return new Response(
      JSON.stringify({ error: 'missing_actor', message: 'Unable to resolve actor user id.' }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const insert = await admin.from('admin_compliance_exports').insert({
    generated_by: actorUserId,
    format,
    window_days: days,
    file_name: fileName,
    signature,
    checksum_sha256: checksumSha256,
    metadata: {
      counts: snapshot.counts,
      since,
    },
  });

  if (insert.error) {
    return new Response(
      JSON.stringify({ error: 'insert_failed', detail: insert.error.message }),
      { status: 500, headers: jsonHeaders },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      format,
      mimeType: format === 'json' ? 'application/json' : 'text/csv',
      fileName,
      signature,
      checksumSha256,
      contentBase64: toBase64(contentBytes),
      generatedAt: snapshot.generatedAt,
      windowDays: days,
      counts: snapshot.counts,
    }),
    { status: 200, headers: jsonHeaders },
  );
});

function toCsv(snapshot: {
  generatedAt: string;
  windowDays: number;
  since: string;
  counts: Record<string, number>;
  auditLogs: Array<Record<string, unknown>>;
  approvalRequests: Array<Record<string, unknown>>;
  impersonationSessions: Array<Record<string, unknown>>;
  bulkJobs: Array<Record<string, unknown>>;
}): string {
  const lines: string[] = [];
  lines.push('section,key,value');
  lines.push(`meta,generatedAt,${csvEscape(snapshot.generatedAt)}`);
  lines.push(`meta,windowDays,${snapshot.windowDays}`);
  lines.push(`meta,since,${csvEscape(snapshot.since)}`);

  for (const [key, value] of Object.entries(snapshot.counts)) {
    lines.push(`counts,${csvEscape(key)},${value}`);
  }

  lines.push('');
  lines.push('audit_logs,id,actor_user_id,target_user_id,action,reason,created_at');
  for (const row of snapshot.auditLogs) {
    lines.push(
      [
        'audit_logs',
        row.id,
        row.actor_user_id,
        row.target_user_id,
        row.action,
        row.reason,
        row.created_at,
      ]
        .map((x) => csvEscape(String(x ?? '')))
        .join(','),
    );
  }

  lines.push('');
  lines.push('approval_requests,id,requested_by,owner_admin_user_id,action_type,reason,status,created_at');
  for (const row of snapshot.approvalRequests) {
    lines.push(
      [
        'approval_requests',
        row.id,
        row.requested_by,
        row.owner_admin_user_id,
        row.action_type,
        row.reason,
        row.status,
        row.created_at,
      ]
        .map((x) => csvEscape(String(x ?? '')))
        .join(','),
    );
  }

  lines.push('');
  lines.push('impersonation_sessions,id,actor_user_id,target_user_id,ticket_id,reason,started_at,ended_at,status');
  for (const row of snapshot.impersonationSessions) {
    lines.push(
      [
        'impersonation_sessions',
        row.id,
        row.actor_user_id,
        row.target_user_id,
        row.ticket_id,
        row.reason,
        row.started_at,
        row.ended_at,
        row.status,
      ]
        .map((x) => csvEscape(String(x ?? '')))
        .join(','),
    );
  }

  lines.push('');
  lines.push('bulk_jobs,id,actor_user_id,job_type,status,summary,created_at');
  for (const row of snapshot.bulkJobs) {
    lines.push(
      [
        'bulk_jobs',
        row.id,
        row.actor_user_id,
        row.job_type,
        row.status,
        row.summary,
        row.created_at,
      ]
        .map((x) => csvEscape(String(x ?? '')))
        .join(','),
    );
  }

  return lines.join('\n');
}

function csvEscape(value: string): string {
  const escaped = value.replaceAll('"', '""');
  if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('"')) {
    return `"${escaped}"`;
  }
  return escaped;
}

function asString(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function clampInt(value: unknown, min: number, max: number, fallback: number): number {
  const parsed = Number.parseInt(String(value), 10);
  if (Number.isNaN(parsed)) return fallback;
  return Math.min(max, Math.max(min, parsed));
}

async function signHmacSha256(data: Uint8Array, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, data);
  return toHex(new Uint8Array(sig));
}

async function sha256Hex(data: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', data);
  return toHex(new Uint8Array(digest));
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function toBase64(bytes: Uint8Array): string {
  let binary = '';
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
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
