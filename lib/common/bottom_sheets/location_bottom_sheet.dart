import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../domain/models/auth/user_address.dart';
import '../../domain/repos/repo_provider.dart';
import '../../presentation/screens/authentication/screens/location_selector_screen.dart';

Future<UserAddress?> showLocationBottomSheet(BuildContext context) {
  final authRepo = Get.find<Repos>().authRepo;


  String? selectedId;

  return showModalBottomSheet<UserAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: XColors.secondaryBG,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Choose Your Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: XColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Saved address",
                    style: TextStyle(fontSize: 13, color: XColors.primary),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<List<UserAddress>>(
                    stream: authRepo.watchMyAddresses(limit: 50),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Failed to load addresses: ${snap.error}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        );
                      }

                      final list = snap.data ?? const <UserAddress>[];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No saved addresses found.',
                                style: TextStyle(
                                  color: XColors.bodyText.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _AddLocationLink(),
                            ],
                          ),
                        );
                      }

                      // Auto-select default (or first) once
                      selectedId ??= (list.firstWhereOrNull((a) => a.isDefault)?.id) ?? list.first.id;

                      return Column(
                        children: [
                          ...list.map((a) {
                            final isSelected = selectedId == a.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _LocationTile(
                                title: a.title,
                                subtitle: a.subtitle,
                                isSelected: isSelected,
                                onTap: () => setState(() => selectedId = a.id),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          _AddLocationLink(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Fetch selected address from current stream snapshot is not accessible here directly,
                        // so do a one-time fetch. (Fast and safe.)
                        final list = await authRepo.getMyAddressesOnce(limit: 50);
                        final selected = list.firstWhereOrNull((x) => x.id == selectedId);
                        Get.back(result: selected);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: XColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm Selection",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _AddLocationLink extends StatelessWidget {
  const _AddLocationLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => LocationSelectorScreen());
      },
      child: const Text(
        'Add Location',
        style: TextStyle(color: Colors.blue),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationTile({
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? XColors.primaryText.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Iconsax.location5, size: 22, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: XColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: XColors.bodyText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.check_circle,
                  color: XColors.primary,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
