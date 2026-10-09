#!/usr/bin/env bash
# Update Dockerfile on new branch -> validate -> push -> raise PR -> enable auto-merge
# Needs env: GH_TOKEN, REPO (owner/name), BUILD_NUMBER. Optional: TARGET_UBUNTU
set -euo pipefail

TARGET_UBUNTU="${TARGET_UBUNTU:-24.04}"
BRANCH="auto/dockerfile-update-${BUILD_NUMBER}"

git config user.name  "jenkins-bot"
git config user.email "jenkins-bot@example.com"
git checkout -b "$BRANCH"

sed -i -E "s|^FROM ubuntu:.*|FROM ubuntu:${TARGET_UBUNTU}|" Dockerfile

if git diff --quiet; then
  echo "Dockerfile already up to date. No PR needed."
  exit 0
fi

# New Dockerfile syntax must be valid BEFORE we raise the PR
bash scripts/dockerfile_check.sh "dockerfile-candidate-${BUILD_NUMBER}"

git commit -am "chore: update Dockerfile base image to ubuntu:${TARGET_UBUNTU} [auto]"
git push "https://x-access-token:${GH_TOKEN}@github.com/${REPO}.git" "HEAD:${BRANCH}"

BODY="Automated PR from Jenkins build #${BUILD_NUMBER}.

Pre-checks passed: bash syntax, CPU/Disk health, Dockerfile lint + build.

\`\`\`
$(cat report/report.txt 2>/dev/null || echo 'no report')
\`\`\`"

gh pr create --repo "$REPO" --base main --head "$BRANCH" \
  --title "Update Dockerfile base image to ubuntu:${TARGET_UBUNTU}" --body "$BODY"

# Merges automatically ONLY after required status checks (Jenkins PR build) pass
gh pr merge --repo "$REPO" "$BRANCH" --auto --squash --delete-branch
