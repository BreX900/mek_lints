import 'dart:collection';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:dio/dio.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Core: https://github.com/dart-lang/lints/blob/main/lib/core.yaml
/// Recommended: https://github.com/dart-lang/lints/blob/main/lib/recommended.yaml
/// Flutter: https://github.com/flutter/packages/blob/master/packages/flutter_lints/lib/flutter.yaml

/// The commented rules already exist in the dart/flutter lints
const _dartCustomRules = <String>{
  'always_declare_return_types',
  'always_use_package_imports',
  'collection_methods_unrelated_type',
  'combinators_ordering',
  'discarded_futures',
  'prefer_final_locals',
  'prefer_single_quotes',
  'unawaited_futures',
  'unreachable_from_main',
  'use_super_parameters',
};
const _flutterCustomRules = <String>{
  ..._dartCustomRules,
  'use_colored_box',
  'use_decorated_box',
};
const _dartCustomErrors = <String, ErrorSeverity>{
  'always_declare_return_types': ErrorSeverity.ERROR,
  'always_use_package_imports': ErrorSeverity.WARNING,
  'annotate_overrides': ErrorSeverity.WARNING,
  'avoid_print': ErrorSeverity.WARNING,
  'avoid_return_types_on_setters': ErrorSeverity.WARNING,
  'avoid_unnecessary_containers': ErrorSeverity.WARNING,
  'body_might_complete_normally_nullable': ErrorSeverity.WARNING,
  'cast_from_null_always_fails': ErrorSeverity.ERROR,
  'cast_from_nullable_always_fails': ErrorSeverity.ERROR,
  'curly_braces_in_flow_control_structures': ErrorSeverity.WARNING,
  'collection_methods_unrelated_type': ErrorSeverity.ERROR,
  'combinators_ordering': ErrorSeverity.WARNING,
  'depend_on_referenced_packages': ErrorSeverity.WARNING,
  'deprecated_colon_for_default_value': ErrorSeverity.ERROR,
  'discarded_futures': ErrorSeverity.WARNING,
  'duplicate_export': ErrorSeverity.WARNING,
  'exhaustive_cases': ErrorSeverity.WARNING,
  'file_names': ErrorSeverity.WARNING,
  'implementation_imports': ErrorSeverity.WARNING,
  'iterable_contains_unrelated_type': ErrorSeverity.ERROR,
  'list_remove_unrelated_type': ErrorSeverity.ERROR,
  'override_on_non_overriding_member': ErrorSeverity.WARNING,
  'prefer_const_declarations': ErrorSeverity.WARNING,
  'prefer_final_locals': ErrorSeverity.WARNING,
  'prefer_single_quotes': ErrorSeverity.WARNING,
  'sort_child_properties_last': ErrorSeverity.WARNING,
  'unawaited_futures': ErrorSeverity.WARNING,
  'unnecessary_cast': ErrorSeverity.WARNING,
  'unnecessary_import': ErrorSeverity.WARNING,
  'use_super_parameters': ErrorSeverity.WARNING,
  'unused_import': ErrorSeverity.WARNING,
};
const _flutterCustomErrors = <String, ErrorSeverity>{
  ..._dartCustomErrors,
  'use_colored_box': ErrorSeverity.WARNING,
  'use_decorated_box': ErrorSeverity.WARNING,
};

