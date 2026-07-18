#!/usr/bin/env bash
# Trigger remote CI builds via GitHub Actions (do not compile heavily on local machine).
#
# Usage:
#   ./tool/ci_trigger.sh                 # analyze/test (ci.yml)
#   ./tool/ci_trigger.sh build           # default linux,android release
#   ./tool/ci_trigger.sh build linux
#   ./tool/ci_trigger.sh build all
#   ./tool/ci_trigger.sh build linux,android,windows,ios profile
#   ./tool/ci_trigger.sh watch           # watch latest run
#   ./tool/ci_trigger.sh download        # download artifacts from latest Build run
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-FRBLanApps/arif}"
CMD="${1:-ci}"
shift || true

need_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI is required: https://cli.github.com/" >&2
    exit 1
  fi
  if ! gh auth status -h github.com >/dev/null 2>&1; then
    echo "gh is not authenticated. Run: gh auth login" >&2
    exit 1
  fi
}

need_gh

case "$CMD" in
  ci|test|analyze)
    echo "Triggering CI (analyze & test) on $REPO ..."
    gh workflow run ci.yml --repo "$REPO"
    sleep 2
    gh run list --repo "$REPO" --workflow=ci.yml --limit 3
    ;;
  build)
    TARGETS="${1:-linux,android}"
    PROFILE="${2:-release}"
    echo "Triggering Build on $REPO targets=$TARGETS profile=$PROFILE ..."
    gh workflow run build.yml --repo "$REPO" \
      -f "targets=$TARGETS" \
      -f "profile=$PROFILE"
    sleep 2
    gh run list --repo "$REPO" --workflow=build.yml --limit 3
    echo
    echo "Watch:  ./tool/ci_trigger.sh watch"
    echo "Fetch:  ./tool/ci_trigger.sh download"
    ;;
  watch)
    WORKFLOW="${1:-Build}"
    RUN_ID="$(gh run list --repo "$REPO" --workflow="$WORKFLOW" --limit 1 --json databaseId -q '.[0].databaseId')"
    if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
      echo "No runs found for workflow $WORKFLOW" >&2
      exit 1
    fi
    echo "Watching run $RUN_ID ..."
    gh run watch "$RUN_ID" --repo "$REPO"
    ;;
  download|dl)
    OUT="${1:-tool/dist/ci-artifacts}"
    RUN_ID="$(gh run list --repo "$REPO" --workflow=Build --status=success --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
    if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
      RUN_ID="$(gh run list --repo "$REPO" --workflow=Build --limit 1 --json databaseId -q '.[0].databaseId')"
    fi
    if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
      echo "No Build runs found" >&2
      exit 1
    fi
    mkdir -p "$OUT"
    echo "Downloading artifacts from run $RUN_ID → $OUT"
    gh run download "$RUN_ID" --repo "$REPO" --dir "$OUT"
    ls -la "$OUT"
    ;;
  status)
    gh run list --repo "$REPO" --limit 10
    ;;
  *)
    cat <<EOF
Usage: $0 <ci|build|watch|download|status> [args]

  ci                         Run analyze & test workflow
  build [targets] [profile]  Run multi-platform build (default: linux,android release)
  watch [WorkflowName]       Stream logs of latest run (default: Build)
  download [dir]             Download latest Build artifacts
  status                     List recent runs

Examples:
  $0 build linux,android
  $0 build all release
  $0 watch Build
  $0 download ./artifacts
EOF
    exit 1
    ;;
esac
