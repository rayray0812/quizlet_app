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

type ClaimedJob = {
  id: number;
  actor_user_id: string;
  job_type: string;
  payload: Record<string, unknown>;
  status: string;
  summary: string;
  attempt_count: number;
  max_attempts: number;
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
  const workerToken = Deno.env.get('ADMIN_WORKER_TOKEN');

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: 'missing_env', message: 'Missing Supabase env.' }),
      { status: 500, headers: jsonHeaders },
    );
  }

  if (!workerToken) {
    return new Response(
      JSON.stringify({ error: 'missing_env', message: 'ADMIN_WORKER_TOKEN not configured.' }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const authHeader = req.headers.get('authorization') ?? '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (token !== workerToken) {
    return new Response(
      JSON.stringify({ error: 'unauthorized', message: 'Invalid worker token.' }),
      { status: 401, headers: jsonHeaders },
    );
  }

  const body = await parseJson(req);
  const maxJobs = clampInt(body?.maxJobs, 1, 100, 20);
  const workerId =
    asString(body?.workerId) ??
    Deno.env.get('ADMIN_WORKER_ID') ??
    `edge-${crypto.randomUUID()}`;

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const executed: Array<Record<string, unknown>> = [];
  const failed: Array<Record<string, unknown>> = [];

  for (let i = 0; i < maxJobs; i += 1) {
    const claim = await admin.rpc('admin_claim_next_bulk_job', { worker: workerId });
    if (claim.error) {
      return new Response(
        JSON.stringify({
          error: 'claim_failed',
          workerId,
          detail: claim.error.message,
          executed,
          failed,
        }),
        { status: 500, headers: jsonHeaders },
      );
    }

    const rows = (claim.data ?? []) as ClaimedJob[];
    const job = rows[0];
    if (!job) {
      break;
    }

    try {
      const result = await runJob(admin, job);
      const complete = await admin.rpc('admin_complete_bulk_job', {
        job_id: job.id,
        success: true,
        err: '',
      });
      if (complete.error) {
        throw new Error(`complete_failed: ${complete.error.message}`);
      }
      executed.push({
        jobId: job.id,
        jobType: job.job_type,
        status: 'done',
        result,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await admin.rpc('admin_complete_bulk_job', {
        job_id: job.id,
        success: false,
        err: message,
      });
      failed.push({
        jobId: job.id,
        jobType: job.job_type,
        status: 'failed',
        error: message,
      });
    }
  }

  return new Response(
    JSON.stringify({
      ok: failed.length === 0,
      workerId,
      maxJobs,
      executedCount: executed.length,
      failedCount: failed.length,
      executed,
      failed,
    }),
    { status: failed.length == 0 ? 200 : 207, headers: jsonHeaders },
  );
});

async function runJob(
  admin: ReturnType<typeof createClient>,
  job: ClaimedJob,
): Promise<Record<string, unknown>> {
  const targets = extractTargetUserIds(job.payload);
  if (targets.length === 0) {
    throw new Error('missing_target_user_ids');
  }

  const results: Array<Record<string, unknown>> = [];
  for (const targetUserId of targets) {
    if (job.job_type === 'signout_user') {
      const response = await admin.rpc('admin_worker_signout_user', {
        target_user_id: targetUserId,
        actor_user_id: job.actor_user_id,
      });
      if (response.error) throw new Error(response.error.message);
      results.push({ targetUserId, action: 'signout_user', response: response.data });
      continue;
    }

    if (job.job_type === 'enforce_mfa') {
      const response = await admin.rpc('admin_worker_enforce_mfa', {
        target_user_id: targetUserId,
        actor_user_id: job.actor_user_id,
      });
      if (response.error) throw new Error(response.error.message);
      results.push({ targetUserId, action: 'enforce_mfa', response: response.data });
      continue;
    }

    if (job.job_type === 'delete_account') {
      const response = await admin.rpc('admin_worker_delete_account', {
        target_user_id: targetUserId,
        actor_user_id: job.actor_user_id,
      });
      if (response.error) throw new Error(response.error.message);
      results.push({ targetUserId, action: 'delete_account', response: response.data });
      continue;
    }

    throw new Error(`unsupported_job_type:${job.job_type}`);
  }

  return {
    targetCount: targets.length,
    results,
  };
}

function extractTargetUserIds(payload: Record<string, unknown>): string[] {
  const single = asString(payload.target_user_id);
  if (single) return [single];

  const many = payload.target_user_ids;
  if (!Array.isArray(many)) return [];

  return many
    .map((value) => asString(value))
    .filter((value): value is string => Boolean(value));
}

function asString(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
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
