# AI-Assisted Development Under Human Governance
## A Practitioner's Guide to Structured Collaboration with Large Language Models

**Authors:** Ioannis (John) Bourlakos · Claude Sonnet 4.6 (Anthropic)

*Developed from the development practice of The Gibbering Engine, a turn-based D&D 5e tactical grid game built with Elixir and Phoenix LiveView. The methodology described here is general and applicable to any software project where a team seeks to use AI assistance without sacrificing engineering discipline.*

---

## Overview

The dominant narrative around AI-assisted development has two poles: uncritical enthusiasm ("ship 10x faster") and reflexive dismissal ("you don't understand your own code"). Both miss the actual design problem.

The design problem is governance: under what conditions can an AI contribute to a codebase without degrading the quality of human judgment that produced it?

This guide describes a methodology built on a simple claim — **AI is most valuable when it operates inside constraints defined by humans, not when it operates instead of them**. It covers the conventions required to instantiate this claim as a working practice, the failure modes to watch for, and how the methodology scales from a solo project to a team.

---

## 1. The Core Distinction

### 1.1 AI as executor, not architect

The central distinction is between *design authority* and *implementation capacity*.

In the methodology described here, humans hold design authority. They decide what gets built, why, and under what constraints. They write the issue specifications, the architecture documents, the brainstorming notes that explore design space before committing to a direction. They set the legal gates, the testing strategy, the git policy.

The AI holds implementation capacity. Given a well-specified problem, it can produce a candidate implementation faster than a human, recall the full context of a codebase on demand, and identify inconsistencies between a proposed change and existing conventions. It executes within a space the human defined.

This is not a limitation on AI capability. It is a deliberate allocation of responsibility. When something is wrong, the human who defined the spec owns the error in design; the human who reviewed the AI's output owns the error in review. Traceability is preserved because the decision record is preserved.

### 1.2 What "governance" means in practice

Governance is not surveillance. It does not mean reviewing every token the AI generates. It means:

1. **Constraints are written down** in a form the AI reads before it acts. In this project that is `CLAUDE.md` — a checked-in file that defines the workflow, the legal gates, the commit conventions, and the scope of AI autonomy.
2. **Decisions are traceable** through the issue tracker and architecture documentation. If a design choice cannot be explained by a document or an issue, it has no place in the codebase.
3. **Output is verified** — not trusted. Every AI-produced change goes through the same gate as a junior engineer's PR: automated checks, and a manual verify phase that observes actual behavior, not just tests.

---

## 2. The Required Conventions

### 2.1 Spec before prompt

No AI session begins on a feature without a prior human act of specification. That act may be an issue file, a brainstorming document, or an architecture note — but something written must exist before the AI is directed to implement.

This is the single most important convention. Without it, the AI fills design decisions the human should own. The spec is not a formality; it is the mechanism by which the human's judgment enters the process before the AI's output does.

**Enforcement:** PR checklist item. A PR that introduces a feature with no corresponding issue is returned.

### 2.2 Workflow paths

Different types of change require different processes. The project defines seven workflow paths (A–G) covering discovery, feature development, bugfix, hotfix, work packages, escalation, and documentation. Each path specifies what must happen before a branch is opened, what must happen before a PR is raised, and what constitutes a valid close.

The AI operates within whichever path applies. It does not select the path. The human determines the type of work and selects the corresponding process.

### 2.3 Legal gates as hard blockers

Every asset (image, font, data file), every dependency, every data source must be verified against the project's license inventory before it enters the codebase. This gate is not negotiable and is not waived because the AI suggested the dependency. The AI is explicitly instructed that legal uncertainty is a blocker, not a risk to manage.

This matters because AI models are trained on large corpora that include content of varied provenance. A model asked to suggest a library may suggest one whose license is incompatible with the project's distribution terms. Governance means the human performs the license check; the AI does not substitute for it.

### 2.4 Commit conventions and attribution

All commits follow conventional commit format (`type(scope): subject`). AI-assisted commits are tagged with a co-author trailer:

