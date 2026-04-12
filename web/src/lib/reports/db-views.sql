-- ============================================================================
-- ConstructionOS Reporting & Dashboards — Database Views
-- Phase 19: Standard views + materialized views for report aggregation
-- ============================================================================
-- Run this AFTER db-schema.sql in your Supabase SQL editor.
-- Prerequisites: cs_projects, cs_contracts, cs_change_orders,
--   cs_safety_incidents, cs_rfis, cs_project_tasks tables must exist.
--
-- Per D-56g: Standard views for light aggregation (always fresh data).
-- Materialized views for heavy aggregation (periodic refresh via pg_cron).
-- API routes fall back to raw queries if views are unavailable.
-- ============================================================================


-- ============================================================================
-- STANDARD VIEWS (always fresh, low-cost joins)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- v_project_budget_summary
-- Budget and financial metrics per project.
-- Joins cs_projects with cs_contracts to compute totals.
-- ---------------------------------------------------------------------------
create or replace view v_project_budget_summary as
select
  p.id as project_id,
  p.name as project_name,
  p.client,
  p.status,
  p.budget as budget_text,
  -- Total contract value across all contracts linked to this project
  coalesce(
    (select sum(
      case
        when c.budget ~ '^\$?[\d,]+\.?\d*$'
        then cast(replace(replace(c.budget, '$', ''), ',', '') as numeric)
        else 0
      end
    )
    from cs_contracts c
    where c.client = p.client and c.stage != 'Lost'),
    0
  ) as contract_value_total,
  -- Change order net impact
  coalesce(
    (select sum(
      case
        when co.amount ~ '^\$?-?[\d,]+\.?\d*$'
        then cast(replace(replace(co.amount, '$', ''), ',', '') as numeric)
        else 0
      end
    )
    from cs_change_orders co
    where co.project_id = p.id),
    0
  ) as change_order_net,
  p.progress,
  p.created_at
from cs_projects p;


-- ---------------------------------------------------------------------------
-- v_project_issue_counts
-- Count of open issues per project: RFIs, change orders, safety incidents.
-- ---------------------------------------------------------------------------
create or replace view v_project_issue_counts as
select
  p.id as project_id,
  p.name as project_name,
  p.status,
  -- Open RFIs (status is not 'Closed' or 'Resolved')
  coalesce(
    (select count(*)
     from cs_rfis r
     where r.project_id = p.id
       and r.status not in ('Closed', 'Resolved')),
    0
  ) as open_rfis,
  -- Open change orders (status is not 'Approved' or 'Rejected')
  coalesce(
    (select count(*)
     from cs_change_orders co
     where co.project_id = p.id
       and co.status not in ('Approved', 'Rejected')),
    0
  ) as open_change_orders,
  -- Critical safety incidents (severity = 'Serious' and not resolved)
  coalesce(
    (select count(*)
     from cs_safety_incidents si
     where si.project_id = p.id
       and si.severity = 'Serious'
       and si.status != 'Resolved'),
    0
  ) as critical_safety_issues,
  -- Total open issues (sum of all)
  coalesce(
    (select count(*)
     from cs_rfis r
     where r.project_id = p.id
       and r.status not in ('Closed', 'Resolved')),
    0
  ) +
  coalesce(
    (select count(*)
     from cs_change_orders co
     where co.project_id = p.id
       and co.status not in ('Approved', 'Rejected')),
    0
  ) +
  coalesce(
    (select count(*)
     from cs_safety_incidents si
     where si.project_id = p.id
       and si.status != 'Resolved'),
    0
  ) as total_open_issues
from cs_projects p;


-- ---------------------------------------------------------------------------
-- v_project_team_summary
-- Team member counts and role breakdown per project.
-- Uses cs_project_tasks assignee data as a proxy for team membership.
-- ---------------------------------------------------------------------------
create or replace view v_project_team_summary as
select
  p.id as project_id,
  p.name as project_name,
  p.team as team_text,
  -- Count distinct assignees from project tasks
  coalesce(
    (select count(distinct pt.assignee_id)
     from cs_project_tasks pt
     where pt.project_id = p.id
       and pt.assignee_id is not null),
    0
  ) as team_member_count,
  -- Count of active tasks (proxy for team activity)
  coalesce(
    (select count(*)
     from cs_project_tasks pt
     where pt.project_id = p.id
       and pt.status not in ('Done', 'Cancelled')),
    0
  ) as active_task_count,
  -- Count of completed tasks
  coalesce(
    (select count(*)
     from cs_project_tasks pt
     where pt.project_id = p.id
       and pt.status = 'Done'),
    0
  ) as completed_task_count
from cs_projects p;


-- ---------------------------------------------------------------------------
-- v_project_safety_summary
-- Safety incident counts by severity and days since last incident.
-- ---------------------------------------------------------------------------
create or replace view v_project_safety_summary as
select
  p.id as project_id,
  p.name as project_name,
  -- Total incidents
  coalesce(
    (select count(*) from cs_safety_incidents si where si.project_id = p.id),
    0
  ) as total_incidents,
  -- Minor incidents
  coalesce(
    (select count(*) from cs_safety_incidents si
     where si.project_id = p.id and si.severity = 'Minor'),
    0
  ) as minor_incidents,
  -- Moderate incidents
  coalesce(
    (select count(*) from cs_safety_incidents si
     where si.project_id = p.id and si.severity = 'Moderate'),
    0
  ) as moderate_incidents,
  -- Serious incidents
  coalesce(
    (select count(*) from cs_safety_incidents si
     where si.project_id = p.id and si.severity = 'Serious'),
    0
  ) as serious_incidents,
  -- Days since last incident (null if no incidents)
  (select extract(day from now() - max(si.created_at))
   from cs_safety_incidents si
   where si.project_id = p.id
  ) as days_since_last_incident,
  -- Most recent incident date
  (select max(si.created_at)
   from cs_safety_incidents si
   where si.project_id = p.id
  ) as last_incident_at
