# tmux-linear

Tmux plugin that displays [Linear](https://linear.app) issue title in the status line, extracted from the current git branch name.

```
feature/ENG-123-fix-auth  →  ENG-123: Fix authentication timeout
```

## Requirements

- `curl`, `jq`
- [Linear API key](https://linear.app/settings/api)
- [TPM](https://github.com/tmux-plugins/tpm)

## Installation

Add to `~/.tmux.conf`:

```tmux
set -g @plugin 'kanghyojun/tmux-linear'
```

Reload tmux, then press `prefix + I` to install.

## Setup

Set your Linear API key via environment variable:

```bash
export LINEAR_API_KEY="lin_api_..."
```

Or via tmux option:

```tmux
set -g @linear_api_key "lin_api_..."
```

## Usage

Add placeholders to `status-right`, `status-left`, or `status-format[n]`:

```tmux
set -g status-right '#{linear_issue} | %H:%M'
set -g status-format[1] '#[align=left] #{linear_id} #{linear_title}'
```

### Placeholders

| Placeholder | Example output |
|---|---|
| `#{linear_issue}` | `ENG-123: Fix authentication timeout` |
| `#{linear_id}` | `ENG-123` |
| `#{linear_title}` | `Fix authentication timeout` |

## Options

| Option | Default | Description |
|---|---|---|
| `@linear_api_key` | `$LINEAR_API_KEY` | Linear API key |
| `@linear_cache_ttl` | `300` | Cache TTL in seconds |
| `@linear_max_title_len` | `40` | Max title length before truncation |
| `@linear_issue_prefixes` | _empty_ | Comma/space-separated issue prefixes to match (e.g. `PI, ENG`). Empty means any prefix |

Example:

```tmux
set -g @linear_cache_ttl "600"
set -g @linear_max_title_len "30"
set -g @linear_issue_prefixes "PI, ENG"
```

## How it works

1. Reads the current pane's working directory
2. Gets the git branch name
3. Extracts the Linear issue ID from branch name (`[A-Z]+-[0-9]+`), optionally filtered by `@linear_issue_prefixes`
4. Fetches the issue title from Linear GraphQL API (cached to `~/.cache/tmux-linear/`)

## License

MIT
