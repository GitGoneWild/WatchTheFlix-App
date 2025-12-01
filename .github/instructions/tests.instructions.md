---
applyTo: "test/**/*.dart"
---

## Testing Guidelines
For test files in this repository:

1. Use flutter_test package; group tests with group().
2. Follow AAA pattern: Arrange (setup), Act (execute), Assert (verify).
3. Mock dependencies with Mockito or custom mocks via GetIt.
4. Test BLoCs: Use bloc_test for event/state flows.
5. Cover edge cases: Success, failure, loading, errors.
6. Aim for 80%+ coverage; run flutter test --coverage.
7. Name tests descriptively: test_methodName_scenario_expectedBehavior.
8. Use expect() for assertions; testWidgets for UI tests.
9. Isolate tests: Reset mocks/GetIt after each test.
10. For integration: Test full flows like playlist loading or streaming.