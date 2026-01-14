# nandoki.yml README

This workflow prints “what time is it” when GitHub Actions runs, plus run context (repo/ref/sha/event/actor). It writes both:

- job logs
- the Actions Summary (`$GITHUB_STEP_SUMMARY`)

## File

- `.github/workflows/nandoki.yml`

## When it runs

- Manual: Actions tab → `nandoki` → `Run workflow`
- PR: when a pull request targets `main`
- Schedule: every hour at `00` minutes (UTC)

## What it prints

- `utc`: current UTC time (`date -u`)
- `local`: runner local time (`date` with timezone)
- `run_id`, `run_number`
- `event`, `ref`, `sha`, `actor`, `repo`

## Notes

- Scheduled workflows use UTC for `cron`.
- The “local” time is the GitHub runner timezone, not your PC timezone.

