import 'dart:async';
import 'package:fitbud/User-App/common/bottom_sheets/location_bottom_sheet.dart';
import 'package:fitbud/User-App/common/widgets/section_heading.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/buddy_profile_screen.dart';
import 'package:fitbud/User-App/features/service/controllers/location_controller.dart';
import 'package:fitbud/User-App/features/service/controllers/plans_controller.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/all_session_invites_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/buddy_find_swipper.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/notifications_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/premium_plans_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/qr_scan_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/specific_catagory_buddies_match_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/catagory_item_icon.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/home_appbar.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/home_product_banner.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/home_session_invite_card.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/plan_card.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationController locationController = Get.find();
  final PremiumPlanController planController = Get.find(); // ← Use controller
  final PageController _pageController = PageController(initialPage: 1000);
  late Timer _timer;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  double _lastOffset = 0;

  final List<Map<String, dynamic>> plans = [
    {
      'title': 'Basic',
      'description': 'Enjoy app functionalities for 15 days.',
      'price': 2000,
      'duration': '15 days',
      'features': [
        'Unlimited Matches',
        'Basic Support',
        'Access to Free Content',
      ],
    },
    {
      'title': 'Standard',
      'description': 'Enjoy app functionalities for 1 month.',
      'price': 3500,
      'duration': '30 days',
      'features': [
        'Unlimited Matches',
        'Priority Support',
        'Access to Premium Content',
        'Ad-Free Experience',
      ],
    },
    {
      'title': 'Premium',
      'description': 'Enjoy app functionalities for 3 months.',
      'price': 9000,
      'duration': '90 days',
      'features': [
        'Unlimited Matches',
        '24/7 Support',
        'Access to Premium Content',
        'Ad-Free Experience',
        'Exclusive Offers',
      ],
    },
  ];

  /// 🔥 Reusable Function: Stop navigation & show your dialog
  void checkPremiumAndProceed(VoidCallback onAllowed) {
    if (planController.hasPremium) {
      onAllowed();
    } else {
      Get.dialog(
        SimpleDialogWidget(
          message:
              "Please purchase our premium plans to use this functionality.",
          icon: Icons.lock_outline,
          iconColor: XColors.primary,
          buttonText: "Ok",
        ),
      );
    }
  }

  final List<Map<String, String>> _banners = [
    {
      'title': 'PRO Gainer',
      'description':
          'A little description about product to be shown on the banner',
      'price': 'Rs. 9985',
      'image': 'assets/images/product1.png',
    },
    {
      'title': 'Whey Protein',
      'description': 'Boost your muscle growth with this whey protein',
      'price': 'Rs. 4499',
      'image': 'assets/images/product2.png',
    },
    {
      'title': 'Creatine',
      'description': 'Enhance strength and endurance effectively',
      'price': 'Rs. 2999',
      'image': 'assets/images/product3.png',
    },
  ];

  final List<Map<String, String>> _buddyRequests = List.generate(
    4,
    (index) => {
      'name': 'Ali Haider ${index + 1}',
      'gender': 'Male',
      'age': '23 years old',
      'interest': 'Cricket',
      'location': 'Street 11 Model Town A, Bahawalpur',
      'time': '${45 + index} mins ago',
      'avatar': 'assets/images/buddy.jpg',
    },
  );

  final List<Map<String, String>> _sessionInvites = List.generate(
    5,
    (index) => {
      'category': 'Gym Practice',
      'image': 'assets/images/gym.jpeg',
      'invitedBy': 'Muhammad Sufyan',
      'dateTime': 'Dec 1${index}, 11:00 PM',
      'location': 'Fitness 360 Commercial Area Branch, Bahawalpur',
    },
  );

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });

    const double sensitivity = 8;
    _scrollController.addListener(() {
      final offset = _scrollController.position.pixels;
      final diff = offset - _lastOffset;

      if (diff > sensitivity) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (diff < -sensitivity) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }

      _lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _getRealIndex(int index) {
    return index % _banners.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: Obx(
          () => CustomHomeAppBar(
            name: 'Muhammad Sufyan',
            location: locationController.currentLocation.value,
            country: 'Pakistan',
            imagePath: 'assets/images/profile.png',
            onLocationTap: () async {
              final pickedLocation = await showLocationBottomSheet(context);
              if (pickedLocation != null) {
                locationController.updateLocation(pickedLocation);
              }
            },
            hasPremium: planController.hasPremium, // ← Controller value
            onScanTap: () {
              Get.to(() => QRScanScreen());
            },
            onNotificationTap: () {
              Get.to(() => NotificationsScreen());
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  //? Categories
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 10,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return CategoryHomeIcon(
                          iconPath: 'assets/icons/badminton.png',
                          title: 'Badminton',
                          onTap: () {
                            checkPremiumAndProceed(() {
                              Get.to(
                                () => SpecificCatagoryBuddiesMatchScreen(),
                              );
                            });
                          },
                        );
                      },
                    ),
                  ),

                  //? Product Banners
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final banner = _banners[_getRealIndex(index)];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: HomeProductBanner(
                            title: banner['title']!,
                            description: banner['description']!,
                            price: banner['price']!,
                            imagePath: banner['image']!,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  //? Session Invites
                  XHeading(
                    title: 'Session Invites',
                    actionText: 'View All',
                    onActionTap: () {
                      Get.to(() => AllSessionInvitesScreen());
                    },
                    sidePadding: 16,
                  ),
                  const SizedBox(height: 16),

                  _sessionInvites.isEmpty
                      ? Column(
                          children: [
                            Image.asset(
                              'assets/images/no-sessions.png',
                              width: 180,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "No session invites found",
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 10,
                              ),
                            ),
                            SizedBox(height: 30),
                          ],
                        )
                      : SizedBox(
                          height: 185,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _sessionInvites.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final data = _sessionInvites[index];
                              return HomeSessionInviteCard(
                                image: data['image']!,
                                category: data['category']!,
                                invitedBy: data['invitedBy']!,
                                dateTime: data['dateTime']!,
                                location: data['location']!,
                                nameOnTap: () {
                                  Get.to(
                                    () => BuddyProfileScreen(
                                      scenario: BuddyScenario.existingBuddy,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                  //? Premium Plans
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GetBuilder<PremiumPlanController>(
                      builder: (_) {
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plans.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            return PlanCard(
                              index: index,
                              title: plan['title'],
                              description: plan['description'],
                              price: plan['price'],
                              duration: plan['duration'],
                              features: List<String>.from(plan['features']),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isFabVisible ? 1 : 0,
                child: FloatingActionButton(
                  backgroundColor: XColors.primary.withOpacity(0.7),
                  elevation: 0,
                  shape: const CircleBorder(),
                  onPressed: () {
                    checkPremiumAndProceed(() {
                      Get.to(() => const BuddyFinderSwiper());
                    });
                  },
                  child: const Icon(Iconsax.discover, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
