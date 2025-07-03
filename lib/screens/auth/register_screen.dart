import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../utils/user_profile_storage.dart';
import 'package:Zura/auth_gate.dart';
import '../../utils/debug_loader.dart';

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
  bool _showConfirmPassword = false;
  String _error = '';
  String _usernameAvailabilityMessage = '';
  bool _isCheckingUsername = false;

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

    // Add username availability checking
    _usernameController.addListener(_checkUsernameAvailability);

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      setState(() {
        _usernameAvailabilityMessage = '';
        _isCheckingUsername = false;
      });
      return;
    }

    // Basic validation first
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _usernameAvailabilityMessage = '';
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final isAvailable = await UserProfileStorage.isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _usernameAvailabilityMessage = isAvailable ? 'Available' : 'Username taken';
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameAvailabilityMessage = '';
          _isCheckingUsername = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final isAvailable = await UserProfileStorage.isUsernameAvailable(username);
      
      if (!isAvailable) {
        setState(() => _error = "Username already taken. Please choose another.");
        return;
      }

      DebugLogger.log("🔥 Creating Firebase user..."); // 🐛 DEBUG
      final user = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        DebugLogger.log("🔥 User created: ${user.uid}"); // 🐛 DEBUG
        DebugLogger.log("🔥 User email: ${user.email}"); // 🐛 DEBUG
        
        final profile = UserProfile.empty().copyWith(
          uid: user.uid,
          name: username,
          email: _emailController.text.trim(),
        );
        
        DebugLogger.log("🔥 Saving user profile..."); // 🐛 DEBUG
        await UserProfileStorage.saveProfile(profile);
        DebugLogger.log("🔥 Profile saved successfully"); // 🐛 DEBUG

        if (!mounted) return;
        
        // Wait a bit for Firebase Auth state to propagate
        DebugLogger.log("🔥 Waiting for auth state to update..."); // 🐛 DEBUG
        await Future.delayed(const Duration(milliseconds: 1000));
        
        DebugLogger.log("🔥 Navigating to AuthGate..."); // 🐛 DEBUG
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false, // Clear entire navigation stack
        );
        DebugLogger.log("🔥 Navigation completed"); // 🐛 DEBUG
      } else {
        DebugLogger.log("🚫 User creation returned null"); // 🐛 DEBUG
        setState(() => _error = "Registration failed. Please try again.");
      }
    } catch (e) {
      DebugLogger.log("🚫 Registration error: $e"); // 🐛 DEBUG
      setState(() => _error = "Registration failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: Stack( // ✅ ADD Stack to overlay back button
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h), // ✅ REDUCED from 40.h
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildHeader(),
                      ),
                      SizedBox(height: 24.h), // ✅ REDUCED from 40.h  
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildRegisterCard(),
                      ),
                      SizedBox(height: 16.h), // ✅ REDUCED from 24.h
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginPrompt(),
                      ),
                      SizedBox(height: 20.h), // ✅ REDUCED from 40.h
                    ],
                  ),
                ),
              ),
              // ✅ ADD Back button
              Positioned(
                top: 16.h,
                left: 16.w,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64.w, // ✅ REDUCED from 72.w
          height: 64.w, // ✅ REDUCED from 72.w
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A00), Color(0xFFFF6B00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A00).withValues(alpha: 0.3),
                blurRadius: 16.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: Icon(
            Icons.movie_filter_rounded,
            size: 28.sp, // ✅ REDUCED from 32.sp
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10.h), // ✅ REDUCED from 12.h
        Text(
          "Join Zura",
          style: TextStyle(
            fontSize: 24.sp, // ✅ REDUCED from 28.sp
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4.h), // ✅ REDUCED from 6.h
        Text(
          "Start your movie discovery journey",
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[400],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w), // ✅ REDUCED from 28.w
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
              "Create Account",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Fill in your details to get started",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 20.h), // ✅ REDUCED from 24.h
            _buildUsernameField(),
            SizedBox(height: 14.h), // ✅ REDUCED from 16.h
            _buildEmailField(),
            SizedBox(height: 14.h), // ✅ REDUCED from 16.h
            _buildPasswordField(),
            SizedBox(height: 14.h), // ✅ REDUCED from 16.h
            _buildConfirmPasswordField(),
            SizedBox(height: 20.h), // ✅ REDUCED from 24.h
            _buildRegisterButton(),
            if (_error.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildErrorContainer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Username",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _usernameController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a username';
            if (value.length < 3) return 'Username must be at least 3 characters';
            if (value.contains('@')) return 'Username cannot contain @';
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Username can only contain letters, numbers, and underscores';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Choose a unique username",
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400], size: 20.sp),
            suffixIcon: _buildUsernameStatusIcon(),
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
        if (_usernameAvailabilityMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 4.w),
            child: Text(
              _usernameAvailabilityMessage,
              style: TextStyle(
                fontSize: 12.sp,
                color: _usernameAvailabilityMessage == 'Available'
                    ? Colors.green[400]
                    : Colors.red[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget? _buildUsernameStatusIcon() {
    if (_isCheckingUsername) {
      return Padding(
        padding: EdgeInsets.all(14.w),
        child: SizedBox(
          width: 16.w,
          height: 16.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    if (_usernameAvailabilityMessage == 'Available') {
      return Icon(Icons.check_circle, color: Colors.green[400], size: 20.sp);
    }

    if (_usernameAvailabilityMessage == 'Username taken') {
      return Icon(Icons.cancel, color: Colors.red[400], size: 20.sp);
    }

    return null;
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _emailController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter your email address",
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400], size: 20.sp),
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
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          decoration: InputDecoration(
            hintText: "Create a secure password",
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

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Confirm Password",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
          decoration: InputDecoration(
            hintText: "Confirm your password",
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20.sp),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey[400],
                size: 20.sp,
              ),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
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

  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _register,
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
                "Create Account",
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

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16.sp,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            "Sign In",
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