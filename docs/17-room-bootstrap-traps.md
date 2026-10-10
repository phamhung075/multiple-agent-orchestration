# 17. Bootstrapping a new room: four traps and how a client removes them

Creating a second room by hand fails in the same four places every time. None of them is hard once
you know it; all of them look like "the seats are broken" when you meet them cold. The durable fix
is to make **the tool that materializes the room do all four**, so a new room needs one command and
no repair.

The setting: a room is defined in your state service (or a local file), a client pulls it, writes a
`rig.yaml` plus one directory per seat, and the orchestrator launches the seats from that spec.

## 17.1 Trap 1: the provider key is not where the seat looks

Symptom: the seat starts, then prints `No API key found for <provider>`.

Cause: the key reaches a seat through the seat's **launch directory** (some runtimes read a `.env`
there) or through the daemon's environment. A new room has a new launch directory and no key.

Fix: keep the key in **one file in your home directory**, and have the client link it into every
room's launch directory:

```
<room dir>/.env  ->  ~/.config/<provider>/env
```

A symlink, not a copy: the secret keeps one home, rotation touches one file, and nothing secret is
ever written into the room's directory. If the file is missing, the client should stop with an error
that names the path, not let the seat discover it at launch.

## 17.2 Trap 2: the working directory is deleted under the seat

Symptom: a seat's shell reports its current directory as `(deleted)`; relative paths and the `.env`
lookup stop working after you re-sync the room.

Cause: the spec said `cwd: .`, which resolves to the **rig directory**, and the client rebuilds that
directory on every sync by building a new one and swapping it in. A seat launched earlier still
stands in the old, now deleted, inode.

Fix: make each seat's `cwd` an absolute path to a directory **no build ever replaces**: the parent
of the rig directory (the room directory). Put the `.env` link there too. Rebuild the rig directory
as often as you like.

General rule: a process's working directory must outlive every rebuild of anything inside it.

## 17.3 Trap 3: the permission policy parks the seat

Symptom: a seat sits in "needs attention" with an approval prompt nobody can answer.

Cause: the default policy asks for approval on every tool call. A seat running unattended in a pane
cannot answer, so the request is cancelled and the seat parks.

Fix: the client writes the room's unattended policy (the orchestrator's "full bypass" posture) into
every seat entry. This is a deliberate choice with a cost, so pair it with chapter 9: a bypassing
seat is only as safe as the deny rules, the sandbox and the commit rules around it. The orchestrator
will print a warning at launch for this posture; that warning is the intended confirmation.

## 17.4 Trap 4: the first launch needs files that only exist after a launch

Symptom: the client refuses to install the seat's rendered files because the seat's state directory
"does not exist yet", and says to run it again once the seats exist, which they cannot until it
succeeds.

Cause: the runtime creates its per-seat state directory at first launch; the client wanted to put
files there before it.

Fix: create the directory (and parents) when absent, then place the files. The runtime adopts the
directory at launch. Keep the guard for the opposite mistake in your own head: if a launch uses a
non-default state root, the files land in the wrong place, so print the root the client assumed.

## 17.5 What the client does, in order

1. Fetch the room's spec and the seats' pinned content.
2. Create each seat's state directory if absent and install the rendered guide and config files.
3. Rewrite the spec so every seat has the stable `cwd` and the policy.
4. Link the provider key into the room directory when any seat uses that provider.
5. Build the rig directory in a staging directory and swap it in (carrying over anything you placed
   there by hand).
6. Print the path of the spec, so the next command is `rig up <that path>`.

## 17.6 Check

```bash
ls -l <room dir>/.env                       # a symlink to your single key file
grep -E 'cwd|permission_policy' <rig.yaml>  # absolute cwd, the policy on every seat
rig up <rig.yaml> && rig ps --nodes -A      # every seat running, none parked
```

A second sync must leave the running seats' working directory intact. If it does not, trap 2 is
back.

Next: [chapter 18 — adding the cloud brain](18-completing-the-system-the-brain.md).
