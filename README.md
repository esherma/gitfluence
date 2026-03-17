# Gitfluence

A native macOS document editor that combines Confluence's rich editing experience with GitHub's pull request and code review workflow — without leaving your editor.

## The Problem

Working across GitHub and a wiki tool like Confluence creates constant context-switching. When you're reviewing a PR, you jump to GitHub. When you're writing specs or documenting decisions, you jump to Confluence. Neither tool does both well: GitHub's markdown editor is barebones, and Confluence knows nothing about your code or pull requests.

For teams that live in both — writing docs, reviewing diffs, leaving comments — the friction adds up.

## What Gitfluence Does

Gitfluence lets you open any git repository and work with it as a unified workspace:

- **Rich document editing** — write and edit Markdown files with a Confluence-style WYSIWYG editor (headings, tables, task lists, slash commands, etc.) or drop into raw source mode
- **PR review** — browse open pull requests, read diffs with syntax highlighting, and leave inline comments without leaving the app
- **Git-aware file browser** — see modified, added, and untracked files at a glance, with status badges in the sidebar

Everything stays in your repo. Docs are Markdown files. Comments go through the GitHub API. No proprietary formats, no lock-in.

## Status

Early development. Core editing and PR review are being built out now.

| Phase | Status |
| --- | --- |
| App shell, file browser, git status | ✅ Done |
| Rich editor (TipTap) + source editor (CodeMirror) | ✅ Done |
| Formatting toolbar + slash commands | ✅ Done |
| Diff viewer (git diff + PR diffs) | 🔧 In progress |
| GitHub PR list + inline comments | 🔧 In progress |
| Polish, keyboard shortcuts, onboarding | ⬜ Planned |

## Tech Stack

- **SwiftUI + AppKit** — native macOS, no Electron
- **TipTap** (via WKWebView) — rich Markdown editing
- **CodeMirror 6** (via WKWebView) — source editing
- **diff2html** — syntax-highlighted diff rendering
- `git` **+** `gh` **CLI** — all git and GitHub operations shell out to the real tools

## Requirements

- macOS 15+
- Xcode 16+
- Node.js 18+ (to rebuild the web bundles)
- `gh` CLI authenticated (`gh auth login`)

## Building

```bash
# Install web bundle dependencies and build
cd WebBundles/rich-editor && npm install && npm run build
cd ../source-editor && npm install && npm run build

# Open in Xcode
open Gitfluence.xcodeproj
```