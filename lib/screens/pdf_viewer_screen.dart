import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String reportName;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.reportName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isDownloading = true;
  bool downloadFailed = false;
  String errorMessage = '';


  bool get _shouldUseUrlLauncher {
    if (kIsWeb) return true;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return true;
    return false;
  }

  Future<void> _launchPdfUrl() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        isDownloading = false;
        downloadFailed = true;
        errorMessage = 'Could not open PDF URL.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (_shouldUseUrlLauncher) {
      _launchPdfUrl();
    } else {
      _downloadPdfForViewing();
    }
  }

  Future<void> _downloadPdfForViewing() async {
    setState(() {
      isDownloading = true;
      downloadFailed = false;
      errorMessage = '';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      // Use unique timestamp to prevent caching old or corrupted files
      final uniqueFileName = '${widget.reportName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$uniqueFileName');

      final response = await Dio().download(
        widget.pdfUrl,
        file.path,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status == 200,
        ),
      );

      // Validate Content-Type
      final contentType = response.headers.value('content-type')?.toLowerCase() ?? '';
      if (!contentType.contains('application/pdf')) {
        await file.delete();
        throw Exception('Invalid file type: $contentType. Expected PDF.');
      }

      // Validate File Size
      final length = await file.length();
      if (length == 0) {
        await file.delete();
        throw Exception('Downloaded file is empty (corrupted).');
      }

      setState(() {
        localPath = file.path;
        isDownloading = false;
      });
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadFailed = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Check Android 11+ Manage External Storage
    if (await Permission.manageExternalStorage.status.isGranted) {
      return true;
    }

    // Try requesting Manage External Storage
    var manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return true;
    }

    // Fallback for older Android versions
    var storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    return false;
  }

  Future<void> _saveToDevice() async {
    final hasPermission = await _requestStoragePermission();
    if (!mounted) return;

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to save the PDF.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading PDF to Downloads folder...')),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final savePath = '${directory!.path}/${widget.reportName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final response = await Dio().download(
        widget.pdfUrl,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status == 200,
        ),
      );

      // Validate downloaded content type
      final contentType = response.headers.value('content-type')?.toLowerCase() ?? '';
      if (!contentType.contains('application/pdf')) {
        final savedFile = File(savePath);
        if (await savedFile.exists()) await savedFile.delete();
        throw Exception('Downloaded file is not a valid PDF.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success! Saved to: $savePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldUseUrlLauncher) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medical Report'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text('PDF opened in external browser/viewer.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _launchPdfUrl,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text('Medical Report'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: isDownloading || downloadFailed ? null : _saveToDevice,
            tooltip: 'Download to Device',
          ),
        ],
      ),
      body: Center(
        child: isDownloading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching PDF securely...'),
                ],
              )
            : downloadFailed
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load PDF\n$errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _downloadPdfForViewing,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Download'),
                        )
                      ],
                    ),
                  )
                : PDFView(
                    filePath: localPath,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    pageFling: true,
                    onError: (error) {
                      debugPrint(error.toString());
                    },
                    onPageError: (page, error) {
                      debugPrint('$page: ${error.toString()}');
                    },
                  ),
      ),
    );
  }
}
