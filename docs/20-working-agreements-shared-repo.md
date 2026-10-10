# 20. Working agreements for several seats in one repository

A team of seats shares one working tree and one git index. Most of the damage a team does to itself
comes from that, not from the model. These agreements are cheap and they hold up.

## 20.1 Commit by pathspec; never stage broadly

The index is shared. A line one seat staged can be swept into another seat's commit.

- Commit with an explicit list of paths: `git commit -m "..." -- <path> <path>`.
- Do not `git add` first. The one exception is a **new** file: mark it with
  `git add -N -- <new file>` (intent to add, no content enters the index), then commit it by pathspec
  like any other.
- Just before committing, read `git status --porcelain -- <paths>` and `git diff HEAD -- <paths>`.
  A commit takes each file's **whole** content, including another seat's unsaved edits. If a line is
  not yours, commit your other paths and hold that file until its owner has committed.
- Never `git add .`, `git add -A`, `--amend`, `reset`, `clean` or `checkout -- <path>`.
- **Seats never push.** They commit and report the hash. One principal pushes, after reviewing.

Enforce this in the seat policy as deny rules with a message that says what to do instead of just
"denied". A bare refusal makes a seat retry; a refusal with the alternative makes it comply.

## 20.2 One file per change for the changelog

A single `CHANGELOG.md` that every seat edits becomes the most-conflicted file in the repository,
and every agent that reads it pays for its full length each time.

Use a directory instead: `CHANGELOG/<date>--<kebab-title>.md`, **one new file per change**. Rules:

- Never edit another change's file; add a new one.
- A short `README.md` in the directory states the format and lists the newest entries.
- Tell agents to `ls CHANGELOG | tail`, never to read the whole directory.

Result: no merge conflicts between seats, a diff that shows exactly one added file per change, and a
changelog read costs a few lines instead of a megabyte. Do the same for a test-suite changelog if you
keep one, or keep it as a single file only when one seat owns it.

## 20.3 Keep the docs small enough to be read

Agents read documentation before acting, so every extra page costs tokens on every task and a stale
page misleads on every task.

- Keep an index and a small number of pages that each answer a question.
- Delete obsolete pages; do not archive them in the tree. Git remembers.
- Merge overlapping pages into one. A fact should have one home.
- Put the rule "small docs, updated in place" in the guide of the seat that writes docs, and let the
  lead decide when a doc deserves to exist.
- **Batch documentation commits.** One docs commit per work item, never one per finding. Fold the
  doc and changelog updates for an item into the commit that carries its code; keep a docs-only
  commit for records with no code change. Otherwise the history reads as nothing but docs.

## 20.4 A writing rule for the seats

One short rule in the guide every seat shares keeps replies cheap and legible:

> Write replies in plain, direct prose. Put the answer first, then the reason, then the next step.
> Use literal wording: no greeting, no recap, no closing offer, no metaphor. Keep each sentence to one
> idea. Never drop "not", "never", "no" or "only"; keep numbers, units, code, commands, paths and
> error text exact. Use full sentences for a security warning, an irreversible action, an ordered
> procedure and any question you ask.

The last sentence matters: brevity is for status, not for the places where a misread costs something.

## 20.5 Pin the guides

Seat guides are code. Store each guide with a digest in a lock file, and make the loader **refuse** a
guide whose digest does not match. Editing a guide then has a deliberate second step (recompute the
digest) that a drive-by edit will not take, and a changed guide is always a reviewed commit.

## 20.6 Check

- `git log --stat` shows each seat commit touching only its own paths.
- No seat has pushed; the principal's push is the only remote write.
- The changelog gained one new file per change and no existing file was edited.

Back to the [README](../README.md).
