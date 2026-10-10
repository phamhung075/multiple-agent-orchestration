# 16. A standalone client for any project

The machine-side tooling of a team (sync a room, keep contexts small, report status, show a grid)
should not live inside the repository of the project it serves. If it does, every new project must
copy or depend on that repository, and the tooling grows hidden assumptions about it.

This chapter describes how to keep the client separate.

## Three parts, three jobs

| Part | Job | Runs |
|---|---|---|
| The server (the brain) | Holds projects, tasks, context, the room and seat definitions, and the MCP tools. It never runs a model. | hosted |
| The orchestrator (the workplace) | Starts and keeps the seats, which are model processes in terminal sessions, and carries messages between them. It knows nothing about the server. | on each machine |
| The client (the connector) | Pulls a room's definition from the server and turns it into something the orchestrator runs; reports seat status back; keeps contexts small; delivers skills; shows the grid. | on each machine |

A seat reaches the brain through the server's MCP endpoint. Because the client depends on neither
the server's repository nor one team's definition, it works with any orchestrator team, not only the
rooms of one server.

## The rule

The client is its own repository with these properties:

- **No dependency on another repository.** Nothing imports from, reads, or defaults to a path in the
  server's repository or in your project.
- **One working directory, one meaning.** The project a command works on is the directory you run it
  from. The client's own state (`.env`, `logs/`, helper binaries) lives in the client's checkout.
- **No default team.** A command that needs a team definition or a skill inventory takes it as a
  required argument. A missing argument is a usage error, not a guess.
- **One connection for every project.** All projects reach the same hosted MCP endpoint with the same
  key, through an environment variable expanded by the agent runtime:

```json
{
  "mcpServers": {
    "server": {
      "type": "http",
      "url": "https://<your-server>/mcp",
      "headers": { "Authorization": "Bearer ${SERVER_TOKEN}" }
    }
  }
}
```

The token never appears in the file.

- **One credential, one env file.** The client reads a single user key and a server URL from one
  `.env` in its own directory; a variable already in the environment wins. Do not add a second
  machine-level key or a second env file for a service: the machine identity is data in the request
  body, not a credential.
- **One skills tree.** Skills live in the client as `skills/share/<skill>` (every room),
  `skills/rooms/<room>/<skill>` (every seat of one room), `skills/rooms/<room>/<seat>/<skill>` (one
  seat) and `skills/client/<skill>` (for a model that runs the client itself). A directory holding a
  `SKILL.md` is a skill; one without it is a seat folder. A seat receives the shared skills, its
  room's and its own, and the client asks the user for each agent's skills path.
- **A cost gate belongs in the client.** If a provider bills less at certain hours, the check is a
  client command with the schedule in UTC, a setting to switch it on or off, and an explicit flag to
  override it for one run. Starting or resuming seats at the expensive hours is refused with the next
  cheap time, not silently allowed.

## How to get there from a client that started inside a project

1. Move the client to its own repository, keeping history. `git subtree split --prefix=<dir>` produces
   a branch with only that directory's commits.
2. Rewrite author and committer on that branch if the repository will be public and the old history
   carries a personal address. Scan messages for local paths.
3. Convert the directory to a submodule **in place**: `git init` in it, add the remote, fetch, reset
   to the remote branch, then in the parent `git rm -r --cached <dir>` and `git submodule add`. The
   files do not move, so editable installs and running processes keep working.
4. Remove every path that points outside the client (`paths.py` should name only the client's own
   files). Make the former defaults required arguments.
5. Move the tests that read the parent project's data back to the parent. The client's suite must pass
   in a copy placed outside any repository; that copy is the proof of independence.
6. Give the client its own `.env.sample` and a README written for an agent: prerequisites with a
   check for each, install, the MCP connection, a launch sequence, a command table, a configuration
   table, and a failure map from message to cause to action.

## What is left to remove

Independence has two parts: no dependency on another repository, and no knowledge of a particular
team. The first is done by the steps above. The second is not: a default room name and a table of
seat roles keyed by one team's name are still team knowledge. Move them into the team definition that
a command receives.

## Language of the client

The case-study client was ported this way: it is now the Go binary `4genteam`
(`sync`, `up`, `compact`, `watch`, `team`, `policy`), and the server it pairs with has no Python
backend left. Only the hooks client of the server's repository still needs Python.

A client mixes three kinds of work, and the right language differs:

| Work | Fits |
|---|---|
| Orchestration glue: parse arguments, call HTTP and the orchestrator, write files | Go |
| A helper that must be small, fast and never stall (watching terminal output, sending keys, forcing a compaction through the runtime's RPC) | Rust, called by the Go client |
| A single static binary to install on a machine without a runtime | Go or Rust |

One language for the client, with Rust only for small helpers, removes the install step of a
language runtime and the second implementation to keep in step. The port is worth it when
installation friction matters more than change speed, and it is done in phases:

1. Move the client to its own module with no import from another repository.
2. Port the long-running parts first (the lifecycle and the compaction supervisor), then the team
   commands, the watch view and the sync verbs, behind one shared command contract. An unported
   command refuses with an explicit error rather than do something weaker.
3. Keep the old implementation until the new one passes the same cases.
4. Delete the old implementation last, and only when all of these hold: every command is in the new
   binary (the help output of both diffed), each old test has an equivalent or a recorded reason, a
   clean clone builds and passes its tests with no old runtime installed, and a reviewer signs off.
   Then point the command on the machine's `PATH` at the new binary and stop the old processes, or
   two supervisors will send to the same seat.

Next: [chapter 17 — bootstrapping a new room](17-room-bootstrap-traps.md).
