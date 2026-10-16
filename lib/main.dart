import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnambraAlertApp());
}

class AnambraAlertApp extends StatelessWidget {
  const AnambraAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nigeria Safety Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        primaryColor: const Color(0xFFEF4444),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF14171F),
        ),
      ),
      home: const RootNavigator(),
    );
  }
}

// -------------------------------------------------------------
// TOP HEADLINE COMPONENT (Shown on ALL screens at the very top)
// "Nigeria Safety Watch | Stay Safe, Stay Silent" (100% Anonymous)
// -------------------------------------------------------------
class TopHeaderHeadline extends StatelessWidget implements PreferredSizeWidget {
  const TopHeaderHeadline({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(26);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: const Text(
          'Nigeria Safety Watch | Stay Safe, Stay Silent',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. ROOT NAVIGATION WRAPPER (Tabs, Biometric Guard, Disguise Decoy)
// -------------------------------------------------------------
class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  int _currentIndex = 0;
  bool _isPremium = false;
  bool _isFakeCallActive = false;

  // Local Biometric Authentication (local_auth)
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _isAuthenticated = true; // Defaults to true if biometric disabled
  bool _isBiometricChecking = false;
  String _biometricStatusMessage = 'Ready';
  bool _isDecoyFromLock = false;

  Map<String, dynamic> _userProfile = {
    'name': 'Protected User',
    'phone': '08123456789',
    'userType': 'STUDENT', // STUDENT, TRADER, RESIDENT
    'lga': 'Awka South',
    'school': 'UNIZIK (Nnamdi Azikiwe University)',
    'dept': 'Computer Science',
    'level': '300L',
    'matric': '2021/CS/1042',
    'market': 'Eke Awka',
    'shop': 'Line 4, Shop 18',
    'community': 'Ifite Awka',
    'contacts': [
      {'name': 'Family Lead', 'phone': '08031234567'},
      {'name': 'Campus Security / SUG', 'phone': '08029876543'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bioEnabled = prefs.getBool('biometric_auth_enabled') ?? false;
      setState(() {
        _isBiometricEnabled = bioEnabled;
        if (bioEnabled) {
          _isAuthenticated = false;
        } else {
          _isAuthenticated = true;
        }
      });

      if (bioEnabled) {
        _authenticateBiometrics();
      }
    } catch (_) {}
  }

  Future<void> _authenticateBiometrics() async {
    setState(() {
      _isBiometricChecking = true;
      _biometricStatusMessage = 'Awaiting fingerprint or face scan...';
    });

    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _isAuthenticated = true;
          _isBiometricChecking = false;
          _biometricStatusMessage = 'Biometrics not supported on this device';
        });
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Anambra Community Alert & Panic Features',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      setState(() {
        _isAuthenticated = authenticated;
        _isBiometricChecking = false;
        _biometricStatusMessage = authenticated
            ? 'Authenticated successfully'
            : 'Authentication cancelled or failed. Tap button to retry.';
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isBiometricChecking = false;
        _biometricStatusMessage = 'Authentication error: $e';
      });
    }
  }

  Future<void> _toggleBiometricAuth(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_auth_enabled', enabled);
      setState(() {
        _isBiometricEnabled = enabled;
        if (!enabled) {
          _isAuthenticated = true;
        }
      });
    } catch (_) {}
  }

  void _lockAppNow() {
    setState(() {
      _isAuthenticated = false;
      _biometricStatusMessage = 'App locked. Scan fingerprint to enter.';
      _isDecoyFromLock = false;
    });
  }

  void _updateProfile(Map<String, dynamic> updated) {
    setState(() {
      _userProfile = updated;
    });
  }

  void _upgradeToPremium() {
    setState(() {
      _isPremium = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Upgraded to Premium! Unlimited contacts and 60-min live GPS unlocked.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _triggerFakeCall() {
    setState(() {
      _isFakeCallActive = true;
    });
  }

  void _dismissFakeCall() {
    setState(() {
      _isFakeCallActive = false;
    });
  }

  void _openDecoyCalculator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DecoyCalculatorScreen(
          onSecretUnlock: () {
            Navigator.of(ctx).pop();
            setState(() {
              _isAuthenticated = true;
              _isDecoyFromLock = false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. If biometric authentication is armed and user has not passed check
    if (_isBiometricEnabled && !_isAuthenticated) {
      if (_isDecoyFromLock) {
        return DecoyCalculatorScreen(
          onSecretUnlock: () {
            setState(() {
              _isAuthenticated = true;
              _isDecoyFromLock = false;
            });
          },
        );
      }
      return BiometricLockScreen(
        isChecking: _isBiometricChecking,
        statusMessage: _biometricStatusMessage,
        onAuthenticate: _authenticateBiometrics,
        onOpenDecoy: () {
          setState(() {
            _isDecoyFromLock = true;
          });
        },
      );
    }

    // 2. Normal authenticated interface
    final screens = [
      PanicScreen(
        userProfile: _userProfile,
        isPremium: _isPremium,
        onTriggerFakeCall: _triggerFakeCall,
        onOpenPaywall: () => setState(() => _currentIndex = 3),
      ),
      SafeRoutesScreen(isPremium: _isPremium),
      RegistrationScreen(
        userProfile: _userProfile,
        isPremium: _isPremium,
        onSaveProfile: _updateProfile,
      ),
      PaywallScreen(
        isPremium: _isPremium,
        onUpgrade: _upgradeToPremium,
      ),
      StealthSettingsScreen(
        onOpenDecoyCalculator: _openDecoyCalculator,
        isBiometricEnabled: _isBiometricEnabled,
        onToggleBiometric: _toggleBiometricAuth,
        onLockNow: _lockAppNow,
      ),
    ];

    return Scaffold(
      appBar: const TopHeaderHeadline(),
      body: Stack(
        children: [
          screens[_currentIndex],
          if (_isFakeCallActive)
            FakeCallScreen(onDismiss: _dismissFakeCall),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF14171F),
        selectedIndex: _currentIndex,
        indicatorColor: const Color(0xFFEF4444).withOpacity(0.2),
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield, color: Color(0xFFEF4444)),
            label: 'Panic SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route, color: Color(0xFFEF4444)),
            label: 'Safe Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFEF4444)),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
            label: 'Premium',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_off_outlined),
            selectedIcon: Icon(Icons.visibility_off, color: Color(0xFFEF4444)),
            label: 'Stealth',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. PANIC SCREEN (STEALTH SILENT MODE & DUAL LOCATION OPTIONS)
// -------------------------------------------------------------
class PanicScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isPremium;
  final VoidCallback onTriggerFakeCall;
  final VoidCallback onOpenPaywall;

  const PanicScreen({
    super.key,
    required this.userProfile,
    required this.isPremium,
    required this.onTriggerFakeCall,
    required this.onOpenPaywall,
  });

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _holdTimer;
  Timer? _locationTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;
  bool _isDispatched = false;
  bool _isSirenOn = false;
  bool _isTorchOn = false;
  Position? _currentPosition;

  // Stealth Silent Mode & Offline State Variables
  final TextEditingController _safetyNoteController = TextEditingController();
  String _savedSafetyNote = "";
  bool _autoGpsEnabled = true;
  bool _isOffline = false;
  bool _noteSavedNotice = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _checkLocationPermission();
    _loadOfflineSafetyNote();
  }

  Future<void> _loadOfflineSafetyNote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedSafetyNote = prefs.getString('my_safety_note') ?? '';
        _safetyNoteController.text = _savedSafetyNote;
        _autoGpsEnabled = prefs.getBool('auto_gps_enabled') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _saveOfflineSafetyNote(String note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_safety_note', note);
      setState(() {
        _savedSafetyNote = note;
        _noteSavedNotice = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _noteSavedNotice = false;
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleAutoGps(bool val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_gps_enabled', val);
      setState(() {
        _autoGpsEnabled = val;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdTimer?.cancel();
    _locationTimer?.cancel();
    _safetyNoteController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (_) {}
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });
    // Silent on sender phone - no siren, no vibration!

    const totalSteps = 30; // 3 seconds = 30 * 100ms
    int step = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      step++;
      setState(() {
        _holdProgress = step / totalSteps;
      });
      if (step >= totalSteps) {
        timer.cancel();
        _triggerPanicDispatch();
      }
    });
  }

  void _cancelHold() {
    if (_isHolding && !_isDispatched) {
      _holdTimer?.cancel();
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  // Trigger silent stealth panic dispatch
  Future<void> _triggerPanicDispatch() async {
    setState(() {
      _isHolding = false;
      _isDispatched = true;
    });
    // Silent on sender phone: NO siren, NO vibration!

    // 1. Auto collect location by itself using geolocator in background
    String mapLink = "https://maps.google.com/?q=6.2209,7.0674";
    if (_autoGpsEnabled) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        _currentPosition = pos;
        mapLink = "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      } catch (_) {}
    }

    // 2. Build security dispatch payload combining Auto GPS Link + EXACT My Safety Note
    final p = widget.userProfile;
    final safetyNoteContent = _savedSafetyNote.trim().isNotEmpty
        ? " | SAFETY NOTE: ${_savedSafetyNote.trim()}"
        : "";

    final message =
        "🚨 STEALTH SILENT ALERT from ${p['name']} (${p['matric'] ?? p['shop']}) "
        "LGA:${p['lga']} School:${p['school']} Level:${p['level']} "
        "Dept:${p['dept']} Matric:${p['matric']} Market:${p['market']} Shop:${p['shop']}"
        "$safetyNoteContent | GPS:$mapLink";

    // 3. Secretly send SMS to trusted contacts using telephony (silent on phone)
    try {
      final Telephony telephony = Telephony.instance;
      final contacts = (p['contacts'] as List<dynamic>?) ?? [];
      for (final contact in contacts) {
        final phone = contact['phone']?.toString() ?? '';
        if (phone.isNotEmpty) {
          await telephony.sendSms(
            to: phone,
            message: message,
            isMultipart: true,
          );
        }
      }
    } catch (_) {
      // Fallback url launch if telephony direct service unavailable
      final encoded = Uri.encodeComponent(message);
      final smsUri = Uri.parse("sms:?body=$encoded");
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    }

    // 4. Premium Live Location updates every 30s for 60 mins
    if (widget.isPremium) {
      int ticks = 0;
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        ticks++;
        if (ticks > 120) {
          timer.cancel();
          return;
        }
        try {
          final updatedPos = await Geolocator.getCurrentPosition();
          final updatedUrl = "https://maps.google.com/?q=${updatedPos.latitude},${updatedPos.longitude}";
          final followUp = "📍 LIVE GPS UPDATE: $updatedUrl";
          final fSms = Uri.parse("sms:?body=${Uri.encodeComponent(followUp)}");
          if (await canLaunchUrl(fSms)) {
            await launchUrl(fSms);
          }
        } catch (_) {}
      });
    }
  }

  void _resetPanic() {
    _locationTimer?.cancel();
    setState(() {
      _isDispatched = false;
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _dialNumber(String num) async {
    final uri = Uri.parse("tel:$num");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Premium or Free Status Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF14171F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isPremium ? const Color(0xFF10B981) : const Color(0xFF374151),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isPremium ? Icons.verified : Icons.lock_outline,
                      color: widget.isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isPremium ? 'STEALTH ACTIVE (30 Days)' : 'FREE MODE (1 Alert/Day)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                if (!widget.isPremium)
                  GestureDetector(
                    onTap: widget.onOpenPaywall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'UPGRADE ₦500',
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------------------
          // OFFLINE STATE WARNING UI BANNER
          // Warns users if GPS or SMS panic features are unavailable due to lack of network signal
          // -------------------------------------------------------------
          Container(
            padding: co
