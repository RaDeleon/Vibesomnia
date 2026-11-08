# Contributing to Vibesomnia

Thanks for helping build a utility for the one-more-commit crowd.

## Start here

1. Read the README and roadmap. Check existing issues before starting a large change.
2. Fork/clone, create a feature branch, and run `swift test`.
3. Make one coherent change and verify it with the local app build.
4. Update the changelog, docs, and relevant tests; describe actual validation in the PR.

Use SwiftUI, native macOS patterns, focused files, and small explicit service
boundaries. Follow AGENTS.md for build, power ownership, remote-control, version,
and documentation rules. Agent sessions also append to sessions.log.

## Reports that help

Include macOS version, Mac architecture, Vibesomnia version, session mode,
charger/external-display conditions, exact reproduction steps, and expected versus
actual results. Redact usernames, paths, hostnames, tokens, and chat contents.
Do not run private conversations or credentials through issue templates.

## Licensing

The current project is AGPL-3.0-only. Contributions are submitted under that
license unless a separate agreement is explicitly accepted. No contributor
copyright assignment or proprietary relicensing right is implied.
Community/Pro separation is deferred; any later contributor-rights policy must be
resolved before relying on contributed code in a differently licensed product.

## Releases

Alpha versions may change behavior and interfaces. Beta requires the documented
acceptance gates and the owner's explicit approval. Only claim checks you ran;
hardware and remote-access validation must be reported separately from unit tests.
