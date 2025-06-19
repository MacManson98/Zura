import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../utils/user_profile_storage.dart';
import 'package:movie_matcher_clean/auth_gate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String _error = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        final profile = UserProfile.empty().copyWith(
          uid: user.uid,
          name: _usernameController.text.trim(),
        );
        await UserProfileStorage.saveProfile(profile);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ));
      }
    } catch (e) {
      setState(() => _error = "Registration failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32.h),
                  _buildHeader(),
                  SizedBox(height: 24.h),
                  _buildRegisterCard(),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A00), Color(0xFFFF6B00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A00).withAlpha(77),
                blurRadius: 3.r,
                spreadRadius: 1.r,
              ),
            ],
          ),
          child: Icon(Icons.movie_filter_rounded, size: 28.sp, color: Colors.white),
        ),
        SizedBox(height: 8.h),
        Text(
          "QueueTogether",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withAlpha(77),
            blurRadius: 3.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: Colors.grey[800]!.withAlpha(77), width: 0.5.w),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text("Create Account", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 16.h),
            _buildTextField("Username", Icons.person_outline, _usernameController, TextInputType.name),
            SizedBox(height: 12.h),
            _buildTextField("Email", Icons.email_outlined, _emailController, TextInputType.emailAddress),
            SizedBox(height: 12.h),
            _buildPasswordField("Password", _passwordController),
            SizedBox(height: 12.h),
            _buildPasswordField("Confirm Password", _confirmPasswordController, confirm: true),
            SizedBox(height: 16.h),
            _buildRegisterButton(),
            SizedBox(height: 12.h),
            _buildLoginLink(),
            if (_error.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(_error, style: TextStyle(color: Colors.red[300], fontSize: 12.sp), textAlign: TextAlign.center),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your $label';
        if (label == "Email" && !value.contains('@')) return 'Enter a valid email';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 18.sp),
        filled: true,
        fillColor: const Color(0xFF262626),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, {bool confirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: !_showPassword,
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (!confirm && value.length < 6) return 'Password must be at least 6 characters';
        if (confirm && value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 18.sp),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400], size: 18.sp),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: const Color(0xFF262626),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFFFF6B00)]),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text("Sign Up", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account? ", style: TextStyle(color: Colors.grey[400], fontSize: 14.sp)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text("Sign In", style: TextStyle(color: const Color(0xFFFF8A00), fontSize: 14.sp, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
