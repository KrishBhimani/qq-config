# qq-config

My own quirq infra (qq) config: which of my projects qq builds, and what must pass before a change
lands. This repo holds **data only**. The code that reads it (`qqcfg`, the schemas) is
[quirq-ai/infra-config](https://github.com/quirq-ai/infra-config) at the commit in
`infra-config.commit`, so my config is checked by quirq's own rules.

```
config/        the 13 areas (org, repos, pipelines, gate, kinds, ...), edited by hand
generated/     workflows written by `qqcfg generate`; never edit these
infra-config.commit   the quirq-ai/infra-config commit that validates this config
```

## Setup (once)

Keep quirq's infra-config next to this repo, at the pinned commit:

```sh
git clone https://github.com/quirq-ai/infra-config
git -C infra-config checkout $(cat qq-config/infra-config.commit)
python3 -m pip install -r infra-config/requirements.in
```

## Every change

Edit `config/`, then from the directory holding both repos:

```sh
python3 infra-config/tools/qqcfg.py validate --root qq-config
python3 infra-config/tools/qqcfg.py generate --root qq-config
python3 infra-config/tools/qqcfg.py validate --root qq-config
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
   python3 infra-config/tools/qqcfg.py deliver <name> path/to/<name> --root qq-config
   ```

5. Make GitHub enforce the check: a ruleset on the project's default branch requiring
   `<name>-presubmit` from GitHub Actions (integration 15368), with no bypass.

## Onboarded

| Project | Kinds | Required check |
| --- | --- | --- |
| [qq-sandbox](https://github.com/KrishBhimani/qq-sandbox) | pytest | `qq-sandbox-presubmit` |

## Known limits (2026-10-07)

- quirq-ai/gate cannot read a data-only config yet: it imports `tools/qqcfg.py` from the config
  directory. So `qqgate required/verdict` and depot's gated `qq status` do not use this repo; `qq`
  judges these projects with its ungated rule (every check green).
- Personal accounts have no GitHub merge queue, so `queue` triggers never fire.
- `health`, `rollers`, `fuzz` and `perf` need at least one entry each, so each has a placeholder
  pointing at qq-sandbox. Replace them as real projects arrive.
