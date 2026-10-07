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
import '../subscription/premium_plans_screen.dart';
import '../subscription/plans_controller.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ Don't call Get.find() in field initializers (binding timing + better stability)
  late final LocationController locationController;
  late final HomeController home;
  late final PremiumPlanController planController;

  final PageController _pageController = PageController(initialPage: 1000);

  Timer? _autoScrollTimer;
  bool _userInteractingWithBanner = false;
  Timer? _interactionDebounce;

  final ScrollController _scrollController = ScrollController();

  // ✅ smooth FAB show/hide without rebuilding whole screen
  final ValueNotifier<bool> _fabVisible = ValueNotifier<bool>(true);
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();

    locationController = Get.find<LocationController>();
    home = Get.find<HomeController>();
    planController = Get.find<PremiumPlanController>();

    _startBannerAutoScroll();
    _setupFabScrollListener();
  }

  void _startBannerAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_userInteractingWithBanner) return;
      if (!_pageController.hasClients) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  void _setupFabScrollListener() {
    const double sensitivity = 8;

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final offset = _scrollController.position.pixels;
      final diff = offset - _lastOffset;

      if (diff > sensitivity) {
        if (_fabVisible.value) _fabVisible.value = false;
      } else if (diff < -sensitivity) {
        if (!_fabVisible.value) _fabVisible.value = true;
      }

      _lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _interactionDebounce?.cancel();

    _pageController.dispose();
    _scrollController.dispose();
    _fabVisible.dispose();

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
          final me = home.me;

          return CustomHomeAppBar(
            name: (me?.displayName?.trim().isNotEmpty == true)
                ? me!.displayName!
                : 'FitBud User',
            location: locationController.locationLabel,
            country: locationController.cityLabel,
            imagePath: (me?.photoUrl?.trim().isNotEmpty == true)
                ? me!.photoUrl!
                : 'assets/images/profile.png',
            onLocationTap: () async {
              final pickedLocation = await showLocationBottomSheet(context);
              if (pickedLocation != null) {
                await locationController.selectAndPersist(pickedLocation);
              }
            },
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
                  // ---------------- Categories ----------------
                  SizedBox(
                    height: 100,
                    child: Obx(() {
                      if (home.loadingActivities.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (home.errActivities.value.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  home.errActivities.value,
                                  style: TextStyle(
                                    color: XColors.bodyText.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: home.fetchActivities,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final cats = home.activities;
                      if (cats.isEmpty) {
                        return const Center(child: Text('No categories found'));
                      }

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final a = cats[index];

                          return CategoryHomeIcon(
                            iconPath: a.iconUrl.isNotEmpty
                                ? a.iconUrl
                                : 'assets/icons/badminton.png',
                            title: a.name,
                            onTap: () {
                              checkPremiumAndProceed(() {
                                Get.to(() => SpecificCatagoryBuddiesMatchScreen(
                                  activity: a.name,
                                ));
                              });
                            },
                          );
                        },
                      );
                    }),
                  ),

                  // ---------------- Products/Banners ----------------
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              home.errProducts.value,
                              style: TextStyle(
                                color: XColors.bodyText.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final prods = home.products;
                    if (prods.isEmpty) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: Text('No products found')),
                      );
                    }

                    return SizedBox(
                      height: 180,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollStartNotification) {
                            _userInteractingWithBanner = true;
                            _interactionDebounce?.cancel();
                          } else if (n is ScrollEndNotification) {
                            _interactionDebounce?.cancel();
                            _interactionDebounce =
                                Timer(const Duration(milliseconds: 700), () {
                                  _userInteractingWithBanner = false;
                                });
                          }
                          return false;
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          itemBuilder: (context, index) {
                            final realIndex = index % prods.length;
                            final p = prods[realIndex];

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: HomeProductBanner(
                                title: p.title,
                                description: p.description,
                                price: 'Rs. ${p.price.toStringAsFixed(0)}',
                                imagePath: p.imageUrl.isNotEmpty
                                    ? p.imageUrl
                                    : 'assets/images/product1.png',
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ---------------- Session Invites ----------------
                  XHeading(
                    title: 'Session Invites',
                    actionText: 'View All',
                    onActionTap: () =>
                        Get.to(() => const AllSessionInvitesScreen()),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              home.errInvites.value,
                              style: TextStyle(
                                color: XColors.bodyText.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {},
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
                          const Text(
                            "No session invites found",
                            style: TextStyle(color: XColors.bodyText, fontSize: 10),
                          ),
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
                            category: (inv.sessionCategory?.isNotEmpty == true)
                                ? inv.sessionCategory!
                                : 'Session',
                            invitedBy: (inv.invitedByName?.isNotEmpty == true)
                                ? inv.invitedByName!
                                : 'Someone',
                            dateTime: inv.sessionDateTime?.toString() ?? '',
                            location: (inv.sessionLocationText?.isNotEmpty == true)
                                ? inv.sessionLocationText!
                                : '',
                            image: (inv.sessionImageUrl?.isNotEmpty == true)
                                ? inv.sessionImageUrl!
                                : 'assets/images/gym.jpeg',
                            invite: inv, // <-- NEW (required)
                            nameOnTap: () {
                              final buddyUserId = inv.invitedByUserId;
                              if (buddyUserId.isEmpty) return;

                              Get.to(() => BuddyProfileScreen(
                                buddyUserId: buddyUserId,
                                scenario: BuddyScenario.existingBuddy,
                              ));
                            },
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // ---------------- Premium Plans ----------------
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
                              Text(
                                planController.error.value,
                                style: TextStyle(
                                  color: XColors.bodyText.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: planController.refreshPlans,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final firebasePlans = planController.plans;
                      if (firebasePlans.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No active plans found.',
                            style: TextStyle(color: XColors.bodyText, fontSize: 11),
                          ),
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

          // ---------------- FAB ----------------
          Positioned(
            bottom: 24,
            right: 16,
            child: ValueListenableBuilder<bool>(
              valueListenable: _fabVisible,
              builder: (_, visible, __) {
                return AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  offset: visible ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: visible ? 1 : 0,
                    child: FloatingActionButton(
                      backgroundColor: XColors.primary.withValues(alpha: 0.7),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}