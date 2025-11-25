import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

void run(HookContext context) {
  final vars = context.vars;
  final featureName = vars['feature_name'] as String? ?? '';
  final entityName = vars['entity_name'] as String? ?? '';
  if (featureName.isEmpty) {
    return;
  }

  final featureSnake = _toSnakeCase(featureName);
  final entitySnake = _toSnakeCase(entityName);
  final baseDir = Directory(p.join(Directory.current.path, 'lib', 'src', featureName));

  if (!baseDir.existsSync()) {
    return;
  }

  void deletePath(String relativePath) {
    final targetDir = Directory(p.join(baseDir.path, relativePath));
    if (targetDir.existsSync()) {
      targetDir.deleteSync(recursive: true);
      return;
    }

    final targetFile = File(p.join(baseDir.path, relativePath));
    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }
  }

  void deleteFeatureFile(String relativeDirectory, String suffix) {
    deletePath(p.join(relativeDirectory, '$featureSnake$suffix'));
    if (featureSnake != featureName) {
      deletePath(p.join(relativeDirectory, '$featureName$suffix'));
    }
  }

  void deleteEntityUsecase(String prefix, {String suffix = ''}) {
    deletePath(
      p.join(
        'domain',
        'usecases',
        '$prefix$entitySnake${suffix}_usecase.dart',
      ),
    );
    if (entitySnake != entityName) {
      deletePath(
        p.join(
          'domain',
          'usecases',
          '$prefix$entityName${suffix}_usecase.dart',
        ),
      );
    }
  }

  final includeDataLayer = vars['include_data_layer'] as bool? ?? true;
  final includeDomainLayer = vars['include_domain_layer'] as bool? ?? true;
  final includeStateManagement = vars['include_state_management'] as bool? ?? true;
  final hasRemote = vars['has_remote_datasource'] as bool? ?? true;
  final hasLocalCache = vars['has_local_cache'] as bool? ?? true;
  final hasList = vars['has_list'] as bool? ?? true;
  final hasDetail = vars['has_detail'] as bool? ?? true;
  final hasCreate = vars['has_create'] as bool? ?? true;
  final hasUpdate = vars['has_update'] as bool? ?? true;
  final hasDelete = vars['has_delete'] as bool? ?? true;
  final useBloc = vars['use_bloc'] as bool? ?? false;

  if (!includeDataLayer) {
    deletePath('data');
  } else {
    if (!hasRemote) {
      deletePath(p.join('data', 'datasources', 'remote'));
    }
    if (!hasLocalCache) {
      deletePath(p.join('data', 'datasources', 'local'));
    }
  }

  if (!includeDomainLayer) {
    deletePath('domain');
  } else {
    if (!hasList) {
      deleteEntityUsecase('get_all_', suffix: 's');
    }
    if (!hasDetail) {
      deleteEntityUsecase('get_');
    }
    if (!hasCreate) {
      deleteEntityUsecase('create_');
    }
    if (!hasUpdate) {
      deleteEntityUsecase('update_');
    }
    if (!hasDelete) {
      deleteEntityUsecase('delete_');
    }
  }

  if (!includeStateManagement) {
    deletePath(p.join('presentation', 'blocs'));
    deletePath(p.join('presentation', 'cubits'));
  } else {
    if (useBloc) {
      deletePath(p.join('presentation', 'cubits'));
    } else {
      deleteFeatureFile(p.join('presentation', 'blocs'), '_bloc.dart');
      deleteFeatureFile(p.join('presentation', 'blocs'), '_event.dart');
    }
  }

  _renderMustacheFile(
    context,
    featureName,
    p.join('presentation', 'cubits', '${featureName}_cubit.dart'),
  );
  _renderMustacheFile(
    context,
    featureName,
    p.join('presentation', 'blocs', '${featureName}_bloc.dart'),
  );
  _renderMustacheFile(
    context,
    featureName,
    p.join('presentation', 'blocs', '${featureName}_event.dart'),
  );
  _renderMustacheFile(
    context,
    featureName,
    p.join('presentation', 'blocs', '${featureName}_state.dart'),
  );
}

