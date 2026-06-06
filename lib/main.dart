import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const KeyboardMacroApp());

class KeyboardMacroApp extends StatelessWidget {
  const KeyboardMacroApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '键盘宏工具', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true, brightness: Brightness.dark),
    home: const MacroHomePage(),
  );
}

class Macro {
  String id, name, trigger, actions;
  bool enabled;
  int execCount;
  Macro({required this.id, required this.name, required this.trigger, required this.actions, this.enabled = true, this.execCount = 0});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'trigger': trigger, 'actions': actions, 'enabled': enabled, 'execCount': execCount};
  factory Macro.fromJson(Map<String, dynamic> j) => Macro(id: j['id'], name: j['name'], trigger: j['trigger'], actions: j['actions'], enabled: j['enabled'] ?? true, execCount: j['execCount'] ?? 0);
}

class MacroHomePage extends StatefulWidget {
  const MacroHomePage({super.key});
  @override
  State<MacroHomePage> createState() => _MacroHomePageState();
}

class _MacroHomePageState extends State<MacroHomePage> {
  List<Macro> _macros = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('macros');
    if (d != null) setState(() => _macros = (json.decode(d) as List).map((e) => Macro.fromJson(e)).toList());
    else {
      _macros = [
        Macro(id: '1', name: '快速保存', trigger: 'Ctrl+S', actions: '保存当前文件', execCount: 156),
        Macro(id: '2', name: '截图粘贴', trigger: 'Ctrl+Shift+S', actions: '截图 → 复制到剪贴板 → 粘贴', execCount: 89),
        Macro(id: '3', name: '打开终端', trigger: 'Ctrl+`', actions: '打开系统终端', execCount: 234),
        Macro(id: '4', name: '切换输入法', trigger: 'Ctrl+Space', actions: '切换中英文输入法', execCount: 1024),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('macros', json.encode(_macros.map((e) => e.toJson()).toList()));
  }

  void _addMacro() {
    final nameC = TextEditingController();
    final triggerC = TextEditingController();
    final actionsC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('新建宏'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '宏名称', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label))),
        const SizedBox(height: 12),
        TextField(controller: triggerC, decoration: const InputDecoration(labelText: '触发快捷键', border: OutlineInputBorder(), prefixIcon: Icon(Icons.keyboard), hintText: '如: Ctrl+Shift+A')),
        const SizedBox(height: 12),
        TextField(controller: actionsC, decoration: const InputDecoration(labelText: '执行动作', border: OutlineInputBorder(), prefixIcon: Icon(Icons.play_arrow)), maxLines: 3),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          if (nameC.text.isNotEmpty && triggerC.text.isNotEmpty) {
            setState(() => _macros.add(Macro(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, trigger: triggerC.text, actions: actionsC.text)));
            _save();
          }
          Navigator.pop(ctx);
        }, child: const Text('创建')),
      ],
    ));
  }

  void _editMacro(Macro m) {
    final nameC = TextEditingController(text: m.name);
    final triggerC = TextEditingController(text: m.trigger);
    final actionsC = TextEditingController(text: m.actions);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑宏'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '宏名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: triggerC, decoration: const InputDecoration(labelText: '触发快捷键', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: actionsC, decoration: const InputDecoration(labelText: '执行动作', border: OutlineInputBorder()), maxLines: 3),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() { m.name = nameC.text; m.trigger = triggerC.text; m.actions = actionsC.text; }); _save(); Navigator.pop(ctx); }, child: const Text('保存')),
      ],
    ));
  }

  void _execMacro(Macro m) { setState(() => m.execCount++); _save(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('执行宏: ${m.name}'), behavior: SnackBarBehavior.floating)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⌨️ 键盘宏工具'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addMacro, tooltip: '新建宏'),
      ]),
      body: _macros.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.keyboard, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('点击 + 创建宏', style: TextStyle(color: Colors.grey.shade500))])) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _macros.length, itemBuilder: (ctx, i) {
        final m = _macros[i];
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: m.enabled ? Colors.deepOrange.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Icon(Icons.keyboard, color: m.enabled ? Colors.deepOrange : Colors.grey))),
          title: Text(m.name, style: TextStyle(fontWeight: FontWeight.bold, color: m.enabled ? null : Colors.grey)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: Text(m.trigger, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
            Text(m.actions, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('已执行 ${m.execCount} 次', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Switch(value: m.enabled, onChanged: (v) { setState(() => m.enabled = v); _save(); }, activeColor: Colors.deepOrange),
            IconButton(icon: const Icon(Icons.play_circle, color: Colors.green), onPressed: m.enabled ? () => _execMacro(m) : null, tooltip: '执行'),
            PopupMenuButton(itemBuilder: (ctx) => [const PopupMenuItem(value: 'edit', child: Text('编辑')), const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red)))], onSelected: (v) { if (v == 'edit') _editMacro(m); if (v == 'delete') { setState(() => _macros.removeAt(i)); _save(); } }),
          ]),
        ));
      }),
    );
  }
}
