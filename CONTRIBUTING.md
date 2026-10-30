# Contributing

DaysCounter is a personal project, but bug reports and fixes are welcome.

## Issues

- **Bugs:** use the bug report form. The most useful reports say which event or calendar setup shows the problem, what the app or widget showed and what you expected; a suggested fix is a bonus.
- **Security problems:** report them privately, see [SECURITY.md](SECURITY.md).
- **Feature ideas:** open an issue to discuss it first. DaysCounter stays small on purpose, so not every idea will fit.

## How the project is developed

- `project.yml` is the source of the Xcode project. Change it, not the generated `DaysCounter.xcodeproj`, which is not checked in.
- Day math, EventKit queries, the shared store and deep links live in `Packages/DaysCounterKit`. Logic changes there come with tests, and `swift test` in that folder passes.
- The app builds for both iOS and macOS.
- No new dependencies without discussing it in an issue first.
- Commit messages and PR titles are plain imperative sentences ("Add …", "Fix …"), no type prefixes.

## Pull requests

Link the issue, list the commands you ran and their results, and say which platforms you checked the change on.
