---
applyTo: "lib/presentation/blocs/**/*.dart"
---

## BLoC Guidelines
For BLoC files in presentation/blocs/:

1. Extend Bloc<Event, State> with equatable states/events.
2. Use on<Event> handlers for event processing.
3. Emit loading/success/error states sequentially.
4. Inject repositories/usecases via GetIt.
5. Handle exceptions: Map to failure states with error messages.
6. Keep BLoCs focused: One per screen/feature (e.g., LiveTvBloc).
7. AddEvent methods: Clear and descriptive.
8. Close streams in override close().
9. Test with bloc_test: Expect state sequences.
10. Integrate with use cases from domain/.