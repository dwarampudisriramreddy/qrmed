import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/utils/web_download_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class AdminMassStickersScreen extends StatefulWidget {
  const AdminMassStickersScreen({super.key});

  @override
  State<AdminMassStickersScreen> createState() =>
      _AdminMassStickersScreenState();
}

class _AdminMassStickersScreenState extends State<AdminMassStickersScreen> {
  College? _selectedCollege;
  final TextEditingController _fromIdController = TextEditingController();
  final TextEditingController _toIdController = TextEditingController();
  bool _isGenerating = false;
  double _progress = 0.0;
  String _statusMessage = '';
  Uint8List? _logoBytes;
  Uint8List? _supremeLogoBytes;

  final Map<String, GlobalKey> _stickerKeys = {};
  List<Equipment> _equipmentsToPrint = [];
  Equipment? _currentEquipmentToRender;

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _loadSupremeLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
      // Precache the logo to ensure it's ready for sticker generation
      precacheImage(const AssetImage('assets/favicon.png'), context);
      precacheImage(const AssetImage('assets/supreme_logo_transparent.png'), context);
    });
  }

  Future<void> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/favicon.png');
      final bytes = data.buffer.asUint8List();
      if (mounted) {
        setState(() {
          _logoBytes = bytes;
        });
        debugPrint('✅ favicon.png bytes loaded');
      }
    } catch (e) {
      debugPrint('❌ Error loading favicon.png bytes: $e');
    }
  }

  Future<void> _loadSupremeLogo() async {
    try {
      final data = await rootBundle.load('assets/supreme_logo_transparent.png');
      final bytes = data.buffer.asUint8List();
      if (mounted) {
        setState(() {
          _supremeLogoBytes = bytes;
        });
        debugPrint('✅ supreme_logo_transparent.png bytes loaded');
      }
    } catch (e) {
      debugPrint('❌ Error loading supreme_logo_transparent.png bytes: $e');
    }
  }

  @override
  void dispose() {
    _fromIdController.dispose();
    _toIdController.dispose();
    super.dispose();
  }

  // ─── Generate & Download ──────────────────────────────────────────────────

  Future<void> _generateAndDownloadZip() async {
    if (_selectedCollege == null) return;

    final fromSerialStr = _fromIdController.text.trim();
    final toSerialStr = _toIdController.text.trim();

    if (fromSerialStr.isEmpty || toSerialStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both From and To Serial numbers')),
      );
      return;
    }

    final fromNum = int.tryParse(fromSerialStr);
    final toNum = int.tryParse(toSerialStr);

    if (fromNum == null || toNum == null || fromNum > toNum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Serial range')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _statusMessage = 'Preparing equipments...';
    });

    try {
      // Precache both logos and wait for them to be ready
      if (mounted) {
        await Future.wait([
          precacheImage(const AssetImage('assets/favicon.png'), context),
          precacheImage(const AssetImage('assets/supreme_logo_transparent.png'), context),
        ]);
      }

      final equipmentProvider =
          Provider.of<EquipmentProvider>(context, listen: false);
      await equipmentProvider.fetchEquipments();

      final List<Equipment> filtered = [];
      final collegeCode = _selectedCollege!.collegeCode;

      for (int i = fromNum; i <= toNum; i++) {
        final fullIdStr = collegeCode + i.toString().padLeft(4, '0');

        Equipment? existing;
        try {
          existing = equipmentProvider.equipments.firstWhere((e) =>
              e.id == fullIdStr && e.collegeId == _selectedCollege!.id);
        } catch (_) {
          existing = null;
        }

        filtered.add(existing ??
            Equipment(
              id: fullIdStr,
              qrcode: fullIdStr,
              name: 'Asset',
              group: '',
              manufacturer: '',
              type: '',
              mode: '',
              serialNo: '',
              department: '',
              installationDate: DateTime.now(),
              status: 'Pending',
              service: '',
              purchasedCost: 0.0,
              hasWarranty: false,
              collegeId: _selectedCollege!.id,
            ));
      }

      if (filtered.isEmpty) throw 'Range yielded no stickers.';

      setState(() {
        _equipmentsToPrint = filtered;
        _statusMessage = 'Starting generation...';
      });

      final archive = Archive();
      final stickerKey = const GlobalObjectKey('current_sticker');

      for (int i = 0; i < _equipmentsToPrint.length; i++) {
        final equipment = _equipmentsToPrint[i];

        setState(() {
          _currentEquipmentToRender = equipment;
          _progress = (i) / _equipmentsToPrint.length;
          _statusMessage =
              'Generating ${i + 1}/${_equipmentsToPrint.length}: ${equipment.id}';
        });

        // Give extra time for the single widget to mount and images to decode
        await Future.delayed(const Duration(milliseconds: 600));

        final bytes = await _captureStickerFromKey(stickerKey);
        if (bytes != null) {
          final filename =
              '${equipment.id}_${equipment.name.replaceAll(' ', '_')}.png';
          archive.addFile(ArchiveFile(filename, bytes.length, bytes));
        } else {
          debugPrint('⚠️ Failed to capture sticker for ${equipment.id}');
        }
      }

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Creating ZIP file...';
      });

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes == null) throw 'Failed to create ZIP archive';

      final fileName =
          'stickers_${_selectedCollege!.collegeCode}_$fromSerialStr-$toSerialStr.zip';

      if (kIsWeb) {
        downloadFileWeb(context, Uint8List.fromList(zipBytes), fileName);
      } else {
        final directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        await io.File(filePath).writeAsBytes(zipBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ZIP saved to: $filePath')),
          );
        }
      }
    } catch (e) {
      debugPrint('💥 Mass Sticker Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _equipmentsToPrint = [];
          _currentEquipmentToRender = null;
        });
      }
    }
  }

  Future<Uint8List?> _captureStickerFromKey(GlobalKey key) async {
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        final boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null || !boundary.hasSize) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        // Wait for next frame to ensure images are painted
        await WidgetsBinding.instance.endOfFrame;
        
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('Attempt $attempt to capture sticker failed: $e');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return null;
  }

  Future<Uint8List?> _captureSticker(String id) async {
    return _captureStickerFromKey(const GlobalObjectKey('current_sticker'));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final collegeProvider = Provider.of<CollegeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Form UI ──────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mass Sticker Download',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a college and enter the range of equipment IDs '
                  'to generate a ZIP of QR stickers.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Step 1 ─ College
                const Text('Step 1: Select College',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<College>(
                  isExpanded: true,
                  value: _selectedCollege,
                  decoration: const InputDecoration(
                    labelText: 'College',
                    border: OutlineInputBorder(),
                  ),
                  items: collegeProvider.colleges
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCollege = val),
                ),
                const SizedBox(height: 24),

                // Step 2 ─ Serial range
                Text(
                  'Step 2: Enter Serial Range'
                  '${_selectedCollege != null ? " (Prefix: ${_selectedCollege!.collegeCode})" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fromIdController,
                        decoration: const InputDecoration(
                          labelText: 'From Serial',
                          hintText: 'e.g. 0001',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _toIdController,
                        decoration: const InputDecoration(
                          labelText: 'To Serial',
                          hintText: 'e.g. 0050',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Progress
                if (_isGenerating) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 12),
                  Center(child: Text(_statusMessage)),
                  const SizedBox(height: 24),
                ],

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateAndDownloadZip,
                    icon: const Icon(Icons.folder_zip),
                    label: Text(_isGenerating
                        ? 'GENERATING...'
                        : 'GENERATE & DOWNLOAD ZIP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Off-screen sticker rendering (ONE AT A TIME) ────────
          if (_currentEquipmentToRender != null)
            Positioned(
              left: -9999,
              top: -9999,
              child: RepaintBoundary(
                key: const GlobalObjectKey('current_sticker'),
                child: _buildStickerWidget(_currentEquipmentToRender!),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Sticker Widget ───────────────────────────────────────────────────────
  //
  //  Landscape 7 cm × 4 cm sticker layout:
  //
  //  ┌──────────────────────────────────────────────┐
  //  │ [navy]  SUPREME  BIOMEDICAL  [logo]           │  ← header
  //  ├─ teal/gold strip ────────────────────────────┤
  //  │                              │               │
  //  │  COLLEGE ID                  │   [ QR Code ] │  ← body
  //  │  collegename@city.in         │               │
  //  │  College Name                │               │
  //  │  ────────────                │               │
  //  │  ASSET ID                    │               │
  //  │  MED0001 (bold)              │               │
  //  │                              │               │
  //  ├──────────────────────────────────────────────┤
  //  │  Scan with QR Med App · Google Play Store     │  ← footer
  //  ├─ navy strip ─────────────────────────────────┤
  //
  //  Logical size 350 × 200, rendered at pixelRatio 3.0 → 1050 × 600 px PNG
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStickerWidget(Equipment p) {
    const double stickerW = 350; // 7 cm at ~50 px/cm
    const double stickerH = 200; // 4 cm at ~50 px/cm
    const Color navyBlue  = Color(0xFF0A1628);
    const Color tealBlue  = Color(0xFF00B4D8);
    const Color goldColor = Color(0xFFFFD60A);

    final qrData = 'https://qrmed-supreme.netlify.app/?id=${p.id}';

    return Container(
      width: stickerW,
      height: stickerH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navyBlue, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ══ HEADER – navy band ══════════════════════════════════
          Container(
            color: navyBlue,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Supreme Logo
                if (_supremeLogoBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.memory(
                        _supremeLogoBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        isAntiAlias: true,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.asset(
                        'assets/supreme_logo_transparent.png',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),

                // Brand name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'SUPREME',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'BIOMEDICAL',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: tealBlue,
                        letterSpacing: 2,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Logo
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _logoBytes != null
                      ? Image.memory(
                          _logoBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          isAntiAlias: true,
                        )
                      : Image.asset(
                          'assets/favicon.png',
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                ),
              ],
            ),
          ),

          // ══ TEAL / GOLD GRADIENT STRIP ══════════════════════════
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [tealBlue, goldColor, tealBlue],
              ),
            ),
          ),

          // ══ BODY – left info | right QR ═════════════════════════
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── LEFT: College ID + Asset ID ─────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // College ID label
                        const Text(
                          'COLLEGE ID',
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_selectedCollege != null) ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _selectedCollege!.id,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: navyBlue,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Thin teal divider
                        Container(
                          height: 1.5,
                          width: 60,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tealBlue, Colors.transparent],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Asset ID label
                        const Text(
                          'ASSET ID',
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            p.id,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Vertical divider ────────────────────────────
                Container(width: 1, color: Colors.black12),

                // ── RIGHT: QR Code fills the panel ──────────────
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 110,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: navyBlue,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: navyBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ══ THIN RULE ═══════════════════════════════════════════
          Container(height: 1, color: Colors.black12),

          // ══ SCAN FOOTER ══════════════════════════════════════════
          Container(
            color: const Color(0xFFF0F8FF),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, color: tealBlue, size: 12),
                const SizedBox(width: 5),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 7.5, color: Colors.black87),
                    children: [
                      TextSpan(text: 'Scan with '),
                      TextSpan(
                        text: 'QR Med App',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: tealBlue,
                        ),
                      ),
                      TextSpan(text: ' from '),
                      TextSpan(
                        text: 'Google Play Store ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34A853),
                        ),
                      ),
                      TextSpan(
                        text: ' or visit web  ',
                        style: TextStyle(color: Colors.black38),
                      ),
                      TextSpan(
                        text: 'qrmed-supreme.netlify.app',
                        style: TextStyle(
                          color: Color(0xFF0066CC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ══ BOTTOM NAVY ACCENT STRIP ════════════════════════════
          Container(height: 4, color: navyBlue),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _circularLogo({
    required IconData icon,
    required Color bgColor,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}
