import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import 'package:lottie/lottie.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AboutPage extends StatefulWidget { 
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.blue.shade200.withOpacity(0.2),
              Colors.white.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimationLimiter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                  _buildLicenseButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('เกี่ยวกับแอปพลิเคชัน'),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Lottie.asset(
          'assets/animations/loader_cat.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 16),
        Text(
          'สูตรอาหาร',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'เวอร์ชัน $_version',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.description_outlined,
              color: Colors.blue,
              title: 'แอปพลิเคชัน',
              subtitle: 'รวบรวมสูตรอาหารและของหวานแสนอร่อย พร้อมวิธีทำที่เข้าใจง่ายสำหรับทุกคน',
            ),
            const Divider(indent: 20, endIndent: 20),
            _buildInfoRow(
              icon: Icons.code_rounded,
              color: Colors.purple,
              title: 'ผู้พัฒนา',
              subtitle: 'กลุ่มก้องน้อย นอนนา',
            ),
            const Divider(indent: 20, endIndent: 20),
            _buildInfoRow(
              icon: Icons.email_outlined,
              color: Colors.teal,
              title: 'ติดต่อและให้คำแนะนำ',
              subtitle: 'ก้องน้อย@comsci.com',
              onTap: () => _launchURL('mailto:ก้องน้อย@comsci.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => showLicensePage(context: context),
      icon: const Icon(Icons.article_outlined),
      label: const Text('ใบอนุญาตซอฟต์แวร์'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade700,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}