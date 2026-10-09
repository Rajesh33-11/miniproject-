#!/usr/bin/env bash
# Runs on a FEATURE branch after all checks pass:
#  1. update Dockerfile on the same feature branch (if needed) + validate it
#  2. push, 3. raise PR feature -> main, 4. enable auto-merge
# Needs env: GH_TOKEN, REPO (owner/name), BRANCH_NAME, BUILD_NUMBER. Optional: TARGET_UBUNTU
set -euo pipefail

TARGET_UBUNTU="${TARGET_UBUNTU:-24.04}"
BASE="main"
REMOTE="https://x-access-token:${GH_TOKEN}@github.com/${REPO}.git"

git config user.name  "jenkins-bot"
git config user.email "jenkins-bot@example.com"
git checkout -B "$BRANCH_NAME"

# --- 1. Update Dockerfile on the feature branch ---
sed -i -E "s|^FROM ubuntu:.*|FROM ubuntu:${TARGET_UBUNTU}|" Dockerfile

if ! git diff --quiet; then
  # New Dockerfile must be valid BEFORE commit/PR
  bash scripts/dockerfile_check.sh "dockerfile-candidate-${BUILD_NUMBER}"
  git commit -am "chore: update Dockerfile base image to ubuntu:${TARGET_UBUNTU} [auto]"
  git push "$REMOTE" "HEAD:${BRANCH_NAME}"
else
  echo "Dockerfile already up to date."
fi

# --- 2. Raise PR (only if not already open) ---
EXISTING=$(gh pr list --repo "$REPO" --head "$BRANCH_NAME" --base "$BASE" --state open --json number --jq '.[0].number // empty')
if [ -z "$EXISTING" ]; then
  BODY="Automated PR from Jenkins build #${BUILD_NUMBER} (branch: ${BRANCH_NAME}).

Pre-checks passed: bash syntax, CPU/Disk health, Dockerfile lint + build.

\`\`\`
$(cat report/report.txt 2>/dev/null || echo 'no report')
\`\`\`"
  gh pr create --repo "$REPO" --base "$BASE" --head "$BRANCH_NAME" \
    --title "Merge ${BRANCH_NAME} into ${BASE}" --body "$BODY"
else
  echo "PR #${EXISTING} already open."
fi

# --- 3. Auto-merge once required status checks (Jenkins PR build) pass ---
gh pr merge --repo "$REPO" "$BRANCH_NAME" --auto --squash --delete-branch
