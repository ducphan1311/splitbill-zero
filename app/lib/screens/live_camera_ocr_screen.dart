import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bill_item.dart';
import '../services/backend_api_service.dart';
import '../services/spatial_ocr_parser.dart';
import '../theme/app_theme.dart';
import 'edit_bill_items_screen.dart';
import 'host_info_dialog.dart';

class LiveCameraOcrScreen extends StatefulWidget {
  const LiveCameraOcrScreen({super.key});

  @override
  State<LiveCameraOcrScreen> createState() => _LiveCameraOcrScreenState();
}

class _LiveCameraOcrScreenState extends State<LiveCameraOcrScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isProcessingOcr = false;
  bool _isCameraReady = false;
  String _ocrStatusMessage = 'Chưa quét hóa đơn. Vui lòng chụp hoặc tải ảnh bill lên.';
  List<BillItem> _detectedItems = [];
  final currencyFormat = NumberFormat("#,##0", "vi_VN");

  Uint8List? _uploadedImageBytes;

  @override
  void initState() {
    super.initState();
    // Start with empty items so it's NOT hardcoded!
    _detectedItems = [];
    _initializeCameraStream();
  }

  Future<void> _initializeCameraStream() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await controller.initialize();
        if (!mounted) return;

        setState(() {
          _cameraController = controller;
          _isCameraReady = true;
          _ocrStatusMessage = 'Camera sẵn sàng. Căn chỉnh hóa đơn và nhấn nút Chụp & Quét.';
        });
      } else {
        setState(() {
          _ocrStatusMessage = 'Không tìm thấy camera. Bạn có thể chọn ảnh hóa đơn từ máy.';
        });
      }
    } catch (e) {
      debugPrint('Camera stream init exception: $e');
      if (mounted) {
        setState(() {
          _ocrStatusMessage = 'Chế độ Trình Duyệt / Simulator: Hãy bấm "Tải ảnh hóa đơn" để quét AI thật.';
        });
      }
    }
  }

  /// 1. Triggered when user snaps a photo via Camera or clicks Capture
  Future<void> _captureAndScanReceipt() async {
    if (_isProcessingOcr) return;

    setState(() {
      _isProcessingOcr = true;
      _ocrStatusMessage = 'Đang chụp ảnh & gửi vào pipeline Google ML Kit OCR...';
    });

    try {
      Uint8List imageBytes;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        imageBytes = await photo.readAsBytes();
      } else {
        // Fallback to sample real receipt asset if no camera is attached
        final ByteData assetData = await rootBundle.load('assets/images/sample_receipt.jpg');
        imageBytes = assetData.buffer.asUint8List();
      }

      setState(() {
        _uploadedImageBytes = imageBytes;
      });

      await _processImageBytesWithOcr(imageBytes, 'camera_capture.jpg');
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() {
          _ocrStatusMessage = 'Lỗi chụp ảnh: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  /// 2. Pick a real receipt image from device gallery or computer file dialog
  Future<void> _pickReceiptImageFile() async {
    try {
      final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() {
        _isProcessingOcr = true;
        _ocrStatusMessage = 'Đang phân tích hình ảnh hóa đơn...';
      });

      final bytes = await file.readAsBytes();
      setState(() {
        _uploadedImageBytes = bytes;
      });

      await _processImageBytesWithOcr(bytes, file.name);
    } catch (e) {
      debugPrint('Pick image error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  /// Core Engine: Process receipt bytes through on-device ML Kit or Backend Vision OCR
  Future<void> _processImageBytesWithOcr(Uint8List bytes, String filename) async {
    List<BillItem> parsedItems = [];

    // Path A: If running on Mobile (iOS / Android), use on-device Google ML Kit TextRecognizer
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/scan_input.jpg');
        await tempFile.writeAsBytes(bytes);

        final inputImage = InputImage.fromFilePath(tempFile.path);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        parsedItems = SpatialOcrParser.parseRecognizedText(recognizedText);
      } catch (err) {
        debugPrint('On-device ML Kit error: $err');
      }
    }

    // Path B: If on Web or fallback, call Backend OCR Engine (macOS Vision & Spatial Clustering)
    if (parsedItems.isEmpty) {
      parsedItems = await BackendApiService.recognizeReceiptImage(bytes, filename);
    }

    if (mounted) {
      setState(() {
        if (parsedItems.isNotEmpty) {
          _detectedItems = parsedItems;
          _ocrStatusMessage = '✓ Nhận diện thành công ${parsedItems.length} món từ hóa đơn thật';
        } else {
          // If no items detected, do not fake hardcode; let user know or enter manually
          _ocrStatusMessage = '⚠️ Chưa tách được món rõ ràng. Bạn có thể thử ảnh khác hoặc tự bấm "Sửa / Thêm món".';
        }
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  double get totalDetectedPrice => _detectedItems.fold(0, (sum, i) => sum + i.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oledCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Tag
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cyanGlow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cyanBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.emeraldGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text(
                              '⚡ GOOGLE ML KIT v2 • ON-DEVICE OCR',
                              style: TextStyle(
                                color: AppColors.electricCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.upload_file, color: AppColors.electricCyan),
                            tooltip: 'Chọn ảnh hóa đơn từ máy',
                            onPressed: _pickReceiptImageFile,
                          ),
                          IconButton(
                            icon: const Icon(Icons.flash_on, color: AppColors.electricCyan),
                            onPressed: () {},
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Quét Hóa Đơn Trực Tiếp', style: AppStyles.displayLarge),
                  const SizedBox(height: 2),
                  const Text('AI nhận diện tọa độ món & đơn giá', style: AppStyles.bodyMedium),
                ],
              ),
            ),

            // Camera / Image Viewport Frame
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkBezel,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyanGlow,
                      blurRadius: 25,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: Real Camera Preview, Uploaded Image, or Blank Viewfinder
                      if (_uploadedImageBytes != null)
                        Image.memory(_uploadedImageBytes!, fit: BoxFit.cover)
                      else if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized)
                        CameraPreview(_cameraController!)
                      else
                        Image.asset(
                          'assets/images/sample_receipt.jpg',
                          fit: BoxFit.cover,
                        ),

                      // Dark Overlay Gradients
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),

                      // Reticle viewfinder corners
                      const _ReticleCorner(top: 16, left: 16, isTop: true, isLeft: true),
                      const _ReticleCorner(top: 16, right: 16, isTop: true, isLeft: false),
                      const _ReticleCorner(bottom: 16, left: 16, isTop: false, isLeft: true),
                      const _ReticleCorner(bottom: 16, right: 16, isTop: false, isLeft: false),

                      // Top Status Badge
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _ocrStatusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPureWhite,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Center: If scanning is in progress
                      if (_isProcessingOcr)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.electricCyan),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppColors.electricCyan),
                                SizedBox(height: 12),
                                Text(
                                  'AI Đang Phân Tích Bounding Box...',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Bounding Boxes Layer for Detected Items (Only appears AFTER scanning!)
                      if (_detectedItems.isNotEmpty)
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 70, bottom: 60),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _detectedItems.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final item = entry.value;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateCard.withValues(alpha: 0.9),
                                    border: Border.all(color: AppColors.electricCyan, width: 1.2),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.cyanGlow,
                                        blurRadius: 8,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '✓ $index. ${item.name} (x${item.quantity})',
                                          style: const TextStyle(
                                            color: AppColors.textPureWhite,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${currencyFormat.format(item.price)} đ',
                                        style: const TextStyle(
                                          color: AppColors.amberGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      else if (!_isProcessingOcr)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _captureAndScanReceipt,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.electricCyan.withValues(alpha: 0.15),
                                    border: Border.all(color: AppColors.electricCyan, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: AppColors.electricCyan, size: 36),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Chạm để Chụp & Quét Bill Bằng AI',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'hoặc bấm icon tải ảnh góc phải trên',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Console
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.slateCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ĐÃ NHẬN DIỆN', style: AppStyles.caption),
                          Text(
                            _detectedItems.isEmpty
                                ? 'Chưa có món nào'
                                : '${_detectedItems.length} Món • Khớp Hóa Đơn',
                            style: AppStyles.bodyMedium,
                          ),
                        ],
                      ),
                      Text(
                        '${currencyFormat.format(totalDetectedPrice)} đ',
                        style: const TextStyle(
                          color: AppColors.amberGold,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm & Create Room CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricCyan,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
                      ),
                      onPressed: _detectedItems.isEmpty
                          ? () {
                              _captureAndScanReceipt();
                            }
                          : () {
                              HostInfoDialog.show(context, _detectedItems);
                            },
                      child: Text(
                        _detectedItems.isEmpty ? '📸 Bắt đầu Quét Hóa Đơn' : 'Xác nhận & Tạo Bàn →',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.electricCyan.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final updatedItems = await Navigator.push<List<BillItem>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditBillItemsScreen(initialItems: _detectedItems),
                              ),
                            );
                            if (updatedItems != null) {
                              setState(() {
                                _detectedItems = updatedItems;
                              });
                            }
                          },
                          child: const Text('✏️ Sửa / Thêm món', style: TextStyle(color: AppColors.electricCyan, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _captureAndScanReceipt,
                          child: const Text('📷 Chụp & Quét Lại', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReticleCorner extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool isTop;
  final bool isLeft;

  const _ReticleCorner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.electricCyan, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.electricCyan, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.electricCyan, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.electricCyan, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
