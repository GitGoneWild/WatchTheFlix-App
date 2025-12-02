# Contributing to WatchTheFlix

Thank you for your interest in contributing to WatchTheFlix! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. Please:

- Be respectful and considerate in all interactions
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Accept responsibility for mistakes and learn from them

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/WatchTheFlix-App.git`
3. Add upstream remote: `git remote add upstream https://github.com/GitGoneWild/WatchTheFlix-App.git`
4. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Flutter SDK 3.24.3 or higher
- Dart SDK 3.2.0 or higher
- Android Studio or VS Code with Flutter extensions
- For iOS: Xcode 15+ (macOS only)
- For desktop: Respective platform SDKs

### Installation

```bash
# Install dependencies
flutter pub get

# Run code generation (for freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor
```

### Running the App

```bash
# Mobile
flutter run

# Web
flutter run -d chrome

# Desktop
flutter run -d windows  # or macos, linux
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/path/to/test_file.dart
```

## Making Changes

### Branch Naming

Use descriptive branch names following this pattern:
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation changes
- `refactor/description` - Code refactoring
- `test/description` - Test additions/modifications

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
- `feat(player): add picture-in-picture support`
- `fix(m3u): handle malformed playlist URLs`
- `docs(readme): update installation instructions`

## Pull Request Process

1. **Before Submitting**
   - Ensure all tests pass: `flutter test`
   - Run linting: `flutter analyze`
   - Format code: `dart format .`
   - Update documentation if needed

2. **PR Description**
   - Describe what changes you made and why
   - Reference any related issues
   - Include screenshots for UI changes
   - List any breaking changes

3. **Review Process**
   - PRs require at least one approval
   - Address all review feedback
   - Keep PRs focused and reasonably sized

4. **After Merge**
   - Delete your feature branch
   - Sync your fork with upstream

## Coding Standards

### Dart/Flutter Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use null safety features appropriately
- Prefer `const` constructors where possible
- Use named parameters for readability

### Architecture

This project follows Clean Architecture:

```
lib/
├── core/          # Shared utilities, errors, theme
├── data/          # Repositories, data sources, models
├── domain/        # Entities, use cases, repository interfaces
├── modules/       # Feature modules (m3u, etc.)
└── presentation/  # BLoCs, screens, widgets
```

### BLoC Pattern

- Use equatable for events and states
- Keep BLoCs focused on single features
- Emit appropriate loading/success/error states

### Dependency Injection

- Use GetIt for DI
- Register services as lazy singletons
- Keep registration organized in `dependency_injection.dart`

## Testing Guidelines

### Test Structure

```dart
void main() {
  group('ClassName', () {
    late ClassName sut; // System Under Test
    
    setUp(() {
      sut = ClassName();
    });
    
    test('should do something when condition', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### Test Coverage Goals

- Unit tests for all business logic
- BLoC tests for state management
- Widget tests for key UI components
- Integration tests for critical flows

### Mocking

- Use `mocktail` for mocking dependencies
- Create mock classes in test files or shared test utilities

## Documentation

### Code Documentation

- Add doc comments (`///`) to public APIs
- Explain complex logic with inline comments
- Keep comments up-to-date with code changes

### README Updates

Update README.md when:
- Adding new features
- Changing installation steps
- Modifying configuration options

### Architecture Docs

Update `docs/` folder when:
- Adding new modules
- Changing data flow
- Modifying API integrations

## Questions?

If you have questions about contributing, feel free to:
- Open a GitHub Discussion
- Check existing issues for similar questions
- Reach out to maintainers

Thank you for contributing to WatchTheFlix! 🎬
