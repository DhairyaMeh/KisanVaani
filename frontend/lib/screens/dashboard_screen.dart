import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/theme_service.dart';
import 'chat_screen.dart';
import 'camera_screen.dart';
import 'government_schemes_screen.dart';
import 'language_selection_screen.dart';
import 'package:google_fonts/google_fonts.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  int _currentImageIndex = 0;
  late Timer _imageTimer;

  final List<String> _backgroundImages = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
    'assets/images/6.png',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Start the slideshow
    _startImageSlideshow();
    _fadeController.forward();
  }

  void _startImageSlideshow() {
    _imageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _imageTimer.cancel();
    super.dispose();
  }

  // Helper methods for user profile
  String _getUserInitials(AuthService authService) {
    String name = authService.userDisplayName ?? 'User';
    if (name.isEmpty) name = 'User';

    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
  }

  String _getWelcomeMessage(AuthService authService, String currentLanguage) {
    String name = authService.userDisplayName ?? 'User';
    if (name.isEmpty || name == 'User') {
      if (authService.userEmail != null) {
        name = authService.userEmail!.split('@')[0];
      } else if (authService.userPhoneNumber != null) {
        name = 'User';
      }
    }

    // Take only first name to keep it short
    String firstName = name.split(' ')[0];

    if (currentLanguage == 'kn') {
      return 'ನಮಸ್ಕಾರ, $firstName';
    } else if (currentLanguage == 'hi') {
      return 'नमस्ते, $firstName';
    } else {
      return 'Hello, $firstName';
    }
  }

  String _getUserDisplayInfo(AuthService authService) {
    if (authService.userEmail != null) {
      return authService.userEmail!;
    } else if (authService.userPhoneNumber != null) {
      return authService.userPhoneNumber!;
    } else {
      return 'Test User Account';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LanguageService, ThemeService, LocationService>(
      builder: (context, languageService, themeService, locationService, child) {
        final currentLanguage = languageService.selectedLanguage;
        final isDark = themeService.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : Colors.grey[50],
          body: Stack(
            children: [
              // Animated background slideshow with overlay
              AnimatedSwitcher(
                duration: Duration(milliseconds: 2000),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: Container(
                  key: ValueKey(_currentImageIndex),
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.asset(
                    _backgroundImages[_currentImageIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Dark overlay for better contrast
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.8),
                            AppTheme.darkBackground.withOpacity(0.9),
                          ]
                        : [
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.35),
                          ],
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modern header with user info and controls
                      _buildModernHeader(currentLanguage, themeService, locationService, isDark),

                      SizedBox(height: 30),

                      // App title section
                      _buildAppTitle(currentLanguage, isDark),

                      SizedBox(height: 40),

                      // Square feature blocks
                      Expanded(
                        child: _buildFeatureBlocks(currentLanguage, isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(String currentLanguage, ThemeService themeService, LocationService locationService, bool isDark) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkCard.withOpacity(0.9)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.primaryGreen.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row with user info and controls
              Row(
                children: [
                  // User avatar
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getUserInitials(authService),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // User greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getWelcomeMessage(authService, currentLanguage),
                          style: currentLanguage == 'kn'
                              ? TextStyle(
                                  color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansKannada',
                                )
                              : currentLanguage == 'hi'
                                  ? TextStyle(
                                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'HindiFont',
                                    )
                                  : GoogleFonts.montserrat(
                                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _getUserDisplayInfo(authService),
                          style: GoogleFonts.montserrat(
                            color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Control buttons
                  Row(
                    children: [
                      // Language toggle badge
                      _buildLanguageBadge(currentLanguage),

                      SizedBox(width: 8),

                      // Theme toggle
                      _buildThemeToggle(themeService),

                      SizedBox(width: 8),

                      // Profile/Settings button
                      _buildProfileButton(currentLanguage),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Location row (subtle)
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: isDark ? AppTheme.darkSecondaryText : Colors.grey[500],
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationService.getDisplayLocation(),
                      style: currentLanguage == 'kn'
                          ? TextStyle(
                              color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                              fontSize: 11,
                              fontFamily: 'NotoSansKannada',
                            )
                          : currentLanguage == 'hi'
                              ? TextStyle(
                                  color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                                  fontSize: 11,
                                  fontFamily: 'HindiFont',
                                )
                              : GoogleFonts.montserrat(
                                  color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                                  fontSize: 11,
                                ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (locationService.errorMessage != null)
                    GestureDetector(
                      onTap: () => locationService.requestLocationPermission(),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.orange,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageBadge(String currentLanguage) {
    return GestureDetector(
      onTap: _showLanguageDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          currentLanguage == 'kn' ? 'KA' : currentLanguage == 'hi' ? 'HI' : 'EN',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(ThemeService themeService) {
    return GestureDetector(
      onTap: () => themeService.toggleTheme(),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeService.isDarkMode
              ? AppTheme.accentOrange
              : AppTheme.accentBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (themeService.isDarkMode
                  ? AppTheme.accentOrange
                  : AppTheme.accentBlue).withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          themeService.getThemeIcon(),
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildProfileButton(String currentLanguage) {
    return GestureDetector(
      onTap: () => _showProfileMenu(currentLanguage),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.accentPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPurple.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildAppTitle(String currentLanguage, bool isDark) {
    return Center(
      child: Column(
        children: [
          // Main title (English - Montserrat)
          Text(
            'KisanVaani',
            style: GoogleFonts.montserrat(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
              shadows: [
                Shadow(
                  blurRadius: 25,
                  color: Colors.black.withOpacity(0.8),
                  offset: Offset(0, 5),
                ),
                Shadow(
                  blurRadius: 10,
                  color: AppTheme.primaryGreen.withOpacity(0.6),
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Localized subtitle
          Text(
            currentLanguage == 'kn'
                ? 'ಕೃಷಿಕವಾಣಿ'
                : currentLanguage == 'hi'
                    ? 'किसानवाणी'
                    : 'KisanVaani',
            style: currentLanguage == 'kn'
                ? AppTheme.kannadaHeading.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 15,
                        color: Colors.black.withOpacity(0.7),
                        offset: Offset(0, 3),
                      ),
                    ],
                  )
                : currentLanguage == 'hi'
                    ? TextStyle(
                        fontFamily: 'HindiFont',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 15,
                            color: Colors.black.withOpacity(0.7),
                            offset: Offset(0, 3),
                          ),
                        ],
                      )
                    : GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 15,
                            color: Colors.black.withOpacity(0.7),
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
          ),

          SizedBox(height: 12),

          // Description badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              currentLanguage == 'kn'
                  ? 'AI ಆಧಾರಿತ ಕೃಷಿ ಸಹಾಯಕ'
                  : currentLanguage == 'hi'
                      ? 'AI आधारित कृषि सहायक'
                      : 'AI-Powered Farming Assistant',
              style: currentLanguage == 'kn'
                  ? AppTheme.kannadaBody.copyWith(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )
                  : currentLanguage == 'hi'
                      ? TextStyle(
                          fontFamily: 'HindiFont',
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )
                      : GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBlocks(String currentLanguage, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height and distribute it
        final availableHeight = constraints.maxHeight;
        final topRowHeight = (availableHeight - 16) * 0.6; // 60% for top row
        final bottomRowHeight = (availableHeight - 16) * 0.4; // 40% for bottom row

        return Column(
          children: [
            // Top row - Two square blocks
            SizedBox(
              height: topRowHeight,
              child: Row(
                children: [
                  // Upload block
                  Expanded(
                    child: _buildSquareFeatureBlock(
                      title: currentLanguage == 'kn'
                          ? 'ಬೆಳೆ ಚಿತ್ರ\nಅಪ್‌ಲೋಡ್'
                          : currentLanguage == 'hi'
                              ? 'फसल चित्र\nअपलोड करें'
                              : 'Upload\nCrop Picture',
                      subtitle: currentLanguage == 'kn'
                          ? 'ರೋಗ ನಿರ್ಣಯ ಪಡೆಯಿರಿ'
                          : currentLanguage == 'hi'
                              ? 'रोग निदान प्राप्त करें'
                              : 'Get disease diagnosis',
                      icon: Icons.camera_alt_rounded,
                      gradient: [Colors.blue[400]!, Colors.blue[600]!],
                      onTap: _navigateToImageUpload,
                      currentLanguage: currentLanguage,
                      isDark: isDark,
                      // 👇 Pass in textStyle
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      subtitleStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Government schemes block
                  Expanded(
                    child: _buildSquareFeatureBlock(
                      title: currentLanguage == 'kn'
                          ? 'ಸರ್ಕಾರಿ\nಯೋಜನೆಗಳು'
                          : currentLanguage == 'hi'
                              ? 'सरकारी\nयोजनाएं'
                              : 'Government\nSchemes',
                      subtitle: currentLanguage == 'kn'
                          ? 'ಸಹಾಯಧನ ಮಾಹಿತಿ'
                          : currentLanguage == 'hi'
                              ? 'सब्सिडी जानकारी'
                              : 'Subsidy information',
                      icon: Icons.account_balance_rounded,
                      gradient: [Colors.orange[400]!, Colors.orange[600]!],
                      onTap: _navigateToSchemes,
                      currentLanguage: currentLanguage,
                      isDark: isDark,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      subtitleStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Bottom row - Full width chat block
            SizedBox(
              height: bottomRowHeight,
              child: _buildRectangleFeatureBlock(
                title: currentLanguage == 'kn'
                    ? 'ಕಿಸಾನ್ ಕವಚ್ ಜೊತೆ ಸಂಭಾಷಣೆ'
                    : currentLanguage == 'hi'
                        ? 'किसानवाणी के साथ चैट करें'
                        : 'Chat with KisanVaani',
                subtitle: currentLanguage == 'kn'
                    ? 'ಧ್ವನಿ ಮತ್ತು ಪಠ್ಯ ಸಂಭಾಷಣೆ'
                    : currentLanguage == 'hi'
                        ? 'आवाज और पाठ बातचीत'
                        : 'Voice and text conversations',
                icon: Icons.chat_rounded,
                gradient: [AppTheme.primaryGreen, AppTheme.lightGreen],
                onTap: _navigateToChat,
                currentLanguage: currentLanguage,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSquareFeatureBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required String currentLanguage,
    required bool isDark, required TextStyle titleStyle, required TextStyle subtitleStyle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              SizedBox(height: 16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: currentLanguage == 'kn'
                    ? AppTheme.kannadaHeading.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )
                    : currentLanguage == 'hi'
                        ? TextStyle(
                            fontFamily: 'HindiFont',
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )
                        : titleStyle.copyWith(
                            color: Colors.white,
                          ),
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: currentLanguage == 'kn'
                    ? AppTheme.kannadaBody.copyWith(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      )
                    : currentLanguage == 'hi'
                        ? TextStyle(
                            fontFamily: 'HindiFont',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          )
                        : subtitleStyle.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRectangleFeatureBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required String currentLanguage,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              // Icon section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              SizedBox(width: 20),

              // Text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: currentLanguage == 'kn'
                          ? AppTheme.kannadaHeading.copyWith(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )
                          : currentLanguage == 'hi'
                              ? TextStyle(
                                  fontFamily: 'HindiFont',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                              : GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      subtitle,
                      style: currentLanguage == 'kn'
                          ? AppTheme.kannadaBody.copyWith(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            )
                          : currentLanguage == 'hi'
                              ? TextStyle(
                                  fontFamily: 'HindiFont',
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                )
                              : GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToImageUpload() {
    final languageService = context.read<LanguageService>();
    final currentLanguage = languageService.selectedLanguage;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(selectedLanguage: currentLanguage),
      ),
    );
  }
  
  void _navigateToSchemes() {
    final languageService = context.read<LanguageService>();
    final currentLanguage = languageService.selectedLanguage;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GovernmentSchemesScreen(selectedLanguage: currentLanguage),
      ),
    );
  }
  
  void _navigateToChat() {
    final languageService = context.read<LanguageService>();
    final currentLanguage = languageService.selectedLanguage;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(selectedLanguage: currentLanguage),
      ),
    );
  }

  // Dialog methods
  void _showLanguageDialog() {
    final languageService = context.read<LanguageService>();
    final themeService = context.read<ThemeService>();
    final currentLanguage = languageService.selectedLanguage;
    final isDark = themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.language, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text(
              currentLanguage == 'kn' ? 'ಭಾಷೆ ಬದಲಾಯಿಸಿ' : 'Change Language',
              style: currentLanguage == 'kn'
                  ? AppTheme.kannadaHeading.copyWith(
                      fontSize: 18,
                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                    )
                  : GoogleFonts.montserrat(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                    ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('en', 'English', 'Switch to English', currentLanguage, isDark),
            SizedBox(height: 8),
            _buildLanguageOption('kn', 'ಕನ್ನಡ', 'ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಿ', currentLanguage, isDark),
            SizedBox(height: 8),
            _buildLanguageOption('hi', 'हिन्दी', 'हिन्दी में बदलें', currentLanguage, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLanguage == 'kn' 
                  ? 'ರದ್ದುಮಾಡಿ' 
                  : currentLanguage == 'hi'
                      ? 'रद्द करें'
                      : 'Cancel',
              style: GoogleFonts.montserrat(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String langCode, String title, String subtitle, String currentLanguage, bool isDark) {
    final languageService = context.read<LanguageService>();
    bool isSelected = currentLanguage == langCode;
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        languageService.changeLanguage(langCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langCode == 'kn' 
                ? 'ಭಾಷೆ ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಲಾಗಿದೆ' 
                : 'Language changed to English'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : (isDark ? AppTheme.darkSurface : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : (isDark ? AppTheme.darkBorder : Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                langCode.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(String currentLanguage) {
    final themeService = context.read<ThemeService>();
    final isDark = themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text(
              currentLanguage == 'kn' ? 'ಪ್ರೊಫೈಲ್' : 'Profile',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkOnSurface : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6, color: AppTheme.accentBlue),
              title: Text(
                currentLanguage == 'kn' ? 'ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳು' : 'Theme Settings',
                style: GoogleFonts.montserrat(
                  color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                ),
              ),
              subtitle: Text(
                themeService.getThemeName(),
                style: GoogleFonts.montserrat(
                  color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showThemeDialog(currentLanguage);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppTheme.errorRed),
              title: Text(
                currentLanguage == 'kn' ? 'ಲಾಗೌಟ್' : 'Sign Out',
                style: GoogleFonts.montserrat(
                  color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(currentLanguage);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLanguage == 'kn' ? 'ಮುಚ್ಚು' : 'Close',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(String currentLanguage) {
    final themeService = context.read<ThemeService>();
    final isDark = themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.palette, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text(
              currentLanguage == 'kn' ? 'ಥೀಮ್ ಆಯ್ಕೆ' : 'Choose Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkOnSurface : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              ThemeMode.light,
              Icons.light_mode,
              currentLanguage == 'kn' ? 'ಬೆಳಕಿನ ಥೀಮ್' : 'Light Theme',
              currentLanguage == 'kn' ? 'ಬಿಳಿ ಹಿನ್ನೆಲೆ' : 'White background',
              themeService,
              currentLanguage,
              isDark,
            ),
            SizedBox(height: 8),
            _buildThemeOption(
              ThemeMode.dark,
              Icons.dark_mode,
              currentLanguage == 'kn' ? 'ಗಾಢ ಥೀಮ್' : 'Dark Theme',
              currentLanguage == 'kn' ? 'ಕಪ್ಪು ಹಿನ್ನೆಲೆ' : 'Dark background',
              themeService,
              currentLanguage,
              isDark,
            ),
            SizedBox(height: 8),
            _buildThemeOption(
              ThemeMode.system,
              Icons.brightness_auto,
              currentLanguage == 'kn' ? 'ಸಿಸ್ಟಮ್ ಥೀಮ್' : 'System Theme',
              currentLanguage == 'kn' ? 'ಸಾಧನದ ಸೆಟ್ಟಿಂಗ್ ಅನುಸರಿಸಿ' : 'Follow device setting',
              themeService,
              currentLanguage,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLanguage == 'kn' ? 'ಮುಚ್ಚು' : 'Close',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeMode mode,
    IconData icon,
    String title,
    String subtitle,
    ThemeService themeService,
    String currentLanguage,
    bool isDark,
  ) {
    bool isSelected = themeService.themeMode == mode;
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        themeService.setThemeMode(mode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'kn' 
                  ? 'ಥೀಮ್ ಬದಲಾಯಿಸಲಾಗಿದೆ' 
                  : 'Theme changed successfully',
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : (isDark ? AppTheme.darkSurface : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : (isDark ? AppTheme.darkBorder : Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppTheme.primaryGreen 
                  : (isDark ? AppTheme.darkSecondaryText : Colors.grey[600]),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(String currentLanguage) {
    final themeService = context.read<ThemeService>();
    final isDark = themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text(
              currentLanguage == 'kn' ? 'ಲಾಗೌಟ್ ಮಾಡಿ' : 'Sign Out',
              style: currentLanguage == 'kn'
                  ? AppTheme.kannadaHeading.copyWith(
                      fontSize: 18,
                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                    )
                  : TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                    ),
            ),
          ],
        ),
        content: Text(
          currentLanguage == 'kn'
              ? 'ನೀವು ನಿಜವಾಗಿಯೂ ಲಾಗೌಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?'
              : 'Are you sure you want to sign out?',
          style: currentLanguage == 'kn'
              ? AppTheme.kannadaBody.copyWith(
                  color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                )
              : TextStyle(
                  fontSize: 16,
                  color: isDark ? AppTheme.darkOnSurface : Colors.black87,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLanguage == 'kn' ? 'ರದ್ದುಮಾಡಿ' : 'Cancel',
              style: TextStyle(color: isDark ? AppTheme.darkSecondaryText : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              currentLanguage == 'kn' ? 'ಲಾಗೌಟ್' : 'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontFamily: currentLanguage == 'kn' ? 'NotoSansKannada' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final authService = context.read<AuthService>();
    final languageService = context.read<LanguageService>();
    final currentLanguage = languageService.selectedLanguage;
    
    try {
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'kn'
                  ? 'ಯಶಸ್ವಿಯಾಗಿ ಲಾಗೌಟ್ ಆಗಿದೆ'
                  : 'Successfully signed out',
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'kn'
                  ? 'ಲಾಗೌಟ್ ಮಾಡುವಲ್ಲಿ ದೋಷ: $e'
                  : 'Error signing out: $e',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
