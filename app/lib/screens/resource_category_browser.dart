import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResourceBrowseCategory {
  const ResourceBrowseCategory(this.title, this.icon, this.tint, this.subcategories);
  final String title;
  final IconData icon;
  final Color tint;
  final List<String> subcategories;
}

/// Browse-only navigation. Resource filtering remains in FindHelpScreen.
class ResourceCategoryBrowser extends StatefulWidget {
  const ResourceCategoryBrowser({super.key, required this.onExplore});
  final void Function(String category) onExplore;

  @override
  State<ResourceCategoryBrowser> createState() => _ResourceCategoryBrowserState();
}

class _ResourceCategoryBrowserState extends State<ResourceCategoryBrowser> {
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  ResourceBrowseCategory? selected;

  static const categories = <ResourceBrowseCategory>[
  ResourceBrowseCategory('Housing & Home Assistance', Icons.home_outlined, Color(0xFFFFE4D9), ['Emergency shelters & temporary housing', 'Rent, mortgage & eviction assistance', 'Home repairs, accessibility & weatherization', 'Furniture, appliances & household essentials', 'Homelessness day services & hygiene', 'Emergency displacement & house-fire recovery']),
  ResourceBrowseCategory('Food, Clothing & Basic Needs', Icons.restaurant_outlined, Color(0xFFE3F4E6), ['Food pantries, groceries & meal programs', 'Clothing, shoes & community closets', 'Personal care, haircuts & hygiene supplies', 'Laundry, showers & essential services', 'Free goods, exchanges & equipment lending']),
  ResourceBrowseCategory('Money, Bills & Financial Support', Icons.account_balance_wallet_outlined, Color(0xFFFFEACD), ['Emergency grants & financial assistance', 'Utilities, energy & water bills', 'Debt, credit & financial counseling', 'Government benefits & public assistance', 'Free tax preparation & financial education']),
  ResourceBrowseCategory('Health, Mental Health & Recovery', Icons.favorite_border_rounded, Color(0xFFFFDEE3), ['Free and affordable healthcare', 'Dental, vision & hearing assistance', 'Mental health, counseling & emotional support', 'Addiction treatment & recovery', 'Medication, medical devices & assistive technology', 'Disability, brain injury & trauma support']),
  ResourceBrowseCategory('Little Villagers — Kids & Teens', Icons.child_care_outlined, Color(0xFFEAD9FB), ['Free books, literacy & tutoring', 'School supplies, backpacks & technology', 'Children\'s clothing, shoes & special-occasion outfits', 'Beds, cribs, diapers & baby essentials', 'School meals & youth food programs', 'Free sports, swimming & equipment', 'Arts, music, STEM & creative programs', 'Camps, after-school care & mentoring', 'Free museums, outings & youth experiences', 'Children\'s health & developmental services', 'Birthdays, holidays, toys & gifts', 'Teen jobs, scholarships & college preparation']),
  ResourceBrowseCategory('Parenting, Family & Relationships', Icons.family_restroom_outlined, Color(0xFFDEEEFD), ['Pregnancy, postpartum & lactation support', 'Childcare & daycare assistance', 'Parenting classes & family support', 'Marriage, couples & family counseling', 'Foster care, adoption & kinship support', 'Family respite & caregiver relief']),
  ResourceBrowseCategory('Jobs, Education & Business', Icons.school_outlined, Color(0xFFDEF3E8), ['Job placement, resumes & interview support', 'Free job training, certifications & licensing', 'Work clothing, tools & transportation support', 'GED, adult literacy, ESL & higher education', 'Business grants, entrepreneurship & mentoring']),
  ResourceBrowseCategory('Transportation & Technology', Icons.directions_car_outlined, Color(0xFFDCEEFF), ['Bus passes, medical rides & transportation assistance', 'Car repairs, driving lessons & license assistance', 'Affordable internet, phones & computers', 'Digital skills, online learning & technology safety']),
  ResourceBrowseCategory('Legal, Safety & Life Transitions', Icons.gavel_outlined, Color(0xFFFFE8D3), ['Free legal aid & consumer protection', 'Domestic violence, trafficking & abuse survivor support', 'Immigration, refugee & identity-document assistance', 'Reentry & incarceration-related family support', 'Grief, funeral & end-of-life assistance']),
  ResourceBrowseCategory('Specialized Community Support', Icons.diversity_3_outlined, Color(0xFFFFE1E5), ['Veterans & military families', 'Seniors & aging services', 'Men\'s and women\'s support programs', 'LGBTQ+ community support', 'Foster youth & young adult independence', 'Support for hospitalized patients & families']),
  ResourceBrowseCategory('Emergencies & Disaster Relief', Icons.health_and_safety_outlined, Color(0xFFEAD9FA), ['Hurricane, flood, fire & disaster recovery', 'Crisis hotlines & immediate safety assistance']),
  ResourceBrowseCategory('Community, Recreation & Pets', Icons.pets_outlined, Color(0xFFE9F2DF), ['Free community events, festivals & entertainment', 'Community gardens, seed libraries & food-growing support', 'Volunteer programs, repair cafés & skill exchanges', 'Social connection, cultural programs & recreation', 'Pet food, veterinary assistance & animal support']),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matching = categories;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (selected != null) ...[
        TextButton.icon(
          onPressed: () => setState(() => selected = null),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('All categories'),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDFCC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(selected!.icon, color: const Color(0xFFDE743F), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(selected!.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20, height: 1.2,
                  fontWeight: FontWeight.w700, color: ink)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Text('Explore support options', style: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 8),
        const Text('Choose a topic to explore available assistance.'),
        const SizedBox(height: 14),
        for (final subcategory in selected!.subcategories)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              title: Text(subcategory, style: const TextStyle(fontSize: 14)),
              leading: CircleAvatar(backgroundColor: const Color(0xFFFFE4D4), child: Icon(selected!.icon, color: const Color(0xFFB56E4C))),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => widget.onExplore(selected!.title),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => widget.onExplore(selected!.title),
          icon: const Icon(Icons.search),
          label: const Text('Browse currently listed resources'),
          style: FilledButton.styleFrom(backgroundColor: sage),
        ),
      ] else ...[
        Text('Browse by Category', style: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 5),
        const Text('12 categories · 67 subcategories',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF626A63))),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 300
              ? 1
              : constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 760
                      ? 3
                      : 2;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          const labels = [
            'Housing', 'Basic Needs', 'Money', 'Health',
            'Kids & Teens', 'Family', 'Jobs & Education',
            'Transport & Tech', 'Legal & Safety', 'Specialized Support',
            'Emergencies', 'Community & Pets',
          ];
          const iconColors = [
            Color(0xFFE97643), Color(0xFF319449), Color(0xFFD99A05),
            Color(0xFFE93463), Color(0xFF7948C9), Color(0xFF1386C4),
            Color(0xFF12845B), Color(0xFF1679C6), Color(0xFFB87715),
            Color(0xFFDE5673), Color(0xFF7140B7), Color(0xFF4A963C),
          ];
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in matching)
                SizedBox(
                  width: width,
                  child: Semantics(
                    button: true,
                    label: 'Browse ${category.title}',
                    excludeSemantics: true,
                    child: Tooltip(
                      message: category.title,
                      child: Material(
                        color: const Color(0xFFFFFAF1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                          side: const BorderSide(color: Color(0xFFD8CFC1)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setState(() => selected = category),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 52),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                              child: Row(children: [
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: category.tint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    category.icon,
                                    size: 22,
                                    color: iconColors[categories.indexOf(category)],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    labels[categories.indexOf(category)],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: ink, fontSize: 12, height: 1.2),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        if (matching.isEmpty)
          const Padding(padding: EdgeInsets.all(18),
            child: Text('No matching categories. Try a different search.')),
      ],
    ]);
  }
}
