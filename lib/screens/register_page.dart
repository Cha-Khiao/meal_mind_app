import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('สมัครสมาชิกไม่สำเร็จ อาจมีอีเมลนี้ในระบบแล้ว'),
              backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        const Text(
                          'สร้างบัญชีของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'ลงทะเบียน เพื่อเข้าถึงสูตรอาหารอีกมากมาย',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 48.0),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildNameField(),
                              const SizedBox(height: 20.0),
                              _buildEmailField(),
                              const SizedBox(height: 20.0),
                              _buildPasswordField(),
                              const SizedBox(height: 20.0),
                              _buildConfirmPasswordField(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        _buildRegisterButton(),
                        const SizedBox(height: 16.0),

                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        labelText: 'ชื่อ-นามสกุล',
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'กรุณากรอกชื่อ';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        labelText: 'อีเมล',
        prefixIcon: Icons.email_outlined,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'รูปแบบอีเมลไม่ถูกต้อง';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _isPasswordObscured,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        labelText: 'รหัสผ่าน',
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
        if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _isConfirmPasswordObscured,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        labelText: 'ยืนยันรหัสผ่าน',
        prefixIcon: Icons.lock_reset_outlined,
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
        if (value != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: Colors.white70),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 25.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(color: Colors.white, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return auth.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF6A11CB),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.4),
                ),
                child: const Text(
                  'สมัครสมาชิก',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'มีบัญชีอยู่แล้ว? ',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text(
            'เข้าสู่ระบบ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}