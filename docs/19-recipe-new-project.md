# 19. The recipe: put the whole system on a new project

This is the checklist that joins the earlier chapters. Follow it top to bottom on any project. Each
step says what to do, which chapter explains it, and a check that must pass before you go on. If a
check fails, fix that step. Do not skip ahead.

The recipe assumes a Linux or macOS machine (WSL2 works) and a git repository you want a team to
work in. Call it `~/my-repo`.

## 19.1 Prepare the machine (once per machine)

1. Run `scripts/doctor.sh` from this guide. It only reads; it changes nothing. Install what it marks
   `MISSING` (chapter 3).
2. Install OpenRig and start its daemon (chapter 4).

```bash
npm install -g @openrig/cli
rig setup --dry-run && rig setup
rig ps                              # answers without an error
```

3. Log in to the runtime your seats will use, for example `claude auth login` (chapter 3).
4. Install the DeepSeek Harness and deepseek-offload if you want cheap workers (chapter 6). Put the
   DeepSeek key in one file in your home directory, never in the repository.
5. Install the 4genthub client, one binary (chapter 16):

```bash
install -m 0755 4genteam ~/.local/bin/
4genteam --help                     # lists every command
```

**Check:** `scripts/doctor.sh` prints no `MISSING`, `rig ps` answers, `4genteam --help` exits 0.

## 19.2 Set the limits before the team runs alone

Decide the permission posture and write the rules for the culture file (chapter 9). Do this now. A
team that runs without prompts can delete things, so the limits come first and the mission second.

**Check:** you can say what a seat may not do (push, delete outside the repository, read `.env`
files) and where that is written.

## 19.3 Start with two seats

Copy `templates/rig.yaml` into your repository and edit the names (chapter 7). Two seats are enough
to learn on: one that builds and one that checks.

```bash
cd ~/my-repo
rig up ./rig.yaml
rig ps --nodes --rig my-team        # both seats show as running
rig send <seat>@my-team "Do one small task. Track it on the queue."
```

**Check:** the seat answers, and the task and the verdict both appear on the queue
(`rig queue list`).

From here on, start and restore the team only through the client: `4genteam up <rig>`. It starts
the daemon, the seats, the status bridge, the compaction supervisor and the watch view, and it
refuses to start DeepSeek seats at peak hours. Starting a room with `rig up` by hand skips the
supervisor and the watchdog, and nothing tells you. In the 4genthub project this is a rule: the
client must check that every required service is running before it reports success.

## 19.4 Give the team a mission that survives a restart

Write `CULTURE.md` from `templates/CULTURE.md`: what the job is, how to behave, how to finish
(chapter 10). Seats read it once at launch, so restart a seat after you change it.

**Check:** stop one seat and start it again. It re-reads the file and continues the job.

## 19.5 Turn on the cheap workers

Teach the owner seat to offload bulk typing in waves, and keep review with the expensive model
(chapter 11). Check the job count after a day: if the leader did all the typing, delegation is not
working.

**Check:** one wave of three or more background jobs runs, and a reviewer accepts or rejects each
result before it is committed.

## 19.6 Keep contexts small without asking the seats

Do not rely on seats to compact themselves (chapter 12). Run the supervisor, one per room
(chapter 13):

```bash
4genteam compact <rig>
```

It reads each seat's context size, waits until the seat is quiet, sends `/compact`, then confirms
the size dropped and tells the seat to continue.

**Check:** the supervisor's log shows a compaction marked as witnessed, with a before and an after
size.

## 19.7 Watch the team, and watch that it still exists

- One window with every seat: `4genteam watch watch --rig <rig>` (chapter 5). It only reads.
- A watchdog for the whole fleet: `scripts/rig-watchdog.sh` (chapter 14). A team can vanish while
  every tool still says it is fine, because they all ask the same daemon.

**Check:** `scripts/rig-watchdog.sh --check` reports a healthy fleet. Stop one seat on purpose and
confirm the watchdog notices.

In the 4genthub project the client is also getting an optional auto-fix. It is off by default. When
the client finds an anomaly (a required service stopped, seats gone, a seat past its context limit)
it runs `claude -p` with permissions bypassed, with a fixed repair prompt, to restore the session.
It writes a log of the anomaly, the command, the output and a re-check afterwards, and it stops and
alerts you after a set number of failed attempts. This is the riskiest posture in chapter 9, so keep
the repair prompt narrow. It is not built yet.

## 19.8 Scale to the real team

Replace the two seats with the seats your project needs. Keep the number small. The 4genthub team
itself runs on five: a lead, an architect, a backend developer, a frontend developer and a reviewer.
Name each seat after its work, point seats of the same kind at one shared type, and keep the
reviewer as the only gate to "done" (chapter 15). Use the working agreements when several seats
share one repository (chapter 20).

**Check:** each seat can say which position it holds after a restart (`rig whoami --json`).

## 19.9 Add the cloud brain when one machine is not enough

Skip this until you need a browser view or a team that survives the laptop (chapter 18).

1. Create an account and a token. Tick `sessions:write` by hand if you want sessions to show on the
   Sessions page.
2. Put the server URL and the token in `~/.config/4genthub/.env` (mode 600). One file, one
   credential.
3. Create the room, then let the client write the rig and the seat files for you (chapter 17 lists
   the four traps this avoids).
4. Send a session: `4genteam sync connector --session <rig-session-name>`.

**Check:** the dashboard shows the seats you launched, drift is empty, and the session appears on
the Sessions page. Today the connector sends one session once; a client that stays connected is not
available yet.

## 19.10 When something breaks

Read chapter 23. Every entry there happened in a real run and has a cause and a fix. If your problem
is not there, find the cause before you change anything. Do not apply a fix only because the
symptom looks familiar.

Next: [chapter 20 — working agreements](20-working-agreements-shared-repo.md).