from cs_projects p;


-- ============================================================================
-- MATERIALIZED VIEWS (heavy aggregation, periodic refresh per D-56g)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- mv_portfolio_financial_rollup
-- Aggregate financial metrics across all projects for the rollup dashboard.
-- Refresh periodically (every 15 minutes via pg_cron recommended).
-- ---------------------------------------------------------------------------
create materialized view mv_portfolio_financial_rollup as
select
  p.id as project_id,
  p.name as project_name,
  p.client,
  p.status,
  p.progress,
  -- Parse budget text to numeric
  case
    when p.budget ~ '^\$?[\d,]+\.?\d*$'
    then cast(replace(replace(p.budget, '$', ''), ',', '') as numeric)
    else 0
  end as budget_numeric,
  -- Contract value total for this project
  coalesce(
    (select sum(
      case
        when c.budget ~ '^\$?[\d,]+\.?\d*$'
        then cast(replace(replace(c.budget, '$', ''), ',', '') as numeric)
        else 0
      end
    )
    from cs_contracts c
    where c.client = p.client and c.stage != 'Lost'),
    0
  ) as contract_value_total,
  -- Change order net
  coalesce(
    (select sum(
      case
        when co.amount ~ '^\$?-?[\d,]+\.?\d*$'
        then cast(replace(replace(co.amount, '$', ''), ',', '') as numeric)
        else 0
      end
    )
    from cs_change_orders co
    where co.project_id = p.id),
    0
  ) as change_order_net,
  -- Open issues count
  coalesce(
    (select count(*)
     from cs_rfis r
     where r.project_id = p.id
       and r.status not in ('Closed', 'Resolved')),
    0
  ) +
  coalesce(
    (select count(*)
     from cs_change_orders co2
     where co2.project_id = p.id
       and co2.status not in ('Approved', 'Rejected')),
    0
  ) as open_issues_count,
  -- Safety incident count
  coalesce(
    (select count(*)
     from cs_safety_incidents si
     where si.project_id = p.id),
    0
  ) as safety_incident_count,
  -- Team member count
  coalesce(
    (select count(distinct pt.assignee_id)
     from cs_project_tasks pt
     where pt.project_id = p.id
       and pt.assignee_id is not null),
    0
  ) as team_member_count,
  p.created_at,
  now() as refreshed_at
from cs_projects p;

-- Unique index required for CONCURRENTLY refresh
create unique index idx_mv_portfolio_rollup_project
  on mv_portfolio_financial_rollup (project_id);


-- ---------------------------------------------------------------------------
-- mv_monthly_spend_trend
-- Monthly financial data across the portfolio for trend charts (D-43).
-- Aggregates contract values by month for time-series visualization.
-- ---------------------------------------------------------------------------
create materialized view mv_monthly_spend_trend as
select
  date_trunc('month', c.created_at) as month,
  count(distinct c.id) as contract_count,
  sum(
    case
      when c.budget ~ '^\$?[\d,]+\.?\d*$'
      then cast(replace(replace(c.budget, '$', ''), ',', '') as numeric)
      else 0
    end
  ) as total_contract_value,
  count(distinct c.client) as unique_clients,
  -- Break down by contract stage
  count(*) filter (where c.stage = 'Won') as won_count,
  count(*) filter (where c.stage = 'Pursuit') as pursuit_count,
  count(*) filter (where c.stage = 'Lost') as lost_count,
  now() as refreshed_at
from cs_contracts c
where c.created_at is not null
group by date_trunc('month', c.created_at)
order by month desc;

-- Unique index required for CONCURRENTLY refresh
create unique index idx_mv_monthly_spend_month
  on mv_monthly_spend_trend (month);


-- ============================================================================
-- REFRESH FUNCTION
-- ============================================================================

-- ---------------------------------------------------------------------------
-- refresh_report_views()
-- Refreshes all materialized views concurrently (non-blocking).
-- Schedule via pg_cron: SELECT cron.schedule('refresh-report-views', '*/15 * * * *', 'SELECT refresh_report_views()');
-- ---------------------------------------------------------------------------
create or replace function refresh_report_views()
returns void as $$
begin
  -- CONCURRENTLY requires a unique index on the materialized view
  -- and allows reads during refresh (non-blocking)
  refresh materialized view concurrently mv_portfolio_financial_rollup;
  refresh materialized view concurrently mv_monthly_spend_trend;

  -- Log the refresh for monitoring
  raise notice 'Report materialized views refreshed at %', now();
end;
$$ language plpgsql;


-- ============================================================================
-- pg_cron SCHEDULING (reference commands — run manually if pg_cron is enabled)
-- ============================================================================

-- Refresh materialized views every 15 minutes:
-- SELECT cron.schedule('refresh-report-views', '*/15 * * * *', 'SELECT refresh_report_views()');

-- To check scheduled jobs:
-- SELECT * FROM cron.job;

-- To remove the schedule:
-- SELECT cron.unschedule('refresh-report-views');
