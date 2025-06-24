import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/auth_service.dart';
import '../../utils/user_profile_storage.dart';
import 'register_screen.dart';
import 'package:Zura/auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _usernameEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showPassword = false;
  String _error = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _slideController.forward();
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _authService.loginWithUsernameOrEmail(
        _usernameEmailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ));

    } catch (e) {
      setState(() => _error = "Login failed. Please check your credentials and try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final input = _usernameEmailController.text.trim();
    if (input.isEmpty) {
      _showSnackBar("Enter your email or username to reset password", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // If it's a username, we need to get the email first
      String email = input;
      if (!input.contains('@')) {
        // It's a username, lookup email
        final foundEmail = await UserProfileStorage.getEmailByUsername(input);
        if (foundEmail == null) {
          _showSnackBar("No account found with that username", isError: true);
          return;
        }
        email = foundEmail;
      }
      
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      _showSnackBar("Password reset email sent", isError: false);
    } catch (e) {
      setState(() => _error = "Failed to send reset email. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 14.sp)),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF0A0A0A),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h), // ✅ MUCH SMALLER - was 40.h
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildHeader(),
                  ),
                  SizedBox(height: 16.h), // ✅ REDUCED from 24.h
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginCard(),
                  ),
                  SizedBox(height: 16.h), // ✅ REDUCED from 20.h
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildSignUpPrompt(),
                  ),
                  SizedBox(height: 20.h), // ✅ REDUCED from 24.h
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
          width: 70.w, // ✅ REDUCED from 80.w
          height: 70.w, // ✅ REDUCED from 80.w
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A00), Color(0xFFFF6B00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A00).withValues(alpha: 0.4),
                blurRadius: 20.r,
                spreadRadius: 2.r,
              ),
              BoxShadow(
                color: const Color(0xFFFF8A00).withValues(alpha: 0.2),
                blurRadius: 40.r,
                spreadRadius: 4.r,
              ),
            ],
          ),
          child: Icon(
            Icons.movie_filter_rounded,
            size: 32.sp, // ✅ REDUCED from 36.sp
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h), // ✅ REDUCED from 16.h
        Text(
          "Zura",
          style: TextStyle(
            fontSize: 32.sp, // ✅ REDUCED from 36.sp
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 6.h), // ✅ REDUCED from 8.h
        Text(
          "Discover your next favorite film",
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[400],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: const Color(0xFFFF8A00).withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withValues(alpha: 0.1),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40.r,
            offset: Offset(0, 16.h),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Sign in to continue your journey",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24.h), // ✅ REDUCED from 32.h
            _buildUsernameEmailField(),
            SizedBox(height: 16.h), // ✅ REDUCED from 20.h
            _buildPasswordField(),
            SizedBox(height: 12.h), // ✅ REDUCED from 16.h
            _buildForgotPasswordButton(),
            SizedBox(height: 24.h), // ✅ REDUCED from 32.h
            _buildLoginButton(),
            if (_error.isNotEmpty) ...[
              SizedBox(height: 20.h),
              _buildErrorContainer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Username or Email",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _usernameEmailController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your username or email';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter username or email",
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400], size: 20.sp),
            filled: true,
            fillColor: const Color(0xFF262626),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: const Color(0xFFFF8A00), width: 2.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2.w),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2.w),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter your password",
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20.sp),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey[400],
                size: 20.sp,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            filled: true,
            fillColor: const Color(0xFF262626),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: const Color(0xFFFF8A00), width: 2.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2.w),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2.w),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _resetPassword,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          "Forgot password?",
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFFFF8A00),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFFF6B00)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withValues(alpha: 0.4),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[500]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red[400]!.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _error,
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16.sp,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: const Color(0xFFFF8A00),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}