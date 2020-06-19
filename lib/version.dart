import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:dshell/src/pubspec/pubspec_file.dart';

/// Walks the user through selecting a new version no.
Version incrementVersion(
    Version version, PubSpecFile pubspec, String pubspecPath) {
  var options = <NewVersion>[
    NewVersion('Keep the current Version'.padRight(25), version),
    NewVersion('Small Patch'.padRight(25), version.nextPatch),
    NewVersion('Non-breaking change'.padRight(25), version.nextMinor),
    NewVersion('Breaking change'.padRight(25), version.nextBreaking),
    NewVersion('Enter custom version no.'.padRight(25), null,
        getVersion: getCustomVersion),
  ];

  print('');
  print(blue('What sort of changes have been made since the last release?'));
  var selected = menu(prompt: 'Select the change level:', options: options);

  version = selected.version;

  print('');

  // recreate the version file
  var packageRootPath = dirname(pubspecPath);

  print('');
  print(green('The new version is: $version'));
  print('');
  version = confirmVersion(version);

  print('The accepted version is: $version');

  // write new version.g.dart file.
  var versionPath = join(packageRootPath, 'lib', 'src', 'version');
  if (!exists(versionPath)) createDir(versionPath, recursive: true);
  var versionFile = join(versionPath, 'version.g.dart');
  print('Regenerating version file at ${absolute(versionFile)}');
  versionFile.write('/// GENERATED BY DShell release.dart do not modify.');
  versionFile.append('/// ${pubspec.name} version');
  versionFile.append("String packageVersion = '$version';");

  // rewrite the pubspec.yaml with the new version
  pubspec.version = version;
  print('pubspec version is: ${pubspec.version}');
  print('pubspec path is: $pubspecPath');
  pubspec.saveToFile(pubspecPath);
  return version;
}

/// Ask the user to confirm the selected version no.
Version confirmVersion(Version version) {
  if (!confirm(prompt: 'Is this the correct version')) {
    try {
      var versionString = ask(prompt: 'Enter the new version: ');

      if (!confirm(prompt: 'Is $versionString the correct version')) {
        exit(1);
      }

      version = Version.parse(versionString);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}

class NewVersion {
  String message;
  final Version _version;
  Version Function() getVersion;

  NewVersion(this.message, this._version, {this.getVersion});

  @override
  String toString() => '$message  (${_version ?? "?"})';

  Version get version {
    if (_version == null) {
      return getVersion();
    } else {
      return _version;
    }
  }
}

/// Ask the user to type a custom version no.
Version keepVersion() {
  Version version;
  while (version == null) {
    try {
      var entered =
          ask(prompt: 'Enter the new Version No.:', validator: Ask.required);
      version = Version.parse(entered);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}

/// Ask the user to type a custom version no.
Version getCustomVersion() {
  Version version;
  while (version == null) {
    try {
      var entered =
          ask(prompt: 'Enter the new Version No.:', validator: Ask.required);
      version = Version.parse(entered);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}
