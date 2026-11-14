import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // لاستخدام المؤقت
import '../config/app_theme.dart';
import '../config/api_endpoints.dart';
import '../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  int _currentStep = 0; // 0: إدخال البريد، 1: إدخال الكود، 2: كلمة المرور الجديدة
  bool _isLoading = false;
  int _timerSeconds = 0; // عداد الثواني
  Timer? _timer; // المؤقت

  // دالة بدء العداد
  void _startTimer() {
    setState(() => _timerSeconds = 60); // 60 ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      if (response.statusCode == 200) {
        setState(() => _currentStep = 1);
        _startTimer(); // بدء العداد بعد الإرسال
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الكود إلى بريدك!')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _codeController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح!')),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'نسيت كلمة المرور' : 'إعادة التعيين'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkBlack, AppTheme.primaryRed],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    if (_currentStep == 0) ...[
                      const Text('أدخل بريدك الإلكتروني لإرسال كود إعادة التعيين',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 20),
                      CustomTextField(hint: 'البريد الإلكتروني', icon: Icons.email, controller: _emailController),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                              onPressed: _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text('إرسال الكود', style: TextStyle(fontSize: 16)),
                            ),
                    ] else if (_currentStep == 1) ...[
                      const Text('أدخل الكود المكون من 6 أرقام الذي وصلك في البريد',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 20),
                      CustomTextField(hint: 'كود التحقق', icon: Icons.pin, controller: _codeController),
                      const SizedBox(height: 12),
                      CustomTextField(hint: 'كلمة المرور الجديدة', icon: Icons.lock, isPassword: true, controller: _newPasswordController),
                      const SizedBox(height: 12),
                      
                      // عداد إعادة الإرسال
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _timerSeconds > 0 ? 'إعادة الإرسال بعد $_timerSeconds ثانية' : 'لم يصلك الكود؟',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          if (_timerSeconds == 0)
                            TextButton(
                              onPressed: _sendCode,
                              child: const Text('إعادة الإرسال', style: TextStyle(color: AppTheme.primaryRed, fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                              onPressed: _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 16)),
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
