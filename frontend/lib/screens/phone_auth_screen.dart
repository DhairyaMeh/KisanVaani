import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'dashboard_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    String phoneNumber = _phoneController.text.trim();
    
    // Add country code if not present
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber'; // Indian country code
    }

    final success = await authService.sendPhoneOTP(phoneNumber);
    
    if (success) {
      setState(() {
        _isOtpSent = true;
      });
      _showSuccessDialog('OTP sent to your phone number');
    } else if (authService.errorMessage != null) {
      _showErrorDialog(authService.errorMessage!);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 6) {
      _showErrorDialog('Please enter valid 6-digit OTP');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.verifyPhoneOTP(_otpController.text);
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else if (authService.errorMessage != null) {
      _showErrorDialog(authService.errorMessage!);
    }
  }

  void _handleResendOtp() {
    _otpController.clear();
    _handleSendOtp();
  }

  void _showErrorDialog(String message) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final currentLanguage = languageService.selectedLanguage;
    final isKannada = currentLanguage == 'kn';
    final isHindi = currentLanguage == 'hi';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isKannada 
                ? 'ದೋಷ' 
                : isHindi
                    ? 'त्रुटि'
                    : 'Error',
            style: TextStyle(
              fontFamily: isKannada 
                  ? 'NotoSansKannada' 
                  : isHindi
                      ? 'HindiFont'
                      : null,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isKannada 
                    ? 'ಸರಿ' 
                    : isHindi
                        ? 'ठीक है'
                        : 'OK',
                style: TextStyle(
                  fontFamily: isKannada 
                      ? 'NotoSansKannada' 
                      : isHindi
                          ? 'HindiFont'
                          : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final currentLanguage = languageService.selectedLanguage;
    final isKannada = currentLanguage == 'kn';
    final isHindi = currentLanguage == 'hi';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isKannada 
                ? 'ಯಶಸ್ಸು' 
                : isHindi
                    ? 'सफलता'
                    : 'Success',
            style: TextStyle(
              fontFamily: isKannada 
                  ? 'NotoSansKannada' 
                  : isHindi
                      ? 'HindiFont'
                      : null,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isKannada 
                    ? 'ಸರಿ' 
                    : isHindi
                        ? 'ठीक है'
                        : 'OK',
                style: TextStyle(
                  fontFamily: isKannada 
                      ? 'NotoSansKannada' 
                      : isHindi
                          ? 'HindiFont'
                          : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneInput() {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.selectedLanguage;
    final isKannada = currentLanguage == 'kn';
    final isHindi = currentLanguage == 'hi';
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isKannada 
                ? 'ನಿಮ್ಮ ಫೋನ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ' 
                : isHindi
                    ? 'अपना फोन नंबर दर्ज करें'
                    : 'Enter your phone number',
            style: TextStyle(
              fontSize: screenHeight * 0.03,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: isKannada 
                  ? 'NotoSansKannada' 
                  : isHindi
                      ? 'HindiFont'
                      : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isKannada 
              ? 'ನಾವು ನಿಮಗೆ ಪರಿಶೀಲನಾ ಕೋಡ್ ಕಳುಹಿಸುತ್ತೇವೆ' 
              : isHindi
                  ? 'हम आपको सत्यापन कोड भेजेंगे'
                  : 'We will send you a verification code',
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              color: Colors.grey[600],
              fontFamily: isKannada 
                  ? 'NotoSansKannada' 
                  : isHindi
                      ? 'HindiFont'
                      : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        SizedBox(height: screenHeight * 0.04),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryGreen),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '+91',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenHeight * 0.02,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: isKannada 
                        ? 'ಫೋನ್ ಸಂಖ್ಯೆ' 
                        : 'Phone Number',
                    hintStyle: TextStyle(
                      fontFamily: isKannada 
                          ? 'NotoSansKannada' 
                          : null,
                      fontSize: screenHeight * 0.018,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: screenHeight * 0.02,
                    fontFamily: isKannada 
                        ? 'NotoSansKannada' 
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isKannada 
                          ? 'ಫೋನ್ ಸಂಖ್ಯೆ ಅವಶ್ಯಕ' 
                          : isHindi
                              ? 'फोन नंबर आवश्यक है'
                              : 'Phone number is required';
                    }
                    if (value.length != 10) {
                      return isKannada 
                          ? 'ಮಾನ್ಯವಾದ 10 ಅಂಕಿಗಳ ಫೋನ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ' 
                          : isHindi
                              ? 'मान्य 10 अंकों का फोन नंबर दर्ज करें'
                              : 'Enter valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: screenHeight * 0.04),
        
        Container(
          height: screenHeight * 0.07,
          constraints: BoxConstraints(
            minHeight: 50,
            maxHeight: 64,
          ),
            child: ElevatedButton(
            onPressed: _handleSendOtp,
            child: Text(
              isKannada 
                  ? 'OTP ಕಳುಹಿಸಿ' 
                  : isHindi
                      ? 'OTP भेजें'
                      : 'Send OTP',
              style: TextStyle(
                fontSize: screenHeight * 0.022,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: isKannada 
                    ? 'NotoSansKannada' 
                    : isHindi
                        ? 'HindiFont'
                        : null,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    final languageService = Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentLanguage = languageService.selectedLanguage;
    final isKannada = currentLanguage == 'kn';
    final isHindi = currentLanguage == 'hi';
    final screenHeight = MediaQuery.of(context).size.height;

    final defaultPinTheme = PinTheme(
      width: screenHeight * 0.07,
      height: screenHeight * 0.07,
      constraints: BoxConstraints(
        minWidth: 50,
        minHeight: 50,
        maxWidth: 65,
        maxHeight: 65,
      ),
      textStyle: TextStyle(
        fontSize: screenHeight * 0.025,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.primaryGreen, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Color.fromRGBO(234, 239, 243, 1),
        border: Border.all(color: AppTheme.primaryGreen),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isKannada 
                ? 'ಪರಿಶೀಲನಾ ಕೋಡ್ ನಮೂದಿಸಿ' 
                : isHindi
                    ? 'सत्यापन कोड दर्ज करें'
                    : 'Enter verification code',
            style: TextStyle(
              fontSize: screenHeight * 0.03,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: isKannada 
                  ? 'NotoSansKannada' 
                  : isHindi
                      ? 'HindiFont'
                      : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isKannada 
              ? '${_phoneController.text} ಗೆ ಕಳುಹಿಸಿದ 6 ಅಂಕಿಗಳ ಕೋಡ್ ನಮೂದಿಸಿ'
              : isHindi
                  ? '${_phoneController.text} पर भेजा गया 6 अंकों का कोड दर्ज करें'
                  : 'Enter the 6-digit code sent to ${_phoneController.text}',
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              color: Colors.grey[600],
              fontFamily: isKannada 
                  ? 'NotoSansKannada' 
                  : isHindi
                      ? 'HindiFont'
                      : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        SizedBox(height: screenHeight * 0.04),
        
        Center(
          child: Pinput(
            controller: _otpController,
            length: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            validator: (s) {
              if (s == null || s.length != 6) {
                return isKannada 
                    ? 'ಮಾನ್ಯವಾದ 6 ಅಂಕಿಗಳ OTP ನಮೂದಿಸಿ' 
                    : isHindi
                        ? 'मान्य 6 अंकों का OTP दर्ज करें'
                        : 'Enter valid 6-digit OTP';
              }
              return null;
            },
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (pin) {
              _handleVerifyOtp();
            },
          ),
        ),
        
        SizedBox(height: screenHeight * 0.04),
        
        Container(
          height: screenHeight * 0.07,
          constraints: BoxConstraints(
            minHeight: 50,
            maxHeight: 64,
          ),
          child: ElevatedButton(
            onPressed: authService.isLoading ? null : _handleVerifyOtp,
            child: authService.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isKannada 
                      ? 'ಪರಿಶೀಲಿಸಿ' 
                      : isHindi
                          ? 'सत्यापित करें'
                          : 'Verify',
                  style: TextStyle(
                    fontSize: screenHeight * 0.022,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: isKannada 
                        ? 'NotoSansKannada' 
                        : isHindi
                            ? 'HindiFont'
                            : null,
                  ),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isKannada 
                  ? 'ಕೋಡ್ ಬರಲಿಲ್ಲವೇ?' 
                  : isHindi
                      ? 'कोड नहीं मिला?'
                      : 'Didn\'t receive code?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: screenHeight * 0.018,
                fontFamily: isKannada 
                    ? 'NotoSansKannada' 
                    : isHindi
                        ? 'HindiFont'
                        : null,
              ),
            ),
            TextButton(
              onPressed: _handleResendOtp,
              child: Text(
                isKannada 
                    ? 'ಮತ್ತೆ ಕಳುಹಿಸಿ' 
                    : isHindi
                        ? 'फिर से भेजें'
                        : 'Resend',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: screenHeight * 0.018,
                  fontWeight: FontWeight.bold,
                  fontFamily: isKannada 
                      ? 'NotoSansKannada' 
                      : isHindi
                          ? 'HindiFont'
                          : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.selectedLanguage;
    final isKannada = currentLanguage == 'kn';
    final isHindi = currentLanguage == 'hi';
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isKannada 
              ? 'ಫೋನ್ ಪರಿಶೀಲನೆ' 
              : isHindi
                  ? 'फोन सत्यापन'
                  : 'Phone Verification',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
            fontFamily: isKannada 
                ? 'NotoSansKannada' 
                : isHindi
                    ? 'HindiFont'
                    : null,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - keyboardHeight,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.05),
                          
                          // Phone icon
                          Container(
                            width: screenHeight * 0.1,
                            height: screenHeight * 0.1,
                            constraints: BoxConstraints(
                              minWidth: 70,
                              minHeight: 70,
                              maxWidth: 100,
                              maxHeight: 100,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.phone_android,
                              size: screenHeight * 0.05,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.04),
                          
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            child: _isOtpSent ? _buildOtpInput() : _buildPhoneInput(),
                          ),
                          
                          SizedBox(height: screenHeight * 0.04),
                          
                          // Back to phone number button for OTP screen
                          if (_isOtpSent)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: Text(
                                isKannada 
                                    ? 'ಫೋನ್ ಸಂಖ್ಯೆ ಬದಲಾಯಿಸಿ' 
                                    : isHindi
                                        ? 'फोन नंबर बदलें'
                                        : 'Change phone number',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: screenHeight * 0.018,
                                  fontFamily: isKannada 
                                      ? 'NotoSansKannada' 
                                      : isHindi
                                          ? 'HindiFont'
                                          : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
