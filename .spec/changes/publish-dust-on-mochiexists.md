status: done
files: .spec/changes/publish-dust-on-mochiexists.md, docs/publish-dust-on-mochiexists.md, .spec/sod-report.md, README.md, docs/viewer.html

# Publish dust on mochiexists

## What
Capture a durable publishing recommendation for `spec-of-dust` itself. The note should record the public-facing naming decision to present the workflow as `dust` on `mochiexists.com`, recommend changing the Mochi homepage label from `clawpost` to `post`, and cite the public evidence used to identify the Mochi GitHub owner via the live site.

## Acceptance criteria
- [ ] A new docs note records the current recommendation to publish `spec-of-dust` publicly as `dust` at `mochiexists.com/dust` while keeping `spec-of-dust` as the repo/product name
- [ ] The docs note records that the live Mochi homepage currently lists `clawpost`, `plate`, `story`, and `yolo`, and recommends changing the homepage label from `clawpost` to `post`
- [ ] The docs note records the evidence trail for the public GitHub owner discovery: `https://mochiexists.com/yolo` links to `https://github.com/mochiexists/yolo`, which establishes `mochiexists` as the public GitHub owner even though the local homepage source was not identified in the current workspace

## Notes
- This is a repo-internal publishing note, not an implementation inside the Mochi site repo
- Keep the note short and factual so it can be reused when the site repo is located later

## Peer spec review
**Claude** (2026-04-17):

Verdict: no blockers. The change is clear and appropriately scoped as a documentation-only note.

- Advisory: include a date in the note so future readers know when the public evidence was gathered
- Advisory: `docs/` creation is acceptable if the file does not already exist
- Advisory: the prefilled closure section can stay minimal, but it should only be treated as final when the change reaches `done`


## Peer code review
**Claude** (2026-04-17):

Verdict: no blockers. The diff is clean and matches the spec.

- The docs note covers the `dust` recommendation at `mochiexists.com/dust` while keeping `spec-of-dust` as the repo name
- The homepage section lists `clawpost`, `plate`, `story`, and `yolo`, then recommends `clawpost` -> `post`
- The evidence trail records `mochiexists.com/yolo` -> `github.com/mochiexists/yolo`
- Generated `sod` outputs stayed consistent once the new files were staged before rerunning the report


## Verify
- [pass] A new docs note records the current recommendation to publish `spec-of-dust` publicly as `dust` at `mochiexists.com/dust` while keeping `spec-of-dust` as the repo/product name
  Verified in `docs/publish-dust-on-mochiexists.md` under `Recommendation`.
- [pass] The docs note records that the live Mochi homepage currently lists `clawpost`, `plate`, `story`, and `yolo`, and recommends changing the homepage label from `clawpost` to `post`
  Verified in `docs/publish-dust-on-mochiexists.md` under `Homepage copy`.
- [pass] The docs note records the evidence trail for the public GitHub owner discovery: `https://mochiexists.com/yolo` links to `https://github.com/mochiexists/yolo`, which establishes `mochiexists` as the public GitHub owner even though the local homepage source was not identified in the current workspace
  Verified in `docs/publish-dust-on-mochiexists.md` under `Evidence trail` and `Current limitation`.


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: the only real wrinkle was that `sod` had to be regenerated after staging the new docs file because the report counts tracked files, not unstaged additions
- Learnings: for docs-only additions in this repo, stage the new tracked file before rerunning `scripts/update-sod-report.sh`
- Outcomes: the repo now has a dated publishing note recommending `mochiexists.com/dust`, a homepage label change from `clawpost` to `post`, and a public evidence trail for the `mochiexists` GitHub owner
- Dust: A small name can still carry the whole workflow.
