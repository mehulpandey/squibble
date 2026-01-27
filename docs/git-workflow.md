# Git & Release Management Guide for Squibble

## Overview
A practical version control and release workflow for a solo iOS developer with a live App Store app.

---

## Branch Strategy (Simple & Effective)

```
main (production)
  │
  ├── feature/add-reactions
  ├── fix/login-crash
  └── fix/widget-not-updating
```

### Branches

| Branch | Purpose | Deploys To |
|--------|---------|------------|
| `main` | Production-ready code | App Store / TestFlight |
| `feature/*` | New features | Dev testing only |
| `fix/*` | Bug fixes | Dev testing only |

### Rules
- `main` is always deployable - never commit broken code directly to it
- All work happens in feature/fix branches
- Merge to `main` only when tested and ready for release

---

## Daily Workflow

### Starting New Work
```bash
# Make sure main is up to date
git checkout main
git pull

# Create a branch for your work
git checkout -b fix/login-crash
# or
git checkout -b feature/dark-mode
```

### While Working
```bash
# Commit frequently with clear messages
git add <specific-files>
git commit -m "Fix nil crash when user has no profile image"

# Push to remote (backup + enables PR)
git push -u origin fix/login-crash
```

### When Ready to Release
```bash
# 1. Create a Pull Request on GitHub
#    - This lets you review all changes before merging
#    - Even as a solo dev, PRs are useful for seeing the full diff

# 2. Merge PR to main (via GitHub UI or CLI)
git checkout main
git pull
git merge fix/login-crash
git push

# 3. Tag the release
git tag -a v1.0.1 -m "Fix login crash for users without profile"
git push origin v1.0.1

# 4. Delete the branch (cleanup)
git branch -d fix/login-crash
git push origin --delete fix/login-crash
```

---

## Version Numbering

Use **Semantic Versioning**: `MAJOR.MINOR.PATCH`

| Version | When to bump | Example |
|---------|--------------|---------|
| PATCH (1.0.X) | Bug fixes, small tweaks | 1.0.0 → 1.0.1 |
| MINOR (1.X.0) | New features, backward compatible | 1.0.1 → 1.1.0 |
| MAJOR (X.0.0) | Breaking changes, major redesign | 1.1.0 → 2.0.0 |

**In Xcode:**
- `CFBundleShortVersionString` = Marketing version (1.0.1) - what users see
- `CFBundleVersion` = Build number (1, 2, 3...) - increment for each TestFlight upload

---

## Release Checklist

Before submitting to App Store:

- [ ] All changes merged to `main`
- [ ] Tested on physical device from `main` branch
- [ ] Version number bumped in Xcode
- [ ] Build number incremented
- [ ] Git tag created matching version
- [ ] Archive and upload to App Store Connect
- [ ] Release notes written

---

## Handling Hotfixes (Urgent Production Bugs)

When you find a critical bug in production:

```bash
# 1. Create hotfix branch from main
git checkout main
git pull
git checkout -b hotfix/critical-crash

# 2. Fix the issue (minimal changes only!)

# 3. Test thoroughly

# 4. Merge to main and tag
git checkout main
git merge hotfix/critical-crash
git tag -a v1.0.2 -m "Hotfix: critical crash on launch"
git push origin main --tags

# 5. Submit to App Store with expedited review if needed
```

---

## Commit Message Guidelines

Format: `<type>: <short description>`

```
feat: Add friend reactions to doodles
fix: Resolve crash when viewing deleted doodle
refactor: Simplify push notification handling
chore: Update dependencies
docs: Add setup instructions to README
```

Keep messages:
- Under 50 characters for the title
- In imperative mood ("Add feature" not "Added feature")
- Focused on what and why, not how

---

## Quick Reference Commands

```bash
# See current branch
git branch

# See all branches
git branch -a

# Switch branches
git checkout <branch-name>

# See recent commits
git log --oneline -10

# See what's changed
git status
git diff

# Undo uncommitted changes to a file
git checkout -- <file>

# Stash work temporarily
git stash
git stash pop

# See tags
git tag -l
```

---

## Example: Complete Bug Fix Flow

```bash
# 1. Start
git checkout main && git pull
git checkout -b fix/widget-not-refreshing

# 2. Work & commit
# ... make changes ...
git add squibble/Widget/WidgetProvider.swift
git commit -m "Fix widget not refreshing after sending doodle"

# 3. Test on device from Xcode (uses dev environment)

# 4. Push and create PR
git push -u origin fix/widget-not-refreshing
# Go to GitHub, create PR, review changes

# 5. Merge (after testing)
git checkout main
git merge fix/widget-not-refreshing
git push

# 6. Bump version in Xcode (1.0.1 → 1.0.2, build 5 → 6)

# 7. Tag and push
git tag -a v1.0.2 -m "Fix widget refresh issue"
git push origin v1.0.2

# 8. Archive in Xcode and upload to App Store Connect

# 9. Cleanup
git branch -d fix/widget-not-refreshing
git push origin --delete fix/widget-not-refreshing
```

---

## Key Principles

1. **Never commit directly to main** - always use branches
2. **Commit often** - small, focused commits are easier to review and revert
3. **Push daily** - your remote is your backup
4. **Tag every release** - so you can always find/restore any version
5. **Keep main deployable** - if you need to release urgently, main should work
