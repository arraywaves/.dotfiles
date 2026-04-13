---
name: git-analysis
description: >
  Analyse any git repository using non-destructive commands to surface project health
  signals: churn hotspots, contributor breakdown, bug-cluster files, commit velocity
  trends, and firefighting frequency. Use when asked to analyse a project, explore its
  git history, understand team activity, identify high-risk files, or answer questions
  like "what changes the most?", "who built this?", "where do bugs cluster?", or
  "is this project healthy?".
---

# Git Explorer

Run any combination of the five analyses below. Always use the current working directory
unless the user specifies a different repo path.

## Analyses

### What Changes the Most

The 20 most-changed files over the last year, good proxy for churn and instability.

```bash
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```

### Who Built This

Commit count per author, merges excluded.

```bash
git shortlog -sn --no-merges
```

### Where Do Bugs Cluster

Files most frequently touched by fix/bug commits, reveals brittle areas.

```bash
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

### Is This Project Accelerating or Dying

Monthly commit counts — spot momentum shifts at a glance.

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

### How Often Is the Team Firefighting

Revert/hotfix commits in the last year — a high count signals instability.

```bash
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```

## Guidance

- Run all five when asked for a general health check; run individual analyses for targeted questions.
- Summarise findings in plain language after showing raw output, highlight the most actionable insight from each.
- All commands are read-only; no flags write to the repo.
- If the repo has no commits matching a filter (e.g. no firefighting commits), note that explicitly, it is itself a signal.