```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

This makes AI involvement visible in the git log without being normatively charged. It is not a disclaimer; it is a factual record, the same way pair programming credit works.

One logical change per commit. The AI does not batch unrelated changes; if it drifts into adjacent cleanup, the human stages only the relevant files.

### 2.5 Test layering

Tests follow a three-layer hierarchy: pure function tests first, integration tests second, end-to-end tests last. The AI is directed to start at the lowest applicable layer. This prevents a common failure mode where AI-generated code is covered only by high-level tests that pass despite incorrect internals.

`mix precommit` runs before every code commit. This is a local gate, enforced per machine, not per person.

### 2.6 Documentation as a shared contract

Architecture documents are the AI's primary source of context about the design. They are also the human's record of design decisions. When the AI proposes a change that would alter the architecture, the change must be reflected in the documentation. The AI cannot operate consistently across sessions without accurate docs; the human cannot reason about the system without them. The incentives align.

### 2.7 Issue tracking inside the codebase

This project keeps issue files in `docs/issues/` — versioned markdown, one file per issue, with a plain-integer counter and a hand-maintained index. This is a deliberate trade-off against external trackers (GitHub Issues, Linear, Jira) and is worth examining explicitly because the AI-assisted context changes the calculus.

**What it gets right:**

*Co-location creates atomicity.* Closing an issue is part of the same commit as the fix. Code state and issue state are always in sync by construction. External trackers fake this with webhooks and commit-message parsing.

*The AI can read it natively.* With an external tracker, the AI would require API calls or copy-pasting to access issue context. With issues as markdown in the repo, the AI reads them as part of the codebase. This is a meaningful advantage in an AI-assisted workflow and partially motivated the design choice.

*Decisions are versioned.* `git log docs/issues/` shows when every issue was opened, when it changed status, when it closed, and which branch was active. That is richer provenance than most external trackers provide.

*No external dependency.* No account management, no data in a third-party system, works offline.

**Where the seams show:**

*The counter file is a serialization point.* Two contributors opening issues simultaneously get a merge conflict on a single-integer file. At solo scale this never occurs. At team scale it is a recurring friction.

*The README index is a conflict magnet* for the same reason — every issue open or close touches the same table.

*No notifications, assignments, or queries.* "Show me all open bugs" is a grep. Adequate when the codebase is familiar; friction for newcomers.

*Discoverability mismatch.* New team members expect issues in GitHub Issues or a project management tool. The `docs/issues/` convention requires explicit onboarding.

**The honest framing:**

This is the ADR (Architecture Decision Record) pattern applied to issue tracking — treating issues as first-class versioned artifacts rather than ephemeral tickets. The trade-off is that external trackers optimize for collaboration features (assignments, notifications, integrations) at the cost of co-location. This project makes the opposite trade, and at solo or small-team scale with an AI pair, it is the right one.

If the team grows past three or four contributors, the counter and README conflicts will motivate tooling: a script that reads the highest existing issue number rather than a single counter file, and a generated index rather than a hand-maintained one.

---

## 3. Failure Modes

### 3.1 Specless prompting

The most common failure: a developer opens an AI session with a vague goal and lets the AI propose the design. The AI produces something plausible. The developer, satisfied with the output, ships it. Six weeks later nobody can explain why the data model looks the way it does.

The fix is the spec-before-prompt norm. It is also the hardest norm to hold because prompting without a spec is faster in the short term.

### 3.2 Review theater

AI output is reviewed with less scrutiny than human output because it "looks right" and arrived quickly. This is the worst of both worlds: the speed advantage of AI combined with the error-detection rate of no review.

The fix is explicit team agreement that AI-generated code receives the same review bar as any other code. The co-author trailer helps — it signals that the reviewer should not assume the author checked their own work.

### 3.3 Architectural drift by accumulation

Each individual AI suggestion is reasonable. Across many sessions, the accumulated suggestions pull the architecture in a direction no human decided. This is particularly insidious because no single commit is wrong.

The fix is architecture doc ownership. Each bounded context or sub-document has a human owner. Changes that touch that area are reviewed by the owner, who can see the direction of drift across sessions.

### 3.4 Convergence without discussion (team setting)

Two developers independently prompt the AI on the same design problem and get different answers. Both implement. Neither knows the other was working on it.

The fix is the same as for any design divergence: decisions go through the issue tracker first. If a decision is worth making, it is worth recording. The issue tracker is the synchronization point, not the AI session.

---

## 4. Scaling to a Team

The methodology is already team-shaped at the solo level. The conventions above — issue tracking, conventional commits, architecture documentation, legal gates — are all conventions that a team would apply regardless of AI involvement. The AI-specific additions are minimal.

### 4.1 Shared AI configuration

`CLAUDE.md` is checked in. Every team member's AI instance reads the same rules. This is the primary mechanism for consistent AI behavior across a team. It must be maintained as a living document, not a one-time setup artifact.

The file should explicitly state:
- What the AI may do autonomously (file edits, test runs, documentation updates)
- What requires human decision before the AI proceeds (schema changes, dependency additions, legal-sensitive changes)
- What the AI must refuse to do regardless of instruction (force pushes, bypassing precommit, adding unverified assets)

### 4.2 AI-free zones

Some decisions should not be delegated to an AI session under any circumstances. These should be listed explicitly:
- Technology stack choices
- Data model changes that affect migrations
- Security-sensitive logic
- Anything with customer-facing legal exposure

Writing these down removes ambiguity. A developer who is unsure whether to use AI for a task can check the list.

### 4.3 The productivity claim, calibrated

AI assistance provides meaningful acceleration in two areas: implementation of well-specified features, and recall of codebase context across sessions. It does not accelerate design, does not improve judgment, and does not substitute for domain knowledge.

A team that adopts this methodology should expect: faster time from spec to working implementation; more consistent adherence to project conventions (because the AI reads them); and no change in the rate of good design decisions (because those remain human).

A team that expects AI to substitute for senior engineering judgment will be disappointed on a timeline proportional to the complexity of the problems they face.

---

## 5. The Claim Worth Making

The claim worth making to a colleague, a hiring manager, or a skeptic is not "we go faster with AI." That is table stakes and it elides the actual question.

The actual question is: *does AI involvement degrade the quality of the engineering judgment that produced the codebase?*

The methodology described here is designed to answer: no. The spec is human. The architecture is human. The review is human. The AI executes in a space the human defined, under constraints the human wrote down, with output the human verified. The git history is legible. The decisions are traceable. A new team member can read the issue tracker and the architecture docs and understand why the system is the way it is — without needing to know which lines were written by a human and which by an AI.

That is the standard worth holding.

---

*This document describes the methodology as practiced in The Gibbering Engine project. The conventions cited (CLAUDE.md, docs/workflow.md, docs/testing.md, docs/git-policy.md, docs/legal.md) are live project artifacts.*
