# Resource Directory card redesign — approved implementation brief

## Preserve
- Existing fixed Community Hub / Ask the Village header, navigation and sign-in gate.
- Existing resource categories and category imagery.
- Existing Firestore-backed resource data; never invent listing counts, feedback, or verification dates.

## Responsive presentation
- Match approved warm cream and forest-green visual reference, rounded white cards, photography, colored category tags.
- 3 columns on wide desktop; 2 on tablet if space permits; 1 on phone.
- Search field, category chips, state and ZIP filtering.
- Each card: category, coverage, photo, name, description, eligibility/service area, last verified if confirmed, helpfulness, Save / Share / Report, View Program Details.
- Detail view exposes complete listing and links; accessible touch targets.

## Data and behavior
- Save toggles private bookmark for signed-in member; provide My Saved Resources.
- Share invokes native share sheet when available, otherwise a clear share-link fallback. Deep link respects authentication.
- Report creates moderated report (outdated, broken link, closed, incorrect, other) without auto-removing listing.
- Helpfulness vote is unique by member and resource, can be changed, with optional reason for negative feedback (unavailable, ineligible, no response, incorrect).
- Show percentage only after >=5 total votes; before then say 'Not enough community feedback yet.'
- 'Last verified' must be written only after real authorized verification, never on vote or report.
- Protect Firestore documents against vote manipulation and unauthorized verification changes.
- Keep reporting identities private and avoid exposing member IDs in aggregate results.

## Acceptance checks
- iPhone, iPad, desktop responsive layouts; fixed header unchanged.
- Signed-out visitor cannot view resource directory or deep-linked resource details.
- Save, unsave, reload; share sheet; report form; negative feedback reasons; change vote; minimum-5 display; verification permission.
- Filter by category, state, ZIP; no false results or placeholder stats.
- No regression to Community Hub navigation or existing resources.
- Test on preview branch before merging and publishing.
