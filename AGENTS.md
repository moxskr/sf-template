# Agent guidance — moxskr-sf-template

Shared instructions for AI coding agents working in this repository.

**Before changing code:** inspect existing selectors, services, trigger actions/metadata, permission sets, tests, and nearby patterns. Prefer extending what exists over introducing parallel abstractions.

## Repository Overview

- Salesforce DX **source-format** org-development project (`sfdx-project.json` name: `moxskr-sf-template`).
- Default package directory: `force-app/` (`force-app/main/default/…`).
- API version: `sourceApiVersion` **67.0** — match new metadata.
- Current scaffold: `classes/`, `lwc/` (placeholders). Add `triggers/`, `objects/`, `permissionsets/`, etc. under `force-app/main/default` as needed — do not invent alternate layouts.
- Samples: `scripts/apex`, `scripts/soql`. Scratch def: `config/project-scratch-def.json`.
- Prefer `sf` CLI over legacy `sfdx`. Never commit `.sf/`, `.sfdx/`, tokens, or credentials.
- Agent skills: `.agents/skills/` (canonical); `.codex/skills` is the Codex link to that directory. Salesforce DX MCP is configured in `.codex/config.toml`.

## Required Architecture

Defaults — do **not** introduce a competing framework without an explicit requirement:

1. Queries → **SOQL Lib**
2. DML → **DML Lib**
3. Asynchronous work → **Async Lib**
4. Triggers → **Trigger Actions Framework**
5. HTTP test mocks → **HTTP Mock Lib**
6. Test-data construction → **Test Lib**
7. Application logging → **Nebula Logger**

Do not add a second selector framework, unit-of-work framework, trigger framework, logger, or HTTP mock framework.

Versions/install IDs: see `README.md` (verified upstream). Apex Fluently unlocked packages use the `btcdev` namespace when installed as packages.

## Apex Rules

- Bulk-safe Apex only: no SOQL/DML/SOSL in loops; use collections and maps.
- Keep classes cohesive; methods focused; prefer selector / service / domain separation over god-classes.
- Declare sharing intentionally (`with sharing`, `inherited sharing`, or documented `without sharing`).
- Enforce the project security model (CRUD/FLS, user vs system mode on SOQL/DML Lib).
- No hardcoded IDs; no environment-specific URLs/secrets in Apex — use Custom Metadata / Named Credentials / config.
- Prefer boundaries that keep code testable (injectable clients, mockable selectors).
- Use modern Apex features supported by API 67.0.
- Prefer platform-idiomatic code over clever abstractions that obscure governor usage.

## Query Rules

- Inspect existing selectors first; extend them instead of duplicating queries.
- Prefer SOQL Lib for reusable application queries.
- Select only needed fields; set execution mode/security deliberately (`.systemMode()`, `.withSharing()` / `.withoutSharing()`, default user mode).
- Avoid duplicate queries in the same transaction when reuse/caching is suitable.

```apex
List<Account> accounts = SOQL.of(Account.SObjectType)
	.with(Account.Id, Account.Name, Account.Industry)
	.whereAre(SOQL.Filter.with(Account.Industry).equal('Technology'))
	.toList();
```

Native SOQL is acceptable only for trivial one-offs, `scripts/`, or cases SOQL Lib cannot express — follow existing repo patterns.

## DML Rules

Route application DML through DML Lib by default:

```apex
new DML()
	.toInsert(new Account(Name = 'Acme'))
	.commitWork();
```

Do not scatter direct `insert` / `update` / `delete` / `undelete` in business logic. Exceptions only when native DML is materially clearer or required — mirror established repository patterns. Keep DML in services, not triggers or selectors.

## Trigger Rules

**Never put business logic directly in an Apex trigger.**

```apex
trigger AccountTrigger on Account (
	before insert, before update, before delete,
	after insert, after update, after delete, after undelete
) {
	new MetadataTriggerHandler().run();
}
```

Implement behavior as Trigger Actions Framework actions + `Trigger_Action__mdt` / `SObject_Trigger_Setting__mdt`.

Before adding a trigger action:

1. Inspect existing actions for the object
2. Inspect trigger metadata and order
3. Determine ordering dependencies
4. Consider bypass behavior
5. Consider recursion / re-entry
6. Keep the implementation bulk-safe

Do not add another trigger framework. Substantial logic belongs in services called from actions.

## Async Rules

Before writing raw `Queueable` / `Database.Batchable` / `Schedulable` orchestration, check whether Async Lib covers the need. Prefer:

```apex
Async.queueable(new MyJob(ids)).enqueue();
```

Still respect Salesforce transaction and governor semantics — do not use async to hide inefficient synchronous design.

## Logging Rules

Use Nebula Logger:

