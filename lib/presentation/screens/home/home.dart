import 'dart:async';

import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../common/bottom_sheets/location_bottom_sheet.dart';
import '../../../common/widgets/catagory_item_icon.dart';
import '../../../common/widgets/home_appbar.dart';
import '../../../common/widgets/home_product_banner.dart';
import '../../../common/widgets/home_session_invite_card.dart';
import '../../../common/widgets/plan_card.dart';
import '../../../common/widgets/section_heading.dart';
import '../../../common/widgets/simple_dialog.dart';
import '../authentication/controllers/location_controller.dart';
import '../budy/all_session_invites_screen.dart';
import '../budy/buddy_find_swipper.dart';
import '../budy/specific_catagory_buddies_match_screen.dart';
import '../notification/notifications_screen.dart';
import '../profile/buddy_profile_screen.dart';
import '../scanning/qr_scan_screen.dart';
import '../subscription/premium_plans_screen.dart';
import '../subscription/plans_controller.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationController locationController = Get.find();
  final HomeController home = Get.find();
  final PremiumPlanController planController = Get.find();

  final PageController _pageController = PageController(initialPage: 1000);
  late Timer _timer;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
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

  void checkPremiumAndProceed(VoidCallback onAllowed) {
    if (home.hasPremium) {
      onAllowed();
      return;
    }

    Get.dialog(
      const SimpleDialogWidget(
        message: "Please purchase our premium plans to use this functionality.",
        icon: Icons.lock_outline,
        iconColor: XColors.primary,
        buttonText: "Ok",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: Obx(() {
          final me = home.me.value;
          return CustomHomeAppBar(
            name: (me?.displayName?.trim().isNotEmpty == true) ? me!.displayName! : 'FitBud User',
            location: locationController.currentLocation.value,
            country: (me?.city?.trim().isNotEmpty == true) ? me!.city! : 'Pakistan',
            imagePath: (me?.photoUrl?.trim().isNotEmpty == true) ? me!.photoUrl! : 'assets/images/profile.png',
            onLocationTap: () async {
              final pickedLocation = await showLocationBottomSheet(context);
              if (pickedLocation != null) locationController.updateLocation(pickedLocation);
            },
            onScanTap: () => Get.to(() => QRScanScreen()),
            onNotificationTap: () => Get.to(() => NotificationsScreen()),
            hasPremium: home.hasPremium,
          );
        }),
      ),

      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // ---------------- Categories (still static; can be from Firestore later) ----------------
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
                              Get.to(() => SpecificCatagoryBuddiesMatchScreen());
                            });
                          },
                        );
                      },
                    ),
                  ),

                  // ---------------- Products/Banners from Firebase ----------------
                  const SizedBox(height: 6),
                  Obx(() {
                    if (home.loadingProducts.value) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (home.errProducts.value.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(home.errProducts.value, style: TextStyle(color: XColors.bodyText.withOpacity(0.7), fontSize: 11)),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {}, // products stream auto-retries; keep for UI consistency
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final prods = home.products;
                    if (prods.isEmpty) {
                      return const SizedBox(height: 180, child: Center(child: Text('No products found')));
                    }

                    return SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: prods.length,
                        itemBuilder: (context, index) {
                          final p = prods[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: HomeProductBanner(
                              title: p.title,
                              description: p.description,
                              price: 'Rs. ${p.price.toStringAsFixed(0)}',
                              imagePath: p.imageUrl.isNotEmpty ? p.imageUrl : 'assets/images/product1.png',
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ---------------- Session Invites from Firebase ----------------
                  XHeading(
                    title: 'Session Invites',
                    actionText: 'View All',
                    onActionTap: () => Get.to(() => AllSessionInvitesScreen()),
                    sidePadding: 16,
                  ),
                  const SizedBox(height: 16),

                  Obx(() {
                    if (home.loadingInvites.value) {
                      return const SizedBox(
                        height: 185,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (home.errInvites.value.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(home.errInvites.value, style: TextStyle(color: XColors.bodyText.withOpacity(0.7), fontSize: 11)),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {}, // stream auto-retries
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (home.invites.isEmpty) {
                      return Column(
                        children: [
                          Image.asset('assets/images/no-sessions.png', width: 180),
                          const SizedBox(height: 4),
                          const Text("No session invites found", style: TextStyle(color: XColors.bodyText, fontSize: 10)),
                          const SizedBox(height: 30),
                        ],
                      );
                    }

                    return SizedBox(
                      height: 185,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: home.invites.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final inv = home.invites[index];
                          return HomeSessionInviteCard(
                            category: (inv.sessionCategory?.isNotEmpty == true) ? inv.sessionCategory! : 'Session',
                            invitedBy: (inv.invitedByName?.isNotEmpty == true) ? inv.invitedByName! : 'Someone',
                            dateTime: inv.sessionDateTime?.toString() ?? '',
                            location: (inv.sessionLocationText?.isNotEmpty == true) ? inv.sessionLocationText! : '',
                            image: (inv.sessionImageUrl?.isNotEmpty == true) ? inv.sessionImageUrl! : 'assets/images/gym.jpeg',

                            nameOnTap: () {
                              Get.to(() => BuddyProfileScreen(scenario: BuddyScenario.existingBuddy));
                            },
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // ---------------- Premium Plans (Firebase plans collection) ----------------
                  XHeading(
                    title: 'Premium Plans',
                    actionText: 'View All',
                    onActionTap: () => Get.to(() => const PremiumPlanScreen()),
                    sidePadding: 16,
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      if (planController.loading.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (planController.error.value.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(planController.error.value, style: TextStyle(color: XColors.bodyText.withOpacity(0.7), fontSize: 11)),
                              const SizedBox(height: 10),
                              OutlinedButton(onPressed: planController.refreshPlans, child: const Text('Retry')),
                            ],
                          ),
                        );
                      }

                      final firebasePlans = planController.plans;
                      if (firebasePlans.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No active plans found.', style: TextStyle(color: XColors.bodyText, fontSize: 11)),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: firebasePlans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final p = firebasePlans[index];
                          return PlanCard(
                            index: index,
                            title: p.name,
                            description: p.description,
                            price: p.price.round(),
                            duration: '${p.durationDays} days',
                            features: p.features,
                          );
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ---------------- FAB (locked unless premium) ----------------
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
