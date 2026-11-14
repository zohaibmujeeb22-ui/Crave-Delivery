class OnboardingItem {
  final String tag;
  final String title;
  final String highlight;
  final String subtitle;
  final int visualIndex;

  const OnboardingItem({
    required this.tag,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.visualIndex,
  });

  static const List<OnboardingItem> items = [
    OnboardingItem(
      tag: 'VISUAL DISCOVERY',
      title: 'Taste before you decide with',
      highlight: 'Live Food Feeds',
      subtitle:
          'Explore authentic dishes through video & photo posts from top local spots. See the texture and portion before you order.',
      visualIndex: 0,
    ),
    OnboardingItem(
      tag: 'CURATED KITCHENS',
      title: 'Direct ordering from the',
      highlight: 'Best Artisanal Eateries',
      subtitle:
          'No bloated menus or hidden middleman markups. Order with guaranteed Cash on Delivery right to your door.',
      visualIndex: 1,
    ),
    OnboardingItem(
      tag: 'INSTANT SYNC',
      title: 'Track your meal from the',
      highlight: 'Kitchen to Table',
      subtitle:
          'Realtime step-by-step updates directly from the chef. Know the second your food enters the flame and leaves the door.',
      visualIndex: 2,
    ),
  ];
}
