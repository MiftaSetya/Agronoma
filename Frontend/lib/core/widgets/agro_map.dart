import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

class AgroMap extends StatefulWidget {
  const AgroMap({
    super.key,
    required this.center,
    this.zoom = 16,
    this.interactive = true,
    this.onCenterChanged,
  });

  final LatLng center;

  final double zoom;

  final bool interactive;

  final void Function(LatLng center)? onCenterChanged;

  @override
  State<AgroMap> createState() => _AgroMapState();
}

class _AgroMapState extends State<AgroMap> {
  static const String _osmUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  late final TileProvider _tiles = NetworkTileProvider(silenceExceptions: true);

  @override
  void dispose() {
    _tiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            minZoom: 3,
            maxZoom: 19,

            cameraConstraint: CameraConstraint.containLatitude(),
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
            onPositionChanged: (camera, hasGesture) {
              if (!hasGesture) return;
              widget.onCenterChanged?.call(camera.center);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: _osmUrl,
              userAgentPackageName: 'com.agronoma.frontend',
              tileProvider: _tiles,
            ),
            const SimpleAttributionWidget(source: Text('OpenStreetMap')),
          ],
        ),

        const IgnorePointer(child: Center(child: _MapPin())),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return const AgroIcon(
      AppAssets.mapPointer,
      size: 42,
      height: 56.714,
      semanticLabel: 'Titik lokasi terpilih',
    );
  }
}
