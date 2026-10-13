import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Peta sungguhan (ubin OpenStreetMap lewat [flutter_map]) dengan pin hijau di
/// tengah — pengganti gambar statis `photo-map.jpg` yang lama.
///
/// Alasan memakai OpenStreetMap dan bukan Google Maps: ubin OSM tidak menuntut
/// kunci API maupun akun penagihan, jadi proyek ini bisa dijalankan siapa pun
/// tanpa menyiapkan Google Cloud. Konsekuensinya peta butuh internet saat
/// aplikasi berjalan dan gaya petanya berbeda dari tangkapan Google Maps pada
/// frame Figma — perbedaan itu disengaja dan dicatat di `docs/testing.md`.
///
/// Titik yang dipilih adalah **pusat** peta; pin selalu di tengah (seperti
/// design `58:222`/`127:721`), sehingga menggeser peta sekaligus memindahkan
/// titik. Atribusi penyedia ubin wajib ikut ditampilkan.
class AgroMap extends StatefulWidget {
  const AgroMap({
    super.key,
    required this.center,
    this.zoom = 16,
    this.interactive = true,
    this.onCenterChanged,
  });

  /// Titik yang ditunjuk pin (pusat peta).
  final LatLng center;

  final double zoom;

  /// Peta boleh digeser/di-zoom. Langkah 1 memakai `false` karena kartu
  /// konfirmasi dan pin tidak perlu digerakkan di sana; pemilih lokasi memakai
  /// `true` supaya titik bisa dicari dengan menggeser peta.
  final bool interactive;

  /// Dipanggil setiap pengguna menggeser/zoom peta — pusat baru untuk pin.
  final void Function(LatLng center)? onCenterChanged;

  @override
  State<AgroMap> createState() => _AgroMapState();
}

class _AgroMapState extends State<AgroMap> {
  /// Ubin OpenStreetMap. `userAgentPackageName` ikut dikirim supaya permintaan
  /// tidak ditolak kebijakan ubin OSM (agen tak dikenal diblokir), dan
  /// `silenceExceptions` membuat ubin gagal — misalnya saat tanpa internet —
  /// jatuh sebagai kotak kosong, bukan galat merah di atas peta.
  static const String _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
            // Batas lintang bawaan saja: ubin tidak tersedia di dekat kutub,
            // jadi peta tidak boleh digeser sampai ke sana.
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
        // Pin digambar di atas peta, bukan sebagai `MarkerLayer`, supaya
        // ukurannya persis seperti design (42x56,7 pada kotak 34,3x41,7).
        const IgnorePointer(child: Center(child: _MapPin())),
      ],
    );
  }
}

/// Pin peta hijau di `assets/icons/map-pointer.svg`.
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
