import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import './Buttons.dart';

/// 二维码渲染、扫描
/// 二维码扫描需要权限：https://pub.dev/packages/mobile_scanner#platform-specific-setup

Widget _defaultQrErrorBuilder (BuildContext context, Object? error) => Container( // 二维码错误默认组件
  child: FittedBox(child: Icon(Icons.qr_code, color: Colors.grey[400], semanticLabel: '二维码错误')),
);

class QrCodeView extends QrImageView { // 二维码渲染
  QrCodeView({
    super.key,
    required super.data,
    super.size,
    super.padding,
    super.backgroundColor = Colors.white,
    super.version,
    super.errorCorrectionLevel,
    super.errorStateBuilder = _defaultQrErrorBuilder,
    super.constrainErrorBounds,
    super.gapless = true,
    super.embeddedImage = const AssetImage('assets/images/logo.png'),
    super.embeddedImageStyle/*  = const QrEmbeddedImageStyle( // 二维码中间的 logo, 在不设置大小的情况下，会根据二维码的大小自动缩放
      size: Size.square(50),
      color: Colors.transparent,
    ) */,
    super.embeddedImageEmitsError = false,
    super.semanticsLabel = '二维码',
    super.eyeStyle,
    super.dataModuleStyle,
  });
}

class QrCodeScanView extends MobileScanner { // 二维码扫描
  final BuildContext context;
  final bool Function(String data)? onValidate;

  QrCodeScanView(this.context, {
    this.onValidate
  }) : super(
    controller: MobileScannerController(
      torchEnabled: false, // 是否默认开启闪光灯
      // useNewCameraSelector: false,
      // formats: [BarcodeFormat.qrCode],
      // facing: CameraFacing.front,
      // detectionSpeed: DetectionSpeed.noDuplicates, // DetectionSpeed.noDuplicates
      // detectionTimeoutMs: 1000,
      returnImage: true,
    ),
    /* errorBuilder: (context, error, child) {
      return Text('scan-error: ${error}');
    }, */
    // fit: BoxFit.contain,
    onDetect: (capture) {
      final List<Barcode> barcodes = capture.barcodes;
      final String? result = barcodes.firstOrNull?.rawValue;
      if (result == null || !ModalRoute.of(context)!.isCurrent) return;
      if (onValidate == null) return Navigator.of(context).pop(result);

      return onValidate(result) ? Navigator.of(context).pop<String>(result) : null;
    },
  );
}

class QrCodeScanPage extends StatefulWidget {
  final String? title;
  final bool Function(String data)? onValidate;

  const QrCodeScanPage({super.key, this.title, this.onValidate});

  @override
  _QrCodeScanPage createState() => _QrCodeScanPage();

    static Future<T?> open<T>(BuildContext context, {String title = '扫码', bool Function(String data)? onValidate}) => Navigator.of(context).push<T>(PageRouteBuilder( // 打开 扫码 界面
      pageBuilder: (context, animation, secondaryAnimation) => QrCodeScanPage(title: title, onValidate: onValidate),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0, 1);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    )
  );
}

class _QrCodeScanPage extends State<QrCodeScanPage> {
  late final QrCodeScanView qrCodeScanView = QrCodeScanView(context);

  @override
  void dispose() {
    qrCodeScanView.controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: widget.title == null ? null : Text(widget.title!),
        // actions: [],
      ),
      body: Stack(
        children: [
          qrCodeScanView,
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: qrCodeScanView.controller != null ? [
                ValueListenableButtons.ToggleFlashlight(controller: qrCodeScanView.controller!),
                StaticButtons.AnalyzeImageFromGallery(controller: qrCodeScanView.controller!),
              ]: [],
            ),
          )
        ],
      ),
    );
  }
}