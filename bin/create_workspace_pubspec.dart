import 'dart:convert';
import 'dart:io';
import 'package:pub/src/pubspec.dart';
import 'package:pub/src/source/hosted.dart';

import 'package:pub/src/system_cache.dart';
import 'package:pub/src/package_name.dart';
import 'package:pub/src/language_version.dart';
import 'package:path/path.dart' as path;

main() {
  if (File('pubspec.yaml').existsSync()) {
    throw Exception(
        'pubspec.yaml exists already. Run in top of a mono-repo with no existing pubspec.yaml');
  }
  final sdkVersion = Platform.version.split(' ').first;
  final pubspecs = Directory.current
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('/pubspec.yaml'))
      .toList();
  if (pubspecs.isEmpty) {
    throw Exception('Found no pubspec.yaml files in child directories');
  }
  final parsedPubspecs = pubspecs
      .map((f) => (
            f.path,
            Pubspec.parse(f.readAsStringSync(), SystemCache().sources,
                location: f.uri)
          ))
      .toList();
  final devDependencies = parsedPubspecs
      .expand((pubspec) => pubspec.$2.devDependencies.entries)
      .toList();

  final mergedDevDependencies = <String, PackageRange>{};

  // If two sub-projects refer to the same dev-dependency, depend on the intersection of the ranges.
  for (final MapEntry(key: name, value: dep) in devDependencies) {
    final existing = mergedDevDependencies[name];
    if (existing == null) {
      mergedDevDependencies[name] = dep;
    } else {
      if (existing.source != dep.source) {
        throw Exception(
            'Package $name has conflicting sources ${existing.source} and ${dep.source}');
      }
      mergedDevDependencies[name] = existing
          .toRef()
          .withConstraint(existing.constraint.intersect(dep.constraint));
    }
  }

  final projectPubspec = '''
name: global_project
environment:
  sdk: ^$sdkVersion

dev_dependencies:
${mergedDevDependencies.entries.map((e) {
    final name = e.key;
    final d = e.value;
    final descriptionJson = d.description.serializeForPubspec(
      containingDir: '.',
      languageVersion: LanguageVersion.parse('3.0'),
    );
    final encoded = json.encode(
        e.value.source is HostedSource && descriptionJson == null
            ? e.value.constraint.toString()
            : {
                'version': e.value.constraint.toString(),
                e.value.source.name: descriptionJson
              });
    return '  $name: $encoded';
  }).join('\n')}

dependency_overrides:
${parsedPubspecs.map((p) => '  ${p.$2.name}: {path: "${path.relative(path.dirname(p.$1))}"}').join('\n')}
''';
  File('pubspec.yaml').writeAsStringSync(projectPubspec);
  print('wrote project-wide `pubspec.yaml`. Run `dart pub get` to resolve.');
}
