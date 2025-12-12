import 'dart:async';
import 'package:fitbud/User-App/common/bottom_sheets/location_bottom_sheet.dart';
import 'package:fitbud/User-App/common/widgets/section_heading.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/buddy_profile_screen.dart';
import 'package:fitbud/User-App/features/service/controllers/location_controller.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/all_buddy_requests_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/all_session_invites_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/buddy_find_swipper.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/notifications_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/premium_plans_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/qr_scan_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/specific_catagory_buddies_match_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/buddy_request_card.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/catagory_item_icon.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/home_appbar.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/home_product_banner.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/home_session_invite_card.dart';
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
  final PageController _pageController = PageController(initialPage: 1000);
  late Timer _timer;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  double _lastOffset = 0;

  bool hasPremium = true;

  /// 🔥 Reusable Function: Stop navigation & show your dialog
  void checkPremiumAndProceed(VoidCallback onAllowed) {
    if (hasPremium) {
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

  // To test No sesstion invites and no requests please remove the comment below.

  // final List<Map<String, String>> _sessionInvites = [];
  // final List<Map<String, String>> _buddyRequests = [];

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
            hasPremium: hasPremium,
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

                  if (hasPremium == false) SizedBox(height: 16),

                  //? Purchase Card
                  if (hasPremium == false)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: XColors.secondaryBG,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            //? Card details
                            Row(
                              children: [
                                //? icon
                                Icon(LucideIcons.info, color: XColors.primary),
                                SizedBox(width: 8),
                                //? Text
                                Expanded(
                                  child: Text(
                                    'Purchase our Premium Plans to enjoy full functionality of the app.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: XColors.bodyText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            //? Button
                            GestureDetector(
                              onTap: () {
                                Get.to(() => PremiumPlanScreen());
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: XColors.primary,
                                ),
                                child: Text(
                                  'Our Plans',
                                  style: TextStyle(
                                    color: XColors.primaryText,
                                    fontWeight: .w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

                  //? Buddy Requests
                  XHeading(
                    title: 'Buddy Requests',
                    actionText: 'View All',
                    onActionTap: () {
                      Get.to(() => AllBuddyRequestsScreen());
                    },
                    sidePadding: 16,
                  ),
                  const SizedBox(height: 16),

                  _buddyRequests.isEmpty
                      ? Column(
                          children: [
                            Image.asset(
                              'assets/images/no-requests.png',
                              width: 180,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "No Requests Found",
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _buddyRequests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 22),
                          itemBuilder: (context, index) {
                            final request = _buddyRequests[index];
                            return BuddyRequestCard(
                              name: request['name']!,
                              gender: request['gender']!,
                              age: request['age']!,
                              interest: request['interest']!,
                              location: request['location']!,
                              time: request['time']!,
                              avatar: request['avatar']!,
                              status: 'pending',
                              onAccept: () {},
                              onReject: () {},
                              onCardTap: () {
                                Get.to(
                                  BuddyProfileScreen(
                                    scenario: BuddyScenario.requestReceived,
                                  ),
                                );
                              },
                            );
                          },
                        ),

                  const SizedBox(height: 16),
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
