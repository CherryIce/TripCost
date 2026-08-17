#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/platform_apis.dart
dart format lib/core/platform/generated/platform_apis.g.dart