void main() async {
  registerLintRules();

  final sdkRules = Analyzer.facade.registeredRules.map((e) => e.name).toSet();
  final sdkErrors =
      Map.fromEntries(errorCodeValues.map((e) => MapEntry(e.name.toLowerCase(), e.errorSeverity)));

  final dartOptions = _check(
    sdkRules: sdkRules,
    sdkErrors: sdkErrors,
    rules: _dartCustomRules,
    errors: _dartCustomErrors,
  );
  final flutterOptions = _check(
    sdkRules: sdkRules,
    sdkErrors: sdkErrors,
    rules: _flutterCustomRules,
    errors: _flutterCustomErrors,
  );

  final dartCoreRules =
      await _fetchRules('https://raw.githubusercontent.com/dart-lang/lints/main/lib/core.yaml');
  final rulesInDartCore = _dartCustomRules.where(dartCoreRules.contains).toList();
  final dartRecommendedRules = await _fetchRules(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/recommended.yaml');
  final dartRules = {...dartCoreRules, ...dartRecommendedRules};
  final rulesInDartRecommended = _dartCustomRules.where(dartRecommendedRules.contains).toList();

  if (rulesInDartCore.isNotEmpty || rulesInDartRecommended.isNotEmpty) {
    print('Dart rules already exist!\n'
        'core: $rulesInDartCore\n'
        'recommended: $rulesInDartRecommended');
  }

  final flutterRules = await _fetchRules(
      'https://raw.githubusercontent.com/flutter/packages/master_archive/packages/flutter_lints/lib/flutter.yaml');
  final rulesInFlutter = _flutterCustomRules.where(flutterRules.contains).toList();

  if (rulesInFlutter.isNotEmpty) {
    print('Flutter rules already exist!\n'
        'flutter: $rulesInFlutter');
  }

  _writeAnalysisOptionsYamlFile(
    include: 'package:lints/recommended.yaml',
    customRules: dartOptions.rules.where((e) => !dartRules.contains(e)),
    customErrors: dartOptions.errors,
    outputPath: './lib/dart.yaml',
  );

  _writeAnalysisOptionsYamlFile(
    include: 'package:flutter_lints/flutter.yaml',
    customRules:
        flutterOptions.rules.where((e) => !(dartRules.contains(e) || flutterRules.contains(e))),
    customErrors: flutterOptions.errors,
    outputPath: './lib/flutter.yaml',
  );
}

_Options _check({
  required Set<String> sdkRules,
  required Map<String, ErrorSeverity> sdkErrors,
  required Set<String> rules,
  required Map<String, ErrorSeverity> errors,
}) {
  final nonExistentRules = rules.where((e) => !sdkRules.contains(e)).toList();
  final nonExistentErrors = errors.keys.where((e) {
    return !(sdkRules.contains(e) || sdkErrors.containsKey(e));
  }).toList();

  if (nonExistentRules.isNotEmpty || nonExistentErrors.isNotEmpty) {
    print('BadRules: $nonExistentRules');
    print('BadErrors: $nonExistentErrors');
    exit(-1);
  }

  final badErrorsLevels = Map.fromEntries(errors.entries.where((target) {
    final sdkError = sdkErrors[target.key];
    if (sdkError == null) return false;
    return target.value.ordinal < sdkError.ordinal;
  }));

  if (badErrorsLevels.isNotEmpty) {
    print('BadErrorsLevels: $badErrorsLevels');
    exit(-1);
  }

  return _Options(
    rules: rules,
    errors: Map.fromEntries(errors.entries.where((target) {
      final sdkError = sdkErrors[target.key];
      if (sdkError == null) return true;
      return target.value.ordinal > sdkError.ordinal;
    })),
  );
}

final _httpClient = Dio();

Future<List<String>> _fetchRules(String url) async {
  final content = await _httpClient.get<String>(url);
  final analysisOptionsContent = loadYamlNode(content.data!).value;
  final analysisOptions = analysisOptionsContent as YamlMap;
  final linter = analysisOptions['linter'] as YamlMap;
  final rules = linter['rules'] as YamlList;
  return rules.cast<String>();
}

void _writeAnalysisOptionsYamlFile({
  required String include,
  required Iterable<String> customRules,
  required Map<String, ErrorSeverity> customErrors,
  required String outputPath,
}) {
  final sortedRules = customRules.toList()..sort();
  final sortedErrors = SplayTreeMap<String, String>.of({
    for (final entry in customErrors.entries) entry.key: entry.value.displayName,
  });

  final editor = YamlEditor(File('./tool/base.yaml').readAsStringSync());

  editor.update(['include'], include);
  editor.update(['linter', 'rules'], sortedRules);
  editor.update(['analyzer', 'errors'], sortedErrors);

  File(outputPath).writeAsStringSync('$editor');
  print('\n$outputPath:\n$editor');
}

class _Options {
  final Set<String> rules;
  final Map<String, ErrorSeverity> errors;

  const _Options({
    required this.rules,
    required this.errors,
  });
}
