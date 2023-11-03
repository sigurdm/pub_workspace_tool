## Pub monorepo tools

Disclaimer: This is not an officially supported Google product.

This repo contains a tool for creating a project-wide pubspec.yaml that depends on all pubspecs in sub-folders of the current directory.

To run:

```
# Activate
$ dart pub global activate -sgit https://github.com/sigurdm/pub_workspace_tool.git

# Run (in the root of the workspace).
$ dart pub global run pub_workspace_tool:create_workspace_pubspec
wrote project-wide `pubspec.yaml`. Run `dart pub get` to resolve.

# dart pub get
...
```