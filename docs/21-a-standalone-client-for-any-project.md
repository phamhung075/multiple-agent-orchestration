# 21. A standalone client for any project

The machine-side tooling of a team (sync a room, keep contexts small, report status, show a grid)
should not live inside the repository of the project it serves. If it does, every new project must
copy or depend on that repository, and the tooling grows hidden assumptions about it.

This chapter describes how to keep the client separate.

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

A client mixes three kinds of work, and the right language differs:

| Work | Fits |
|---|---|
| Orchestration glue: parse arguments, call HTTP and the orchestrator, write files | any; Python is fastest to change |
| A helper that must be small, fast and never stall (watching terminal output, sending keys) | Rust or Go |
| A single static binary to install on a machine without a runtime | Go or Rust |

Porting is worth it when installation friction matters more than change speed. Port one command at a
time behind one shared command contract, and have an unported command refuse with an explicit error
rather than do something weaker. Keep the reference implementation until the port passes the same
cases.