```apex
Logger.info('…');
Logger.warn('…');
Logger.error('…', record, ex);
Logger.saveLog();
```

Prefer that over application-level `System.debug`. Persist logs per Nebula’s `saveLog` / save-method guidance.

Never log: passwords, secrets, bearer tokens, session IDs, private keys, or unnecessary sensitive payloads. Use data masking (`LogEntryDataMaskRule__mdt`) where relevant.

## Integration Rules

- Named Credentials / External Credentials for HTTP auth and endpoints.
- Keep HTTP transport out of domain services.
- Tests: HTTP Mock Lib.

```apex
new HttpMock()
	.whenGetOn('/api/v1/customer')
	.body('{"id":"123","name":"Acme"}')
	.statusCodeOk()
	.mock();
```

## Testing Rules

Every behavioral change needs appropriate automated tests.

- Locate and extend existing tests; follow naming already in the repo (or `ThingTest` / `Thing_Test` consistently once established).
- Test Lib for data setup; HTTP Mock Lib for callouts; SOQL Lib mocking when it improves isolation.
- Bulk, negative, and edge cases; `SeeAllData=false`; deterministic data; `Assert.*`.
- Arrange / Act / Assert; `Test.startTest` / `stopTest` when meaningful.
- Run the smallest relevant tests while iterating; run the broader required suite before claiming done.
- Do not write tests only to raise coverage percentages.

```apex
Account acc = (Account) AccountTestModule.Builder()
	.set(Account.Name, 'Acme')
	.buildAndInsert();
```

## Metadata Rules

- Include required `-meta.xml` companions; API version **67.0**.
- Follow existing naming; update **permission sets** when new Apex/objects/fields need access.
- Avoid editing profiles unless the project explicitly uses them for that purpose.
- Treat destructive changes carefully; do not deploy to production/unexpected orgs without an explicit ask.

## Dependency Rules

- Do not copy library source into `force-app` to avoid installing packages.
- Do not modify third-party library source unless this repo intentionally vendors it.
- Do not upgrade Salesforce libraries opportunistically during unrelated work.
- When explicitly upgrading: check upstream README/releases, note breaking changes, update package refs + `README.md` dependency table, run affected tests.

## LWC Rules

- Prefer Lightning base components and SLDS.
- Keep `@api` small; use `@wire` for cacheable reads; imperative Apex for user-driven/non-cacheable calls.
- Jest for non-trivial JS; accessible HTML/CSS.
- Do not depend on undocumented Salesforce internal DOM.

## Commands

Prefer repository scripts:

```bash
npm install
npm run prettier
npm run prettier:verify
npm run lint
npm run test:unit
npm run precommit
```

Salesforce:

```bash
sf project deploy start --source-dir force-app
sf project retrieve start --source-dir force-app
sf apex run test --tests <TestClass> --wait 10
sf apex run test --test-level RunLocalTests --wait 20
```

Skills refresh (when needed):

```bash
npx skills add forcedotcom/sf-skills -a codex -s '*' -y
```

## Operating constraints

- Small, reviewable diffs scoped to the request.
- Scratch orgs for ephemeral work; sandboxes/production need explicit confirmation before deploy.
- Prefer plan → metadata → deploy → test → fix.
- Keep `.forceignore`, Prettier, ESLint, and Husky behavior intact — fix hooks, do not bypass.
- Ask when org-impacting requirements are ambiguous (scratch vs sandbox, object model, permissions).
- Do not claim tests/validation passed unless executed.

## Git commit messages

- Use a short, imperative, sentence-case subject.
- Do not use conventional-commit prefixes such as `feat:`, `fix:`, or `chore:`.
- Keep the subject focused on the user-visible change and consistent with the existing repository history.
- Add `Co-authored-by: Codex <codex@openai.com>` as the final trailer to commits created by Codex.

## Validation Before Completion

1. Format/lint changed files (`npm run prettier`, `npm run lint` as applicable).
2. Run static analysis if configured for the change (not wired as CI yet — do not invent status).
3. Run relevant Apex and/or LWC Jest tests.
4. Validate metadata structure and API versions.
5. Check for hardcoded IDs/secrets.
6. Verify query/DML bulk safety.
7. Verify sharing/security behavior.
8. Ensure logging uses Nebula Logger where application logging is needed.
9. Verify triggers use `MetadataTriggerHandler` + Trigger Actions Framework.
10. Review `git diff` for unrelated changes.

## Compact end-to-end shape

```
Trigger → MetadataTriggerHandler → Trigger Action → Service
                                              ├── SOQL selector
                                              ├── DML Lib
                                              └── Nebula Logger
Test → Test Lib (+ SOQL.mock / HttpMock as needed)
```
