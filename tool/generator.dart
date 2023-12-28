import 'dart:collection';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// https://dart.dev/tools/linter-rules

const _dartRules = <String, ErrorSeverity?>{
  'always_declare_return_types': ErrorSeverity.ERROR,
  'always_put_control_body_on_new_line': ErrorSeverity.NONE,
  'always_put_required_named_parameters_first': ErrorSeverity.NONE,
  'always_specify_types': ErrorSeverity.NONE,
  'always_use_package_imports': null,
  'annotate_overrides': null,
  'avoid_annotating_with_dynamic': null,
  'avoid_bool_literals_in_conditional_expressions': null,
  'avoid_catches_without_on_clauses': ErrorSeverity.NONE,
  'avoid_catching_errors': null,
  'avoid_classes_with_only_static_members': ErrorSeverity.NONE,
  'avoid_double_and_int_checks': null,
  'avoid_dynamic_calls': null,
  'avoid_empty_else': null,
  'avoid_equals_and_hash_code_on_mutable_classes': null,
  'avoid_escaping_inner_quotes': null,
  'avoid_field_initializers_in_const_classes': null,
  'avoid_final_parameters': null,
  'avoid_function_literals_in_foreach_calls': null,
  'avoid_implementing_value_types': null,
  'avoid_init_to_null': null,
  'avoid_js_rounded_ints': ErrorSeverity.NONE,
  'avoid_multiple_declarations_per_line': null,
  'avoid_null_checks_in_equality_operators': null,
  'avoid_positional_boolean_parameters': ErrorSeverity.INFO,
  'avoid_print': null,
  'avoid_private_typedef_functions': null,
  'avoid_redundant_argument_values': null,
  'avoid_relative_lib_imports': null,
  'avoid_renaming_method_parameters': null,
  'avoid_return_types_on_setters': null,
  'avoid_returning_null_for_void': null,
  'avoid_returning_this': null,
  'avoid_setters_without_getters': null,
  'avoid_shadowing_type_parameters': null,
  'avoid_single_cascade_in_expression_statements': null,
  'avoid_types_on_closure_parameters': ErrorSeverity.NONE, // Check in future versions
  'avoid_slow_async_io': null,
  'avoid_type_to_string': null,
  'avoid_types_as_parameter_names': null,
  'avoid_unused_constructor_parameters': null,
  'avoid_void_async': null,
  'await_only_futures': null,
  'camel_case_extensions': null,
  'camel_case_types': null,
  'cascade_invocations': ErrorSeverity.NONE,
  'cancel_subscriptions': null,
  'cast_nullable_to_non_nullable': null,
  'close_sinks': null,
  'collection_methods_unrelated_type': ErrorSeverity.ERROR,
  'combinators_ordering': null,
  'comment_references': null,
  'conditional_uri_does_not_exist': null,
  'constant_identifier_names': null,
  'control_flow_in_finally': null,
  'curly_braces_in_flow_control_structures': null,
  'dangling_library_doc_comments': null,
  'depend_on_referenced_packages': null,
  'deprecated_consistency': null,
  'deprecated_member_use_from_same_package': null,
  'directives_ordering': null,
  'discarded_futures': null,
  'empty_catches': null,
  'empty_constructor_bodies': null,
  'empty_statements': null,
  'eol_at_end_of_file': null,
  'exhaustive_cases': null,
  'file_names': null,
  'hash_and_equals': null,
  'implicit_reopen': ErrorSeverity.NONE, // Maybe...
  'invalid_case_patterns': null,
  'implementation_imports': null,
  'implicit_call_tearoffs': ErrorSeverity.NONE,
  'join_return_with_assignment': null,
  'leading_newlines_in_multiline_strings': null,
  'library_annotations': null,
  'library_names': null,
  'library_prefixes': null,
  'library_private_types_in_public_api': null,
  'lines_longer_than_80_chars': ErrorSeverity.NONE,
  'literal_only_boolean_expressions': null,
  'matching_super_parameters': null,
  'missing_whitespace_between_adjacent_strings': ErrorSeverity.NONE,
  'no_default_cases': ErrorSeverity.NONE,
  'no_adjacent_strings_in_list': null,
  'no_duplicate_case_values': null,
  'no_leading_underscores_for_library_prefixes': null,
  'no_leading_underscores_for_local_identifiers': null,
  'no_literal_bool_comparisons': null,
  'no_logic_in_create_state': null,
  'no_runtimeType_toString': null,
  'no_self_assignments': null,
  'no_wildcard_variable_uses': null,
  'non_constant_identifier_names': null,
  'noop_primitive_operations': null,
  'null_check_on_nullable_type_parameter': null,
  'null_closures': null,
  'omit_local_variable_types': null,
  'only_throw_errors': null,
  'one_member_abstracts': ErrorSeverity.NONE,
  'overridden_fields': null,
  'package_api_docs': null,
  'package_names': null,
  'package_prefixed_library_names': null,
  'parameter_assignments': null,
  'prefer_adjacent_string_concatenation': null,
  'prefer_asserts_in_initializer_lists': null,
  'prefer_collection_literals': null,
  'prefer_conditional_assignment': null,
  'prefer_const_constructors': null,
  'prefer_const_constructors_in_immutables': null,
  'prefer_const_declarations': null,
  'prefer_const_literals_to_create_immutables': null,
  'prefer_constructors_over_static_methods': ErrorSeverity.NONE,
  'prefer_contains': null,
  'prefer_double_quotes': ErrorSeverity.NONE,
  'prefer_expression_function_bodies': ErrorSeverity.NONE,
  'prefer_final_fields': null,
  'prefer_final_in_for_each': null,
  'prefer_final_locals': null,
  'prefer_final_parameters': ErrorSeverity.NONE,
  'prefer_for_elements_to_map_fromIterable': null,
  'prefer_foreach': null,
  'prefer_function_declarations_over_variables': null,
  'prefer_generic_function_type_aliases': null,
  'prefer_if_elements_to_conditional_expressions': null,
  'prefer_if_null_operators': null,
  'prefer_initializing_formals': null,
  'prefer_inlined_adds': null,
  'prefer_int_literals': ErrorSeverity.NONE,
  'prefer_interpolation_to_compose_strings': null,
  'prefer_is_empty': null,
  'prefer_is_not_empty': null,
  'prefer_is_not_operator': null,
  'prefer_iterable_whereType': null,
  'prefer_mixin': null,
  'prefer_null_aware_method_calls': null,
  'prefer_null_aware_operators': null,
  'prefer_relative_imports': ErrorSeverity.NONE,
  'prefer_single_quotes': null,
  'prefer_spread_collections': null,
  'prefer_typing_uninitialized_variables': null,
  'prefer_void_to_null': null,
  'provide_deprecation_message': null,
  'recursive_getters': null,
  'require_trailing_commas': ErrorSeverity.NONE, // Check in future versions
  'secure_pubspec_urls': null,
  'slash_for_doc_comments': null,
  'sort_constructors_first': ErrorSeverity.NONE,
  'sort_pub_dependencies': ErrorSeverity.NONE,
  'sort_unnamed_constructors_first': null,
  'test_types_in_equals': null,
  'throw_in_finally': null,
  'tighten_type_of_initializing_formals': null,
  'type_annotate_public_apis': null,
  'type_init_formals': null,
  'type_literal_in_constant_pattern': null,
  'unawaited_futures': null,
  'unnecessary_await_in_return': ErrorSeverity.NONE,
  'unnecessary_brace_in_string_interps': null,
  'unnecessary_breaks': null,
  'unnecessary_const': null,
  'unnecessary_constructor_name': null,
  'unnecessary_final': ErrorSeverity.NONE,
  'unnecessary_getters_setters': null,
  'unnecessary_lambdas': null,
  'unnecessary_late': null,
  'unnecessary_library_directive': ErrorSeverity.NONE,
  'unnecessary_new': null,
  'unnecessary_null_aware_assignments': null,
  'unnecessary_null_aware_operator_on_extension_on_nullable': null,
  'unnecessary_null_checks': null,
  'unnecessary_null_in_if_null_operators': null,
  'unnecessary_nullable_for_final_variable_declarations': null,
  'unnecessary_overrides': null,
  'unnecessary_parenthesis': null,
  'unnecessary_raw_strings': null,
  'unnecessary_statements': null,
  'unnecessary_string_escapes': null,
  'unnecessary_string_interpolations': null,
  'unnecessary_this': null,
  'unnecessary_to_list_in_spreads': null,
  'unreachable_from_main': null,
  'unrelated_type_equality_checks': null,
  'unsafe_html': null,
  'use_enums': null,
  'use_full_hex_values_for_flutter_colors': null,
  'use_function_type_syntax_for_parameters': null,
  'use_if_null_to_convert_nulls_to_bools': null,
  'use_is_even_rather_than_modulo': null,
  'use_late_for_private_fields_and_variables': null,
  'use_named_constants': null,
  'use_raw_strings': null,
  'use_rethrow_when_possible': null,
  'use_setters_to_change_properties': null,
  'use_string_buffers': null,
  'use_string_in_part_of_directives': null,
  'use_super_parameters': null,
  'use_test_throws_matchers': null,
  'use_to_and_as_if_applicable': null,
  'valid_regexps': null,
  'void_checks': null,
};
const _flutterRules = <String, ErrorSeverity?>{
  'avoid_unnecessary_containers': null,
  'avoid_web_libraries_in_flutter': null,
  'flutter_style_todos': ErrorSeverity.NONE,
  'sized_box_for_whitespace': null,
  'sized_box_shrink_expand': null,
  'sort_child_properties_last': null,
  'use_build_context_synchronously': null,
  'use_colored_box': null,
  'use_decorated_box': null,
  'use_key_in_widget_constructors': null,
};
const _packageRules = <String, ErrorSeverity?>{
  'do_not_use_environment': null,
  'prefer_asserts_with_message': ErrorSeverity.INFO,
  'public_member_api_docs': ErrorSeverity.INFO,
  // Move to flutter package rules
  'diagnostic_describe_all_properties': ErrorSeverity.NONE,
};
const _allRules = {
  ..._dartRules,
  ..._flutterRules,
  ..._packageRules,
};

