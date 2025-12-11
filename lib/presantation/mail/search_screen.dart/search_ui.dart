import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  bool _isReadOnly = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: ClipPath(
            child: AppBar(
              backgroundColor: AppColors.bg,
              elevation: 1,
              // automaticallyImplyLeading: false,
              title: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.cancel, color: AppColors.iconDefault),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        readOnly: _isReadOnly,
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: AppColors.iconDefault),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: AppColors.headingText),
                        onTap: () {
                          setState(() {
                            _isReadOnly = false;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.mic, color: AppColors.iconActive),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Wrap(
            spacing: 8,
            children: [
              _buildLabelChip('Attachments'),
              _buildLabelChip('7 days'),
              _buildLabelChip('For me'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.bg,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}
