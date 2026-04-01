---
name: release
description: Run local tests, auto-calculate semver, generate release notes, tag and release
---

# Release Skill

This skill automates the release process: local test validation, version bump calculation, release note generation, tagging, and pushing.

## Workflow

When the user asks to release, follow these steps in order:

### 1. Run Local Tests

```bash
./test/run-tests.sh
```

If any test fails, stop and report the failures. Do not proceed with release.

### 2. Determine Current and Next Version

```bash
# Get latest tag
git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
```

Parse the current version (e.g., `v0.1.0`). Then analyze `git log` since the last tag to determine the bump type:

- **MAJOR** bump: if any commit contains `BREAKING CHANGE` or `!:` in the subject
- **MINOR** bump: if any commit starts with `feat:` or `feat(`
- **PATCH** bump: for `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `ci:`, `chore:`, or any other commit

Calculate the next version accordingly.

### 3. Generate Release Notes

```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  git log ${LAST_TAG}..HEAD --oneline --no-merges
else
  git log --oneline --no-merges
fi
```

Categorize commits into sections:

```
## Features
- feat: descriptions

## Bug Fixes
- fix: descriptions

## Other Changes
- docs, refactor, chore, ci, test, style, perf: descriptions
```

Strip the conventional commit prefix (e.g., `feat: `, `fix: `) for cleaner notes.

### 4. Confirm with User

Present the calculated version and generated release notes. Ask for confirmation before proceeding.

### 5. Tag and Push

Upon confirmation:

```bash
git tag -a v{VERSION} -m "Release v{VERSION}"
git push origin main
git push origin v{VERSION}
```

This triggers the GitHub Actions CI workflow which will:
- Build and test
- Push image to `ghcr.io`
- Create GitHub Release

### 6. Report

After push, inform the user:
- New version tag
- GHCR image URL: `ghcr.io/{repo}:{version}`
- GitHub Release URL (will be created by CI)

## Rules

- Never skip the test step
- Never push without user confirmation
- If `git log` is empty since last tag, warn the user
- Use semver format: `v{MAJOR}.{MINOR}.{PATCH}`
- If no previous tag exists, start at `v0.1.0`
