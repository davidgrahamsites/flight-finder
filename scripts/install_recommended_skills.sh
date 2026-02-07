#!/usr/bin/env bash
set -euo pipefail

INSTALLER="/Users/appleadmin/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

install_if_missing() {
  local skill_name="$1"
  shift

  if [[ -d "$SKILLS_DIR/$skill_name" ]]; then
    echo "Skipping $skill_name (already installed)"
  else
    python3 "$INSTALLER" "$@"
  fi
}

install_if_missing "frontend-design" --repo anthropics/skills --path skills/frontend-design
install_if_missing "webapp-testing" --repo anthropics/skills --path skills/webapp-testing
install_if_missing "mcp-builder" --repo anthropics/skills --path skills/mcp-builder

install_if_missing "playwright-skill" --repo lackeyjb/playwright-skill --path \
  skills/playwright-skill

install_if_missing "swiftui-expert-skill" --repo AvdLee/SwiftUI-Agent-Skill --path \
  swiftui-expert-skill

install_if_missing "swift-patterns" --repo efremidze/swift-patterns-skill --path \
  swift-patterns

install_if_missing "verification-before-completion" --repo obra/superpowers --path skills/verification-before-completion
install_if_missing "test-driven-development" --repo obra/superpowers --path skills/test-driven-development

cat <<'MSG'
Installed recommended skills for FlightFinder.
Restart Codex to pick up new skills.
MSG
