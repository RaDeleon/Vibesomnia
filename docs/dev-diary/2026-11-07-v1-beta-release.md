# Giving the beta a clear download

Date: 2026-11-07 · Status: unpublished website notes · Version: 1.0.0-beta.1

The owner approved the V1.0 beta milestone and asked to merge remaining work and
publish a release with an installer. The previous alpha.5 prerelease existed on
the Releases page, but the main sidebar showed tags rather than its version.
V1.0 — Beta 1 is therefore a normal GitHub release marked Latest, with the beta
stage retained in its title, app version and notes. That visibility setting does
not imply a stable or notarized build.

The beta includes actual power-state verification and a dashboard switch that
controls current protection. The owner visually confirmed the alpha.6 switch
was ON while system and CLI checks agreed. Repeated physical lid/remote testing
remains incomplete.

A further report that another app handled sleep exposed a second problem: an
old alpha.5 preview copy was running instead of the updated bundle. The global
sleep override was enabled with no owned guard. This does not identify which
utility set it. Clearing unowned state requires owner confirmation with the lid
open, since restoring normal sleep while closed could disconnect the session.
The installation goal is one current app in Applications and obsolete copies in
Trash, while preserving preferences and user-authored add-ons.

The package path previously accepted alpha versions only. It now supports beta
and verifies the package version, full app version, bundle build number and CLI
version together. Signing and notarization remain unfinished; the distributed
beta explicitly discloses that limitation.

Possible article angle: finding a release and finding the right installed app
are both part of the product. A technically correct build is not enough if users
keep opening an older copy or cannot find its download.

## Follow-up: one installed app and an explicit backlog

The owner chose to leave the unowned system sleep override enabled and defer
investigation. [Issue #3](https://github.com/RaDeleon/Vibesomnia/issues/3) records
what was observed and how to investigate without adopting or clearing unknown
state automatically.

With the lid open, the older app quit gracefully and the beta package installed
successfully into Applications. Three obsolete app copies and the old alpha
installer/checksum were moved to Trash. The installed app's metadata, CLI and
signature were verified; only the Applications copy was running afterward.
Status reported no active Vibesomnia session, and the global sleep override
remained enabled. This resolves local version ambiguity while leaving the cause
of the external/unowned setting open for later work.
