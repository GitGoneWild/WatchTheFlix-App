---
applyTo: "**/*.dart"
---

## Dart/Flutter Code Guidelines
When writing or modifying Dart files in this repository:

1. Use null safety (! operator sparingly; prefer safe navigation).
2. Follow Dart style guide: 2-space indentation, trailing commas.
3. Include docstrings for public classes/methods (/// format).
4. Use async/await over .then(); handle errors with try/catch or Either/Failure.
5. Imports: Alphabetize, separate dart: / package: / relative.
6. For widgets: Prefer const constructors; use Keys where needed.
7. State management: Emit states via BLoC; use BlocBuilder/BlocListener.
8. Avoid hard-coded strings; use constants from core/constants/.
9. Ensure code is platform-agnostic unless in platform-specific files.
10. Run dart analyze before committing.