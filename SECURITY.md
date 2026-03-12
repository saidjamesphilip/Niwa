# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Older releases | No |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** open a public issue
2. Use [private vulnerability reporting](https://github.com/saidjamesphilip/Niwa/security/advisories/new) on GitHub
3. Include steps to reproduce, if possible
4. Allow reasonable time for a fix before public disclosure

## Scope

Niwa is a local-first application. The only network call is a user-initiated "Check for Updates" that fetches the latest version from GitHub Releases. The following areas are in scope for security reports:

| Area | Detail |
|------|--------|
| **Local data storage** | SwiftData (SQLite) in App Group container — tasks, notes, XP, settings |
| **Clipboard access** | Reads `NSPasteboard.general` to populate clipboard history |
| **Notification content** | Health reminder notifications via `UNUserNotificationCenter` |
| **Process execution** | App restart uses `/usr/bin/open` via `Process` |
| **Update checker** | Manual-only GET to `api.github.com/repos/.../releases/latest` — no auth, no user data sent |

### Out of Scope

- No analytics, no telemetry, no tracking
- No user authentication or credential storage
- No remote data sync

## Response

- Critical issues will be patched and released as soon as possible
- You will be credited in the release notes (unless you prefer otherwise)
- We aim to acknowledge reports within 48 hours
