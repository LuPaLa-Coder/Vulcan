# Vulcan Release History

## [2026.8.5.0] - 2026-08-05

### Vulcan-Dispatch (v2026.8.5.0)
**New**: Entry point routing agent. Automatically detects target (Generic/AWS/Azure) and task type (code-gen, SCA), then delegates to the correct Vulcan agent.
- Agent routing with signal detection
- Multi-step task orchestration (code-gen → SCA → handoff)
- Integrated handoff to external services (code review, security audit)

### Vulcan-Core (v2026.8.5.0)
Core .NET development agent for provider-agnostic, cloud-agnostic scenarios.
- Generic APIs (REST, Minimal APIs, gRPC)
- Storage choices (LiteDB, SQLite, PostgreSQL, MongoDB)
- Anti-pattern encyclopedia (async, performance, supply-chain, design)
- Observability (Serilog, OpenTelemetry)
- Quality Gates (security, coverage, static analysis)

### Vulcan-AWS (v2026.8.5.0)
AWS cloud-native agent for Lambda, DynamoDB, CDK, EventBridge Pipes, and more.
- Lambda Powertools, Native AOT cold-start optimization
- DynamoDB single-table design and TTL/Streams patterns
- CDK with cdk-nag guardrails
- LocalStack testing, X-Ray tracing
- S3 Object Lambda for data transformation

### Vulcan-Azure (v2026.8.5.0)
Azure cloud-native agent for Functions, Cosmos DB, Bicep, Durable Functions.
- Managed Identity, Key Vault, Default Azure Credential
- Cosmos DB NoSQL patterns and partitioning
- Durable Functions catalog (human approval, fanout)
- Bicep IaC, blue-green deployment, WAF, APIM
- Azurite + Cosmos DB Emulator for local testing

### Vulcan-SCA (v2026.8.5.0)
Software Composition Analysis agent for NuGet dependency security and health.
- Vulnerability scanning (NU1903, NU1904 critical; NU1901/NU1902 moderate)
- Deprecation detection and upgrade guidance
- Outdated package detection with lock-file management
- Remediation loop (scan → fix via Vulcan-Core → re-scan, max 10 iterations)
- Zero-tolerance policy: 0 vulnerabili · 0 deprecati · 0 outdated

---

## Version Scheme

Versions follow the format `YYYY.M.G.N`:
- **YYYY**: Year (e.g., 2026)
- **M**: Month (e.g., 8 = August)
- **G**: General release counter (e.g., 5)
- **N**: Patch counter (e.g., 0)

Example: `2026.8.5.0` = August 2026, 5th general release, 0th patch.

---

## Planned Releases

### [3.0] Fase 1 + Fase 2 — Riallineamento e Verifica Automatica
- Sync agent visibility (SCA, Dispatch added to routing tables)
- CI/CD validation (lint-agents, link-check, sync-check, size-budget)
- Regression checks (RC-1..57 converted to executable evals)

### [3.1] Fase 3 — Bonifica Snippet e Enforcement
- Fix 13 non-compilant snippets (C1-C15)
- Add `tools:` and `model:` declarations in frontmatter
- Compilable sample code in `samples/`

### [3.2] Fase 4 — Rifattorizzazione Strutturale
- Scorporamento di Vulcan-Core (split into Core + Patterns)
- Unified block system (shared Livello 1, Guardrail, Profili Operativi)
- Anti-pattern renumbering (NET1-33 prefix)
- Residual content (F1-F8: DR, secrets rotation, Aspire, B2C, checkov/tfsec)
