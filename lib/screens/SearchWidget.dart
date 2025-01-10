import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final Function(String) onSearch;
  final bool isSearchingClasses;
  final Function() onToggleSearchType;

  const SearchWidget({
    super.key,
    required this.onSearch,
    required this.isSearchingClasses,
    required this.onToggleSearchType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    isSearchingClasses ? 'Search Classes' : 'Search Students',
                border: OutlineInputBorder(),
              ),
              onChanged: onSearch,
            ),
          ),
          IconButton(
            icon: Icon(
              isSearchingClasses ? Icons.school : Icons.person,
              color: Colors.blueAccent,
            ),
            onPressed: onToggleSearchType,
          ),
        ],
      ),
    );
  }
}
