import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitbud/utils/colors.dart';

import '../../domain/models/sessions/session.dart';
import '../../domain/repos/repo_provider.dart';

class SessionInviteSheet extends StatefulWidget {
  final bool isGroup;
  final String? groupName;
  final int? membersCount;

  /// NEW (no UI impact): for direct buddy invite
  final String? invitedUserId;

  const SessionInviteSheet({
    super.key,
    this.isGroup = false,
    this.groupName,
    this.membersCount,
    this.invitedUserId,
  });

  @override
  State<SessionInviteSheet> createState() => _SessionInviteSheetState();
}

class _SessionInviteSheetState extends State<SessionInviteSheet> {
  final activities = ["Gym", "Running", "Cycling", "Sports", "Yoga"];
  final gymList = [
    "Iron Fitness",
    "Muscle Factory",
    "Power House",
    "Fitness Club",
    "Not found in the list",
  ];

  String? selectedActivity;
  String? selectedGym;
  String? location;
  DateTime? selectedDateTime;

  final _locationController = TextEditingController();

  bool _saving = false;

  Repos get repos => Get.find<Repos>();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // -----------------------------
  // Pick Date & Time (No Past)
  // -----------------------------
  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: XColors.primary,
            onPrimary: Colors.white,
            surface: XColors.secondaryBG,
            onSurface: XColors.primaryText,
          ), dialogTheme: DialogThemeData(backgroundColor: XColors.primaryBG),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: XColors.primary,
            onPrimary: Colors.white,
            surface: XColors.secondaryBG,
            onSurface: XColors.primaryText,
          ), dialogTheme: DialogThemeData(backgroundColor: XColors.primaryBG),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (combined.isBefore(now)) {
      Get.snackbar(
        "Invalid Time",
        "You cannot select past date/time",
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => selectedDateTime = combined);
  }

  // -----------------------------
  // Custom Gym / Location Dialog
  // -----------------------------
  Future<void> openCustomLocationDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: XColors.secondaryBG,
        title: Text(
          "Enter Session Location",
          style: TextStyle(color: XColors.primary, fontSize: 12),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: XColors.primaryText),
          decoration: InputDecoration(
            hintText: "Enter location",
            hintStyle: TextStyle(
              color: XColors.secondaryText.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: XColors.borderColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: XColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: XColors.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                location = controller.text.trim();
                selectedGym = null;
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  SessionType _mapSessionType(String activity) {
    final a = activity.toLowerCase();
    if (a == 'gym') return SessionType.gym;
    if (a == 'sports') return SessionType.game;
    return SessionType.other;
  }

  // -----------------------------
  // Save Session (WORKING)
  // -----------------------------
  Future<void> saveSession() async {
    if (_saving) return;

    if (selectedActivity == null) {
      Get.snackbar(
        "Required",
        "Please select activity",
        backgroundColor: XColors.warning.withValues(alpha: 0.7),
        colorText: XColors.primaryText,
      );
      return;
    }

    if (selectedActivity == "Gym" && location == null) {
      Get.snackbar(
        "Required",
        "Please select a gym or enter custom location",
        backgroundColor: XColors.warning.withValues(alpha: 0.7),
        colorText: XColors.primaryText,
      );
      return;
    }

    if (selectedActivity != "Gym" && _locationController.text.trim().isEmpty) {
      Get.snackbar(
        "Required",
        "Please enter location",
        backgroundColor: XColors.warning.withValues(alpha: 0.7),
        colorText: XColors.primaryText,
      );
      return;
    }

    if (selectedDateTime == null) {
      Get.snackbar(
        "Required",
        "Please select date & time",
        backgroundColor: XColors.warning.withValues(alpha: 0.7),
        colorText: XColors.primaryText,
      );
      return;
    }

    // Direct (non-group) must know who to invite
    if (!widget.isGroup) {
      final uid = (widget.invitedUserId ?? '').trim();
      if (uid.isEmpty) {
        Get.snackbar(
          "Error",
          "No buddy selected to invite",
          backgroundColor: Colors.red.withValues(alpha: 0.2),
          colorText: Colors.red,
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final finalLocation = (selectedActivity == "Gym")
          ? (location ?? '')
          : _locationController.text.trim();

      final session = Session(
        id: '', // repo creates id
        type: _mapSessionType(selectedActivity!),
        title: selectedActivity!, // keep current UI intent
        description: '', // you can add later without UI change
        createdByUserId: '', // repo overrides with auth uid
        startAt: selectedDateTime,
        endAt: null,
        location: null, // optional later
        locationName: finalLocation,
        gymId: '',
        status: SessionStatus.scheduled,
        isGroupSession: widget.isGroup,
        groupId: '',
        createdAt: null,
        updatedAt: null,
      );

      // 1) Create session
      final sessionId = await repos.sessionRepo.createSession(session);

      // 2) Send invite (direct buddy)
      if (!widget.isGroup) {
        await repos.sessionRepo.inviteUserToSession(
          sessionId: sessionId,
          invitedUserId: widget.invitedUserId!.trim(),
        );
      }

      // Close sheet and show success
      if (mounted) Navigator.pop(context);

      Get.snackbar(
        "Success",
        "Your session invite has been sent!",
        backgroundColor: XColors.primary.withValues(alpha: 0.7),
        colorText: XColors.bodyText,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        colorText: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sheet background color
      decoration: BoxDecoration(
        color: XColors.primaryBG,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          left: 18,
          right: 18,
          top: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: XColors.borderColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title
            Text(
              "Create Session Invite",
              style: TextStyle(
                color: XColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Group Info Row (if group)
            if (widget.isGroup)
              Row(
                children: [
                  Icon(Icons.group, color: XColors.primaryText, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.groupName ?? "Group",
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.person, color: XColors.primaryText, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "${widget.membersCount ?? 0} members",
                    style: TextStyle(color: XColors.primaryText, fontSize: 12),
                  ),
                ],
              ),
            if (widget.isGroup) const SizedBox(height: 18),

            // Activity Dropdown
            Text("Activity", style: TextStyle(color: XColors.secondaryText, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedActivity,
              decoration: _inputDecoration(),
              dropdownColor: XColors.secondaryBG,
              style: TextStyle(color: XColors.primaryText),
              items: activities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (value) {
                selectedActivity = value;
                selectedGym = null;
                location = null;
                _locationController.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 18),

            // Location / Gym
            if (selectedActivity == "Gym") ...[
              Text("Gym Location", style: TextStyle(color: XColors.secondaryText, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedGym,
                decoration: _inputDecoration(),
                dropdownColor: XColors.secondaryBG,
                style: TextStyle(color: XColors.primaryText),
                items: gymList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (value) async {
                  if (value == "Not found in the list") {
                    await openCustomLocationDialog();
                  } else {
                    selectedGym = value;
                    location = value;
                    setState(() {});
                  }
                },
              ),
              if (selectedGym == null && location != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: XColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Custom Location: $location",
                    style: TextStyle(
                      color: XColors.primaryText,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Text("Location", style: TextStyle(color: XColors.secondaryText, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                style: TextStyle(color: XColors.primaryText),
                decoration: _inputDecoration().copyWith(
                  hintText: "Enter location",
                  hintStyle: TextStyle(
                    color: XColors.secondaryText.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onChanged: (val) => location = val.trim(),
              ),
            ],

            const SizedBox(height: 18),

            // Date & Time
            Text("Date & Time", style: TextStyle(color: XColors.secondaryText, fontSize: 12)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => pickDateTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: XColors.secondaryBG,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: XColors.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDateTime == null
                          ? "Select date & time"
                          : "${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} • "
                          "${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: XColors.primaryText.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Icon(Icons.calendar_month, size: 18, color: XColors.secondaryText),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: XColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : saveSession,
                child: Text(
                  "Create Session",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: XColors.secondaryBG,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: XColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: XColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
