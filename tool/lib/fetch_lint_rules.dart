import 'dart:convert';

import 'package:http/http.dart';
import 'package:tool/linter_rule.dart';

Future<List<LinterRule>> fetchLinterRules(String dartVersion) async {
  final response = await get(Uri.parse(
    'https://raw.githubusercontent.com/dart-lang/sdk/refs/tags/$dartVersion/pkg/linter/tool/machine/rules.json',
  ));

  final json = jsonDecode(response.body) as List<dynamic>;

  return json
      .map((rule) => LinterRule.fromJson(rule as Map<String, dynamic>))
      .where((rule) => rule.state != LinterRuleState.removed)
      .where((rule) => !rule.sinceDartSdk.contains('wip'))
      .toList();
}
