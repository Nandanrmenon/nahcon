import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nahcon/utils/constants.dart';

class MovieCard extends StatefulWidget {
  final String title;
  final String? posterUrl;
  final String? releaseDate;
  final double? rating;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  const MovieCard({
    super.key,
    required this.title,
    this.posterUrl,
    this.releaseDate,
    this.rating,
    required this.onTap,
    this.onPlay,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onHover: (hovering) => setState(() => _isHovered = hovering),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: _isHovered ? 4 : 1,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.all(0),
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      width: 2.0,
                      color: _isHovered
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(15)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  widget.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.posterUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Icon(Symbols.broken_image, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Symbols.movie, size: 48),
                        ),
                  // Hover Overlay
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(_isHovered ? 0.7 : 0.0),
                        ],
                      ),
                    ),
                  ),
                  widget.onPlay != null
                      ? Positioned(
                          bottom: 10,
                          left: 10,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isHovered ? 1.0 : 0.0,
                            child: IconButton.filled(
                              style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStatePropertyAll(kAppColor),
                                  foregroundColor:
                                      WidgetStatePropertyAll(Colors.black)),
                              onPressed: () => widget.onPlay!(),
                              icon: Icon(
                                Symbols.play_arrow_rounded,
                                // fill: 1,
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (widget.rating != null)
                  Flexible(
                    child: Row(
                      children: [
                        const Icon(Symbols.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.rating!.toStringAsFixed(1),
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.rating == null)
                  SizedBox(
                    height: 17,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
