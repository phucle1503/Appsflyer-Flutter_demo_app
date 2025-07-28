import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _panelIdController = TextEditingController();
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin(); 

  String _cleverTapId = '';
  String _panelId = '485-766-KW7Z';

  bool _isEditingPanelId = false;
  bool inboxInitialized = false;
  bool _isOptedOut = false;
  bool _reportNetworkInfo = true;
  bool _isOffline = false;

  int _currentIndex = 0;

  List<Map<String, dynamic>> _eventProperties = [_createProperty()];

  List<Map<String, dynamic>> _userProperties = [_createProperty()];

  String _currentIdentity = '';
  List<String> _recentActions = [];

  @override
  void initState() {
    super.initState();
    _loadGdprSettings();
    _loadPanelId();
    _initializeInboxHandlers();
    CleverTapPlugin.initializeInbox();
    _recentActions.add('${_formatTime(DateTime.now())}: CleverTap initialized');

      CleverTapPlugin.getCleverTapID().then((id) {
        setState(() {
          _cleverTapId = id ?? '';
        });
      }).catchError((error) {
        setState(() {
          _cleverTapId = 'Error: $error';
        });
      });
  }

  Future<void> _loadGdprSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOptedOut = prefs.getBool('opt_out') ?? false;
      _reportNetworkInfo = prefs.getBool('network_info') ?? true;
      _isOffline = prefs.getBool('offline') ?? false;
    });
    CleverTapPlugin.setOptOut(_isOptedOut);
    CleverTapPlugin.enableDeviceNetworkInfoReporting(_reportNetworkInfo);
    CleverTapPlugin.setOffline(_isOffline);
  }

  Future<void> _updateOptOut(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('opt_out', value);
    setState(() => _isOptedOut = value);
    CleverTapPlugin.setOptOut(value);
  }

  Future<void> _updateNetworkInfo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('network_info', value);
    setState(() => _reportNetworkInfo = value);
    CleverTapPlugin.enableDeviceNetworkInfoReporting(value);
  }

  Future<void> _updateOffline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline', value);
    setState(() => _isOffline = value);
    CleverTapPlugin.setOffline(value);
  }

  static Map<String, dynamic> _createProperty() {
    return {
      'keyController': TextEditingController(),
      'valueController': TextEditingController(),
      'type': 'String',
    };
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      _buildCustomEventsTab(),
      _buildEventSampleTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('CleverTap Demo')),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Custom UA - EA'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Event Sample'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildCleverTapStatusSection({bool editable = false}) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CleverTap Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            editable && _isEditingPanelId
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _panelIdController,
                          decoration: const InputDecoration(labelText: 'Edit Panel ID'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          final newId = _panelIdController.text.trim();
                          await _savePanelId(newId);
                          setState(() {
                            _panelId = newId;
                            _isEditingPanelId = false;
                          });
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text('Panel ID: $_panelId'),
                      if (editable)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _panelIdController.text = _panelId;
                              _isEditingPanelId = true;
                            });
                          },
                        ),
                    ],
                  ),
            Text('CT_Id: $_cleverTapId'),
            Text('Identity: ${_currentIdentity.isEmpty ? '' : _currentIdentity}'),
            const Text('Recent Actions:'),
            ..._recentActions.map((action) => Text('• $action')),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomEventsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
        _buildCleverTapStatusSection(editable: false),
          const SizedBox(height: 20),
          const Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          _buildTextField(_idController, 'Identity'),
          _buildTextField(_emailController, 'Email'),
          _buildTextField(_phoneController, 'Phone'),
          ..._userProperties.asMap().entries.map((entry) {
            var prop = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(prop['keyController'], 'Property Key'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: prop['type'],
                        onChanged: (String? newValue) {
                          setState(() {
                            prop['type'] = newValue!;
                          });
                        },
                        items: ['String', 'Number', 'Boolean']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Data Type'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 50, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: prop['valueController'],
                        decoration: const InputDecoration(labelText: 'Property Value'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),

          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _userProperties.add(_createProperty());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text("Add User Property"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onUserLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('OnUserLogin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _pushProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Push Profile'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Custom Event Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          _buildTextField(_eventNameController, 'Event Name'),
          ..._eventProperties.asMap().entries.map((entry) {
            var prop = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(prop['keyController'], 'Property Key'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: prop['type'],
                        onChanged: (String? newValue) {
                          setState(() {
                            prop['type'] = newValue!;
                          });
                        },
                        items: ['String', 'Number', 'Boolean']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Data Type'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 50, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: prop['valueController'],
                        decoration: const InputDecoration(labelText: 'Property Value'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _eventProperties.add(_createProperty());
              });
            },
            icon: const Icon(Icons.add), 
            label: const Text("Add Event Property"), 
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _sendCustomEvent,
            child: const Text('Send Custom Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSampleTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            label: const Text('Charged Event'),
            onPressed: _sendChargedEvent,
          ),
          const SizedBox(height: 24),
          const Text('⚙️ Coming soon: E-commerce Samples, Travel, Banking...'),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildCleverTapStatusSection(editable: true),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _syncLocationToCleverTap,
            icon: const Icon(Icons.location_on),
            label: const Text('Sync Location', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showPushPrimer,
            icon: const Icon(Icons.notifications),
            label: const Text('Show Push Primer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAppInbox,
            icon: const Icon(Icons.mail),
            label: const Text('Go to App Inbox', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _checkAndRequestPushPermission,
            icon: const Icon(Icons.notifications),
            label: const Text('Push Permission Dialog', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('⚖️ GDPR Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                SwitchListTile(
                  title: const Text('Cho phép theo dõi hành vi'),
                  subtitle: const Text('Tắt nếu bạn muốn dừng gửi dữ liệu đến CleverTap'),
                  value: !_isOptedOut,
                  onChanged: (val) => _updateOptOut(!val),
                ),
                SwitchListTile(
                  title: const Text('Gửi thông tin mạng'),
                  subtitle: const Text('Bật để cho phép gửi thông tin Wi-Fi, mạng...'),
                  value: _reportNetworkInfo,
                  onChanged: _updateNetworkInfo,
                ),
                SwitchListTile(
                  title: const Text('Kết nối CleverTap'),
                  subtitle: const Text('Tắt nếu bạn muốn tạm dừng gửi dữ liệu đến CleverTap'),
                  value: !_isOffline,
                  onChanged: (val) => _updateOffline(!val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color.fromARGB(255, 50, 81, 136)),
          filled: true,
          fillColor: Color.fromARGB(0, 89, 130, 173),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(255, 143, 152, 168)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(255, 143, 152, 168), width: 2),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _savePanelId(String panelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('panel_id', panelId);
  }

  Future<void> _loadPanelId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _panelId = prefs.getString('panel_id') ?? '485-766-KW7Z';
    });
  }

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
      CleverTapPlugin.setLocation(p.latitude, p.longitude);

      CleverTapPlugin.recordEvent("Location Synced", {
      "lat": p.latitude,
      "lng": p.longitude,
    });

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

  void _showPushPrimer() {
    var pushPrimerJSON = {
      'inAppType': 'half-interstitial',
      'titleText': 'Get Notified',
      'messageText': 'Please enable notifications on your device to use Push Notifications.',
      'followDeviceOrientation': false,
      'positiveBtnText': 'Allow',
      'negativeBtnText': 'Cancel',
      'fallbackToSettings': false,
      'backgroundColor': '#f6acff',
      'btnBorderColor': '#000000',
      'titleTextColor': '#000000',
      'messageTextColor': '#000000',
      'btnTextColor': '#000000',
      'btnBackgroundColor': '#FFFFFF',
      'btnBorderRadius': '4',
      'imageUrl': 'https://media.licdn.com/dms/image/v2/C560BAQF34hDVYAkTPA/company-logo_200_200/company-logo_200_200/0/1661180193743?e=2147483647&v=beta&t=JB3TxPIt2t6byGsInkGfnAr736S3z8J4gyrZbRSM_Kc'
    };

    CleverTapPlugin.promptPushPrimer(pushPrimerJSON);
  }

  void _initializeInboxHandlers() {
    _cleverTapPlugin.setCleverTapInboxDidInitializeHandler(inboxDidInitialize); 
    _cleverTapPlugin.setCleverTapInboxMessagesDidUpdateHandler(inboxMessagesDidUpdate);
  }

  void inboxDidInitialize() {
    setState(() {
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
    CleverTapPlugin.showInbox(styleConfig);
  }

  Future<void> _checkAndRequestPushPermission() async {
    bool? isGranted = await CleverTapPlugin.getPushNotificationPermissionStatus();
    if (isGranted == null) {
      debugPrint("⚠️ Không lấy được trạng thái quyền push.");
      return;
    }

    if (!isGranted) {
      const fallbackToSettings = false; // true: chuyển tới Settings nếu bị từ chối
      CleverTapPlugin.promptForPushNotification(fallbackToSettings);
      debugPrint("📩 Hiển thị dialog xin quyền push...");
    } else {
      debugPrint("✅ Push permission đã được cấp.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Push Notification đã được cấp quyền")),
      );
    }
  }

  void _sendChargedEvent() {
    final chargeDetails = {
      'Amount': 2599.98,
      'Payment Mode': 'Credit Card',
      'Charged ID': 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
    };

    final itemData = {
      'Product Id': 'P001',
      'Product Name': 'Laptop Pro 15',
      'Category': 'Electronics',
      'Price': 1299.99,
      'Quantity': 2,
    };

    CleverTapPlugin.recordChargedEvent(chargeDetails, [itemData]);

    setState(() {
      _recentActions.add('${_formatTime(DateTime.now())}: Charged Event');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Đặt hàng thành công!')),
    );
  }

  void _onUserLogin() async {
    final identity = _idController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final Map<String, dynamic> profile = {};
    if (identity.isNotEmpty) profile['Identity'] = identity;
    if (email.isNotEmpty) profile['Email'] = email;
    if (phone.isNotEmpty) profile['Phone'] = phone;

    for (var prop in _userProperties) {
      final key = prop['keyController'].text.trim();
      final valueText = prop['valueController'].text.trim();
      final type = prop['type'];
      if (key.isEmpty || valueText.isEmpty) continue;

      dynamic value;
      switch (type) {
        case 'Number':
          value = num.tryParse(valueText);
          break;
        case 'Boolean':
          if (valueText.toLowerCase() == 'true') value = true;
          else if (valueText.toLowerCase() == 'false') value = false;
          break;
        default:
          value = valueText;
      }
      if (value != null) profile[key] = value;
    }

    if (profile.isNotEmpty) {
      await CleverTapPlugin.onUserLogin(profile);

          /// 🚀 Gán ct_objectId vào Firebase user property
      CleverTapPlugin.getCleverTapID().then((ctId) {
        FirebaseAnalytics.instance.setUserProperty(name: 'ct_objectId', value: ctId);
      });
      if (profile.containsKey('Identity')) {
        setState(() {
          _currentIdentity = profile['Identity'];
        });
      }
      setState(() {
        _recentActions.add('${_formatTime(DateTime.now())}: onUserLogin');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Sent profile: $profile')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Không có trường dữ liệu nào được nhập.')),
      );
    }
  }

  void _pushProfile() async {
    final identity = _idController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final Map<String, dynamic> profile = {};
    if (identity.isNotEmpty) profile['Identity'] = identity;
    if (email.isNotEmpty) profile['Email'] = email;
    if (phone.isNotEmpty) profile['Phone'] = phone;

    for (var prop in _userProperties) {
      final key = prop['keyController'].text.trim();
      final valueText = prop['valueController'].text.trim();
      final type = prop['type'];
      if (key.isEmpty || valueText.isEmpty) continue;

      dynamic value;
      switch (type) {
        case 'Number':
          value = num.tryParse(valueText);
          break;
        case 'Boolean':
          if (valueText.toLowerCase() == 'true') value = true;
          else if (valueText.toLowerCase() == 'false') value = false;
          break;
        default:
          value = valueText;
      }
      if (value != null) profile[key] = value;
    }

    if (profile.isNotEmpty) {
      await CleverTapPlugin.profileSet(profile);
      setState(() {
        _recentActions.add('${_formatTime(DateTime.now())}: Push Profile');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Updated profile: $profile')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Không có trường dữ liệu nào được nhập.')),
      );
    }
  }

  void _sendCustomEvent() async {
    final eventName = _eventNameController.text.trim();
    if (eventName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập Event Name")),
      );
      return;
    }

    final Map<String, dynamic> properties = {};
    for (var prop in _eventProperties) {
      final key = prop['keyController'].text.trim();
      final valueText = prop['valueController'].text.trim();
      final type = prop['type'];
      if (key.isEmpty || valueText.isEmpty) continue;

      dynamic value;
      switch (type) {
        case 'Number':
          value = num.tryParse(valueText);
          break;
        case 'Boolean':
          if (valueText.toLowerCase() == 'true') value = true;
          else if (valueText.toLowerCase() == 'false') value = false;
          break;
        default:
          value = valueText;
      }
      if (value != null) properties[key] = value;
    }

    try {
      await CleverTapPlugin.recordEvent(eventName, properties);
      setState(() {
        _recentActions.add('${_formatTime(DateTime.now())}: Send Event - $eventName');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Event đã được gửi: $eventName\nPayload: $properties")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Gửi event thất bại!")),
      );
    }
  }
}
