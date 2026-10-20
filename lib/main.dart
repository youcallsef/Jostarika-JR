import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  runApp(const OfflineAIChatApp());
}

class OfflineAIChatApp extends StatelessWidget {
  const OfflineAIChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JR_ai',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      home: const InitializerScreen(),
    );
  }
}

// شاشة تهيئة لمنع الشاشة الرمادية
class InitializerScreen extends StatelessWidget {
  const InitializerScreen({super.key});

  Future<void> _initHive() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('chats_box')) {
      await Hive.openBox('chats_box');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initHive(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const ChatHomeScreen();
        }
        // شاشة حميمية أو سوداء مطابقة لتصميم التطبيق بدل الرمادي المزعج
        return const Scaffold(
          backgroundColor: Color(0xFF0A0E17),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4AF37),
            ),
          ),
        );
      },
    );
  }
}

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  late Box chatBox;
  List<String> chatKeys = [];
  String currentChatKey = '';
  List<Map<String, dynamic>> currentMessages = [];
  
  final TextEditingController _controller = TextEditingController();
  bool isThinking = false;

  @override
  void initState() {
    super.initState();
    chatBox = Hive.box('chats_box');
    _loadChatsList();
  }

  void _loadChatsList() {
    setState(() {
      chatKeys = chatBox.keys.map((e) => e.toString()).toList();
      if (chatKeys.isEmpty) {
        _createNewChat('محادثة 1');
      } else {
        currentChatKey = chatKeys.first;
        _loadMessages(currentChatKey);
      }
    });
  }

  void _createNewChat(String title) {
    String key = DateTime.now().millisecondsSinceEpoch.toString();
    List<Map<String, dynamic>> initialMsg = [
      {'sender': 'ai', 'text': 'أهلاً بك! أنا نموذج Qwen الأوفلاين، جاهز للرد عليك بدون إنترنت.'}
    ];
    chatBox.put(key, initialMsg);
    setState(() {
      chatKeys = chatBox.keys.map((e) => e.toString()).toList();
      currentChatKey = key;
      currentMessages = initialMsg;
    });
  }

  void _loadMessages(String key) {
    var stored = chatBox.get(key);
    if (stored != null) {
      setState(() {
        currentChatKey = key;
        currentMessages = List<Map<String, dynamic>>.from(stored);
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || isThinking) return;

    String userText = _controller.text;
    _controller.clear();

    setState(() {
      currentMessages.add({'sender': 'user', 'text': userText});
      currentMessages.add({'sender': 'ai', 'text': 'جارٍ الرّد...'});
      isThinking = true;
    });
    chatBox.put(currentChatKey, currentMessages);

    await Future.delayed(const Duration(seconds: 2));

    String aiReply = "هذا رد من نموذج Qwen المحلي المعالج داخل جهازك بدون إنترنت.";

    setState(() {
      currentMessages.removeLast();
      currentMessages.add({'sender': 'ai', 'text': aiReply});
      isThinking = false;
    });
    chatBox.put(currentChatKey, currentMessages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('محادثة: ${chatKeys.indexOf(currentChatKey) + 1}'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.85),
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CurvedLinesPainter(),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 95),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentMessages.length,
                  itemBuilder: (context, index) {
                    bool isUser = currentMessages[index]['sender'] == 'user';
                    bool isLoading = currentMessages[index]['text'] == 'جارٍ الرّد...';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isUser 
                                  ? const Color(0xFFB8860B).withOpacity(0.3) 
                                  : const Color(0xFF1E40AF).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(
                            color: isUser ? const Color(0xFFB8860B) : const Color(0xFF2563EB),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoading) ...[
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                currentMessages[index]['text'],
                                style: TextStyle(
                                  color: isLoading ? const Color(0xFFD4AF37) : Colors.white,
                                  fontSize: 15,
                                  fontWeight: isLoading ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8860B).withOpacity(0.35),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(-3, 0),
                      ),
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withOpacity(0.45),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(3, 0),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك للنموذج...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFB8860B), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFFD4AF37)),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                'محادثاتك المحفوظة',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _createNewChat('محادثة ${chatKeys.length + 1}');
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('محادثة جديدة', style: TextStyle(color: Colors.white)),
            ),
          ),
          const Divider(color: Colors.white24, height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: chatKeys.length,
              itemBuilder: (context, index) {
                String key = chatKeys[index];
                bool isSelected = key == currentChatKey;
                return ListTile(
                  title: Text('محادثة رقم ${index + 1}', style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white70)),
                  selected: isSelected,
                  selectedTileColor: Colors.white10,
                  onTap: () {
                    _loadMessages(key);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class CurvedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.cubicTo(
      size.width * 0.4, size.height * 0.1,
      size.width * 0.6, size.height * 0.4,
      size.width, size.height * 0.3,
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.cubicTo(
      size.width * 0.3, size.height * 0.85,
      size.width * 0.7, size.height * 0.6,
      size.width, size.height * 0.75,
    );

    paint.shader = const LinearGradient(
      colors: [Colors.black, Color(0xFF1E3A8A), Colors.black],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
