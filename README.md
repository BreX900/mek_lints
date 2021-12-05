# Mek Lints

Mek packages and plugins lints rules.

# How to enable these lints

1. In a terminal, located at the root of your package, run this command:
```shell
dart pub add --dev mek_lints --git-url https://github.com/BreX900/mek_lints.git
```
or
```shell
flutter pub add --dev mek_lints --git-url https://github.com/BreX900/mek_lints.git
```

2. Create a new analysis_options.yaml file, next to the pubspec, that includes the lints package:
```yaml
include: package:mek_lints/dart.yaml
```
or
```yaml
include: package:mek_lints/flutter.yaml
```