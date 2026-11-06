import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_content_service.dart';
import 'resource_category_browser.dart';
import 'guided_help_assistant.dart';

class _SelectedStatePainter extends CustomPainter {
  const _SelectedStatePainter(this.statePath, this.color);
  final Path statePath;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 959, size.height / 593);
    canvas.translate(-174, -100);
    canvas.drawPath(statePath, Paint()..color = color.withValues(alpha: 0.82));
    canvas.drawPath(statePath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SelectedStatePainter oldDelegate) =>
      oldDelegate.statePath != statePath || oldDelegate.color != color;
}

class FindHelpScreen extends StatefulWidget {
  const FindHelpScreen({super.key});

  @override
  State<FindHelpScreen> createState() => _FindHelpScreenState();
}

class _FindHelpScreenState extends State<FindHelpScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final admin = AdminContentService();
  final zipController = TextEditingController();
  final directorySearchController = TextEditingController();
  final directoryResultsKey = GlobalKey();
  final stateResultsKey = GlobalKey();
  String directoryQuery = '';
  int view = 0;
  bool guidedHelp = false;
  String? selectedState;
  String? selectedNeed;
  Set<String> saved = {};
  bool showMap = false;
  Map<String, Path> stateShapes = {};
  final mapTransform = TransformationController();
  bool showAllResources = false;
  String? selectedPathId;
  String? localZip;
  String? providerFilter;
  String? areaFilter;
  String? costFilter;
  String eligibilityFilter = '';
  bool allCategoriesOpen = false;

  static const stateNames = <String, String>{
    'AL':'Alabama','AK':'Alaska','AZ':'Arizona','AR':'Arkansas','CA':'California',
    'CO':'Colorado','CT':'Connecticut','DE':'Delaware','FL':'Florida','GA':'Georgia',
    'HI':'Hawaii','ID':'Idaho','IL':'Illinois','IN':'Indiana','IA':'Iowa',
    'KS':'Kansas','KY':'Kentucky','LA':'Louisiana','ME':'Maine','MD':'Maryland',
    'MA':'Massachusetts','MI':'Michigan','MN':'Minnesota','MS':'Mississippi',
    'MO':'Missouri','MT':'Montana','NE':'Nebraska','NV':'Nevada','NH':'New Hampshire',
    'NJ':'New Jersey','NM':'New Mexico','NY':'New York','NC':'North Carolina',
    'ND':'North Dakota','OH':'Ohio','OK':'Oklahoma','OR':'Oregon','PA':'Pennsylvania',
    'RI':'Rhode Island','SC':'South Carolina','SD':'South Dakota','TN':'Tennessee',
    'TX':'Texas','UT':'Utah','VT':'Vermont','VA':'Virginia','WA':'Washington',
    'WV':'West Virginia','WI':'Wisconsin','WY':'Wyoming',
  };

  static const needs = <(String, IconData)>[
    ('Food', Icons.restaurant_outlined),
    ('Rent & Housing', Icons.home_outlined),
    ('Utilities', Icons.lightbulb_outline_rounded),
    ('Healthcare', Icons.medical_services_outlined),
    ('Childcare', Icons.child_care_outlined),
    ('Transportation', Icons.directions_bus_outlined),
    ('Employment', Icons.work_outline_rounded),
    ('Legal Help', Icons.gavel_outlined),
    ('Crisis & Safety', Icons.health_and_safety_outlined),
  ];

  static const helpPaths = <HelpPath>[
    HelpPath('food', 'Food or groceries', 'Find food pantries, meals, SNAP and grocery support.', Icons.restaurant_outlined, ['Food']),
    HelpPath('housing', 'Rent, bills or housing', 'Get help with rent, shelter, utilities and keeping your home.', Icons.home_outlined, ['Rent & Housing', 'Utilities']),
    HelpPath('family', 'Health, family or childcare', 'Find healthcare, childcare, transportation and family support.', Icons.favorite_border_rounded, ['Healthcare', 'Childcare', 'Transportation']),
    HelpPath('work', 'Work, legal or other support', 'Get connected to jobs, legal aid, safety planning and someone who can help.', Icons.handshake_outlined, ['Employment', 'Legal Help', 'Crisis & Safety']),
  ];

  static const builtIns = <HelpResource>[
    HelpResource(
      id: "fl-myaccess",
      title: "MyACCESS — SNAP, Medicaid & Cash Assistance",
      description: "Florida’s application portal for food benefits, Medicaid and temporary cash assistance.",
      needs: ["Food", "Healthcare", "Utilities"],
      states: ["FL"],
      url: "https://myaccess.myflfamilies.com/",
      serviceArea: "Florida statewide",
      eligibility: "Rules differ by benefit and household circumstances; DCF determines eligibility.",
      howToApply: "Apply through MyACCESS; use the DCF public-assistance page for local application help.",
      cost: "Free application",
      phone: "",
      sourceUrls: ["https://myaccess.myflfamilies.com/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-wic",
      title: "Florida WIC",
      description: "Nutrition benefits, breastfeeding support and referrals for pregnant or postpartum women, infants and young children.",
      needs: ["Food", "Healthcare", "Childcare"],
      states: ["FL"],
      url: "https://www.floridahealth.gov/individual-family-health/womens-health/wic/",
      serviceArea: "Florida statewide",
      eligibility: "Florida residents who meet WIC income and nutrition requirements; children must be under five.",
      howToApply: "Contact your county WIC office for a certification appointment.",
      cost: "No cost for eligible participants",
      phone: "800-342-3556",
      sourceUrls: ["https://www.floridahealth.gov/individual-family-health/womens-health/wic/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-ship",
      title: "SHIP — Local Housing Assistance",
      description: "Local housing programs may assist with repairs, homeownership or rental needs. Available assistance varies by locality.",
      needs: ["Rent & Housing"],
      states: ["FL"],
      url: "https://www.floridahousing.org/programs/special-programs/ship---state-housing-initiatives-partnership-program/local-government-information",
      serviceArea: "Florida statewide",
      eligibility: "Local income, property and program requirements apply.",
      howToApply: "Choose your participating city; otherwise choose your county. Ask the local SHIP office about open programs and waitlists.",
      cost: "Assistance terms vary; some support may be loans rather than grants",
      phone: "",
      sourceUrls: ["https://www.floridahousing.org/programs/special-programs/ship---state-housing-initiatives-partnership-program/local-government-information", "https://www.floridahousing.org/buyers-renters/local-housing-programs"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-liheap",
      title: "LIHEAP — Energy Bill Assistance",
      description: "Find the local agency handling help with home heating and cooling bills.",
      needs: ["Utilities"],
      states: ["FL"],
      url: "https://floridajobs.org/community-development/Low-Income-Home-Energy-Assistance-Program/find-your-local-low-income-home-energy-assistance-program-provider-for-help",
      serviceArea: "Florida statewide",
      eligibility: "Income-qualified households; local funding and documentation rules apply.",
      howToApply: "Find your county provider and use its application link or call the agency.",
      cost: "Assistance subject to eligibility and available funds",
      phone: "",
      sourceUrls: ["https://floridajobs.org/community-development/Low-Income-Home-Energy-Assistance-Program/find-your-local-low-income-home-energy-assistance-program-provider-for-help"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-csbg",
      title: "Community Services Block Grant Assistance",
      description: "Local agencies provide services that may include basic needs, employment support and help stabilizing household finances.",
      needs: ["Food", "Rent & Housing", "Utilities", "Employment", "Transportation"],
      states: ["FL"],
      url: "https://www.floridajobs.org/community-development/community-services-block-grant-program/find-your-community-services-block-grant-program-provider-for-help",
      serviceArea: "Florida statewide",
      eligibility: "Income-qualified households; available services differ by county.",
      howToApply: "Contact the listed provider serving your county to request screening.",
      cost: "Ask local provider about services and funding",
      phone: "",
      sourceUrls: ["https://www.floridajobs.org/community-development/community-services-block-grant-program/find-your-community-services-block-grant-program-provider-for-help"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-weatherization",
      title: "Weatherization — Home Energy Improvements",
      description: "Local weatherization offices assess eligible homes for improvements that reduce energy use.",
      needs: ["Rent & Housing", "Utilities"],
      states: ["FL"],
      url: "https://www.floridajobs.org/community-development/Weatherization-Assistance-Program/contact-your-local-weatherization-office-for-help",
      serviceArea: "Florida statewide",
      eligibility: "Low-income households; home assessment and local program rules apply.",
      howToApply: "Contact the weatherization office listed for your county to apply.",
      cost: "Program assistance for eligible households",
      phone: "",
      sourceUrls: ["https://www.floridajobs.org/community-development/Weatherization-Assistance-Program/contact-your-local-weatherization-office-for-help"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-school-readiness",
      title: "School Readiness — Childcare Assistance",
      description: "Financial assistance for eligible families needing early education and childcare.",
      needs: ["Childcare"],
      states: ["FL"],
      url: "https://familyservices.floridaearlylearning.com/",
      serviceArea: "Florida statewide",
      eligibility: "Low-income families meeting School Readiness requirements; local coalitions determine eligibility and placement.",
      howToApply: "Create a Family Portal account and apply; contact your early learning coalition for help.",
      cost: "Family copayments and waiting lists may apply",
      phone: "",
      sourceUrls: ["https://familyservices.floridaearlylearning.com/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-kidcare",
      title: "Florida KidCare — Children’s Health Coverage",
      description: "Apply for children’s health and dental insurance through Florida’s coverage programs.",
      needs: ["Healthcare", "Childcare"],
      states: ["FL"],
      url: "https://www.floridakidcare.org/",
      serviceArea: "Florida statewide",
      eligibility: "Children under 19; eligibility and premiums depend on the applicable program and household circumstances.",
      howToApply: "Apply through the linked Parent Portal or request a paper application by phone.",
      cost: "Application is free; coverage may be free, subsidized or full-pay",
      phone: "888-540-5437",
      sourceUrls: ["https://www.floridakidcare.org/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-career",
      title: "CareerSource — Local Career Centers",
      description: "Find local assistance with resumes, interviewing, job searches and training opportunities.",
      needs: ["Employment"],
      states: ["FL"],
      url: "https://careersourceflorida.com/career-services/",
      serviceArea: "Florida statewide",
      eligibility: "Job seekers; eligibility for funded training varies.",
      howToApply: "Use Find Your Local Team and contact your local career center.",
      cost: "Ask the local center about training eligibility and costs",
      phone: "",
      sourceUrls: ["https://careersourceflorida.com/career-services/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-legal-directory",
      title: "Florida Courts — Legal Aid Directory",
      description: "Official links to statewide and regional civil legal aid organizations.",
      needs: ["Legal Help"],
      states: ["FL"],
      url: "https://www.flcourts.gov/Services/Family-Courts/self-help-information/Legal-Aid",
      serviceArea: "Florida statewide",
      eligibility: "Each organization screens for location, income and type of civil legal matter.",
      howToApply: "Choose a provider serving your county and follow its intake process.",
      cost: "Free or reduced-cost assistance depending on provider",
      phone: "",
      sourceUrls: ["https://www.flcourts.gov/Services/Family-Courts/self-help-information/Legal-Aid"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-elder",
      title: "Elder Helpline — Aging & Caregiver Services",
      description: "Connect with local aging services, caregiver support and community assistance.",
      needs: ["Healthcare", "Food", "Transportation", "Specialized Support"],
      states: ["FL"],
      url: "https://elderaffairs.org/about-us/elder-helpline-1-800-963-5337/",
      serviceArea: "Florida statewide",
      eligibility: "Older adults and caregivers; each service has its own eligibility criteria.",
      howToApply: "Call the statewide helpline or use the county contact list.",
      cost: "Referrals; service costs and waitlists vary",
      phone: "800-963-5337",
      sourceUrls: ["https://elderaffairs.org/about-us/elder-helpline-1-800-963-5337/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-senior-legal",
      title: "Florida Senior Legal Helpline",
      description: "Telephone advice and brief help with eligible civil legal problems.",
      needs: ["Legal Help", "Specialized Support"],
      states: ["FL"],
      url: "https://elderaffairs.org/programs-and-services/florida-senior-legal-helpline/",
      serviceArea: "Florida statewide",
      eligibility: "Eligible Florida residents age 60 or older who meet income and other screening rules.",
      howToApply: "Call for intake and a telephone appointment. Criminal and traffic matters are excluded.",
      cost: "Free for eligible callers",
      phone: "888-895-7873",
      sourceUrls: ["https://elderaffairs.org/programs-and-services/florida-senior-legal-helpline/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-shine",
      title: "SHINE — Medicare Insurance Counseling",
      description: "Confidential counseling helps Medicare beneficiaries and caregivers understand health coverage.",
      needs: ["Healthcare", "Specialized Support"],
      states: ["FL"],
      url: "https://elderaffairs.org/contact-us/",
      serviceArea: "Florida statewide",
      eligibility: "Medicare beneficiaries, their families and caregivers.",
      howToApply: "Call the Elder Helpline and request SHINE counseling.",
      cost: "Free counseling",
      phone: "800-963-5337",
      sourceUrls: ["https://elderaffairs.org/contact-us/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-veterans",
      title: "Florida Veterans — Benefits & Service Officers",
      description: "Accredited state and county officers help veterans navigate earned benefits and claims.",
      needs: ["Specialized Support", "Healthcare", "Employment"],
      states: ["FL"],
      url: "https://floridavets.org/benefits-services/",
      serviceArea: "Florida statewide",
      eligibility: "Veterans and eligible family members; benefit requirements vary.",
      howToApply: "Use the county service-office links or contact FDVA for benefits counseling.",
      cost: "Free claims assistance",
      phone: "727-319-7440",
      sourceUrls: ["https://floridavets.org/benefits-services/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-transport",
      title: "Transportation Disadvantaged — County Coordinators",
      description: "Find shared rides for residents who cannot drive or obtain other transportation because of age, disability or income.",
      needs: ["Transportation", "Specialized Support"],
      states: ["FL"],
      url: "https://www.fdot.gov/ctd/community-transportation-coordinators",
      serviceArea: "Florida statewide",
      eligibility: "County coordinators determine eligibility for transportation-disadvantaged services.",
      howToApply: "Call the Find a Ride number for your county; advance reservations are generally required.",
      cost: "A rider fare may apply",
      phone: "",
      sourceUrls: ["https://www.fdot.gov/ctd/community-transportation-coordinators", "https://www.fdot.gov/ctd/aboutus/communitytransystem"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-apd",
      title: "Agency for Persons with Disabilities — Apply for Services",
      description: "Application and local office information for developmental disability supports.",
      needs: ["Healthcare", "Specialized Support"],
      states: ["FL"],
      url: "https://apd.myflorida.com/services/apply.htm",
      serviceArea: "Florida statewide",
      eligibility: "APD reviews qualifying developmental disability and other program requirements.",
      howToApply: "Follow the official online or paper application instructions; submit supporting records.",
      cost: "Eligibility, enrollment and service availability vary",
      phone: "",
      sourceUrls: ["https://apd.myflorida.com/services/apply.htm"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-early-steps",
      title: "Early Steps — Infant & Toddler Development",
      description: "Early intervention support for infants and toddlers with qualifying developmental needs.",
      needs: ["Healthcare", "Childcare"],
      states: ["FL"],
      url: "https://www.floridahealth.gov/individual-family-health/child-infant-youth/",
      serviceArea: "Florida statewide",
      eligibility: "Children from birth to 36 months with qualifying delays, disabilities or at-risk conditions.",
      howToApply: "Open Early Steps from the state health page and request a local referral.",
      cost: "No cost to eligible families",
      phone: "",
      sourceUrls: ["https://www.floridahealth.gov/individual-family-health/child-infant-youth/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-child-support",
      title: "Florida Child Support — Apply for Services",
      description: "Online enrollment for assistance with child support cases.",
      needs: ["Legal Help", "Childcare"],
      states: ["FL"],
      url: "https://floridarevenue.com/childsupport/signup/Pages/Signup.aspx",
      serviceArea: "Florida statewide",
      eligibility: "Parents or caregivers seeking services; DOR explains existing-case and enrollment requirements.",
      howToApply: "Review signup instructions and apply through the linked eServices portal.",
      cost: "Review current program fee rules before enrolling",
      phone: "",
      sourceUrls: ["https://floridarevenue.com/childsupport/signup/Pages/Signup.aspx"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-dv-centers",
      title: "Florida Certified Domestic Violence Centers",
      description: "Find local survivor advocacy, safety planning and shelter-related support.",
      needs: ["Legal Help", "Crisis & Safety", "Rent & Housing"],
      states: ["FL"],
      url: "https://www.myflfamilies.com/services/abuse/domestic-violence/find-your-local-domestic-violence-center/",
      serviceArea: "Florida statewide",
      eligibility: "Survivors and affected families; contact the local center about available support.",
      howToApply: "Find your county’s certified center and contact its advocate using the official listing.",
      cost: "Confirm specific services with the center",
      phone: "",
      sourceUrls: ["https://www.myflfamilies.com/services/abuse/domestic-violence/find-your-local-domestic-violence-center/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-disaster",
      title: "Florida Disaster — Recovery Programs",
      description: "Official starting point for recovery assistance after disasters.",
      needs: ["Crisis & Safety", "Rent & Housing"],
      states: ["FL"],
      url: "https://www.floridadisaster.org/dem/recovery/recovery-programs/",
      serviceArea: "Florida statewide",
      eligibility: "Assistance depends on the disaster declaration, affected location, losses and application period.",
      howToApply: "Select Individual Assistance and follow current disaster-specific instructions.",
      cost: "Program terms vary; some assistance is loan-based",
      phone: "",
      sourceUrls: ["https://www.floridadisaster.org/dem/recovery/recovery-programs/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-feeding-florida",
      title: "Feeding Florida — Statewide Food Bank Finder",
      description: "Find the regional food bank and pantry network serving your county.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://www.feedingflorida.org/find-food-now/",
      serviceArea: "Florida statewide",
      eligibility: "Households needing food; individual distribution requirements vary.",
      howToApply: "Choose your county and follow the regional food bank’s food-finder instructions.",
      cost: "Confirm requirements and current distributions",
      phone: "",
      sourceUrls: ["https://www.feedingflorida.org/find-food-now/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Statewide",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-ne",
      title: "Feeding Northeast Florida",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://feedingnefl.org/find-food-now/",
      serviceArea: "Alachua, Baker, Bradford, Clay, Duval, Flagler, Gilchrist, Levy, Nassau, Putnam, St. Johns and Union counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://feedingnefl.org/find-food-now/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-central",
      title: "Second Harvest Food Bank of Central Florida",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://feedhopenow.org/find-help/food-finder/",
      serviceArea: "Brevard, Lake, Marion, Orange, Osceola, Seminole and Volusia counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://feedhopenow.org/find-help/food-finder/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-gulf",
      title: "Feeding the Gulf Coast",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://www.feedingthegulfcoast.org/find-help",
      serviceArea: "Bay, Escambia, Holmes, Okaloosa, Santa Rosa, Walton and Washington counties in Florida",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://www.feedingthegulfcoast.org/find-help", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-bigbend",
      title: "Second Harvest of the Big Bend",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://fightinghunger.org/find-food/",
      serviceArea: "Calhoun, Columbia, Dixie, Franklin, Gadsden, Gulf, Hamilton, Jackson, Jefferson, Lafayette, Leon, Liberty, Madison, Suwannee, Taylor and Wakulla counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://fightinghunger.org/find-food/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-tampa",
      title: "Feeding Tampa Bay",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/",
      serviceArea: "Citrus, Hardee, Hernando, Highlands, Hillsborough, Manatee, Pasco, Pinellas, Polk and Sumter counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-allfaiths",
      title: "All Faiths Food Bank",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://allfaithsfoodbank.org/foodfinder/",
      serviceArea: "DeSoto and Sarasota counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://allfaithsfoodbank.org/foodfinder/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-treasure",
      title: "Treasure Coast Food Bank",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://stophunger.org/find-support/",
      serviceArea: "Indian River, Martin, Okeechobee and St. Lucie counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://stophunger.org/find-support/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-chapin",
      title: "Harry Chapin Food Bank",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://harrychapinfoodbank.org/find-food/",
      serviceArea: "Charlotte, Collier, Glades, Hendry and Lee counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://harrychapinfoodbank.org/find-food/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-food-south",
      title: "Feeding South Florida",
      description: "Locate food assistance through this regional food bank and its community partners.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://feedingsouthflorida.org/benefits-emergency-services/",
      serviceArea: "Broward, Miami-Dade, Monroe and Palm Beach counties",
      eligibility: "Pantry and program requirements differ by location.",
      howToApply: "Use the food finder or contact the program before traveling. A warehouse may not distribute directly to residents.",
      cost: "Food assistance; confirm each program’s terms",
      phone: "",
      sourceUrls: ["https://feedingsouthflorida.org/benefits-emergency-services/", "https://www.feedingflorida.org/our-network/florida-food-bank-counties-map/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-beam",
      title: "BEAM — Food & Emergency Financial Assistance",
      description: "Food, benefits navigation and limited assistance to help eligible Beaches households maintain stability.",
      needs: ["Food", "Utilities", "Rent & Housing"],
      states: ["FL"],
      url: "https://jaxbeam.org/financial-emergency-assistance-programs/",
      serviceArea: "Jacksonville Beaches service area; confirm eligibility for your address",
      eligibility: "Low-income residents within BEAM’s service area; program-specific screening applies.",
      howToApply: "Use Get Help and review the required documents before requesting assistance.",
      cost: "Financial assistance depends on eligibility and funding",
      phone: "",
      sourceUrls: ["https://jaxbeam.org/financial-emergency-assistance-programs/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-ccjax",
      title: "Catholic Charities Jacksonville — Get Assistance",
      description: "Food support, emergency financial assistance and other family services.",
      needs: ["Food", "Utilities", "Rent & Housing", "Employment"],
      states: ["FL"],
      url: "https://www.ccbjax.org/get-assistance",
      serviceArea: "Jacksonville / Northeast Florida; confirm program coverage",
      eligibility: "Program-specific eligibility and service area apply.",
      howToApply: "For emergency rent, mortgage or utility assistance, first call United Way at 211 or 904-632-0600 for referral.",
      cost: "Funding and service availability vary",
      phone: "904-632-0600",
      sourceUrls: ["https://www.ccbjax.org/get-assistance", "https://www.ccbjax.org/contact"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-sulzbacher",
      title: "Sulzbacher — Housing & Support",
      description: "Housing placement and supportive services for people experiencing or at risk of homelessness.",
      needs: ["Rent & Housing", "Healthcare", "Employment"],
      states: ["FL"],
      url: "https://www.sulzbacherjax.org/permanent-housing",
      serviceArea: "Jacksonville / Duval County",
      eligibility: "Housing eligibility and referral requirements apply.",
      howToApply: "Most housing placements require Duval Coordinated Entry through Changing Homelessness. Contact Sulzbacher for program guidance.",
      cost: "Housing terms depend on the program",
      phone: "904-394-4950",
      sourceUrls: ["https://www.sulzbacherjax.org/permanent-housing"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-mercy",
      title: "Mercy Support Services — Supportive Housing",
      description: "Structured supportive housing, financial coaching and goal planning for families or young adults facing homelessness.",
      needs: ["Rent & Housing", "Utilities", "Employment"],
      states: ["FL"],
      url: "https://www.mercysupportservices.org/self-sufficiency-program",
      serviceArea: "Clay County",
      eligibility: "Requires six months of Clay residency, full-time employment, coaching participation and additional screening.",
      howToApply: "Call to request program information and application requirements.",
      cost: "Program fee is 30% of income",
      phone: "904-297-4052",
      sourceUrls: ["https://www.mercysupportservices.org/self-sufficiency-program"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-jala",
      title: "Jacksonville Area Legal Aid",
      description: "Civil legal help with housing, benefits, family and other eligible matters.",
      needs: ["Legal Help"],
      states: ["FL"],
      url: "https://www.jaxlegalaid.org/apply/",
      serviceArea: "Duval, Clay, St. Johns and Nassau offices; service coverage depends on the case",
      eligibility: "Screening depends on income, location and legal issue.",
      howToApply: "Follow the application page or contact the office serving your county.",
      cost: "Free services for qualifying cases; separate reduced-fee programs also exist",
      phone: "904-356-8371",
      sourceUrls: ["https://www.jaxlegalaid.org/apply/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-metro",
      title: "Metropolitan Ministries — Food & Family Support",
      description: "Groceries, meals, shelter applications and community support in the Tampa Bay area.",
      needs: ["Food", "Rent & Housing", "Employment", "Childcare"],
      states: ["FL"],
      url: "https://www.metromin.org/get-help/",
      serviceArea: "Tampa Bay; program-specific Hillsborough, Pasco, Pinellas and other service areas",
      eligibility: "Each service has location, household and documentation requirements.",
      howToApply: "Select the help needed on the Get Help page; shelter requests require an application and intake.",
      cost: "Eligibility and availability vary",
      phone: "813-209-1200",
      sourceUrls: ["https://www.metromin.org/get-help/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-metro-financial",
      title: "Metropolitan Ministries — Hillsborough Financial Assistance",
      description: "Intake and orientation for households seeking available financial assistance.",
      needs: ["Rent & Housing", "Utilities"],
      states: ["FL"],
      url: "https://www.metromin.org/financial-assistance-for-hillsborough-county/",
      serviceArea: "Hillsborough County",
      eligibility: "County residency and program screening required; booking routes differ by ZIP code.",
      howToApply: "Reserve the required in-person orientation using the link for your ZIP code.",
      cost: "Limited appointments and funds; approval is not guaranteed",
      phone: "",
      sourceUrls: ["https://www.metromin.org/financial-assistance-for-hillsborough-county/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-up-orlando",
      title: "United Against Poverty Orlando — Emergency Food Help",
      description: "Food assistance and help applying for benefits, with referrals to additional support.",
      needs: ["Food"],
      states: ["FL"],
      url: "https://uporlando.org/emergency-food-assistance/",
      serviceArea: "Orlando area",
      eligibility: "Staff assess needs and program eligibility; grocery membership rules apply separately.",
      howToApply: "Contact the Orlando campus for emergency assistance and benefits screening.",
      cost: "Emergency assistance differs from the Member Share grocery program, which charges handling fees",
      phone: "",
      sourceUrls: ["https://uporlando.org/emergency-food-assistance/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-chapman",
      title: "Chapman Partnership — Homelessness Support",
      description: "Housing-focused services and coordinated support for people experiencing homelessness.",
      needs: ["Rent & Housing", "Healthcare", "Employment"],
      states: ["FL"],
      url: "https://chapmanpartnership.org/contact/",
      serviceArea: "Miami-Dade County",
      eligibility: "Coordinated assessment and referral determine access.",
      howToApply: "Start with the Miami-Dade Homeless Helpline. Do not assume direct walk-in placement.",
      cost: "Contact intake about available programs",
      phone: "877-994-4357",
      sourceUrls: ["https://chapmanpartnership.org/contact/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: "fl-pet-tampa",
      title: "Humane Society of Tampa Bay — Pet Food Assistance",
      description: "Pet food support and an application-based delivery option for eligible homebound residents.",
      needs: ["Community & Pets"],
      states: ["FL"],
      url: "https://hstb.org/pet-assistance/",
      serviceArea: "Tampa Bay; confirm service availability",
      eligibility: "Pet owners in need; delivery has separate qualification requirements.",
      howToApply: "Check the current distribution details before visiting; apply separately for home delivery.",
      cost: "Free limited pet food; veterinary services may carry fees",
      phone: "",
      sourceUrls: ["https://hstb.org/pet-assistance/"],
      reviewedAt: "2026-11-05",
      label: "Florida • Local / regional",
      verified: "",
    ),
    HelpResource(
      id: '211',
      title: '211 Essential Community Services',
      description: 'Confidential help finding local food, housing, utility, healthcare, transportation, and other essential services.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Transportation','Employment','Legal Help','Crisis & Safety'],
      url: 'https://www.211.org/',
      phone: '211',
      label: 'Free • Nationwide',
      verified: '',
    ),
    HelpResource(
      id: 'usa-benefits',
      title: 'USA.gov Benefit Finder',
      description: 'Answer a few questions to find government benefits and financial-help programs that may fit your situation.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Employment'],
      url: 'https://www.usa.gov/benefit-finder',
      label: 'Official government resource',
      verified: '',
    ),
    HelpResource(
      id: 'food-help',
      title: 'Government Food Assistance',
      description: 'Learn about SNAP, WIC, emergency food programs, and other ways to get nutritious food.',
      needs: ['Food'],
      url: 'https://www.usa.gov/food-help',
      label: 'Official • Nationwide',
      verified: '',
    ),
    HelpResource(
      id: 'rent-help',
      title: 'Emergency Rent Assistance',
      description: 'Find state and local options for emergency rental assistance and housing support.',
      needs: ['Rent & Housing'],
      url: 'https://www.usa.gov/emergency-pay-rent',
      label: 'Official • Nationwide',
      verified: '',
    ),
    HelpResource(
      id: 'utility-help',
      title: 'Help With Utility Bills',
      description: 'Explore energy, phone, internet, heating, cooling, and weatherization assistance.',
      needs: ['Utilities'],
      url: 'https://www.usa.gov/help-with-utility-bills',
      label: 'Official • Nationwide',
      verified: '',
    ),
    HelpResource(
      id: 'housing-help',
      title: 'USA.gov Housing Help',
      description: 'Find rental assistance, emergency housing, affordable housing, foreclosure, and home-repair information.',
      needs: ['Rent & Housing'],
      url: 'https://www.usa.gov/housing-help',
      label: 'Official • Nationwide',
      verified: '',
    ),
    HelpResource(
      id: 'state-social-services',
      title: 'State Benefits & Social Services',
      description: 'Find your state social service agency for SNAP, cash assistance, Medicaid, childcare help, and other state-run programs.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Employment'],
      url: 'https://www.usa.gov/state-social-services',
      label: 'Official government directory',
      verified: '',
    ),
    HelpResource(
      id: 'emergency-food',
      title: 'Emergency Food Assistance',
      description: 'Find emergency food options, including food pantries, hunger hotlines, disaster food assistance, and local help.',
      needs: ['Food'],
      url: 'https://www.usa.gov/emergency-food-assistance',
      phone: '1-866-348-6479',
      label: 'Official • Nationwide',
      verified: '',
    ),
    HelpResource(
      id: 'health-center',
      title: 'Find a Community Health Center',
      description: 'Search nearby health centers for medical, dental, behavioral-health, vision, and other care.',
      needs: ['Healthcare'],
      url: 'https://findahealthcenter.hrsa.gov/',
      label: 'Official • Local locator',
      verified: '',
    ),
    HelpResource(
      id: 'childcare-referral',
      title: 'Child Care Resource & Referral Search',
      description: 'Find the local organization that helps families locate childcare, financial assistance, and family services.',
      needs: ['Childcare'],
      url: 'https://www.childcareaware.org/resources/ccrr-search/',
      label: 'Nationwide local locator',
      verified: '',
    ),
    HelpResource(
      id: 'jobs-local',
      title: 'American Job Center Finder',
      description: 'Find nearby no-cost help with job searches, training, résumé support, workshops, computers, and employment services.',
      needs: ['Employment'],
      url: 'https://www.careeronestop.org/LocalHelp/AmericanJobCenters/find-american-job-centers.aspx',
      phone: '1-877-872-5627',
      label: 'Official • Local locator',
      verified: '',
    ),
    HelpResource(
      id: 'legal-aid',
      title: 'Free Civil Legal Aid Finder',
      description: 'Search by address or city for nonprofit legal aid for housing, family, benefits, safety, consumer, and other civil matters.',
      needs: ['Legal Help'],
      url: 'https://www.lsc.gov/about-lsc/what-legal-aid/i-need-legal-help',
      label: 'Nationwide nonprofit network',
      verified: '',
    ),
    HelpResource(
      id: '988',
      title: '988 Suicide & Crisis Lifeline',
      description: 'Free, confidential support for mental-health struggles, emotional distress, substance-use concerns, or a crisis. Call, text, or chat.',
      needs: ['Crisis & Safety','Healthcare'],
      url: 'https://988lifeline.org/get-help/',
      phone: '988',
      label: 'Free • 24/7',
      verified: '',
    ),
    HelpResource(
      id: 'local-programs',
      title: 'Search Local Programs & Nonprofits',
      description: 'Enter your ZIP code below to search food pantries, rent help, bills, health care, transportation, job help, and other programs near you.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Transportation','Employment','Legal Help','Crisis & Safety'],
      url: 'https://www.findhelp.org/',
      label: 'Local nonprofit directory',
      verified: '',
    ),
    HelpResource(
      id: 'fl-benefits',
      title: 'Florida Public Assistance',
      description: 'Apply for Florida food assistance, temporary cash assistance, Medicaid, and refugee assistance.',
      needs: ['Food','Healthcare','Childcare','Rent & Housing'],
      states: ['FL'],
      url: 'https://www.myflfamilies.com/services/public-assistance',
      phone: '(850) 300-4323',
      label: 'Florida official resource',
      verified: '',
    ),
    HelpResource(
      id: 'fl-homelessness',
      title: 'Florida Homelessness Assistance',
      description: 'Information about emergency shelter, housing stabilization, rental assistance, and local Continuums of Care.',
      needs: ['Rent & Housing','Crisis & Safety'],
      states: ['FL'],
      url: 'https://www.myflfamilies.com/services/abuse/homelessness',
      phone: '(850) 300-4323',
      label: 'Florida official resource',
      verified: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _loadStateShapes();
  }

  @override
  void dispose() {
    zipController.dispose();
    directorySearchController.dispose();
    mapTransform.dispose();
    super.dispose();
  }

  Future<void> _loadStateShapes() async {
    final svg = await rootBundle.loadString('assets/images/us_states_map.svg');
    final shapes = <String, Path>{};
    final tags = RegExp(r'<path\b[^>]*>', dotAll: true);
    final ids = RegExp(r'\bid="([A-Z]{2})"');
    final paths = RegExp(r'\bd="([^"]+)"', dotAll: true);
    for (final tag in tags.allMatches(svg)) {
      final markup = tag.group(0)!;
      final id = ids.firstMatch(markup)?.group(1);
      final data = paths.firstMatch(markup)?.group(1);
      if (id != null && data != null && stateNames.containsKey(id)) {
        try {
          shapes[id] = parseSvgPathData(data);
        } catch (_) {
          // A malformed shape must not prevent the other states from working.
        }
      }
    }
    if (mounted) setState(() => stateShapes = shapes);
  }

  void _selectStateAndShowResults(String state) {
    setState(() {
      selectedState = state;
      showAllResources = true;
      directoryQuery = '';
      directorySearchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = stateResultsKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut, alignment: 0.06);
      }
    });
  }

  void _tapState(TapDownDetails details, Size size) {
    if (stateShapes.isEmpty) return;
    // SVG viewBox is 174 100 959 593, and the map fills this aspect ratio.
    final point = Offset(
      174 + details.localPosition.dx * 959 / size.width,
      100 + details.localPosition.dy * 593 / size.height,
    );
    for (final entry in stateShapes.entries.toList().reversed) {
      if (entry.value.contains(point)) {
        _selectStateAndShowResults(entry.key);
        return;
      }
    }
  }

  Future<void> _loadSaved() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => saved = (preferences.getStringList('saved_help_resources') ?? const <String>[]).toSet());
    }
  }

  Future<void> _toggleSaved(String id) async {
    setState(() => saved.contains(id) ? saved.remove(id) : saved.add(id));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('saved_help_resources', saved.toList());
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That resource could not be opened.')));
    }
  }

  Future<void> _call(String phone) async {
    final value = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('tel:$value'));
  }

  List<HelpResource> _managed(List<ManagedContentItem> items) {
    return items
        .where((item) => item.data['helpResource'] == true)
        .map((item) => HelpResource(
              id: 'admin_${item.id}',
              title: item.text('title', 'Community resource'),
              description: item.text('description', item.text('body')),
              needs: item.text('need', item.text('category', 'General')).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
              states: item.text('state').split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList(),
              url: item.text('url'),
              phone: item.text('phone'),
              label: item.text('freeLabel', 'Community resource'),
              verified: item.text('verifiedAt', 'Check availability'),
              providerType: item.text('providerType'),
              costType: item.text('costType'),
              serviceScope: item.text('serviceScope'),
              serviceArea: item.text('serviceArea'),
              eligibility: item.text('eligibility'),
              howToApply: item.text('howToApply'),
              cost: item.text('cost'),
            ))
        .toList();
  }

  List<HelpResource> _stateStartingPoints() {
    final state = selectedState;
    if (state == null) return const <HelpResource>[];
    final name = stateNames[state]!;
    return [
      HelpResource(
        id: 'local_food_$state',
        title: '$name food and grocery help',
        description: 'Find local food banks, groceries, SNAP guidance, meal programs, and other food support near you through 211.',
        needs: const ['Food'],
        states: [state],
        url: 'https://www.211.org/get-help/food-programs-food-benefits',
        phone: '211',
        label: 'Local help in $name',
        verified: '',
      ),
      HelpResource(
        id: 'local_housing_$state',
        title: '$name rent, housing and utility help',
        description: 'Find local rent assistance, shelter, mortgage, utility-bill help, and housing-stability programs through 211.',
        needs: const ['Rent & Housing', 'Utilities'],
        states: [state],
        url: 'https://www.211.org/get-help/housing-expenses',
        phone: '211',
        label: 'Local help in $name',
        verified: '',
      ),
      HelpResource(
        id: 'local_health_$state',
        title: '$name health, childcare and transportation help',
        description: 'Get connected with local medical-cost, medication, appointment transportation, childcare, and family-support options.',
        needs: const ['Healthcare', 'Childcare', 'Transportation'],
        states: [state],
        url: 'https://www.211.org/get-help/healthcare-expenses',
        phone: '211',
        label: 'Local help in $name',
        verified: '',
      ),
      HelpResource(
        id: 'local_work_$state',
        title: '$name job, legal and crisis support',
        description: 'Talk with a local 211 specialist about employment, legal help, safety planning, and other urgent support.',
        needs: const ['Employment', 'Legal Help', 'Crisis & Safety'],
        states: [state],
        url: 'https://www.211.org/',
        phone: '211',
        label: 'Local help in $name',
        verified: '',
      ),
    ];
  }

  HelpPath? get _selectedPath {
    for (final path in helpPaths) {
      if (path.id == selectedPathId) return path;
    }
    return null;
  }

  List<HelpResource> _applyNeed(List<HelpResource> items) {
    final path = _selectedPath;
    if (selectedNeed != null) return items.where((resource) => resource.needs.contains(selectedNeed)).toList();
    if (path != null) return items.where((resource) => resource.needs.any(path.needs.contains)).toList();
    if (selectedNeed == null) return items;
    return items.where((resource) => resource.needs.contains(selectedNeed)).toList();
  }

  List<HelpResource> _visible(List<HelpResource> managed) {
    final all = [...builtIns, ...managed];
    if (view == 2) return all.where((resource) => saved.contains(resource.id)).toList();

    if (selectedState != null) {
      final stateSpecific = all.where((resource) => resource.states.contains(selectedState)).toList();
      final local = _applyNeed([...stateSpecific, ..._stateStartingPoints()]);
      final nationwide = _applyNeed(all.where((resource) => resource.states.isEmpty).toList());
      return [...local, ...nationwide];
    }

    return _applyNeed(all);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.cloudReady ? admin.watchPublished('resources') : Stream.value(const <ManagedContentItem>[]),
      builder: (context, snapshot) {
        final managed = _managed(snapshot.data ?? const <ManagedContentItem>[]);
        final visible = _visible(managed);
        final localResults = selectedState == null || view == 2
            ? const <HelpResource>[]
            : visible.where((resource) => resource.states.contains(selectedState)).toList();
        final nationwideResults = selectedState == null || view == 2
            ? visible
            : visible.where((resource) => resource.states.isEmpty).toList();
        if (view == 1) return _courses(snapshot.data ?? const <ManagedContentItem>[]);
        if (view == 0) return _helpStart();
        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                color: cream,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextButton.icon(
              onPressed: () => setState(() {
                selectedNeed = null;
                selectedPathId = null;
                selectedState = null;
                showAllResources = false;
              }),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Resource Directory'),
              style: TextButton.styleFrom(
                foregroundColor: sage,
                alignment: Alignment.centerLeft,
              ),
            ),
              ),
            ),
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
            Text('Find Help', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 4),
            Text('Free and low-cost support, organized by location and need.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF626A63))),
            const SizedBox(height: 14),
            _urgentBanner(),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Find Help'), icon: Icon(Icons.map_outlined)),
                ButtonSegment(value: 1, label: Text('Courses'), icon: Icon(Icons.auto_stories_outlined)),
                ButtonSegment(value: 2, label: Text('Saved'), icon: Icon(Icons.bookmark_border_rounded)),
              ],
              selected: {view},
              onSelectionChanged: (value) => setState(() {
                view = value.first;
                if (view == 1) selectedState = null;
              }),
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 15),
            if (view == 0) ...[
              if (selectedPathId != null) _selectedHelpHeader(),
              const SizedBox(height: 12),
              _zipSearch(),
              if (localZip != null) ...[
                const SizedBox(height: 15),
                _localResultsPanel(),
              ],
              const SizedBox(height: 15),
              _stateBrowser(),
            ],
            if (view == 2) _savedHeader(),
            const SizedBox(height: 18),
            Row(
              key: stateResultsKey,
              children: [
                Expanded(child: Text(_resultsTitle(), style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700, color: ink))),
                Text('${visible.length} resources', style: const TextStyle(color: sage, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              _empty()
            else if (selectedState != null && view != 2) ...[
              Text('Help in ${stateNames[selectedState]}', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 4),
              const Text('Local and state-specific options come first.', style: TextStyle(fontSize: 12, color: Color(0xFF626A63))),
              const SizedBox(height: 10),
              _resourceGrid(localResults),
              if (nationwideResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Nationwide programs', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 4),
                const Text('More trusted options available across the country.', style: TextStyle(fontSize: 12, color: Color(0xFF626A63))),
                const SizedBox(height: 10),
                _resourceGrid(nationwideResults),
              ],
            ] else ...[
              _resourceGrid((showAllResources ? visible : visible.take(6)).toList()),
              if (!showAllResources && visible.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => showAllResources = true),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text('See all ' + visible.length.toString() + ' resources'),
                    style: OutlinedButton.styleFrom(foregroundColor: sage, minimumSize: const Size.fromHeight(46)),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Program availability and eligibility can change. Confirm details directly with the provider before relying on assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: Color(0xFF737873), height: 1.4),
            ),
              ],
            )),
          ],
        );
      },
    );
  }

  Widget _urgentBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF0D7), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE9C98C))),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFFFE2AF), child: Icon(Icons.support_agent_rounded, color: ink)),
          const SizedBox(width: 11),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Need help finding something now?', style: TextStyle(fontWeight: FontWeight.w900)),
            SizedBox(height: 2),
            Text('Call 211 for confidential local assistance.', style: TextStyle(fontSize: 12)),
          ])),
          TextButton(onPressed: () => _call('211'), child: const Text('Call')),
        ]),
      );

  Future<void> _chooseState() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Text('States', style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 5),
              const Text('We will show statewide and nationwide help.'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: stateNames.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: line),
                  itemBuilder: (context, index) {
                    final entry = stateNames.entries.elementAt(index);
                    return ListTile(
                      leading: Container(
                        width: 38,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(9)),
                        child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900, color: sage)),
                      ),
                      title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: selectedState == entry.key ? const Icon(Icons.check_circle_rounded, color: sage) : const Icon(Icons.chevron_right_rounded, color: sage),
                      onTap: () => Navigator.pop(context, entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) _selectStateAndShowResults(choice);
  }

  Widget _map() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0E8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined, color: gold, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Find help in your state', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink))),
                if (selectedState != null) TextButton(onPressed: () => setState(() => selectedState = null), child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap a state on the map or choose from the list to explore local resources. Pinch to zoom for smaller states.',
              style: TextStyle(fontSize: 12, color: Color(0xFF626A63)),
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 959 / 593,
              child: LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: InteractiveViewer(
                    transformationController: mapTransform,
                    minScale: 1,
                    maxScale: 5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _tapState(details, size),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SvgPicture.asset(
                            'assets/images/us_states_map.svg',
                            fit: BoxFit.fill,
                            semanticsLabel: 'Interactive United States state selection map',
                          ),
                          if (selectedState != null && stateShapes.containsKey(selectedState))
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _SelectedStatePainter(stateShapes[selectedState]!, sage),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseState,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(selectedState == null ? 'Select a state' : stateNames[selectedState]!),
              style: OutlinedButton.styleFrom(
                foregroundColor: sage,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: sage),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );

  Widget _courses(List<ManagedContentItem> managed) {
    final custom = managed
        .where((item) => item.data['course'] == true)
        .map((item) => SupportCourse(
              title: item.text('title', 'Village course'),
              description: item.text('description', item.text('body')),
              community: item.text('community', 'Village'),
              length: item.text('courseLength', 'Self-paced'),
              url: item.text('courseUrl', item.text('url')),
            ))
        .toList();
    const starter = <SupportCourse>[
      SupportCourse(title: 'Building a Stronger Relationship', description: 'A practical starting place for communicating better, reconnecting, and handling hard moments as a team.', community: 'Relationships', length: '4 short lessons'),
      SupportCourse(title: 'The Men’s Wellbeing Room', description: 'Guided conversations around pressure, emotional health, fatherhood, friendship, and purpose.', community: 'Men', length: '5 short lessons'),
      SupportCourse(title: 'Motherhood Without Losing Yourself', description: 'Support for identity, routines, asking for help, and caring for yourself while caring for everyone else.', community: 'Moms', length: '4 short lessons'),
      SupportCourse(title: 'Boundaries That Feel Like Care', description: 'Learn how to name your needs, hold healthy limits, and protect your peace without guilt.', community: 'Women', length: '3 short lessons'),
    ];
    final courses = [...custom, ...starter];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Find Help'), icon: Icon(Icons.map_outlined)),
            ButtonSegment(value: 1, label: Text('Courses'), icon: Icon(Icons.auto_stories_outlined)),
            ButtonSegment(value: 2, label: Text('Saved'), icon: Icon(Icons.bookmark_border_rounded)),
          ],
          selected: {view},
          onSelectionChanged: (value) => setState(() => view = value.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 15),
        Text('Learn & grow', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 4),
        Text('Short, supportive courses made for the conversations happening in the Village.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF626A63))),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(18)),
          child: const Row(children: [
            Icon(Icons.auto_stories_outlined, color: sage),
            SizedBox(width: 10),
            Expanded(child: Text('Choose a topic that meets you where you are. New courses are added by the Village.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: 18),
        Text('Courses for your season', style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 10),
        for (final course in courses) ...[
          _courseCard(course),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  Widget _courseCard(SupportCourse course) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 43, height: 43, decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.play_lesson_outlined, color: sage)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.community, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(course.title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
            ])),
          ]),
          const SizedBox(height: 10),
          Text(course.description, style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: ink)),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.schedule_outlined, size: 16, color: sage),
            const SizedBox(width: 5),
            Expanded(child: Text(course.length, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sage))),
            if (course.url.isNotEmpty)
              FilledButton(onPressed: () => _open(course.url), style: FilledButton.styleFrom(backgroundColor: sage, visualDensity: VisualDensity.compact), child: const Text('Start'))
            else
              OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This course is coming soon.'))), style: OutlinedButton.styleFrom(foregroundColor: sage), child: const Text('Coming soon')),
          ]),
        ]),
      );

  Widget _needs() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final need in needs)
            FilterChip(
              avatar: Icon(need.$2, size: 17, color: selectedNeed == need.$1 ? Colors.white : sage),
              label: Text(need.$1),
              selected: selectedNeed == need.$1,
              onSelected: (_) => setState(() => selectedNeed = selectedNeed == need.$1 ? null : need.$1),
              selectedColor: sage,
              labelStyle: TextStyle(color: selectedNeed == need.$1 ? Colors.white : ink, fontWeight: FontWeight.w700),
            ),
        ],
      );

  Widget _savedHeader() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(18)),
        child: const Row(children: [
          Icon(Icons.bookmark_rounded, color: sage),
          SizedBox(width: 10),
          Expanded(child: Text('Resources you save will stay here for quick access.', style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  void _showZipResults() {
    final zip = zipController.text.trim();
    if (!RegExp(r'^\d{5}').hasMatch(zip)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 5-digit ZIP code.')));
      return;
    }
    setState(() => localZip = zip);
  }

  Widget _localResultsPanel() {
    final zip = localZip!;
    final path = _selectedPath;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Local results for ' + zip, style: GoogleFonts.playfairDisplay(fontSize: 21, fontWeight: FontWeight.w700, color: ink)),
            Text('Focused on ' + (path?.title ?? selectedNeed ?? 'available help').toLowerCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF626A63))),
          ])),
          TextButton(onPressed: () => setState(() => localZip = null), child: const Text('Edit ZIP')),
        ]),
        const SizedBox(height: 10),
        _inlineResult(
          icon: Icons.volunteer_activism_outlined,
          title: 'Programs and nonprofits near you',
          detail: 'Search current local organizations serving your ZIP.',
          onTap: () => _open('https://www.findhelp.org/search/text?postal=' + zip + '&term=individuals'),
        ),
        _inlineResult(
          icon: Icons.support_agent_rounded,
          title: 'Talk to a local 211 specialist',
          detail: 'Get help explaining your situation and finding options.',
          onTap: () => _call('211'),
        ),
        if (path?.id == 'family' || selectedNeed == 'Healthcare' || selectedNeed == 'Childcare')
          _inlineResult(
            icon: Icons.local_hospital_outlined,
            title: 'Community health centers near you',
            detail: 'Find low-cost medical, dental, behavioral and family care.',
            onTap: () => _open('https://findahealthcenter.hrsa.gov/?incrementalsearch=true&radius=10&zip=' + zip),
          ),
        if (path?.id == 'work' || selectedNeed == 'Legal Help')
          _inlineResult(
            icon: Icons.gavel_outlined,
            title: 'Free legal aid',
            detail: 'Find nonprofit civil legal assistance in your area.',
            onTap: () => _open('https://www.lsc.gov/about-lsc/what-legal-aid/i-need-legal-help'),
          ),
      ]),
    );
  }

  Widget _inlineResult({
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Icon(icon, color: sage),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(fontSize: 11.5, color: Color(0xFF626A63))),
            ])),
            const Icon(Icons.arrow_forward_rounded, color: sage, size: 19),
          ]),
        ),
      );


  Widget _zipSearch() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sage,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.location_searching_rounded, color: Color(0xFFFFE4B4)),
              SizedBox(width: 8),
              Text('Start with where you live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 5),
            const Text('Enter a ZIP code to see real programs and nonprofits serving your area.', style: TextStyle(color: Color(0xFFE7EFE1), fontSize: 12, height: 1.35)),
            const SizedBox(height: 12),
            TextField(
              controller: zipController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              decoration: InputDecoration(
                counterText: '',
                prefixIcon: const Icon(Icons.location_on_outlined, color: sage),
                hintText: 'Enter ZIP code',
                suffixIcon: TextButton(
                  onPressed: _showZipResults,
                  child: const Text('Search'),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      );

  Widget _needExplorer() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('What do you need help with?', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink))),
              if (selectedNeed != null)
                TextButton(onPressed: () => setState(() => selectedNeed = null), child: const Text('Clear')),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final need in needs)
                  ChoiceChip(
                    avatar: Icon(need.$2, size: 16, color: selectedNeed == need.$1 ? Colors.white : sage),
                    label: Text(need.$1),
                    selected: selectedNeed == need.$1,
                    onSelected: (_) => setState(() {
                      selectedNeed = selectedNeed == need.$1 ? null : need.$1;
                      showAllResources = false;
                    }),
                    selectedColor: sage,
                    labelStyle: TextStyle(color: selectedNeed == need.$1 ? Colors.white : ink, fontSize: 11, fontWeight: FontWeight.w700),
                    side: BorderSide(color: selectedNeed == need.$1 ? sage : line),
                  ),
              ],
            ),
          ],
        ),
      );

  void _submitDirectorySearch() {
    final query = directorySearchController.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      directoryQuery = query;
      selectedNeed = null;
      selectedPathId = null;
      showAllResources = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resultsContext = directoryResultsKey.currentContext;
      if (resultsContext != null) {
        Scrollable.ensureVisible(resultsContext,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: 0.05);
      }
    });
  }


  String _providerType(HelpResource resource) {
    if (resource.providerType.isNotEmpty) return resource.providerType;
    const government = {
      'fl-myaccess','fl-wic','fl-ship','fl-liheap','fl-csbg','fl-weatherization',
      'fl-school-readiness','fl-kidcare','fl-legal-directory','fl-elder',
      'fl-senior-legal','fl-shine','fl-veterans','fl-transport','fl-apd',
      'fl-early-steps','fl-child-support','fl-dv-centers','fl-disaster',
      'fl-benefits','fl-homelessness','usa-benefits','food-help','rent-help',
      'utility-help','housing-help','state-social-services','emergency-food',
      'health-center','jobs-local',
    };
    if (government.contains(resource.id)) return 'Government';
    if (resource.id == 'fl-ccjax' || resource.id == 'fl-beam' ||
        resource.id == 'fl-mercy') return 'Faith-based';
    const nonprofits = {
      'fl-career','fl-feeding-florida','fl-food-ne','fl-food-central','fl-food-gulf',
      'fl-food-bigbend','fl-food-tampa','fl-food-allfaiths','fl-food-treasure',
      'fl-food-chapin','fl-food-south','fl-sulzbacher','fl-jala','fl-metro',
      'fl-metro-financial','fl-up-orlando','fl-chapman','fl-pet-tampa',
      '211','childcare-referral','legal-aid','988',
    };
    if (nonprofits.contains(resource.id) || resource.id.startsWith('local_')) return 'Nonprofit';
    if (resource.id == 'local-programs') return 'Business';
    return '';
  }

  String _serviceScope(HelpResource resource) {
    if (resource.serviceScope.isNotEmpty) return resource.serviceScope;
    if (resource.states.isEmpty) return 'Nationwide';
    if (resource.serviceArea == 'Florida statewide' ||
        resource.id == 'fl-benefits' || resource.id == 'fl-homelessness') return 'Statewide';
    return 'Local';
  }

  String _costType(HelpResource resource) {
    if (resource.costType.isNotEmpty) return resource.costType;
    // Tag only services with a documented free access route. A free
    // application does not mean that the underlying service is free.
    const free = {'fl-wic','fl-senior-legal','fl-shine','fl-veterans',
      'fl-early-steps','211','988','usa-benefits','fl-legal-directory'};
    if (free.contains(resource.id)) return 'Free';
    return '';
  }

  bool _matchesFilters(HelpResource resource) {
    final provider = _providerType(resource);
    if (providerFilter != null && provider != providerFilter &&
        !(providerFilter == 'Nonprofit' && provider == 'Faith-based')) return false;
    if (areaFilter != null && _serviceScope(resource) != areaFilter) return false;
    if (costFilter != null && _costType(resource) != costFilter) return false;
    final eligibility = eligibilityFilter.trim().toLowerCase();
    return eligibility.isEmpty ||
        resource.eligibility.toLowerCase().contains(eligibility) ||
        resource.description.toLowerCase().contains(eligibility);
  }

  int get _filterCount => [providerFilter, areaFilter, costFilter]
      .where((value) => value != null).length + (eligibilityFilter.isEmpty ? 0 : 1);

  Future<void> _showFilters() async {
    var provider = providerFilter;
    var area = areaFilter;
    var cost = costFilter;
    var eligibility = eligibilityFilter;
    final eligibilityController = TextEditingController(text: eligibility);
    final applied = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      backgroundColor: cream,
      builder: (sheetContext) => StatefulBuilder(builder: (context, update) {
        Widget choices(String title, List<String> values, String? current,
            void Function(String?) change) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              ChoiceChip(label: const Text('All'), selected: current == null,
                onSelected: (_) => update(() => change(null))),
              for (final value in values)
                ChoiceChip(label: Text(value), selected: current == value,
                  onSelected: (selected) => update(() => change(selected ? value : null))),
            ]),
            const SizedBox(height: 18),
          ],
        );
        return SafeArea(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
              Text('Filter resources', style: GoogleFonts.playfairDisplay(
                fontSize: 26, fontWeight: FontWeight.w700, color: sage)),
              const SizedBox(height: 18),
              choices('Who provides the help?',
                ['Government','Nonprofit','Faith-based','Community','Business'],
                provider, (value) => provider = value),
              choices('Service area', ['Local','Statewide','Nationwide'],
                area, (value) => area = value),
              choices('Cost', ['Free','Reduced cost','Sliding scale'],
                cost, (value) => cost = value),
              TextField(controller: eligibilityController,
                onChanged: (value) => eligibility = value,
                decoration: const InputDecoration(
                  labelText: 'Eligibility keywords',
                  hintText: 'For example: veterans, children, seniors',
                  border: OutlineInputBorder())),
              const SizedBox(height: 8),
              const Text('Eligibility is determined by each program. Some listings may not have all filter details.',
                style: TextStyle(fontSize: 12, color: Color(0xFF626A63))),
              const SizedBox(height: 18),
              Row(children: [
                TextButton(onPressed: () => update(() {
                  provider = null; area = null; cost = null; eligibility = '';
                  eligibilityController.clear();
                }), child: const Text('Clear filters')),
                const Spacer(),
                FilledButton(onPressed: () => Navigator.pop(sheetContext, true),
                  style: FilledButton.styleFrom(backgroundColor: sage),
                  child: const Text('Show resources')),
              ]),
            ]),
        ));
      }),
    );
    Future<void>.delayed(const Duration(milliseconds: 500), eligibilityController.dispose);
    if (applied == true && mounted) setState(() {
      providerFilter = provider; areaFilter = area; costFilter = cost;
      eligibilityFilter = eligibility.trim(); showAllResources = true;
    });
  }

  Future<void> _chooseDirectoryState() async {
    final value = await showModalBottomSheet<String>(
      context: context, showDragHandle: true, backgroundColor: cream,
      builder: (sheetContext) => SafeArea(child: ListView(
        children: [
          const ListTile(title: Text('Choose a state',
            style: TextStyle(fontWeight: FontWeight.w700))),
          ListTile(title: const Text('All states'),
            onTap: () => Navigator.pop(sheetContext, 'ALL')),
          for (final entry in stateNames.entries)
            ListTile(title: Text(entry.value), selected: selectedState == entry.key,
              onTap: () => Navigator.pop(sheetContext, entry.key)),
        ],
      )),
    );
    if (value != null && mounted) setState(() {
      selectedState = value == 'ALL' ? null : value;
      showAllResources = true;
    });
  }

  Widget _quickCategories() {
    const categories = <(String, String, IconData)>[
      ('Housing', 'Rent & Housing', Icons.home_outlined),
      ('Food', 'Food', Icons.restaurant_outlined),
      ('Money & Bills', 'Utilities', Icons.account_balance_wallet_outlined),
      ('Health', 'Healthcare', Icons.favorite_border_rounded),
      ('Kids & Family', 'Childcare', Icons.family_restroom_outlined),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Browse by Category', style: GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 350 ? 2 : 3;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        Widget chip(String label, IconData icon, bool active, VoidCallback tap) =>
          SizedBox(width: width, child: OutlinedButton.icon(
            onPressed: tap, icon: Icon(icon, size: 18),
            label: Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              backgroundColor: active ? paleSage : cream, foregroundColor: sage,
              side: const BorderSide(color: line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          ));
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final category in categories)
            chip(category.$1, category.$3, selectedNeed == category.$2,
              () => setState(() {
                selectedNeed = selectedNeed == category.$2 ? null : category.$2;
                selectedPathId = null; showAllResources = true;
              })),
          chip('All categories', Icons.grid_view_outlined, allCategoriesOpen,
            () => setState(() => allCategoriesOpen = !allCategoriesOpen)),
        ]);
      }),
      if (allCategoriesOpen) ...[
        const SizedBox(height: 12),
        ResourceCategoryBrowser(onExplore: _exploreCategory),
      ],
    ]);
  }

  Widget _directorySearchResults() {
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.cloudReady ? admin.watchPublished('resources')
          : Stream.value(const <ManagedContentItem>[]),
      builder: (context, snapshot) {
        final query = directoryQuery.toLowerCase();
        final items = _visible(_managed(snapshot.data ?? const <ManagedContentItem>[]))
            .where(_matchesFilters)
            .where((resource) => query.isEmpty ||
                resource.title.toLowerCase().contains(query) ||
                resource.description.toLowerCase().contains(query) ||
                resource.serviceArea.toLowerCase().contains(query) ||
                resource.eligibility.toLowerCase().contains(query) ||
                resource.needs.any((need) => need.toLowerCase().contains(query)))
            .toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Expanded(child: Text('Resources for you',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: sage))),
              OutlinedButton.icon(onPressed: _showFilters,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(_filterCount == 0 ? 'Filters' : 'Filters ($_filterCount)'),
                style: OutlinedButton.styleFrom(foregroundColor: sage)),
            ])),
          const SizedBox(height: 7),
          Text('${items.length} resources • ${selectedState == null ? 'All states' : stateNames[selectedState]}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF626A63))),
          if (selectedNeed != null || _filterCount > 0 || directoryQuery.isNotEmpty)
            Row(children: [
              Expanded(child: Text(selectedNeed ?? 'Filtered results',
                style: const TextStyle(fontSize: 12, color: sage))),
              TextButton(onPressed: () => setState(() {
                selectedNeed = null; selectedPathId = null;
                providerFilter = null; areaFilter = null; costFilter = null;
                eligibilityFilter = ''; directoryQuery = '';
                directorySearchController.clear();
              }), child: const Text('Clear filters')),
            ]),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No matching resources found. Try fewer filters or another location.'))
          else _resourceGrid(items),
        ]);
      },
    );
  }

  Widget _helpStart() => guidedHelp
      ? ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 32), children: [
          TextButton.icon(onPressed: () => setState(() => guidedHelp = false),
            icon: const Icon(Icons.arrow_back), label: const Text('Back to resources')),
          GuidedHelpAssistant(onBrowse: (need, state, zip) => setState(() {
            guidedHelp = false; selectedNeed = need; selectedPathId = null;
            selectedState = state; localZip = zip; showAllResources = true;
          })),
        ])
      : ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 32), children: [
          Text('Resource Directory', style: GoogleFonts.playfairDisplay(
            fontSize: 29, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          const Text('Find support near you.'),
          const SizedBox(height: 12),
          TextField(controller: directorySearchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitDirectorySearch(),
            onChanged: (value) => setState(() => directoryQuery = value.trim()),
            decoration: InputDecoration(hintText: 'What do you need help with?',
              prefixIcon: const Icon(Icons.search_rounded, color: sage),
              suffixIcon: IconButton(tooltip: 'Search resources',
                onPressed: _submitDirectorySearch, icon: const Icon(Icons.arrow_forward)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(flex: 5, child: _locationButton(icon: Icons.location_on_outlined,
              label: selectedState == null ? 'All states' : stateNames[selectedState]!,
              onTap: _chooseDirectoryState)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _locationButton(icon: Icons.pin_drop_outlined,
              label: localZip ?? 'ZIP code', onTap: _chooseZip)),
            const SizedBox(width: 6),
            IconButton.filled(tooltip: 'Browse by map',
              onPressed: () => setState(() => showMap = !showMap),
              style: IconButton.styleFrom(backgroundColor: sage),
              icon: const Icon(Icons.map_outlined)),
          ]),
          if (showMap) ...[const SizedBox(height: 10), _map()],
          if (localZip != null) ...[
            const SizedBox(height: 10), _localResultsPanel(),
          ],
          const SizedBox(height: 16),
          _quickCategories(),
          const SizedBox(height: 16),
          KeyedSubtree(key: directoryResultsKey, child: _directorySearchResults()),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: () => setState(() => guidedHelp = true),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Help me find the right support'),
            style: TextButton.styleFrom(foregroundColor: sage)),
        ]);

  Widget _locationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Material(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 53,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x1D000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(children: [
              Icon(icon, color: const Color(0xFF0A9A69), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: ink),
            ]),
          ),
        ),
      );

  Future<void> _chooseZip() async {
    final enteredZip = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search by ZIP code',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'We’ll use it to point you to local programs and nonprofits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF626A63)),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: zipController,
                autofocus: true,
                maxLength: 5,
                keyboardType: TextInputType.number,
                onSubmitted: (value) => Navigator.pop(sheetContext, value.trim()),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter ZIP code',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: sage),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, zipController.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: sage,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Find resources near me'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (enteredZip == null) return;
    if (!RegExp(r'^\d{5}$').hasMatch(enteredZip)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a 5-digit ZIP code.')),
        );
      }
      return;
    }
    if (mounted) setState(() => localZip = enteredZip);
  }

  void _exploreCategory(String category) {
    directoryQuery = '';
    directorySearchController.clear();
    // Existing resource data supports nine broad needs. Do not falsely label
    // unmatched listings as category-specific until tags are migrated.
    const mapping = <String, String>{
      'Housing & Home Assistance': 'Rent & Housing',
      'Food, Clothing & Basic Needs': 'Food',
      'Money, Bills & Financial Support': 'Utilities',
      'Health, Mental Health & Recovery': 'Healthcare',
      'Little Villagers — Kids & Teens': 'Childcare',
      'Parenting, Family & Relationships': 'Childcare',
      'Jobs, Education & Business': 'Employment',
      'Transportation & Technology': 'Transportation',
      'Legal, Safety & Life Transitions': 'Legal Help',
      'Emergencies & Disaster Relief': 'Crisis & Safety',
      'Specialized Community Support': 'Specialized Support',
      'Community, Recreation & Pets': 'Community & Pets',
    };
    if (!mapping.containsKey(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Specific listings for $category are being added. Showing currently available resources.')),
      );
    }
    setState(() {
      selectedPathId = null;
      selectedNeed = mapping[category];
      showAllResources = true;
      allCategoriesOpen = false;
    });
  }

  Widget _helpPathCard(HelpPath path) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() {
          selectedPathId = path.id;
          selectedState = null;
          showAllResources = false;
        }),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(15)), child: Icon(path.icon, color: sage)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(path.title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 3),
              Text(path.detail, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF626A63))),
            ])),
            const Icon(Icons.arrow_forward_rounded, color: sage),
          ]),
        ),
      );

  Widget _selectedHelpHeader() {
    final path = _selectedPath!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(path.icon, color: sage),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Looking for help with', style: TextStyle(fontSize: 11.5, color: Color(0xFF626A63))),
          Text(path.title, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
        ])),
        TextButton(onPressed: () => setState(() {
          selectedPathId = null;
          selectedNeed = null;
          selectedState = null;
          showAllResources = false;
        }), child: const Text('Change')),
      ]),
    );
  }

  Widget _stateBrowser() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFFF4F0E8), borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.map_outlined, color: gold),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Browse help by state', style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
                const Text('State benefits and programs come first.', style: TextStyle(fontSize: 11.5, color: Color(0xFF626A63))),
              ])),
              TextButton(
                onPressed: () => setState(() => showMap = !showMap),
                child: Text(showMap ? 'Hide map' : 'Open map'),
              ),
            ]),
            if (showMap) ...[
              const SizedBox(height: 12),
              _map(),
            ],
          ],
        ),
      );


  String _resultsTitle() {
    if (view == 2) return 'Saved resources';
    final path = _selectedPath;
    if (path != null) return 'Support for ' + path.title;
    if (selectedNeed != null) return selectedNeed!;
    if (selectedState != null) return 'Help in ' + (stateNames[selectedState] ?? '');
    return 'Trusted nationwide help';
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
        child: Column(children: [
          const Icon(Icons.search_off_rounded, color: sage, size: 32),
          const SizedBox(height: 7),
          Text(view == 2 ? 'No saved resources yet.' : 'No matching resources yet.', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Try another need or use 211 to find local help.', textAlign: TextAlign.center),
        ]),
      );


  Widget _resourceGrid(List<HelpResource> resources) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < resources.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _resourceCard(resources[i]),
      ],
    ],
  );

  IconData _resourceIcon(HelpResource resource) {
    if (resource.needs.contains('Food')) return Icons.restaurant_outlined;
    if (resource.needs.contains('Rent & Housing')) return Icons.home_outlined;
    if (resource.needs.contains('Utilities')) return Icons.account_balance_wallet_outlined;
    if (resource.needs.contains('Healthcare')) return Icons.favorite_border_rounded;
    if (resource.needs.contains('Childcare')) return Icons.child_care_outlined;
    if (resource.needs.contains('Employment')) return Icons.work_outline_rounded;
    if (resource.needs.contains('Legal Help')) return Icons.gavel_outlined;
    if (resource.needs.contains('Transportation')) return Icons.directions_bus_outlined;
    if (resource.needs.contains('Community & Pets')) return Icons.pets_outlined;
    return Icons.volunteer_activism_outlined;
  }

  Widget _resourceCard(HelpResource resource) {
    final provider = _providerType(resource);
    final scope = _serviceScope(resource);
    final cost = _costType(resource);
    Widget tag(String text, Color background) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 11, color: ink)));
    final body = Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(resource.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(fontSize: 20,
            fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 6),
        Wrap(spacing: 5, runSpacing: 5, children: [
          if (provider.isNotEmpty) tag(provider, paleSage),
          tag(scope, const Color(0xFFF3EBDD)),
          if (cost.isNotEmpty) tag(cost, const Color(0xFFFFE3AF)),
        ]),
        const SizedBox(height: 7),
        Text(resource.description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: ink)),
        if (resource.serviceArea.isNotEmpty && scope == 'Local') ...[
          const SizedBox(height: 4),
          Text(resource.serviceArea, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF626A63))),
        ],
      ]);
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(tooltip: saved.contains(resource.id) ? 'Unsave resource' : 'Save resource',
        onPressed: () => _toggleSaved(resource.id), color: sage,
        icon: Icon(saved.contains(resource.id) ? Icons.bookmark : Icons.bookmark_border)),
      const SizedBox(width: 4),
      FilledButton(onPressed: () => _showResourceDetails(resource),
        style: FilledButton.styleFrom(backgroundColor: sage),
        child: const Text('Details')),
      if (resource.phone.isNotEmpty)
        IconButton(tooltip: 'Call program', onPressed: () => _call(resource.phone),
          color: sage, icon: const Icon(Icons.call_outlined, size: 21)),
    ]);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 650;
        final icon = Container(width: 44, height: 44,
          decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(12)),
          child: Icon(_resourceIcon(resource), color: sage, size: 27));
        if (wide) return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          icon, const SizedBox(width: 14), Expanded(child: body),
          const SizedBox(width: 14), actions,
        ]);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            icon, const SizedBox(width: 11), Expanded(child: body),
          ]),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: actions),
        ]);
      }),
    );
  }

  Future<void> _showResourceDetails(HelpResource resource) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(resource.title,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resource.description),
              const SizedBox(height: 12),
              Text(resource.label, style: const TextStyle(color: sage)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (_providerType(resource).isNotEmpty)
                  Chip(label: Text(_providerType(resource))),
                Chip(label: Text(_serviceScope(resource))),
                if (_costType(resource).isNotEmpty)
                  Chip(label: Text(_costType(resource))),
              ]),
              if (resource.serviceArea.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Service area', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(resource.serviceArea),
              ],
              if (resource.eligibility.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Who may qualify', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(resource.eligibility),
              ],
              if (resource.howToApply.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('How to apply', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(resource.howToApply),
              ],
              if (resource.cost.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Cost and availability', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(resource.cost),
              ],
              if (resource.reviewedAt.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Website research reviewed: ${resource.reviewedAt}'),
                const SizedBox(height: 4),
                const Text('Website information was reviewed; the provider has not confirmed current funding, openings or eligibility for you. Contact the program before traveling or applying.'),
              ],
              if (resource.sourceUrls.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Research sources', style: TextStyle(fontWeight: FontWeight.w700)),
                for (var i = 0; i < resource.sourceUrls.length; i++)
                  TextButton(
                    onPressed: () => _open(resource.sourceUrls[i]),
                    child: Text('Source ${i + 1}: ${Uri.parse(resource.sourceUrls[i]).host}'),
                  ),
              ],
              if (resource.phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Phone: ${resource.phone}'),
              ],
              if (resource.verified.isNotEmpty && resource.verified != 'Check availability') ...[
                const SizedBox(height: 12),
                Text('Verification on record: ${resource.verified}'),
              ],
              const SizedBox(height: 16),
              const Text('Community feedback',
                style: TextStyle(fontWeight: FontWeight.w700)),
              const Text('Not enough community feedback yet',
                style: TextStyle(fontSize: 12)),
              Wrap(spacing: 6, children: [
                TextButton.icon(onPressed: () => _voteResource(resource, true),
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: const Text('Helpful')),
                TextButton.icon(onPressed: () => _voteResource(resource, false),
                  icon: const Icon(Icons.thumb_down_outlined, size: 18),
                  label: const Text('Not helpful')),
              ]),
              Wrap(spacing: 6, children: [
                TextButton.icon(
                  onPressed: resource.url.isEmpty ? null
                    : () => Share.share(resource.url, subject: resource.title),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share')),
                TextButton.icon(onPressed: () => _reportResource(resource),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Report')),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to resources'),
          ),
          if (resource.url.isNotEmpty)
            FilledButton(
              onPressed: () => _open(resource.url),
              child: const Text('Visit program website'),
            ),
        ],
      ),
    );
  }

  Future<void> _reportResource(HelpResource resource) async {
    final reason = await showDialog<String>(context: context, builder: (dialogContext) =>
      SimpleDialog(title: Text('Report ${resource.title}'), children: [
        for (final issue in ['Outdated information', 'Broken link', 'Program closed', 'Incorrect details', 'Other'])
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, issue),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(issue))),
      ]));
    if (!mounted || reason == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to report a resource.')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('resource_reports').add({
        'resourceId': resource.id,
        'reporterUid': uid,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted for review. Thank you.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report could not be submitted. Please try again.')));
    }
  }

  Future<void> _voteResource(HelpResource resource, bool helpful) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    String reason = '';
    if (!helpful) {
      final selected = await showDialog<String>(context: context, builder: (dialogContext) =>
        SimpleDialog(title: const Text('Why was it not helpful?'), children: [
          for (final issue in ['Unavailable', 'Ineligible', 'No response', 'Incorrect information'])
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, issue),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(issue))),
        ]));
      if (selected == null) return;
      reason = selected;
    }
    try {
      await FirebaseFirestore.instance.collection('resource_votes')
        .doc(resource.id).collection('members').doc(uid).set({
          'uid': uid, 'helpful': helpful, 'reason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your feedback has been saved.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save feedback. Please try again.')));
    }
  }

}

class HelpPath {
  const HelpPath(this.id, this.title, this.detail, this.icon, this.needs);
  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final List<String> needs;
}

class SupportCourse {
  const SupportCourse({
    required this.title,
    required this.description,
    required this.community,
    required this.length,
    this.url = '',
  });

  final String title;
  final String description;
  final String community;
  final String length;
  final String url;
}

class HelpResource {
  const HelpResource({
    required this.id,
    required this.title,
    required this.description,
    required this.needs,
    required this.url,
    required this.label,
    required this.verified,
    this.states = const <String>[],
    this.phone = '',
    this.providerType = '',
    this.costType = '',
    this.serviceScope = '',
    this.serviceArea = '',
    this.eligibility = '',
    this.howToApply = '',
    this.cost = '',
    this.reviewedAt = '',
    this.sourceUrls = const <String>[],
  });

  final String providerType;
  final String costType;
  final String serviceScope;
  final String serviceArea;
  final String eligibility;
  final String howToApply;
  final String cost;
  final String reviewedAt;
  final List<String> sourceUrls;
  final String id;
  final String title;
  final String description;
  final List<String> needs;
  final List<String> states;
  final String url;
  final String phone;
  final String label;
  final String verified;
}
