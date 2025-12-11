import 'package:shared_preferences/shared_preferences.dart';

class MailboxStorage {
  static const String _mailboxKey = 'selected_mailbox_id';
  static const String draftsMailboxKey = 'drafts_mailbox_id';
  static const String archiveKey = 'archive_mailbox_id';
  static const String inboxKey = 'inbox_mailbox_id';
  static const String sentKey ='sent_mailbox_id';

  

  // Save mailbox ID
  static Future<void> saveMailboxId(String mailboxId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mailboxKey, mailboxId);
  }

  // Retrieve mailbox ID
  static Future<String?> getMailboxId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mailboxKey);
  }




static Future<void> saveDraftsMailboxId(String draftsMailboxId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(draftsMailboxKey, draftsMailboxId);
}

static Future<String?> getDraftsMailboxId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(draftsMailboxKey);
}




static Future<void> saveArchiveMailboxId(String archiveMailboxId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(archiveKey, archiveMailboxId);
  }

  // Retrieve Archive Mailbox ID
  static Future<String?> getArchiveMailboxId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(archiveKey);
  }


// Save Inbox Mailbox ID
static Future<void> saveInboxMailboxId(String inboxMailboxId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(inboxKey, inboxMailboxId);
}

// Retrieve Inbox Mailbox ID
static Future<String?> getInboxMailboxId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(inboxKey);
}



// Save Sent Mailbox ID
static Future<void> saveSentMailboxId(String sentMailboxId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(sentKey, sentMailboxId);
}

// Retrieve Sent Mailbox ID
static Future<String?> getSentMailboxId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(sentKey);
}


}