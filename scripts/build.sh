#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

show_usage() {
    echo "Usage: ./build.sh <environment> <platform> [options]"
    echo ""
    echo "Arguments:"
    echo "  environment    staging | production"
    echo "  platform       ios | android | web"
    echo ""
    echo "Examples:"
    echo "  ./build.sh staging ios           # Build iOS staging"
    echo "  ./build.sh production android    # Build Android production"
    echo "  ./build.sh staging web           # Build web staging"
    echo "  ./build.sh production ios --release    # Build iOS production release"
    exit 1
}

if [ $# -lt 2 ]; then
    show_usage
fi

ENVIRONMENT="$1"
PLATFORM="$2"
shift 2

case "$ENVIRONMENT" in
    staging)
        ENV_FILE="$PROJECT_DIR/env/staging-env.json"
        FLAVOR="staging"
        ;;
    production)
        ENV_FILE="$PROJECT_DIR/env/production-env.json"
        FLAVOR="production"
        ;;
    *)
        echo "Error: Invalid environment '$ENVIRONMENT'"
        show_usage
        ;;
esac

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

case "$PLATFORM" in
    ios)
        echo "Building iOS $ENVIRONMENT..."
        cd "$PROJECT_DIR"
        flutter build ios --flavor "$FLAVOR" --dart-define-from-file="$ENV_FILE" "$@"
        ;;
    android)
        echo "Building Android $ENVIRONMENT..."
        cd "$PROJECT_DIR"
        flutter build apk --flavor "$FLAVOR" --dart-define-from-file="$ENV_FILE" "$@"
        ;;
    web)
        echo "Building Web $ENVIRONMENT..."
        cd "$PROJECT_DIR"
        flutter build web --dart-define-from-file="$ENV_FILE" "$@"
        ;;
    *)
        echo "Error: Invalid platform '$PLATFORM'"
        show_usage
        ;;
esac

echo ""
echo "============================================"
echo "Build completed: $PLATFORM ($ENVIRONMENT)"
echo "============================================"