String _toSnakeCase(String value) {
  final buffer = StringBuffer();
  String? previous;

  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    final isLower = char.toLowerCase() == char && char.toUpperCase() != char;
    final isDigit = int.tryParse(char) != null;

    if ((isUpper || (char == '-' || char == ' ')) && previous != null && previous != '_') {
      buffer.write('_');
    }

    if (isUpper || isLower || isDigit) {
      buffer.write(char.toLowerCase());
      previous = char.toLowerCase();
    } else {
      if (previous != '_') {
        buffer.write('_');
        previous = '_';
      }
    }
  }

  final result = buffer.toString().replaceAll(RegExp('_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  return result.isEmpty ? value.toLowerCase() : result;
}

String _toPascalCase(String value) {
  final snake = _toSnakeCase(value);
  if (snake.isEmpty) return '';
  return snake.split('_').where((part) => part.isNotEmpty).map((part) => part[0].toUpperCase() + part.substring(1)).join();
}

String _toTitleCase(String value) {
  final snake = _toSnakeCase(value);
  if (snake.isEmpty) return '';
  return snake.split('_').where((part) => part.isNotEmpty).map((part) => part[0].toUpperCase() + part.substring(1)).join(' ');
}

void _renderMustacheFile(
  HookContext context,
  String featureName,
  String relativePath,
) {
  final outputFile = File(
    p.join(Directory.current.path, 'lib', 'src', featureName, relativePath),
  );

  if (!outputFile.existsSync()) {
    return;
  }

  final raw = outputFile.readAsStringSync();
  if (!raw.contains('{{')) {
    return;
  }

  final renderContext = Map<String, dynamic>.from(context.vars);
  final rendered = _renderTemplate(raw, renderContext);
  outputFile.writeAsStringSync(rendered);
}

class _SectionResult {
  const _SectionResult(this.content, this.end);

  final String content;
  final int end;
}

String _renderTemplate(String source, Map<String, dynamic> vars) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < source.length) {
    final start = source.indexOf('{{', index);
    if (start == -1) {
      buffer.write(source.substring(index));
      break;
    }

    buffer.write(source.substring(index, start));
    final end = source.indexOf('}}', start);
    if (end == -1) {
      buffer.write(source.substring(start));
      break;
    }

    final tag = source.substring(start + 2, end).trim();
    index = end + 2;
    if (tag.isEmpty) {
      continue;
    }

    final prefix = tag[0];
    final name = (prefix == '#' || prefix == '^' || prefix == '/') ? tag.substring(1).trim() : tag;

    if (prefix == '#') {
      final section = _extractSection(source, index, name);
      index = section.end;

      if (_caseTransforms.containsKey(name)) {
        final inner = _renderTemplate(section.content, vars);
        buffer.write(_caseTransforms[name]!(inner));
        continue;
      }

      final value = vars[name];
      final bool condition = value == true;
      if (condition) {
        buffer.write(_renderTemplate(section.content, vars));
      }
      continue;
    }

    if (prefix == '^') {
      final section = _extractSection(source, index, name);
      index = section.end;

      final value = vars[name];
      final bool condition = value == true;
      if (!condition) {
        buffer.write(_renderTemplate(section.content, vars));
      }
      continue;
    }

    if (prefix == '/') {
      // Should not occur, skip.
      continue;
    }

    buffer.write(_resolveVariable(name, vars));
  }

  return buffer.toString();
}

_SectionResult _extractSection(String source, int startIndex, String name) {
  var index = startIndex;
  var depth = 1;

  while (index < source.length) {
    final open = source.indexOf('{{', index);
    if (open == -1) {
      throw Exception('Unclosed section {{$name}}');
    }

    final close = source.indexOf('}}', open);
    if (close == -1) {
      throw Exception('Unclosed tag {{$name}}');
    }

    final tag = source.substring(open + 2, close).trim();
    if (tag.startsWith('#') || tag.startsWith('^')) {
      final sectionName = tag.substring(1).trim();
      if (sectionName == name) {
        depth++;
      }
    } else if (tag.startsWith('/')) {
      final sectionName = tag.substring(1).trim();
      if (sectionName == name) {
        depth--;
        if (depth == 0) {
          final content = source.substring(startIndex, open);
          final endIndex = close + 2;
          return _SectionResult(content, endIndex);
        }
      }
    }

    index = close + 2;
  }

  throw Exception('Unclosed section {{$name}}');
}

String _resolveVariable(String name, Map<String, dynamic> vars) {
  final value = vars[name];
  if (value == null) return '';
  return value.toString();
}

typedef _CaseTransform = String Function(String input);

final Map<String, _CaseTransform> _caseTransforms = {
  'snakeCase': _toSnakeCase,
  'pascalCase': _toPascalCase,
  'titleCase': _toTitleCase,
};
