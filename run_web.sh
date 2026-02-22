#!/bin/bash
cd /home/runner/workspace

# Profile mode compiles all Dart into a single JS file via dart2js.
# This eliminates the require.js deferred-module stale-URL blank-screen
# issue that happens in debug mode after every hot-restart.
# Hot restart (R) still works; only hot reload (r) is unavailable.
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0 --profile
