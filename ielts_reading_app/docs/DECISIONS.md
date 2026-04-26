# Architecture Decision Records (ADRs)

## ADR-001: Bring-Your-Own-Key (BYOK) for OpenRouter
**Status:** Accepted
**Context:** OpenRouter access is keyed per user account. Pooling all users under one key would be brittle and difficult to rate-limit safely.
**Decision:** Each end-user provides their own OpenRouter key in-app. Stored in flutter_secure_storage.
**Consequences:** Zero infra cost for the developer. Higher friction at onboarding — mitigated with in-app walkthrough.

## ADR-002: Riverpod over Bloc
**Status:** Accepted
**Decision:** Riverpod 2.x with code-gen.

## ADR-003: Feature-first folders
**Status:** Accepted
**Decision:** `lib/features/<name>/{data,domain,presentation,providers}`.
