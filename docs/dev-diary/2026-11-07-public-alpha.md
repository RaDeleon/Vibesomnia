# Opening the repo while it is still alpha

- Date: November 7, 2026 (America/Los_Angeles)
- Version: alpha.5; no application code changed for this decision
- Stage: Public repository notes, not a published angelodeleon.com article

## The decision

The original plan was to keep Vibesomnia private until acceptance testing was
complete. After the first closed-lid observation, installer build and private
prerelease, Angelo explicitly asked to make the repository public now.

This changes who can see the work. It does not turn the alpha into a beta or
establish that the remaining tests have passed. The existing installer is still
unsigned and unnotarized, and installation, repeated lid cycles, remote interaction
and wider hardware compatibility remain acceptance work.

## What becomes visible

Public visibility exposes repository history, branches, the draft PR, development
diary and the existing alpha.5 prerelease assets. The diary is source material for
future website posts; no article is automatically published to angelodeleon.com.

A targeted pre-publication check covered 126 historical text blobs for common
credential patterns and personal absolute paths, with no matches. This is evidence
of a bounded hygiene check, not a complete security review or a claim that the app
has no vulnerabilities.

## An unfinished presentation detail

The default branch still contains the initial README. The complete application,
illustrated README and current documentation are on the feature branch in draft
PR #1. Changing visibility does not merge that PR. The release uses the existing
alpha.5 source tag; no release tag or binary was replaced.

## A useful future post angle

What does “public” mean for an unfinished utility that changes sleep behavior?
This milestone is about showing the work with honest limits. A useful follow-up
will explain which tests were complete at publication and which later changed
confidence in the app. Avoid describing openness itself as a quality certification.

## Evidence

- [Alpha.5 prerelease](https://github.com/RaDeleon/Vibesomnia/releases/tag/v0.1.0-alpha.5)
- [Draft PR #1](https://github.com/RaDeleon/Vibesomnia/pull/1)
- [Remaining acceptance tests](../TESTING.md)
- [Engineering log](../../sessions.log)

## Integration follow-up

Later that evening, Angelo explicitly requested merging all remaining repository
work. PR #1 is the only open PR; the icon and alpha.1 branches are ancestors of
its feature branch. A merge commit preserves those relationships and the source
release tags. The PR records the integration result and CI status. This brings
the public-facing repository toward the complete app and README without treating
code integration as acceptance testing or changing the alpha designation.
