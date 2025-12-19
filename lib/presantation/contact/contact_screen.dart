import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ContactsScreen(),
    );
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> contacts =
          await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
      });
    } else {
      log("Permission denied to read contacts");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("Contacts"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: const BoxDecoration(
            color: Color(0xFF0011FF),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: "Nde"),
            Tab(text: "Device"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _contacts.isEmpty
                    ? const Text("No contacts available.")
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(contact.displayName.isNotEmpty
                                    ? contact.displayName[0]
                                    : "?"),
                              ),
                              title: Text(contact.displayName),
                              subtitle: Text(
                                contact.phones.isNotEmpty
                                    ? contact.phones.first.number
                                    : "No Phone Number",
                              ));
                        },
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickContacts,
                  child: const Text('Pick Contacts'),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _contacts.isEmpty
                    ? const Text("No contacts available.")
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(contact.displayName.isNotEmpty
                                    ? contact.displayName[0]
                                    : "?"),
                              ),
                              title: Text(contact.displayName),
                              subtitle: Text(
                                contact.phones.isNotEmpty
                                    ? contact.phones.first.number
                                    : "No Phone Number",
                              ));
                        },
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickContacts,
                  child: const Text('Pick Contact'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
