# moxskr-sf-template

Salesforce DX **source-format** template for org-based development. Application metadata lives under `force-app/`, is tracked in Git, and is deployed with the Salesforce CLI (`sf`).

This repository starts nearly empty (`force-app/main/default/classes` and `lwc` placeholders only). It standardizes how Apex, triggers, integrations, logging, and tests are built so humans and coding agents share one architecture.

## Overview

| Item | Value |
|------|--------|
| Project name (`sfdx-project.json`) | `moxskr-sf-template` |
| Structure | Org-development DX project (single default package directory `force-app`) |
| Source API version | `67.0` |
| Namespace | none (unmanaged application source) |
| Login URL | `https://login.salesforce.com` |

**High-level architecture**

```
Trigger (thin)
  → Trigger Actions Framework (metadata-ordered actions)
    → Service / domain logic
      ├── SOQL Lib selectors
      ├── DML Lib
      ├── Async Lib (when work must leave the request)
      └── Nebula Logger

Tests
  ├── Test Lib (test data)
  ├── SOQL Lib mocking
  └── HTTP Mock Lib (callouts)
```

## Technology Stack

- **Salesforce DX** — source format, scratch orgs, CLI deploy/retrieve
- **Apex** — API `67.0` (match new metadata to `sfdx-project.json` → `sourceApiVersion`)
- **Lightning Web Components** — folder scaffolded; Jest configured for unit tests
- **Salesforce CLI (`sf`)** — preferred over legacy `sfdx`
- **Node.js / npm** — Prettier, ESLint, Husky, lint-staged, LWC Jest
- **Python / uv** (optional) — `pyproject.toml` pins Ruff + ty for template scripts (`requires-python >= 3.14`)

## Repository Structure

```
force-app/
  main/
    default/
      classes/          # Apex (application code)
      lwc/              # Lightning Web Components
scripts/
  apex/                 # Anonymous Apex samples
  soql/                 # Ad-hoc SOQL samples
config/
  project-scratch-def.json
manifest/
  package.xml           # Broad retrieve manifest (API 67.0)
.agents/skills/         # Canonical Salesforce agent skills
.claude/ .cursor/ .codex/  # Agent/MCP config (skills often symlink here)
```

Directories such as `triggers/`, `objects/`, and `permissionsets/` are created when you add that metadata — do not invent parallel layouts outside `force-app`.

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- Node.js + npm (compatible with the dependencies in `package.json`)
- Java (required by Salesforce VS Code extensions / some CLI tooling)
- An authenticated Salesforce org
- A Dev Hub org if you create scratch orgs (`config/project-scratch-def.json`)

## Setup

```bash
npm install

# Authenticate a development org
sf org login web --alias my-org
sf config set target-org my-org

# Optional: Dev Hub + scratch org
sf org login web --alias my-devhub --set-default-dev-hub
sf org create scratch --definition-file config/project-scratch-def.json --alias my-scratch --set-default --duration-days 7
```

Deploy application source after dependencies are installed in the target org:

```bash
sf project deploy start --source-dir force-app
```

### Agent skills / MCP (optional)

Salesforce agent skills live under `.agents/skills/`. Refresh:

```bash
npx skills add forcedotcom/sf-skills -a claude-code -a cursor -a codex -s '*' -y
```

DX MCP is configured in `.mcp.json` (Claude) and `.cursor/mcp.json`. Codex uses `.codex/config.toml`.

## Dependencies / Salesforce Libraries

Install these **unlocked packages** into each development org (scratch/sandbox) before relying on the architecture below. Versions and package IDs were verified against upstream docs/READMEs on **2026-08-11**. Prefer unlocked packages; do not invent package IDs.

