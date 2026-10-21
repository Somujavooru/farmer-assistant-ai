import '../models/paddy_condition.dart';

class PaddyKnowledgeBase {
  static const List<PaddyCondition> conditions = [
    PaddyCondition(
      id: 'brown_planthopper',
      name: 'Brown Planthopper (BPH)',
      type: 'Pest',
      symptoms: [
        'Nymphs and adults gather at the base of rice plants above water level.',
        'Leaves turn yellow, then brownish-orange, and dry up rapidly.',
        'Circular patches of dried, burnt-looking plants ("Hopperburn") appear in the field.',
      ],
      affectedPart: 'Lower Stem & Leaf Sheath Base',
      cropImpact: 'Causes rapid drying ("hopperburn") and can lead to severe crop lodging and yield loss if unmanaged.',
      severityGuidance: 'High',
      managementPractices: '1. Drain field water for 2-3 days to disturb BPH breeding environment.\n2. Avoid excessive nitrogen fertilizer applications.\n3. Preserve natural biological predators such as spiders, mirid bugs, and water striders.',
      preventionPractices: 'Plant BPH-resistant rice varieties. Maintain proper hill spacing for sunlight penetration. Avoid prophylactic broad-spectrum pesticide sprays early in the season.',
      whenToContactExpert: 'Contact your local agricultural extension officer or Krishi Vigyan Kendra (KVK) if hopperburn patches appear or if more than 10-15 BPH insects per hill are observed.',
    ),
    PaddyCondition(
      id: 'stem_borer',
      name: 'Paddy Stem Borer',
      type: 'Pest',
      symptoms: [
        'Central tillers dry up and turn brown during vegetative stage ("Deadheart").',
        'Panicles turn completely white and produce empty grains at flowering stage ("Whitehead").',
        'Tiny entry holes and larval frass visible on lower stems.',
      ],
      affectedPart: 'Stem Interior & Panicle Neck',
      cropImpact: 'Prevents panicle grain filling, causing complete loss of affected tillers.',
      severityGuidance: 'High',
      managementPractices: '1. Set up pheromone traps or light traps to monitor adult moth activity.\n2. Clip leaf tips before transplanting to eliminate egg masses.\n3. Conserve natural egg parasitoids like Trichogramma species.',
      preventionPractices: 'Synchronize planting across nearby fields. Harvest close to ground level and plow or flood stubble immediately after harvest to kill overwintering larvae.',
      whenToContactExpert: 'Consult an extension officer if deadhearts exceed 5% of tillers or whiteheads exceed 2% during panicle initiation.',
    ),
    PaddyCondition(
      id: 'leaf_folder',
      name: 'Rice Leaf Folder',
      type: 'Pest',
      symptoms: [
        'Leaf blades are folded longitudinally with silk threads.',
        'White, papery longitudinal streaks appear on leaves where larvae scrape green tissue.',
        'Transparent damaged leaf canopy visible in severe infestations.',
      ],
      affectedPart: 'Leaf Blade & Flag Leaf',
      cropImpact: 'Reduces photosynthetic leaf area, impairing grain filling if the flag leaf is damaged.',
      severityGuidance: 'Moderate',
      managementPractices: '1. Pass a long rope across the crop canopy in early morning to dislodge larvae.\n2. Avoid excessive nitrogen top-dressing.\n3. Protect natural predators like predatory beetles and wasps.',
      preventionPractices: 'Maintain recommended plant spacing, eliminate field weeds, and avoid unnecessary early-season chemical sprays.',
      whenToContactExpert: 'Seek expert advice if more than 1-2 damaged folded leaves per hill are found on the flag leaf during booting or panicle emergence.',
    ),
    PaddyCondition(
      id: 'rice_bug',
      name: 'Rice Bug (Gandhi Bug)',
      type: 'Pest',
      symptoms: [
        'Slender greenish-brown bugs emitting a pungent odor around flowering panicles.',
        'Brown spots or punctures on developing milky grains.',
        'Grains remain partially empty, chaffy, or discolored at harvest.',
      ],
      affectedPart: 'Milky Grains & Flowering Panicle',
      cropImpact: 'Directly reduces grain weight, seed quality, and market value.',
      severityGuidance: 'Moderate',
      managementPractices: '1. Net or smoke field borders during early morning or late evening when bugs are active.\n2. Clear flowering wild grasses from field bunds.\n3. Apply sticky traps near bunds.',
      preventionPractices: 'Synchronize sowing time across village clusters so all fields flower simultaneously.',
      whenToContactExpert: 'Contact agricultural experts if more than 1-2 rice bugs per hill are observed during the grain milking stage.',
    ),
    PaddyCondition(
      id: 'blast',
      name: 'Rice Blast (Pyricularia oryzae)',
      type: 'Disease',
      symptoms: [
        'Eye-shaped or diamond-shaped lesions with dark brown borders and gray centers on leaves.',
        'Blackened, rotten panicle joints causing panicle breakage ("Neck Blast").',
        'Dark brown lesions on leaf collars and stem nodes.',
      ],
      affectedPart: 'Leaf Blade, Leaf Collar & Panicle Neck',
      cropImpact: 'Can cause severe leaf drying and total panicle loss if neck blast occurs before grain filling.',
      severityGuidance: 'High',
      managementPractices: '1. Maintain recommended water levels; avoid completely drying out fields during blast outbreaks.\n2. Split nitrogen applications and apply recommended potassic fertilizers.\n3. Burn or safely compost severely blast-damaged foliage.',
      preventionPractices: 'Use certified disease-free seeds. Treat seeds with recommended bio-agents (like Trichoderma). Plant blast-resistant varieties.',
      whenToContactExpert: 'Contact your KVK or extension center immediately if spindle lesions appear on flag leaves or neck blast is noticed at flowering.',
    ),
    PaddyCondition(
      id: 'brown_spot',
      name: 'Brown Spot (Helminthosporium)',
      type: 'Disease',
      symptoms: [
        'Small, round to oval brown spots with yellow halos scattered across leaves.',
        'Dark brown lesions on grain glumes and hulls.',
        'Seedlings appear stunted and weak.',
      ],
      affectedPart: 'Leaf Blade & Grain Glumes',
      cropImpact: 'Reduces grain weight and seed germination quality, often associated with soil nutrient deficiency.',
      severityGuidance: 'Moderate',
      managementPractices: '1. Apply balanced soil fertilizers, especially Potassium (K) and Zinc (Zn).\n2. Ensure adequate soil moisture and avoid severe soil drought.\n3. Incorporate farmyard manure (FYM) to enrich soil health.',
      preventionPractices: 'Conduct soil testing before sowing, ensure seed treatment, and use well-decomposed organic manure.',
      whenToContactExpert: 'Seek expert advice if leaf spots cover more than 10-15% of total leaf area during tillering.',
    ),
    PaddyCondition(
      id: 'bacterial_leaf_blight',
      name: 'Bacterial Leaf Blight (BLB)',
      type: 'Disease',
      symptoms: [
        'Water-soaked yellow-to-white wavy lesions starting from leaf tips/margins and moving downwards.',
        'Leaves dry up and turn grayish-white.',
        'Milky bacterial ooze drops may appear on young infected leaves in humid early mornings.',
      ],
      affectedPart: 'Leaf Margins & Seedling Base',
      cropImpact: 'Causes leaf wilting and drying ("Kresek"), reducing grain yield by 20-50%.',
      severityGuidance: 'High',
      managementPractices: '1. Drain standing water from infected fields to prevent bacterial spread through water flow.\n2. Avoid leaf tip clipping during transplanting if BLB is present in the region.\n3. Reduce or delay nitrogen fertilizer top-dressing.',
      preventionPractices: 'Grow BLB-resistant rice varieties. Practice strict field hygiene and clean irrigation channels.',
      whenToContactExpert: 'Contact agricultural experts immediately if leaf wilting or bacterial ooze spreads across more than 5% of plants.',
    ),
    PaddyCondition(
      id: 'sheath_blight',
      name: 'Sheath Blight (Rhizoctonia)',
      type: 'Disease',
      symptoms: [
        'Oval or greenish-gray water-soaked spots on leaf sheaths near the water line.',
        'Lesions enlarge with dark brown borders and light gray centers.',
        'Dark mustard-seed-like sclerotia develop on infected sheaths.',
      ],
      affectedPart: 'Lower Leaf Sheath & Leaf Canopy',
      cropImpact: 'Causes tiller lodging (falling over) and canopy collapse under high canopy humidity.',
      severityGuidance: 'Moderate to High',
      managementPractices: '1. Drain field water temporarily to reduce canopy humidity.\n2. Avoid excessive plant density and high nitrogen fertilizer application.\n3. Remove weed hosts along field bunds.',
      preventionPractices: 'Adopt recommended plant spacing (e.g. 20x15 cm) to allow air circulation and sunlight penetration.',
      whenToContactExpert: 'Consult an extension officer if sheath blight lesions reach the upper flag leaf sheath before flowering.',
    ),
  ];

  static PaddyCondition? getById(String id) {
    return conditions.where((c) => c.id == id).firstOrNull;
  }

  static List<PaddyCondition> search(String query) {
    if (query.trim().isEmpty) return conditions;
    final q = query.trim().toLowerCase();
    return conditions.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.type.toLowerCase().contains(q) ||
          c.affectedPart.toLowerCase().contains(q) ||
          c.symptoms.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }
}
