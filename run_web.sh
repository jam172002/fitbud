#!/bin/bash
export PATH="/home/runner/flutter/bin:$PATH"
cd /home/runner/workspace
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0
