import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/imports/common_imports.dart';

class GroupNameEditScreen extends StatefulWidget {
  final String groupId;
  final String keyToEdit;
  final String initialValue;

  const GroupNameEditScreen({
    super.key,
    required this.groupId,
    required this.keyToEdit,
    required this.initialValue,
  });

  @override
  State<GroupNameEditScreen> createState() => _GroupNameEditScreenState();
}

class _GroupNameEditScreenState extends State<GroupNameEditScreen> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  Future<void> _updateGroupField() async {
    final updatedValue = _controller.text.trim();
    if (updatedValue.isEmpty) {
      Messenger.alertError('Field cannot be empty');
      return;
    }

    final accessToken = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    setState(() => _isLoading = true);

    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final payload = {
        "groupId": widget.groupId,
        widget.keyToEdit: updatedValue,
      };

      final response = await Dio().put(
        "https://api.nowdigitaleasy.com/wschat/v1/group",
        data: payload,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, updatedValue);
        Messenger.alertSuccess("Group updated successfully");
      } else {
        throw Exception('Unexpected status: ${response.statusCode}');
      }
    } catch (e) {
      Messenger.alertError('Update failed. Please try again.');
      print("❌ Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroupName = widget.keyToEdit == 'group_name';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(isGroupName ? 'Edit Group Name' : 'Edit Description'),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    isGroupName ? 'Enter group name' : 'Enter description',
                prefixIcon: const Icon(Icons.edit, color: Colors.green),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.grey),
                  onPressed: () {},
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.text.trim().isNotEmpty && !_isLoading
                        ? _updateGroupField
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
