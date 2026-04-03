# Git Workflow

## Branch Roles

- `main`: stable branch for milestones and known-good states
- `develop`: integration branch for ongoing work
- task branches: short-lived branches created from `develop`

Recommended task branch naming:

- `feature/<topic>` for new functions or enhancements
- `fix/<topic>` for bug fixes
- `verify/<topic>` for verification-focused work
- `docs/<topic>` for documentation-only changes

## Daily Flow

1. Start from `develop`.
2. Update local branches from remote.
3. Create a focused task branch.
4. Make code and documentation changes together when behavior changes.
5. Run the needed compile, simulation, or debug steps.
6. Push the task branch.
7. Open a PR into `develop`.
8. Merge `develop` into `main` only for stable milestones.

## Suggested Commands

Update local repository:

```bash
git switch develop
git pull origin develop
```

Create a task branch:

```bash
git switch -c feature/<topic>
```

Push a new task branch:

```bash
git push -u origin feature/<topic>
```

## Commit Guidance

Keep commits focused and readable. Prefer one logical purpose per commit.

Recommended commit style:

- `rtl: refine axi4 master write response handling`
- `uvm: add backpressure coverage for read channel`
- `docs: update axi4 master legality notes`

## PR Checklist

Every PR should clearly include:

- change summary
- reason for the change
- affected modules or files
- verification completed
- known limitations or remaining work
- version name or change name

## Documentation Rule

If a change affects interface intent, assumptions, legal behavior, corner cases, or verification scope, update the relevant document in `docs/` in the same change whenever possible.
