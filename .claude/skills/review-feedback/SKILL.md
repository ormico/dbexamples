---
name: review-feedback
description: Triage and address PR code review comments — assess validity, plan fixes, implement, validate with Docker + dbpatch, and report decisions to the user.
disable-model-invocation: true
argument-hint: "[pr-number] (auto-detects from current branch if omitted)"
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(docker *)
  - Bash(docker compose *)
  - Bash(dbpatch *)
  - Bash(pwsh *)
  - Bash(mkdir *)
  - Bash(ls *)
  - Edit
  - Write
  - Read
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
---

# Address PR Code Review Feedback

Determine the PR number:
1. If `$ARGUMENTS` contains a number, use that
2. Otherwise, auto-detect from the current branch:
   ```bash
   gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number'
   ```
3. If no PR is found, ask the user for the PR number

---

## Phase 1: Gather Comments

Store the repo name and PR number in shell variables first so every subsequent command uses them consistently:

```bash
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
PR_NUMBER=<PR_NUMBER>

# Fetch all inline review comments (includes the comment id needed for replies)
gh api --paginate "repos/$REPO/pulls/$PR_NUMBER/comments" \
  --jq '.[] | {id, path, line, body, user: .user.login}'

# Fetch top-level review summaries
gh api --paginate "repos/$REPO/pulls/$PR_NUMBER/reviews" \
  --jq '.[] | {id, user: .user.login, state, body}'
```

Record each comment's `id` alongside the file, line, and body. You will need these IDs in Phase 8 to post replies to the correct threads.

---

## Phase 2: Triage — Assess Each Comment

For each comment, read the relevant code and assess:

1. **Is it valid?** Does it identify a real bug, quality issue, or improvement?
2. **Priority?** High (correctness/bug), Medium (quality), Low (style/nice-to-have), Trivial (cosmetic)
3. **Fix it?** Valid comments may still be out of scope, speculative, or conflict with project conventions.

**Present a summary table to the user before implementing anything:**

| # | Comment (summary) | Valid? | Priority | Action |
|---|-------------------|--------|----------|--------|
| 1 | ...               | Yes    | High     | Fix — real bug |
| 2 | ...               | Yes    | Low      | Skip — cosmetic |
| 3 | ...               | No     | —        | Skip — misunderstands design |

For each skip recommendation, explain why. **Ask the user which comments to address before proceeding.** Do not implement anything without user approval on the triage.

---

## Phase 3: Plan Fixes

For approved comments:
- Group related comments that can be fixed together
- Identify which files need changes
- Check if fixes could affect patch execution order or `dependsOn` graph
- Note if any fix requires a new patch (schema change) vs. editing existing files

---

## Phase 4: Implement Fixes

For each approved fix:
1. Make the code change
2. If the fix corrects SQL in a patch, verify the patch ID and `dependsOn` are still correct
3. If the fix adds a new patch, use `dbpatch addpatch -n <name>` (never hand-edit `patches.json`)

Follow all project conventions (see `docs/IMPLEMENTATION_GUIDE.md` and `.claude/CLAUDE.md`).

---

## Phase 5: Validate

For any SQL or schema fixes, validate against a running database:

```bash
# Start Docker if not running
docker compose up -d

# Apply all patches
dbpatch build
```

If `dbpatch build` fails, fix and re-run. Do not retry without a change.

Run validation queries to confirm the fix is correct (see `docs/IMPLEMENTATION_GUIDE.md` Phase 5).

---

## Phase 6: Report to User

Summarize what was done:

- **Fixed:** List each comment addressed and what changed
- **Skipped (approved):** Comments agreed to skip, with rationale
- **Skipped (user override):** Comments the user decided not to fix
- **New issues found:** Any problems discovered during fixes not in the original review

---

## Phase 7: Commit

```bash
git add <specific-files>
git commit -m "fix: address PR review feedback (#<PR_NUMBER>)"
```

**Do NOT push** unless the user explicitly asks.
**Do NOT merge the PR** — PR merging is always a manual action by the developer.
**Do NOT add Co-Authored-By or Claude attribution.**

---

## Phase 8: Reply to Review Threads (if user asks to push or explicitly requests replies)

After the commit is pushed, post a reply on each review comment thread using the comment `id` recorded in Phase 1. Use the exact `id` for each comment — do not guess or match by file/line alone.

```bash
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
COMMIT="$(git rev-parse --short HEAD)"

# For a comment that was fixed:
gh api "repos/$REPO/pulls/comments/<COMMENT_ID>/replies" \
  -f body="Fixed in $COMMIT: <one-sentence explanation of what changed>"

# For a comment that was intentionally not fixed:
gh api "repos/$REPO/pulls/comments/<COMMENT_ID>/replies" \
  -f body="Won't fix: <explanation of why this was declined or is out of scope>"
```

**Critical rules for replies:**
- Match each reply to the specific `id` from Phase 1 — never approximate by file or line number
- Every addressed comment gets a reply; every skipped comment gets a "Won't fix" reply
- Do NOT resolve threads — leave that for the developer to do after reviewing the replies
- Do NOT reply to top-level review summaries (the `reviews` endpoint) — only to inline comments

---

## Important Reminders

- **The user decides** what gets fixed — always present triage before implementing
- **Explain your reasoning** for skip recommendations
- **Don't over-fix** — address what was raised, don't refactor nearby code
- **Never merge PRs** — the developer does that manually
- **If a comment requires a design change**, flag it — it may warrant a separate issue
