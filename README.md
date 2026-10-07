# qq-config

My own quirq infra (qq) config: which of my projects qq builds, and what must pass before a change
lands. This repo holds **data only**. The code that reads it (`qqcfg`, the schemas) is
[quirq-ai/infra-config](https://github.com/quirq-ai/infra-config) at the commit in
`infra-config.commit`, so my config is checked by quirq's own rules.

```
config/               the 13 areas (org, repos, pipelines, gate, kinds, ...), edited by hand
generated/            workflows written by `qq cfg generate`; never edit these
infra-config.commit   the quirq-ai/infra-config commit that validates this config
infra/repo.toml       makes this a qq repo (pinned Python)
infra/commands/cfg.sh `qq cfg ...`: runs quirq's qqcfg on this config
```

## Setup (once)

You need [depot](https://github.com/quirq-ai/depot)'s `qq` on `PATH`. Then:

```sh
git clone https://github.com/KrishBhimani/qq-config
cd qq-config
qq sync
```

The first `qq cfg` clones quirq-ai/infra-config to `../infra-config` if it is not there (or set
`QQ_INFRA_CONFIG`), and makes `.venv-qqcfg` from the pinned Python with infra-config's pinned
requirements. It refuses to run if `../infra-config` is not at the commit in `infra-config.commit`,
and says how to fix that.

## Every change

Edit `config/`, then:

```sh
qq cfg validate
qq cfg generate
qq cfg validate
```

Commit `config/` and `generated/` together. CI (`.github/workflows/validate.yml`) runs the same
validate on every PR.

## Onboard a project

1. The project must be **public** and under `github.com/krishbhimani`.
2. Add a `[[repo]]` to `config/repos.toml` with its `kinds` (see `config/kinds.toml`:
   `python-service`, `pytest`, `node-app`, ...).
3. Add two builders to `config/pipelines.toml`: `<name>-presubmit` (`blocking = true`,
   `triggers = ["change", "queue"]`) and `<name>-postsubmit` (`triggers = ["land"]`).
4. Validate and generate (above), then deliver the workflows into the project and commit them there:

   ```sh
   qq cfg deliver <name> ../<name>
   ```

5. Make GitHub enforce the check: a ruleset on the project's default branch requiring
   `<name>-presubmit` from GitHub Actions (integration 15368), with no bypass.

## Onboarded

| Project | Kinds | Required check |
| --- | --- | --- |
| [qq-sandbox](https://github.com/KrishBhimani/qq-sandbox) | pytest | `qq-sandbox-presubmit` |
| [argus-code](https://github.com/KrishBhimani/argus-code) | uv-pytest | `argus-code-presubmit` |

## Known limits (2026-10-07)

- quirq-ai/gate cannot read a data-only config yet: it imports `tools/qqcfg.py` from the config
  directory. So `qqgate required/verdict` and depot's gated `qq status` do not use this repo; `qq`
  judges these projects with its ungated rule (every check green).
- Personal accounts have no GitHub merge queue, so `queue` triggers never fire.
- `health`, `rollers`, `fuzz` and `perf` need at least one entry each, so each has a placeholder
  pointing at qq-sandbox. Replace them as real projects arrive.