Apex Fluently packages (`btcdev` namespace when installed as packages) are part of [Apex Fluently](https://github.com/beyond-the-cloud-dev). Source-deploy / unmanaged options also exist on each project’s installation page — use those if you intentionally avoid the namespace.

| Library | Purpose | Version (verified) | GitHub | Installation |
|---------|---------|--------------------|--------|--------------|
| **SOQL Lib** | Fluent, mockable queries and selectors | `6.11.1` (`04tP6000003On13IAC`) | [soql-lib](https://github.com/beyond-the-cloud-dev/soql-lib) | [Install docs](https://soql.beyondthecloud.dev/installation) · `sf package install --wait 20 --security-type AdminsOnly --package 04tP6000003On13IAC` |
| **DML Lib** | Fluent DML, relationships, mocking | `3.1.0` (`04tP60000036moDIAQ`) | [dml-lib](https://github.com/beyond-the-cloud-dev/dml-lib) | [Install docs](https://dml.beyondthecloud.dev/installation) · `sf package install --wait 20 --security-type AdminsOnly --package 04tP60000036moDIAQ` |
| **Async Lib** | Queueable chaining, batch, schedule, finalizers, job tracking | `2.7.0` (`04tP6000003Sp7WIAS`) | [async-lib](https://github.com/beyond-the-cloud-dev/async-lib) | [Install docs](https://async.beyondthecloud.dev/introduction/installation) · `sf package install --wait 20 --security-type AdminsOnly --package 04tP6000003Sp7WIAS` |
| **HTTP Mock Lib** | Fluent HTTP callout mocks in tests | `1.2.0` (`04tP6000002EJBJIA4`) | [http-mock-lib](https://github.com/beyond-the-cloud-dev/http-mock-lib) | [Install docs](https://httpmock.beyondthecloud.dev/installation) · `sf package install --wait 20 --security-type AdminsOnly --package 04tP6000002EJBJIA4` |
| **Test Lib** | Test-data Builder / Mocker modules | `0.1.0` BETA (`04tP600000390yLIAQ`) | [test-lib](https://github.com/beyond-the-cloud-dev/test-lib) | [Install docs](https://testlib.beyondthecloud.dev/installation) · `sf package install --wait 20 --security-type AdminsOnly --package 04tP600000390yLIAQ` |
| **Trigger Actions Framework** | Metadata-driven trigger actions (Apex + Flow) | `0.3.4-1` (`04tKY000000R0yHYAS`) | [trigger-actions-framework](https://github.com/mitchspano/trigger-actions-framework) | [README install links](https://github.com/mitchspano/trigger-actions-framework) · `sf package install --wait 20 --security-type AdminsOnly --package 04tKY000000R0yHYAS` |
| **Nebula Logger** | Application logging (Apex, LWC, Flow) | Unlocked `v4.19.1` (`04tg7000000GqibAAC`) | [NebulaLogger](https://github.com/jongpie/NebulaLogger) | Prefer unlocked package · `sf package install --wait 20 --security-type AdminsOnly --package 04tg7000000GqibAAC` |

**Why this project uses them**

- **SOQL Lib** — consistent selectors, binding safety, FLS/sharing modes, and test mocking without string-built SOQL.
- **DML Lib** — centralize DML, parent/child relationships, and partial-success options away from services’ happy-path noise.
- **Async Lib** — standard way to chain queueables, schedule work, run batch, and track results without ad-hoc async frameworks.
- **HTTP Mock Lib** — one fluent mock API instead of one-off `HttpCalloutMock` classes.
- **Test Lib** — reusable builders/mockers for deterministic test data.
- **Trigger Actions Framework** — thin triggers, ordered metadata, bypass/recursion controls.
- **Nebula Logger** — durable, searchable logs instead of `System.debug` for application behavior.

> Examples below use the **un-namespaced** type names from upstream docs. If you installed Apex Fluently unlocked packages, prefix types with `btcdev.` (for example `btcdev.SOQL`, `btcdev.DML`, `btcdev.Async`).

## Architecture and Development Patterns

### SOQL

Use **SOQL Lib** for programmatic application queries. Put reusable queries in selector classes. Do not scatter complex inline SOQL through services.

```apex
List<Account> accounts = SOQL.of(Account.SObjectType)
	.with(Account.Id, Account.Name, Account.Industry)
	.whereAre(SOQL.Filter.with(Account.Industry).equal('Technology'))
	.toList();
```

Selector pattern:

```apex
public inherited sharing class SOQL_Account extends SOQL implements SOQL.Selector {
	public static final String MOCK_ID = 'SOQL_Account';

	public static SOQL_Account query() {
		return new SOQL_Account();
	}

	private SOQL_Account() {
		super(Account.SObjectType);
		with(Account.Id, Account.Name);
		mockId(MOCK_ID);
	}

	public SOQL_Account byIds(Set<Id> accountIds) {
		whereAre(SOQL.Filter.id().isIn(accountIds));
		return this;
	}

	public SOQL_Account byIndustry(String industry) {
		whereAre(SOQL.Filter.with(Account.Industry).equal(industry));
		return this;
	}
}
```

Native SOQL in square brackets remains reasonable for one-off scripts under `scripts/`, trivial single-field lookups in tightly scoped private helpers, or platform requirements SOQL Lib cannot express. Prefer selectors for anything reused or tested.

Docs: [soql.beyondthecloud.dev](https://soql.beyondthecloud.dev/)

### DML

Use **DML Lib** for application-level DML instead of scattering `insert` / `update` / `delete` through business logic.

```apex
new DML()
	.toInsert(new Account(Name = 'Acme'))
	.commitWork();

new DML()
	.toUpdate(account)
	.commitWork();
```

Parent/child relationships (IDs resolved on commit):

```apex
Account account = new Account(Name = 'Parent Account');
Contact contact = new Contact(FirstName = 'John', LastName = 'Doe');

new DML()
	.toInsert(account)
	.toInsert(DML.Record(contact).withRelationship(Contact.AccountId, account))
	.commitWork();
```

Perform DML in services (or dedicated unit-of-work helpers), not in triggers or selectors. Prefer `userMode()` / sharing settings intentionally for the execution context.

Docs: [dml.beyondthecloud.dev](https://dml.beyondthecloud.dev/)

### Async processing

Use **Async Lib** when work must leave the synchronous transaction: long processing, callout-heavy fan-out, scheduled jobs, or multi-step chains that would hit queueable limits.

Supported constructs: **Queueable** (with chaining), **Batch**, **Schedulable** (`CronBuilder` / `asSchedulable()`), **finalizers**, and **Async Result** tracking via custom job IDs / `AsyncResult__c`.

```apex
public class AccountProcessorJob extends QueueableJob {
	private List<Id> accountIds;

	public AccountProcessorJob(List<Id> accountIds) {
		this.accountIds = accountIds;
	}

	public override void work() {
		List<Account> accounts = SOQL_Account.query().byIds(new Set<Id>(accountIds)).toList();
		for (Account acc : accounts) {
			acc.Description = 'Processed';
		}
		new DML().toUpdate(accounts).commitWork();
	}
}

Async.Result result = Async.queueable(new AccountProcessorJob(accountIds))
	.enqueue();
```

Prefer **synchronous** processing when the work is small, must participate in the same transaction/rollback, or must return results to the caller immediately. Do not move inefficient synchronous code to async merely to hide governor pressure.

Docs: [async.beyondthecloud.dev](https://async.beyondthecloud.dev/)

### Trigger architecture

All business trigger logic uses **Trigger Actions Framework**. Triggers stay minimal.

```
Salesforce Trigger
        ↓
MetadataTriggerHandler
        ↓
Trigger Action metadata (order / bypass / entry criteria)
        ↓
Apex Trigger Action / Flow Trigger Action
        ↓
Service / domain logic
```

```apex
trigger AccountTrigger on Account (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete
) {
	new MetadataTriggerHandler().run();
}
```

Apex trigger action:

```apex
public class TA_Account_SetIndustryDefaults implements TriggerAction.BeforeInsert {
	public void beforeInsert(List<Account> triggerNew) {
		for (Account account : triggerNew) {
			if (String.isBlank(account.Industry)) {
				account.Industry = 'Technology';
			}
		}
	}
}
```

Register actions with `SObject_Trigger_Setting__mdt` + `Trigger_Action__mdt` (order on the metadata controls sequence). Use framework bypass mechanisms and recursion prevention rather than static boolean hacks. When an action grows beyond simple field defaults, delegate to a service.

Docs: [mitchspano.com/trigger-actions-framework](https://mitchspano.com/trigger-actions-framework/)

### Logging

**Nebula Logger** is the application logger. Do not add custom logger wrappers unless there is a clear project-specific need. Avoid `System.debug` for production application logging.

```apex
Logger.info('Processing account');
Logger.warn('Account has incomplete configuration');
Logger.error('Account processing failed');
Logger.saveLog();
```

Exception + record context:

```apex
try {
	// ...
} catch (Exception ex) {
	Logger.error('Account processing failed', account, ex);
	Logger.saveLog();
	throw ex;
}
```

Use levels deliberately (`ERROR` / `WARN` / `INFO` / finer levels for diagnostics). Call `Logger.saveLog()` when entries must persist for the transaction (or use documented save methods for special contexts). Never log passwords, tokens, session IDs, private keys, or unnecessary sensitive payloads. Prefer Nebula’s data masking via `LogEntryDataMaskRule__mdt` for known sensitive patterns.

### HTTP callouts

- Use **Named Credentials / External Credentials**
- Keep transport in focused client/integration classes; map payloads with DTOs where useful
- Tests use **HTTP Mock Lib** unless it cannot express the scenario

```apex
new HttpMock()
	.whenGetOn('/api/v1/customer')
	.body('{"id":"123","name":"Acme"}')
	.statusCodeOk()
	.mock();
```

Multiple endpoints:

```apex
new HttpMock()
	.whenGetOn('/api/v1/authorize').body('{ "token": "aZ3Xb7Qk" }').statusCodeOk()
	.whenPostOn('/api/v1/create').body('{ "success": true, "message": null }').statusCodeOk()
	.mock();
```

### Test data

Prefer **Test Lib** modules (Builder for DML-backed data, Mocker for in-memory/fake-ID isolation):

```apex
Account acc = (Account) AccountTestModule.Builder()
	.set(Account.Name, 'Acme Corp')
	.set(Account.Industry, 'Technology')
	.buildAndInsert();

List<SObject> accounts = AccountTestModule.Builder()
	.set(Account.Industry, 'Technology')
	.buildAndInsert(10);

Id fakeAccountId = TestModule.IdGenerator.get(Account.SObjectType);
```

Define project `*TestModule` Builder/Mocker classes per [Test Lib](https://testlib.beyondthecloud.dev/) — do not invent APIs. Convenience methods such as `withName()` are fine once declared on your module.

## Testing Standards

- `@IsTest`, `SeeAllData=false` (never enable SeeAllData)
- Arrange / Act / Assert
- `Test.startTest()` / `Test.stopTest()` around the behavior under test when async, callouts, or governor resets matter
- Assert behavior with `Assert.*` APIs
- Cover positive, negative, and bulk paths for non-trivial logic
- Mock HTTP with HTTP Mock Lib; mock SOQL with `SOQL.mock(...).thenReturn(...)` when isolation helps
- Prefer Test Lib builders over ad-hoc object graphs
- Do not add tests solely to inflate coverage

### Combined example

```apex
public with sharing class AccountIndustryService {
	public static void normalizeIndustry(Set<Id> accountIds) {
		List<Account> accounts = SOQL_Account.query().byIds(accountIds).toList();
		for (Account account : accounts) {
			if (String.isBlank(account.Industry)) {
				account.Industry = 'Technology';
				Logger.info('Defaulted Industry', account);
			}
		}
		new DML()
			.toUpdate(accounts)
			.identifier('AccountIndustryService.normalizeIndustry')
			.commitWork();
		Logger.saveLog();
	}
}

@IsTest
private class AccountIndustryServiceTest {
	@IsTest
	static void normalizeIndustry_defaultsBlankIndustry() {
		Account account = (Account) AccountTestModule.Builder()
			.set(Account.Name, 'Blank Industry Co')
			.buildAndInsert();

		Test.startTest();
		AccountIndustryService.normalizeIndustry(new Set<Id>{ account.Id });
		Test.stopTest();

		Account updated = (Account) SOQL.of(Account.SObjectType)
			.with(Account.Industry)
			.whereAre(SOQL.Filter.id().equal(account.Id))
			.toObject();
		Assert.areEqual('Technology', updated.Industry);
	}

	@IsTest
	static void normalizeIndustry_unit_mocksSelectorAndDml() {
		Account account = (Account) AccountTestModule.Mocker()
			.setFakeId()
			.set(Account.Name, 'Mock Co')
			.build();

		SOQL.mock(SOQL_Account.MOCK_ID).thenReturn(new List<Account>{ account });
		DML.mock('AccountIndustryService.normalizeIndustry').allUpdates();

		Test.startTest();
		AccountIndustryService.normalizeIndustry(new Set<Id>{ account.Id });
		Test.stopTest();

		Assert.areEqual('Technology', account.Industry);
		DML.Result result = DML.retrieveResultFor('AccountIndustryService.normalizeIndustry');
		Assert.isFalse(result.updatesOf(Account.SObjectType).hasFailures());
	}
}
```

Selectors used with `SOQL.mock` must call `.mockId(SOQL_Account.MOCK_ID)` in their constructor. Use `.identifier(...)` on DML when you need `DML.mock` in unit tests.

## Salesforce Security Standards

- Declare sharing intentionally: `with sharing`, `inherited sharing`, or documented `without sharing`
- Choose SOQL Lib / DML Lib **user mode vs system mode** and sharing methods to match the use case — do not “disable security for convenience”
- Enforce CRUD/FLS for user-facing paths; document elevated system-mode services
- Secrets stay in Named Credentials, Protected Custom Settings/Metadata, or external secret stores — never in Apex/LWC source
- Prefer **permission sets** for access; avoid profile edits unless this project explicitly relies on profiles
- No hardcoded Salesforce IDs or environment-specific URLs in Apex

## Governor Limits / Bulkification

- No SOQL, SOSL, or DML inside loops
- Bulk-safe collections (`Set` / `Map`) and single-pass processing
- Bound callouts; batch or queue work that cannot finish synchronously
- Avoid duplicate queries in one transaction (reuse selector results / caching where appropriate)
- Design trigger actions and services for 200-record batches

## Development Commands

From `package.json`:

```bash
npm install
npm run prettier              # format force-app metadata/source
npm run prettier:verify
npm run lint                 # ESLint on LWC JS
npm run test                 # LWC Jest
npm run test:unit
npm run test:unit:watch
npm run test:unit:coverage
npm run precommit            # lint-staged (Husky)
```

Salesforce CLI (common):

```bash
sf project deploy start --source-dir force-app
sf project retrieve start --source-dir force-app
sf apex run test --test-level RunLocalTests --wait 20
sf apex run test --tests AccountIndustryServiceTest --wait 10
sf org open
```

## Code Quality

Configured in-repo:

| Tool | Role |
|------|------|
| Prettier (+ `prettier-plugin-apex`, `@prettier/plugin-xml`) | Format Apex/LWC/XML/JSON |
| ESLint (`@salesforce/eslint-config-lwc`) | LWC JavaScript lint |
| Husky + lint-staged | Pre-commit format / lint / related Jest |
| `sfdx-lwc-jest` | LWC unit tests |
| EditorConfig | Indentation defaults (tabs; spaces for XML) |

Not configured as a project CI pipeline today (no `.github/workflows`). Salesforce Code Analyzer / PMD may be run ad hoc via CLI/skills; do not claim they are wired into CI until added.

## Contribution Workflow

1. Create a focused branch from `main`.
2. Inspect existing selectors, services, trigger actions, and tests before adding peers.
3. Keep diffs small and on-architecture (libraries above — no competing frameworks).
4. Run Prettier/ESLint and the smallest relevant Apex/LWC tests locally.
5. Open a PR with a clear description of behavior and test evidence.
6. Do not commit `.sf/`, `.sfdx/`, tokens, or secrets. Do not bypass Husky hooks — fix failures.

## Additional Resources

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Apex Fluently](https://apexfluently.beyondthecloud.dev/)
- [Nebula Logger](https://github.com/jongpie/NebulaLogger)
- [Trigger Actions Framework docs](https://mitchspano.com/trigger-actions-framework/)
