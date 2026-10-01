# <LEDGER>.md — <source> → <target>

Source: <path> (untouched). Target: <path>, same layout, one file per source module.

## Slice order
0 shared/config → 1 domain → 2 infrastructure → 3 application → 4 server routes → 5 auth → 6 websocket

## Module map

| Slice | Source module | Target file | Lines | Status |
|---|---|---|---|---|
| 0-shared | `config/auth_config.py` | `config/auth_config.go` | 56 | done |
| 0-shared | `cli/cli.py` | `cli/cli.go` | 444 | n/a (framework CLI; server-only runtime) |
| 1-domain | `domain/entities/agent_template.py` | `domain/entities/agent_template.go` | 260 | todo |

Statuses: `todo` · `done` · `done (tested)` · `n/a (<reason>)`.
Progress:  grep -c '| todo |' <LEDGER>.md ; grep -c '| done' <LEDGER>.md

## Next
(What the owner was doing, the last command run, the next concrete step. Updated before every compact.)
