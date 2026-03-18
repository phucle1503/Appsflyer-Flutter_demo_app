import 'package:flutter/material.dart';
// import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_page.dart';
import 'package:firebase_core/firebase_core.dart';        
import 'package:firebase_messaging/firebase_messaging.dart'; 


class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginPageState();
}

class _LoginPageState extends State<Loginpage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _logMessage = '';
  bool inboxInitialized = false;  
  bool isLoggedIn = false;
  // final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin();

  @override
  void initState() {
    super.initState();
    // _initializeInboxHandlers(); 
    _checkLoginAndInitInbox();  
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final identity = _idController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final profile = {
        'Name': name,
        'Identity': identity,
        'Email': email,
        'Phone': phone,
        'stuff': ['bags', 'shoes'],
      };

      // await CleverTapPlugin.onUserLogin(profile);
      // await CleverTapPlugin.recordEvent('Login', {'method': 'email_password'});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true); 

      // CleverTapPlugin.initializeInbox();
  
      setState(() {
        _logMessage =
            '[Login] Name: $name | ID: $identity | Email: $email | Phone: $phone | Password: $password';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final identity = _idController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      final profile = {
        'Name': name,
        'Identity': identity,
        'Email': email,
        'Phone': phone,
        'stuff': ['bags', 'shoes'],
      };

      // await CleverTapPlugin.profileSet(profile);

      setState(() {
        _logMessage = '[Update] Đã cập nhật profile cho ID $identity ';
        // _fetchCleverTapId();
      });
    }
  }

  // Future<void> _fetchCleverTapId() async {
  // try {
  //   final CT_id = await CleverTapPlugin.getCleverTapID();
  //   debugPrint('CleverTap ID: $CT_id');
  //   setState(() {
  //     _logMessage = '[CleverTap ID] Đã log CT_id: $CT_id';
  //   });
  // } catch (e) {
  //   debugPrint('Lấy CleverTap ID lỗi: $e');
  //   }
  // }

  Future<void> _syncLocationToCleverTap() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Quyền truy cập vị trí bị từ chối.")),
        );
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Quyền truy cập vị trí bị từ chối vĩnh viễn.")),
      );
      return;
    }

    try {
      Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
      // CleverTapPlugin.setLocation(p.latitude, p.longitude);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🧭 Đã gửi vị trí: (${p.latitude}, ${p.longitude})")),
      );
      print("🧭 Đã gửi vị trí: (${p.latitude}, ${p.longitude})");

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lấy vị trí thất bại.")),
      );
    }
  }

  void _goToProductPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>  Productpage()),
    );
  }

  void _showPushPrimer() {
    var pushPrimerJSON = {
      'inAppType': 'half-interstitial',
      'titleText': 'Get Notified',
      'messageText': 'Please enable notifications on your device to use Push Notifications.',
      'followDeviceOrientation': false,
      'positiveBtnText': 'Allow',
      'negativeBtnText': 'Cancel',
      'fallbackToSettings': true,
      //fallbackToSettings: true --> navigate to settings; fallbackToSettings: false --> show single opt-in
      'backgroundColor': '#f6acff',
      'btnBorderColor': '#000000',
      'titleTextColor': '#000000',
      'messageTextColor': '#000000',
      'btnTextColor': '#000000',
      'btnBackgroundColor': '#FFFFFF',
      'btnBorderRadius': '4',
      'imageUrl': 'https://media.licdn.com/dms/image/v2/C560BAQF34hDVYAkTPA/company-logo_200_200/company-logo_200_200/0/1661180193743?e=2147483647&v=beta&t=JB3TxPIt2t6byGsInkGfnAr736S3z8J4gyrZbRSM_Kc'
    };

    // CleverTapPlugin.promptPushPrimer(pushPrimerJSON);
  }

  // void _initializeInboxHandlers() {
  //   _cleverTapPlugin.setCleverTapInboxDidInitializeHandler(inboxDidInitialize);
  //   _cleverTapPlugin.setCleverTapInboxMessagesDidUpdateHandler(inboxMessagesDidUpdate);
  // }

  void _checkLoginAndInitInbox() async {
    final prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('is_logged_in');
    if (loggedIn == true) {
      // CleverTapPlugin.initializeInbox();
    }
  }

  void inboxDidInitialize() {
      this.setState(() {      
      inboxInitialized = true;
      debugPrint("[App Inbox] ✅ Đã khởi tạo Inbox");
          });
  }

  void inboxMessagesDidUpdate() {
    debugPrint("[App Inbox] 🔄 Có cập nhật tin nhắn mới");
    setState(() {});
  }

  void _showAppInbox() {
    if (!inboxInitialized) {
      debugPrint("❌ Inbox chưa sẵn sàng");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inbox chưa sẵn sàng. Vui lòng thử lại sau.')),
      );
      return;
    }
    
    var styleConfig = {
      'noMessageText': 'Không có tin nhắn nào.',
      'noMessageTextColor': '#000000',
      'navBarTitle': 'App Inbox',
      'navBarTitleColor': '#FFFFFF',
      'navBarColor': '#1976D2',
      'tabs': ['Promotions', 'Offers', 'Others']
    };
    // CleverTapPlugin.showInbox(styleConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập Name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'Identity'),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập Identity' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập Email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('Update Profile'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _goToProductPage,
                  child: const Text('Go to Products'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _syncLocationToCleverTap,
                  child: const Text('Sync Location'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showPushPrimer,
                  child: const Text('Show Push Primer'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showAppInbox,
                  child: const Text('Go to App Inbox'),
                ),
                const SizedBox(height: 16),
                Text(
                  _logMessage,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
