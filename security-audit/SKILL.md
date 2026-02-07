---
name: security-audit
description: Security and compliance audit workflow for commercial releases. Use when asked for security review, risk assessment, or pre-release audit.
---

# Security Audit

## Required steps
- If `rules.md` exists in the repo, read it and apply project-specific requirements.
- Read `references/security.md` and follow the scope, scan commands, and output format.
- If git operations are requested, invoke `$git-ops` and follow its policy.

## 他スキルとの連携

- **code-review**: コードレビューと併用してセキュリティ観点を強化
- **implementation-rules**: セキュリティ要件を実装ルールに反映
- **fastlane-appstore-release**: リリース前の最終セキュリティチェック
