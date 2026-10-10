# Resource Directory — approved Browse by Category design

Design reference: user-approved left-side mobile mockup from October 10, 2026.

## Scope
- Replace only the browsing surface within the existing Community Hub > Resources / Find Help flow. Do not alter other tabs, shell header, bottom navigation, or Village Promise.
- Show a warm hero title "Resource Directory", subtitle "Find free and low-cost programs and services in your area", search input ("What do you need help with?"), state selector and county/ZIP filter.
- Under "Browse by Category", render a responsive grid of all 12 sections defined in `app/data/resource-taxonomy.json`, preserving their order. Three columns on phone if readable; adapt on larger screens. Cards use distinct soft pastel backgrounds, category icon, clear label and chevron.
- On tap, open category detail showing the associated subcategories and real resource results, respecting current data sources and navigation.
- Do not display counts unless computed from actual matching resource records. Never display subcategory totals as resource counts.
- Preserve current free guest access to two full results before inviting free signup; never gate emergency/crisis information.
- Use real state/county/ZIP eligibility; do not claim programs operate statewide based only on a nationwide organization name.
- Accessibility: screen-reader labels, 44pt+ tap targets, text scaling, adequate contrast, keyboard support.
- No placeholder providers, invented verified badges, or fake availability.

## Acceptance tests
1. All 12 categories appear, including Little Villagers.
2. Search and state filters affect real results.
3. Category tap navigates to matching results, with no duplicate program records.
4. Existing Community Hub and other tabs remain unchanged.
5. iPhone, iPad and desktop layouts render without clipped images or overflowing cards.
6. Guest preview shows two results; crisis contacts remain accessible without login.

Status: design specification committed; UI integration and verification are separate pending work.
