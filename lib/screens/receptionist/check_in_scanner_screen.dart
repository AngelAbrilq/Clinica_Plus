import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/reception_provider.dart';
import '../../utils/app_exception.dart';
import 'widgets/check_in_result_sheet.dart';

/// Escáner del QR del paciente. También permite escribir el código a mano
/// (útil en web o si la cámara no está disponible).
class CheckInScannerScreen extends StatefulWidget {
  const CheckInScannerScreen({super.key});

  @override
  State<CheckInScannerScreen> createState() => _CheckInScannerScreenState();
}

class _CheckInScannerScreenState extends State<CheckInScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Mientras se procesa un código (o se muestra el resultado) se ignoran
  /// nuevas lecturas, para no registrar dos veces al mismo paciente.
  bool _isBusy = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw != null) _processCode(raw);
  }

  Future<void> _processCode(String raw) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await context.read<ReceptionProvider>().checkInFromCode(
        raw,
      );
      HapticFeedback.mediumImpact();
      if (mounted) await showCheckInResultSheet(context, result: result);
    } on AppException catch (error) {
      HapticFeedback.heavyImpact();
      if (mounted)
        await showCheckInResultSheet(context, errorMessage: error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _enterCodeManually() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Escribir código'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Código de check-in',
            hintText: 'Lo ve el paciente debajo de su QR',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Registrar llegada'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code != null && code.trim().isNotEmpty) await _processCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in'),
        actions: [
          IconButton(
            tooltip: 'Linterna',
            onPressed: _scanner.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _scanner, onDetect: _onDetect),
                const _ScanFrame(),
                if (_isBusy)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Text(
                    'Apunta la cámara al código QR que el paciente tiene en su app.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _enterCodeManually,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Escribir código'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marco guía sobre la cámara (esquinas redondeadas que respiran).
class _ScanFrame extends StatefulWidget {
  const _ScanFrame();

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: ScaleTransition(
        scale: Tween(
          begin: 0.96,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    ),
  );
}
