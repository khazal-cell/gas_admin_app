import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';

class AdminColors {
  static const Color primary = Color(0xFFF92424);
  static const Color slate = Color(0xFF707C88);
  static const Color dark = Color(0xFF1E272E);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF4F6F9);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCxej2WMgulbbgNZmZLUja8H_Z6ZqjB9l8",
      projectId: "gazi-delivery",
      messagingSenderId: "761149642574",
      appId: "1:761149642574:web:0000000000000000000000",
    ),
  );

  runApp(const GasAdminApp());
}

class GasAdminApp extends StatelessWidget {
  const GasAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحةالمدير',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.primary,
          primary: AdminColors.primary,
          secondary: AdminColors.slate,
        ),
        scaffoldBackgroundColor: AdminColors.background,
        useMaterial3: true,
      ),
      home: const AdminLoginScreen(),
    );
  }
}

// ==========================================
// 1. شاشة قفل المدير (كلمة المرور + البصمة)
// ==========================================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'يرجى تأكيد بصمة قفل الجهاز للدخول إلى لوحة المدير',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (didAuthenticate && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainDashboard()),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _verifyPassword() async {
    final enteredPassword = _passwordController.text.trim();
    if (enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('system_settings').doc('admin_security').get();
      String correctPassword = 'admin';
      if (doc.exists && doc.data()?['password'] != null) {
        correctPassword = doc.data()!['password'];
      } else {
        await FirebaseFirestore.instance.collection('system_settings').doc('admin_security').set({
          'password': 'admin',
        });
      }

      if (enteredPassword == correctPassword && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainDashboard()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور غير صحيحة!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحقق: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AdminColors.dark,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.fingerprint, size: 70, color: AdminColors.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'لوحة تحكم المدير',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'الدخول بكلمة المرور أو بصمة قفل الجهاز',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: AdminColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'أدخل كلمة المرور',
                      prefixIcon: Icon(Icons.lock_outline, color: AdminColors.slate),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _verifyPassword,
                      icon: const Icon(Icons.login),
                      label: const Text('دخول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: AdminColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'الدخول بالبصمة',
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                      ),
                      onPressed: _checkBiometrics,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. لوحة التحكم المركزية
// ==========================================
class AdminMainDashboard extends StatefulWidget {
  const AdminMainDashboard({super.key});

  @override
  State<AdminMainDashboard> createState() => _AdminMainDashboardState();
}

class _AdminMainDashboardState extends State<AdminMainDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchOrdersController = TextEditingController();
  final TextEditingController _searchDriversController = TextEditingController();
  final TextEditingController _searchCustomersController = TextEditingController();
  String _orderSearchQuery = '';
  String _driverSearchQuery = '';
  String _customerSearchQuery = '';
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchOrdersController.dispose();
    _searchDriversController.dispose();
    _searchCustomersController.dispose();
    super.dispose();
  }

  Future<bool> _verifyAdminSecurity() async {
    try {
      final bool canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canAuth) {
        final bool didAuth = await _auth.authenticate(
          localizedReason: 'يرجى تأكيد البصمة أو الوجه لتأكيد العملية',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (didAuth) return true;
      }
    } catch (_) {}

    bool? passwordConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final TextEditingController passCtrl = TextEditingController();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد كلمة المرور'),
            content: TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'أدخل كلمة مرور المدير', border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  final doc = await FirebaseFirestore.instance.collection('system_settings').doc('admin_security').get();
                  String correctPass = doc.exists && doc.data()?['password'] != null ? doc.data()!['password'] : 'admin';
                  if (passCtrl.text.trim() == correctPass) {
                    Navigator.pop(ctx, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور غير صحيحة')));
                  }
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
        );
      },
    );
    return passwordConfirmed ?? false;
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير كلمة مرور المدير'),
          content: TextField(
            controller: newPassController,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (newPassController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('system_settings').doc('admin_security').set({
                    'password': newPassController.text.trim(),
                  }, SetOptions(merge: true));
                  if (mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivationDaysDialog(String driverDocId, String driverName) {
    final TextEditingController daysController = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تفعيل اشتراك: $driverName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('حدد عدد أيام الاشتراك المطلوبة لهذا الموزع:', style: TextStyle(fontSize: 13, color: AdminColors.slate)),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الأيام (مثال: 30، 35، 60)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                bool isAllowed = await _verifyAdminSecurity();
                if (isAllowed) {
                  int days = int.tryParse(daysController.text.trim()) ?? 30;
                  DateTime expiryDate = DateTime.now().add(Duration(days: days));

                  await FirebaseFirestore.instance.collection('drivers').doc(driverDocId).update({
                    'status': 'نشط',
                    'subscriptionExpiry': Timestamp.fromDate(expiryDate),
                    'subscriptionDays': days,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تفعيل الموزع بنجاح لمدة $days يوماً ✅')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('تفعيل وإرسال'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز تحكم الإدارة الشامل'),
          backgroundColor: AdminColors.dark,
          foregroundColor: AdminColors.white,
          actions: [
            IconButton(
              tooltip: 'تغيير كلمة المرور',
              icon: const Icon(Icons.password),
              onPressed: _showChangePasswordDialog,
            ),
            IconButton(
              tooltip: 'تسجيل خروج',
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AdminColors.primary,
            labelColor: AdminColors.primary,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.tune), text: 'التحكم العام'),
              Tab(icon: Icon(Icons.people), text: 'الموزعون والاشتراكات'),
              Tab(icon: Icon(Icons.person_pin), text: 'الزبائن'),
              Tab(icon: Icon(Icons.storage), text: 'قاعدة الطلبات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTrialPeriodTab(),
            _buildDriversSubscriptionTab(),
            _buildCustomersManagementTab(),
            _buildOrdersDatabaseSearchTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialPeriodTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system_settings').doc('general').snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final bool isTrialActive = data['isTrialActive'] ?? true;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isTrialActive ? Icons.lock_open : Icons.lock, color: isTrialActive ? Colors.green : AdminColors.primary, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('مفتاح الفترة التجريبية العام (Master Switch)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTrialActive
                          ? 'الفترة التجريبية مفعّالة حالياً: بإمكان جميع الموزعين استلام الطلبات مجاناً دون قيود.'
                          : 'الفترة التجريبية مُعطلة ومغلقة: يتطلب من الموزعين تفعيل الاشتراك اليدوي.',
                      style: const TextStyle(fontSize: 13, color: AdminColors.slate, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isTrialActive ? Colors.green.shade50 : AdminColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isTrialActive ? Colors.green : AdminColors.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTrialActive ? 'الوضع الحالي: تجريبي مجاني مفتوح' : 'الوضع الحالي: اشتراك مدفوع إجباري',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isTrialActive ? Colors.green.shade900 : AdminColors.primary),
                          ),
                          Switch(
                            value: isTrialActive,
                            activeColor: Colors.green,
                            inactiveThumbColor: AdminColors.primary,
                            onChanged: (val) async {
                              bool isAllowed = await _verifyAdminSecurity();
                              if (isAllowed) {
                                FirebaseFirestore.instance.collection('system_settings').doc('general').set({
                                  'isTrialActive': val,
                                }, SetOptions(merge: true));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriversSubscriptionTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDrivers = snapshot.data?.docs ?? [];
        int totalDriversCount = allDrivers.length;
        int activeSubscriptionsCount = 0;

        for (var doc in allDrivers) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'نشط') {
            activeSubscriptionsCount++;
          }
        }

        final filteredDrivers = allDrivers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final phone = (data['phone'] ?? doc.id).toString().toLowerCase();
          final area = (data['area'] ?? '').toString().toLowerCase();
          return name.contains(_driverSearchQuery) || phone.contains(_driverSearchQuery) || area.contains(_driverSearchQuery);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AdminColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminColors.slate.withOpacity(0.2))),
                      child: Column(
                        children: [
                          const Icon(Icons.badge, color: AdminColors.slate, size: 24),
                          const SizedBox(height: 4),
                          Text('$totalDriversCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text('إجمالي الموزعين', style: TextStyle(fontSize: 11, color: AdminColors.slate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AdminColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                      child: Column(
                        children: [
                          const Icon(Icons.verified, color: Colors.green, size: 24),
                          const SizedBox(height: 4),
                          Text('$activeSubscriptionsCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text('الاشتراكات الفعالة', style: TextStyle(fontSize: 11, color: AdminColors.slate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _searchDriversController,
                decoration: InputDecoration(
                  hintText: 'بحث عن موزع...',
                  prefixIcon: const Icon(Icons.search, color: AdminColors.slate),
                  filled: true,
                  fillColor: AdminColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _driverSearchQuery = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredDrivers.isEmpty
                  ? const Center(child: Text('لا توجد نتائج مطابقة'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredDrivers.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDrivers[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final String name = data['name'] ?? 'موزع';
                        final String phone = data['phone'] ?? doc.id;
                        final String area = data['area'] ?? 'غير محددة';
                        final String status = data['status'] ?? 'قيد المراجعة';
                        final String dealerCode = data['dealerCode'] ?? 'بدون معرف';
                        final bool isActive = (status == 'نشط');

                        String expiryText = 'غير مفعل';
                        if (data['subscriptionExpiry'] != null) {
                          Timestamp expiryTs = data['subscriptionExpiry'];
                          DateTime expiryDate = expiryTs.toDate();
                          int remainingDays = expiryDate.difference(DateTime.now()).inDays;
                          if (remainingDays >= 0) {
                            expiryText = 'متبقي: $remainingDays يوم';
                          } else {
                            expiryText = 'منتهي الاشتراك ⚠️';
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                                      child: Icon(isActive ? Icons.verified : Icons.lock_clock, color: isActive ? Colors.green.shade800 : Colors.orange.shade800),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'نسخ معلومات الموزع',
                                                icon: const Icon(Icons.copy, size: 16, color: AdminColors.slate),
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(text: 'الموزع: $name\nالهاتف: $phone\nالمنطقة: $area\nالمعرف: $dealerCode'));
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ معلومات الموزع ✅')));
                                                },
                                              ),
                                            ],
                                          ),
                                          Text('هاتف: $phone | منطقة: $area | المعرف: $dealerCode', style: const TextStyle(fontSize: 12, color: AdminColors.slate)),
                                          Text(expiryText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.blue.shade800 : Colors.red)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isActive ? Colors.green : Colors.orange),
                                      ),
                                      child: Text(
                                        isActive ? 'مفعل ✅' : 'معطل ⛔',
                                        style: TextStyle(color: isActive ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                                        icon: const Icon(Icons.call, size: 16),
                                        label: const Text('اتصال'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          bool isAllowed = await _verifyAdminSecurity();
                                          if (isAllowed) {
                                            if (isActive) {
                                              await FirebaseFirestore.instance.collection('drivers').doc(doc.id).update({'status': 'معطل'});
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('تم إيقاف اشتراك الموزع بنجاح ⛔')),
                                                );
                                              }
                                            } else {
                                              _showActivationDaysDialog(doc.id, name);
                                            }
                                          }
                                        },
                                        icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 16),
                                        label: Text(isActive ? 'إيقاف الاشتراك' : 'تفعيل واختيار أيام'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isActive ? Colors.red.shade600 : Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomersManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allCustomers = snapshot.data?.docs ?? [];
        int totalCustomersCount = allCustomers.length;

        final filteredCustomers = allCustomers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final phone = (data['phone'] ?? '').toString().toLowerCase();
          final area = (data['area'] ?? '').toString().toLowerCase();
          return name.contains(_customerSearchQuery) || phone.contains(_customerSearchQuery) || area.contains(_customerSearchQuery);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminColors.slate.withOpacity(0.2))),
                child: Column(
                  children: [
                    const Icon(Icons.people_alt, color: AdminColors.primary, size: 26),
                    const SizedBox(height: 4),
                    Text('$totalCustomersCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.primary)),
                    const Text('إجمالي الزبائن المسجلين', style: TextStyle(fontSize: 12, color: AdminColors.slate)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _searchCustomersController,
                decoration: InputDecoration(
                  hintText: 'بحث عن زبون (الاسم، الهاتف، المنطقة)...',
                  prefixIcon: const Icon(Icons.search, color: AdminColors.slate),
                  filled: true,
                  fillColor: AdminColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _customerSearchQuery = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? const Center(child: Text('لا توجد نتائج مطابقة'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final doc = filteredCustomers[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final String name = data['name'] ?? 'زبون';
                        final String phone = data['phone'] ?? '';
                        final String area = data['area'] ?? 'غير محدد';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'نسخ معلومات الزبون',
                                            icon: const Icon(Icons.copy, size: 16, color: AdminColors.slate),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: 'الزبون: $name\nالهاتف: $phone\nالعنوان: $area'));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ معلومات الزبون ✅')));
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('الهاتف: $phone', style: const TextStyle(fontSize: 13, color: AdminColors.slate)),
                                      Text('العنوان: $area', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'حذف حساب الزبون',
                                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                                  onPressed: () async {
                                    bool isAllowed = await _verifyAdminSecurity();
                                    if (isAllowed) {
                                      await doc.reference.delete();
                                      var subs = await FirebaseFirestore.instance.collection('customer_subscriptions').where('customerPhone', isEqualTo: phone).get();
                                      for (var sub in subs.docs) {
                                        await sub.reference.delete();
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم حذف حساب الزبون بنجاح ✅')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersDatabaseSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchOrdersController,
            decoration: InputDecoration(
              hintText: 'ابحث عن أي طلب (اسم الزبون، الهاتف، الحالة)...',
              prefixIcon: const Icon(Icons.search, color: AdminColors.primary),
              filled: true,
              fillColor: AdminColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _orderSearchQuery = val.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data?.docs ?? [];
              final filteredOrders = orders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['customerName'] ?? '').toString().toLowerCase();
                final phone = (data['customerPhone'] ?? '').toString().toLowerCase();
                final address = (data['address'] ?? data['area'] ?? '').toString().toLowerCase();
                return name.contains(_orderSearchQuery) || phone.contains(_orderSearchQuery) || address.contains(_orderSearchQuery);
              }).toList();

              if (filteredOrders.isEmpty) {
                return const Center(child: Text('لم يتم العثور على أي طلب يطابق البحث'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final doc = filteredOrders[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text('${data['customerName'] ?? 'زبون'} - ${data['quantity'] ?? 1} قنينة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'نسخ تفاصيل الطلب',
                                    icon: const Icon(Icons.copy, size: 16, color: AdminColors.slate),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: 'الزبون: ${data['customerName']}\nالهاتف: ${data['customerPhone']}\nالعنوان: ${data['address'] ?? data['area']}\nالكمية: ${data['quantity']} (${data['cylinderType']})\nالحالة: ${data['status']}'));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ تفاصيل الطلب ✅')));
                                    },
                                  ),
                                ],
                              ),
                              Text(data['status'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('هاتف: ${data['customerPhone'] ?? ''} | العنوان: ${data['address'] ?? data['area'] ?? ''}'),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'حذف الطلب نهائياً',
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () async {
                                  bool isAllowed = await _verifyAdminSecurity();
                                  if (isAllowed) {
                                    await FirebaseFirestore.instance.collection('orders').doc(doc.id).delete();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الطلب بنجاح')));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}