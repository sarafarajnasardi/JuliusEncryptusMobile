import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Julius Encryptus',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[400]!,
          secondary: Colors.tealAccent,
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward().then((_) => _navigateToHome());
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const DecoderPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo1.jpg',
                          width: 180,
                          height: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Julius Encryptus',
                      style: GoogleFonts.rajdhani(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DecoderPage extends StatefulWidget {
  const DecoderPage({super.key});

  @override
  _DecoderPageState createState() => _DecoderPageState();
}

class _DecoderPageState extends State<DecoderPage> {
  final TextEditingController _inputController = TextEditingController();
  List<Map<String, dynamic>> _decodedResults = [];
  bool _isLoading = false;
  Future<void> _scanText() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        _showSnackBar('No image selected', isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();

      try {
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        setState(() {
          _inputController.text = recognizedText.text;
        });
        _showSnackBar('Text scanned successfully!', isError: false);
      } catch (e) {
        _showSnackBar('Error recognizing text: ${e.toString()}', isError: true);
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      _showSnackBar('Error accessing camera: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _decodeCipher() async {
    if (_inputController.text.isEmpty) {
      _showSnackBar('Please enter text to decode', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _decodedResults = [];
    });

    try {
      final response = await http.post(
        Uri.parse('https://juliusencryptus.onrender.com'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cipher': _inputController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['body'] != null) {
          setState(() {
            _decodedResults = List<Map<String, dynamic>>.from(
              data['body']['corr'].map((item) => Map<String, dynamic>.from(item)),
            );
          });
          if(_decodedResults.isNotEmpty) {
            _showSnackBar('Successfully decoded!', isError: false);
          }else{
            _showSnackBar('Input Must be Caesar Cipher!', isError: true);
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to decode text');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileContent = await file.readAsString();
        setState(() {
          _inputController.text = fileContent;
        });
        _showSnackBar('File loaded successfully!', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error loading file: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Julius Encryptus',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInputCard(),
                const SizedBox(height: 16),
                _buildDecodeButton(),
                const SizedBox(height: 24),
                ..._buildResults(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Encrypted Text',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inputController,
                maxLines: 4,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Type or paste your encrypted text here...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanText,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Text'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDecodeButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _decodeCipher,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Text(
          'Decode Text',
          style: TextStyle(color: Colors.white,fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _buildResults() {
    if (_decodedResults.isEmpty) {
      return [
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Enter text above to see decoded results',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return _decodedResults.asMap().entries.map((entry) {
      final int index = entry.key;
      final result = entry.value;

      return FadeInUp(
        delay: Duration(milliseconds: 400 + (index * 100)),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_open,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Decoded Result ${index + 1}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    result['ans'],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                if (result['quantities'] != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Statistical Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Shift', result['quantities']['shift']),
                  _buildStatRow('Mean', result['quantities']['mean']),
                  _buildStatRow('Mode', result['quantities']['mode']),
                  _buildStatRow('Median', result['quantities']['median']),
                  _buildStatRow('Std Dev', result['quantities']['std_dev']),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              //color: Theme.of(context).colorScheme.primary,
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Image.asset('assets/logo1.jpg', fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(
                  'Julius Encryptus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('About Us'),
            onTap: () {
              _launchURL('https://juliusencryptus-caesar.onrender.com');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri _url = Uri.parse(url);
    if (await launchUrl(_url)) {
      await launchUrl(_url);
    } else {
      _showSnackBar('Could not launch $url', isError: true);
    }
  }
}