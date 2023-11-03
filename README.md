## Pub monorepo tools

This repo contains a tool for creating a project-wide pubspec.yaml that depends on all pubspecs in sub-folders of the current directory.

To run:

```
# Activate
$ dart pub global activate -sgit https://github.com/sigurdm/pub_workspace_tool.git

$ dart pub global run pub_workspace_tool:create_workspace_pubspec
```