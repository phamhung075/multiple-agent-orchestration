# 2. The blueprint: what you are building and in what order

Chapter 1 gave the idea. This chapter shows the finished system on one page, says what each part is
for, and gives the order in which to build it. Every later chapter is one step of that order.

## 2.1 The finished system

You end up with five things working together on your own machine, plus an optional sixth in the cloud:

| # | Part | What it does for you | Built in |
|---|---|---|---|
| 1 | **OpenRig** (`rig`) | Starts your team from a YAML file, keeps the queue, sends messages between seats | chapters 4, 7, 8 |
| 2 | **herdr and tmux** | The terminals the seats live in. herdr also gives you one window that shows every seat | chapter 5 |
| 3 | **DeepSeek offload** | Lets a seat hand bulk typing to a cheap model running in the background | chapters 6, 11 |
| 4 | **Self-compaction** | A supervisor that shrinks each seat's context before it fills up | chapters 12, 13 |
| 5 | **The 4genthub client** (`4genteam`) | One binary on your machine. It starts the stack, runs the supervisor, shows the grid and talks to the cloud | chapter 16 |
| 6 | **4genthub, the cloud brain** (optional) | Keeps rooms, seats and tasks outside your disk, and shows them to you in a browser | chapters 17, 18 |

Parts 1 to 4 are enough to get real work done on one machine. Part 5 puts them behind one command so
a new project does not start from zero. Part 6 is what you add when the team has to outlive the
laptop, or when someone who is not at your terminal needs to see it.

## 2.2 How the parts talk to each other

```
 you ── browser ──▶ 4genthub (cloud)
                        ▲
                        │ the client dials OUT; the cloud never connects in
                        │
 you ── terminal ─▶ 4genteam ──▶ OpenRig daemon ──▶ seats (tmux or herdr panes)
                        │                              │
                        │                              └──▶ deepseek-offload ──▶ cheap workers
                        └──▶ compaction supervisor (reads each seat's context size)
```

Two rules hold everywhere:

- **Nothing reaches into your machine.** The client opens every connection to the cloud. You open no
  inbound port.
- **A seat is a position, not a model.** The seat keeps its name, queue and history. Which model sits
  in it can change.

## 2.3 The build order, and why it is this order

1. **Understand and prepare** (chapters 1 to 3). Read the idea once. Check your machine and accounts.
   Skipping the checks costs the most time later.
2. **Install the tools** (chapters 4 to 6). OpenRig first, because everything else hangs on its
   daemon. Then the terminals, then the DeepSeek workers.
3. **Run a first team and learn to drive it** (chapters 7 to 9). Start with two seats, learn the
   commands you will use every day, and set the safety limits before the team runs without you.
4. **Make it run for hours** (chapters 10 to 14). Write the mission file, offload bulk work, spend
   fewer tokens, compact automatically, and notice when the whole fleet dies.
5. **Scale it and make it reusable** (chapters 15 to 19). The seat model, the standalone client,
   new rooms without repair, the cloud, and a checklist that puts all of it on a new project.
6. **Run it with several seats in one repository** (chapters 20 and 21). Working agreements, and how
   to test a change to the seats' instructions without risking the real team.
7. **Reference** (chapters 22 and 23). The real migration this guide came from, and every problem
   hit on the way, each with its fix.

If you only have an hour, do chapters 3 to 7 and then read chapter 19. You will have a working team
and a map of the rest.

## 2.4 What you need to decide before you start

| Decision | Options | Advice |
|---|---|---|
| Terminal holder | tmux, herdr | Either works. herdr is OpenRig's default provider, gives the one-window view of every seat, and its seats survive a tmux server crash (chapter 14). Claude Code seats usually run in tmux |
| Runtime in the seats | Claude Code, Codex, agy, omp | Use what you already pay for. Match each seat's instruction file to its runtime (chapter 15.3) |
| Cheap model for bulk work | DeepSeek through `dsh` | Check the off-peak hours of your plan first (chapter 11.8) |
| Cloud brain | none, hosted 4genthub, self-hosted | Skip it until one machine is not enough |

## 2.5 Check

You can name the six parts, say which of them are optional, and say what the client dials out to.
If you can, go on to chapter 3.

Next: [chapter 3 — prerequisites](03-prerequisites.md).
