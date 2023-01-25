import 'dart:collection';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:dio/dio.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Core: https://github.com/dart-lang/lints/blob/main/lib/core.yaml
/// Recommended: https://github.com/dart-lang/lints/blob/main/lib/recommended.yaml
/// Flutter: https://github.com/flutter/packages/blob/master/packages/flutter_lints/lib/flutter.yaml

final customRules = <String>{
  'always_declare_return_types',
  'always_use_package_imports',
  'collection_methods_unrelated_type',
  'combinators_ordering',
  'discarded_futures',
  'unawaited_futures',
  'unreachable_from_main',
};
final customErrors = <String, ErrorSeverity>{
  'always_declare_return_types': ErrorSeverity.ERROR,
  'always_use_package_imports': ErrorSeverity.WARNING,
  'annotate_overrides': ErrorSeverity.WARNING,
  'avoid_print': ErrorSeverity.WARNING,
  'avoid_return_types_on_setters': ErrorSeverity.WARNING,
  'collection_methods_unrelated_type': ErrorSeverity.ERROR,
  'combinators_ordering': ErrorSeverity.WARNING,
  'discarded_futures': ErrorSeverity.WARNING,
  'exhaustive_cases': ErrorSeverity.WARNING,
  'implementation_imports': ErrorSeverity.WARNING,
  'iterable_contains_unrelated_type': ErrorSeverity.ERROR,
  'list_remove_unrelated_type': ErrorSeverity.ERROR,
  'unawaited_futures': ErrorSeverity.WARNING,

  /// Messages

  'body_might_complete_normally_catch_error': ErrorSeverity.WARNING,
  'body_might_complete_normally_nullable': ErrorSeverity.WARNING,
  'cast_from_null_always_fails': ErrorSeverity.ERROR,
  'cast_from_nullable_always_fails': ErrorSeverity.ERROR,
  'deprecated_colon_for_default_value': ErrorSeverity.ERROR,
  'duplicate_export': ErrorSeverity.WARNING,
  'override_on_non_overriding_member': ErrorSeverity.WARNING,
  'unnecessary_import': ErrorSeverity.WARNING,
  'unused_import': ErrorSeverity.WARNING,
};

void main() async {
  registerLintRules();

  final rules = Analyzer.facade.registeredRules.map((e) => e.name).toList();
  final errors = errorCodeValues.whereType<HintCode>().map((e) => e.name.toLowerCase()).toList();

  final nonExistentRules = customRules.where((e) => !rules.contains(e)).toList();
  final nonExistentErrors = customErrors.keys.where((e) {
    return !(rules.contains(e) || errors.contains(e));
  }).toList();

  if (nonExistentRules.isNotEmpty || nonExistentErrors.isNotEmpty) {
    print('BadRules: $nonExistentRules');
    print('BadErrors: $nonExistentErrors');
    return;
  }

  final rulesInDartCore = await _hasRules(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/core.yaml', customRules);
  final rulesInDartRecommended = await _hasRules(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/recommended.yaml', customRules);
  final rulesInFlutter = await _hasRules(
      'https://raw.githubusercontent.com/flutter/packages/master_archive/packages/flutter_lints/lib/flutter.yaml',
      customRules);

  if (rulesInDartCore.isNotEmpty ||
      rulesInDartRecommended.isNotEmpty ||
      rulesInFlutter.isNotEmpty) {
    print('Rules already exist!\n'
        'core: $rulesInDartCore\n'
        'recommended: $rulesInDartRecommended\n'
        'flutter: $rulesInFlutter');
    return;
  }

  final sortedRules = customRules.toList()..sort();
  final sortedErrors = <String, String>{
    ...SplayTreeMap.of({
      for (final entry in customErrors.entries)
        if (rules.contains(entry.key)) entry.key: entry.value.displayName,
    }),
    ...SplayTreeMap.of({
      for (final entry in customErrors.entries)
        if (errors.contains(entry.key)) entry.key: entry.value.displayName,
    }),
  };

  final editor = YamlEditor(File('./tool/base.yaml').readAsStringSync());

  editor.update(['linter', 'rules'], sortedRules);
  editor.update(['analyzer', 'errors'], sortedErrors);

  editor.update(['include'], 'package:lints/recommended.yaml');
  File('./lib/dart.yaml').writeAsStringSync('$editor');

  editor.update(['include'], 'package:flutter_lints/flutter.yaml');
  File('./lib/flutter.yaml').writeAsStringSync('$editor');
}

final httpClient = Dio();

Future<List<String>> _hasRules(String url, Iterable<String> customRules) async {
  final content = await httpClient.get<String>(url);
  final analysisOptionsContent = loadYamlNode(content.data!).value;
  final analysisOptions = analysisOptionsContent as YamlMap;
  final linter = analysisOptions['linter'] as YamlMap;
  final rules = linter['rules'] as YamlList;
  return customRules.where(rules.contains).toList();
}
