import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';

class MembersDialog extends StatelessWidget {
  final List<Map<String, String>> members;
  final VoidCallback onGroupMemberTap;

  const MembersDialog({
    super.key,
    required this.members,
    required this.onGroupMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: XColors.secondaryBG,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: 400, // fixed height, scrollable inside
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Group Members",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: XColors.primaryText,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return GestureDetector(
                      onTap: onGroupMemberTap,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage(member['avatar'] ?? ''),
                            backgroundColor: XColors.secondaryBG,
                          ),
                          SizedBox(width: 12),
                          Text(
                            member['name'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: XColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: XColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
