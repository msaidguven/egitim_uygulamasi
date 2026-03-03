import 'dart:math';

import 'package:flutter/material.dart';

class MapLayoutComponent extends StatefulWidget {
  const MapLayoutComponent({
    super.key,
    required this.center,
    required this.nodes,
    this.maxNodesPerPage = 8,
  });

  final Widget center;
  final List<Widget> nodes;
  final int maxNodesPerPage;

  @override
  State<MapLayoutComponent> createState() => _MapLayoutComponentState();
}

class _MapLayoutComponentState extends State<MapLayoutComponent> {
  static const double _nodeHalfExtent = 41; // Size 82 / 2
  static const double _centerHalfExtent = 110; 
  static const double _centerClearance = 32;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return Center(child: widget.center);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeMinRadius = _centerHalfExtent + _nodeHalfExtent + _centerClearance;
        final maxRadiusByBounds = min(
          constraints.maxWidth / 2 - _nodeHalfExtent - 12,
          constraints.maxHeight / 2 - _nodeHalfExtent - 12,
        );
        
        // Calculate radius based on count to avoid overcrowding, but keep it safe from center.
        final radius = max(safeMinRadius, maxRadiusByBounds.clamp(140.0, 380.0));

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildRadialLayer(
                nodes: widget.nodes,
                radius: radius,
              ),
              Align(
                alignment: Alignment.center,
                child: widget.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadialLayer({
    required List<Widget> nodes,
    required double radius,
  }) {
    final count = nodes.length;
    if (count == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cx = width / 2;
        final cy = height / 2;

        // Use a full circle if many nodes, or a top-heavy arc if few.
        final isLargeCount = count > 6;
        final startAngle = isLargeCount ? -pi / 2 : -pi * 0.90;
        final sweep = isLargeCount ? pi * 2 : pi * 0.80;
        final step = count == 1 ? 0.0 : sweep / (isLargeCount ? count : (count - 1));

        return Stack(
          children: List.generate(count, (index) {
            final angle = startAngle + (step * index);
            
            // Vertical ellipse to give more room for the castle
            final dyMultiplier = 1.18; 
            
            final dx = cos(angle) * radius;
            final dy = sin(angle) * radius * dyMultiplier;

            return Positioned(
              left: cx + dx,
              top: cy + dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: nodes[index],
              ),
            );
          }),
        );
      },
    );
  }
}
