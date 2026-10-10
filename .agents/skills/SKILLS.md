# Agent Skills for the flutter_it Ecosystem

AI coding assistants (Claude Code, Cursor, GitHub Copilot, Codex, Gemini CLI, Cline, OpenCode …)
write better flutter_it code when they have the ecosystem's rules and patterns at hand. The
`skills/` directories of the flutter_it packages ship exactly that, in the
[Agent Skills](https://agentskills.io) open standard: one directory per skill with a `SKILL.md`
whose YAML frontmatter tells the agent when to use it.

Skills are for the agent, not for you: they are terse, rule-first and contain no tutorials.

## What ships where

| Package on pub.dev | Skills in its `skills/` directory |
|---|---|
| `flutter_it` (this package) | `flutter-it-overview`, `flutter-it-architecture`, `flutter-it-feed-datasource`, `flutter-it-get-it`, `flutter-it-watch-it`, `flutter-it-command-it`, `flutter-it-listen-it` |
| `get_it` | `get-it-expert` |
| `watch_it` | `watch-it-expert` |
| `command_it` | `command-it-expert` |
| `listen_it` | `listen-it-expert` |

The `flutter-it-get-it` … `flutter-it-listen-it` skills are the same content as the
`<package>-expert` skills; the prefix is required by the Dart skills tool (see below).

| Skill | Covers |
|---|---|
| overview | What the construction set is, which package to use for what, how they combine |
| architecture | Pragmatic Flutter Architecture: services, managers, views, proxies with override fields, scopes, testing |
| feed-datasource | Paginated feeds / infinite scroll with FeedDataSource and PagedFeedDataSource |
| get-it | Registration types, scopes and shadowing, async init with `init()`, `findFirstObjectRegistration`, flags |
| watch-it | `watch*` functions, handlers, ordering rules, cached factories with `param1`/`param2`, `createOnce`, startup |
| command-it | Creating and running commands, `isRunning`/`canRun`/`errors`, restrictions, error filters, testing |
| listen-it | Operators (`map`, `where`, `select`, `debounce`, `combineLatest` …), chain lifecycle, reactive collections |

## Installation

### From your project's dependencies (recommended)

The official Dart tool [`skills`](https://pub.dev/packages/skills) copies the skills of your
**direct** dependencies into the directory your agent reads (`.claude/skills/`,
`.cursor/skills/`, `.github/skills/`, `.agents/skills/` …), auto-detecting the agent:

```bash
dart run skills@ get            # interactive selection
dart run skills@ get --all      # everything, no prompts
dart run skills@ get --agent copilot   # Copilot is not auto-detected
```

Re-run `dart run skills@ get` after upgrading packages to refresh the skills;
`dart run skills@ list` / `prune` / `remove` manage what is installed.

Because only direct dependencies are scanned, a project that depends on `watch_it` only will
receive `watch-it-expert` but not `get-it-expert`; add `get_it` to your pubspec as well, or
depend on `flutter_it`, which ships all seven skills.

### From this repository

Works for any project, independent of pub dependencies, and is the way to get the
ecosystem-wide skills (architecture, feed-datasource, overview) when you use the packages
individually:

```bash
dart run skills@ add flutter-it/flutter_it
# or, with the cross-agent installer
npx skills add flutter-it/flutter_it
```

### Manually

Copy any `skills/<name>/` directory into your agent's skills directory, e.g.
`.claude/skills/` (project) or `~/.claude/skills/` (global) for Claude Code.

## Naming convention

The Dart skills tool only installs skills whose directory name starts with the package name
followed by a hyphen (`get_it` → `get-it-…`, `flutter_it` → `flutter-it-…`) and silently skips
all others. The frontmatter `name:` must equal the directory name.
This is why the umbrella package carries `flutter-it-` prefixed copies.

## Maintaining the skills

- The editing source for all skills is `skills/` in the
  [flutter_it monorepo](https://github.com/flutter-it) (short names). After an edit the file is
  copied unchanged into the owning package's `skills/` directory and, renamed with the
  `flutter-it-` prefix, into this package.
- Keep a `SKILL.md` under 500 lines; put critical rules first, then patterns, then anti-patterns.
- Verify code against the package sources, not from memory.
- Contributions: open a PR against the package that owns the skill (or against this repository
  for the ecosystem-wide ones).

## Learn more

- Documentation: https://flutter-it.dev (AI skills page: https://flutter-it.dev/misc/ai_skills)
- Dart guide for package skills: https://dart.dev/tools/pub/package-skills
- Discord: https://discord.gg/ZHYHYCM38h
