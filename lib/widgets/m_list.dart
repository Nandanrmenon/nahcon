import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class MListItemData {
  final String title;
  final String subtitle;
  final Function onTap;
  final Widget? leading;
  final Widget? suffix;
  final bool selected;

  MListItemData({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
    this.suffix,
    this.selected = false,
  });
}

class MListHeader extends StatelessWidget {
  final String title;
  const MListHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class MListView extends StatefulWidget {
  final items;
  final bool? enableScroll;
  final bool? shrinkWrap;
  const MListView(
      {super.key, required this.items, this.enableScroll, this.shrinkWrap});

  @override
  State<MListView> createState() => _MListViewState();
}

class _MListViewState extends State<MListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: widget.shrinkWrap != null ? false : true,
      physics: widget.enableScroll != null
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        bool isLastItem(int index) {
          if (UniversalPlatform.isWeb) {
            return index == widget.items.length - 1;
          } else {
            return index == widget.items.length - 1;
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16.0, right: 4.0),
              title: Text(widget.items[index].title),
              leading: widget.items[index].leading,
              subtitle: widget.items[index].subtitle.isNotEmpty
                  ? Text(widget.items[index].subtitle)
                  : null,
              onTap: () => widget.items[index].onTap(),
              trailing: widget.items[index].suffix,
              selected: widget.items[index].selected,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(
          height: 4,
        );
      },
    );
  }
}
