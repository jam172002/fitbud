class FirestorePaths {
  // Root collections
  static const users = 'users';
  static const buddyRequests = 'buddyRequests';
  static const friendships = 'friendships';
  static const groups = 'groups';
  static const conversations = 'conversations';
  static const sessions = 'sessions';
  static const String activities = 'activities';
  static const gyms = 'gyms';
  static const plans = 'plans';
  static const subscriptions = 'subscriptions';
  static const transactions = 'transactions';
  static const scans = 'scans';
  static const notifications = 'notifications';


  // User subcollections
  static String userSettings(String uid) => '$users/$uid/settings';
  static String userDeviceTokens(String uid) => '$users/$uid/deviceTokens';
  static String userScanHistory(String uid) => '$users/$uid/scanHistory';
  static String userNotifications(String uid) => '$users/$uid/notifications';

  // Group subcollections
  static String groupMembers(String groupId) => '$groups/$groupId/members';
  static String groupInvites(String groupId) => '$groups/$groupId/invites';
  static String userGroupMemberships(String uid) =>
      '$users/$uid/groupMemberships';

  // Conversation subcollections
  static String conversationParticipants(String conversationId) => '$conversations/$conversationId/participants';
  static String conversationMessages(String conversationId) => '$conversations/$conversationId/messages';
  static String messageReceipts(String conversationId, String messageId) =>
      '$conversations/$conversationId/messages/$messageId/receipts';

  // Session subcollections
  static String sessionInvites(String sessionId) => '$sessions/$sessionId/invites';
  static String sessionParticipants(String sessionId) => '$sessions/$sessionId/participants';

  static String userConversations(String uid) =>
      '$users/$uid/conversations';


}