void main() async {
  registerLintRules();

  final sdkRules = Analyzer.facade.registeredRules
      .where((e) => e.state.isStable || e.state.isExperimental)
      .map((e) => e.name)
      .toSet();
  final sdkErrors =
      Map.fromEntries(errorCodeValues.map((e) => MapEntry(e.name.toLowerCase(), e.errorSeverity)));

  final missingRules = sdkRules.where((e) => !_allRules.containsKey(e)).toList();
  if (missingRules.isNotEmpty) {
    print('Missing rules: ${missingRules.map((e) => '\'$e\'').join(', ')}');
    exit(-1);
  }

  Map<String, ErrorSeverity> _filterErrors(Map<String, ErrorSeverity?> customErrors) {
    return Map.fromEntries(customErrors.entries.map((e) {
      final sdkSeverity = sdkErrors[e] ?? ErrorSeverity.NONE;
      final customSeverity = e.value ?? ErrorSeverity.WARNING;

      if (customSeverity == ErrorSeverity.NONE) {
        if (sdkSeverity != ErrorSeverity.NONE) {
          print('You should not disable this rule ${e.key} as it is active in the dart sdk.');
          exit(-1);
        }
        return null;
      }
      if (sdkSeverity == customSeverity) return null;

      return MapEntry(e.key, customSeverity);
    }).nonNulls);
  }

  _writeFile(
    fileName: 'dart',
    errors: _filterErrors(_dartRules),
  );
  _writeFile(
    fileName: 'dart_package',
    include: 'dart',
    errors: _filterErrors(_packageRules),
  );

  _writeFile(
    fileName: 'flutter',
    include: 'dart',
    errors: _filterErrors(_flutterRules),
  );
  _writeFile(
    fileName: 'flutter_package',
    include: 'flutter',
    errors: _filterErrors(_packageRules),
  );
}

void _writeFile({
  required String fileName,
  String? include,
  required Map<String, ErrorSeverity> errors,
}) {
  final displayErrors = Map.fromEntries(errors.entries.map((e) {
    return MapEntry(e.key, e.value.displayName);
  }));

  final editor = YamlEditor(File('./tool/base.yaml').readAsStringSync());

  if (include == null) {
    editor.remove(['include']);
  } else {
    editor.update(['include'], 'package:mek_lints/$include.yaml');
  }
  editor.update(['linter', 'rules'], displayErrors.keys.toList());
  editor.update(['analyzer', 'errors'], displayErrors);

  File('./lib/${fileName}.yaml').writeAsStringSync('$editor');
}
