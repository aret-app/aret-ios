# ARET — shared coding-agent contract

This repository is developed by **multiple people and multiple AI
assistants**. The goal is a reliable Hiking app, not autonomous changes
without review. Follow [CLAUDE.md](CLAUDE.md) regardless of model/vendor.

- Read [README.md](README.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md),
  [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and
  [docs/REGIONAL_DISCOVERY.md](docs/REGIONAL_DISCOVERY.md) first.
- Pilot geography: **Alpi Apuane + Appennino tosco-emiliano**.
- Maintain a clear distinction between *in code*, *compiled*,
  *device-tested* and *production-ready*.
- Work on a branch + PR; no unreviewed rewrites of shared source.
- Do not guess mountain difficulties, create fictional GPX, infer
  path/summit connectivity, or present forecast data as safety approval.
- Keep provider attribution, OpenStreetMap data rights, HealthKit
  permissions and local-first privacy.
- Use XcodeGen's `project.yml` for target/SPM changes.
- Add tests and update developer docs for new APIs/screens.
- If Xcode cannot be run, explicitly list **unverified build/test steps**.

See [docs/QA_SCENARIOS.md](docs/QA_SCENARIOS.md) before a field release.
