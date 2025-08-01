import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 使用 window_manager 纯 Flutter 端隐藏系统标题栏并设为无边框
  await windowManager.ensureInitialized();
  const initialSize = Size(1280, 720);
  const minSize = Size(800, 600);

  const options = WindowOptions(
    size: initialSize,
    minimumSize: minSize,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: 'VS Code 设置',
    titleBarStyle: TitleBarStyle.hidden, // 隐藏系统标题栏
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setAsFrameless(); // 无边框
    await windowManager.setResizable(true); // 允许缩放
    await windowManager.setMinimumSize(minSize); // 设置最小尺寸
    // 可选：如果希望不限制最大尺寸，可不设置最大尺寸或设置为很大
    // await windowManager.setMaximumSize(const Size.infinite);

    // 确保不是最大化状态（最大化时无法拖边缩放）
    final isMax = await windowManager.isMaximized();
    if (isMax) {
      await windowManager.unmaximize();
    }

    await windowManager.show();
    await windowManager.focus();
  });

  // 使用 window_manager 做窗口管理时，避免 bitsdojo_window 的窗口级控制以防冲突
  // doWhenWindowReady(() {
  //   appWindow.alignment = Alignment.center;
  // });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '设置面板',
      theme: ThemeData(
        fontFamily: 'PingFangSC',
        // 显式定义浅蓝/深蓝配色，避免 fromSeed 仍然生成偏粉的次级色
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          // 主色：深蓝
          primary: Color(0xFF1E88E5), // Blue 600
          onPrimary: Colors.white,
          // 次级：浅蓝
          secondary: Color(0xFF90CAF9), // Blue 200
          onSecondary: Color(0xFF0D47A1),
          // 错误配色保持默认红
          error: Color(0xFFB00020),
          onError: Colors.white,
          // 背景/表面
          background: Colors.white,
          onBackground: Color(0xFF1A1C1E),
          surface: Color(0xFFF7F9FC), // 很浅的蓝灰，替代粉白背景
          onSurface: Color(0xFF1A1C1E),
          surfaceVariant: Color(0xFFE3F2FD), // 浅蓝变体，替代粉色变体
          onSurfaceVariant: Color(0xFF294166),
          outline: Color(0xFF90A4AE),
          outlineVariant: Color(0xFFB0BEC5),
          shadow: Colors.black54,
          scrim: Colors.black54,
          inverseSurface: Color(0xFF294166),
          onInverseSurface: Colors.white,
          inversePrimary: Color(0xFF0D47A1), // 深蓝反相
          // 额外必填字段（在部分 Flutter 版本）
          primaryContainer: Color(0xFF1565C0),
          onPrimaryContainer: Colors.white,
          secondaryContainer: Color(0xFFBBDEFB),
          onSecondaryContainer: Color(0xFF0D47A1),
          surfaceTint: Color(0xFF1E88E5),
          tertiary: Color(0xFF1565C0),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFBBDEFB),
          onTertiaryContainer: Color(0xFF0D47A1),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
      home: const SettingsPage(title: 'VS Code 设置'),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 参照 VSCode settings.json 的扁平键名结构，左侧编辑产生右侧 JSON
  // 编辑器（editor.*）
  final _editorTabSize = TextEditingController();
  final _editorFontFamily = TextEditingController();
  final _editorFontSize = TextEditingController();
  final _editorFontWeight = TextEditingController();
  final _editorLineHeight = TextEditingController();
  bool _editorFontLigatures = false;

  // 终端（terminal.integrated.*）
  final _terminalFontFamily = TextEditingController();
  final _terminalFontSize = TextEditingController();
  final _terminalFontWeight = TextEditingController();
  final _terminalLineHeight = TextEditingController();
  bool _terminalFontLigatures = false;

  // 编辑器附加设置
  String? _editorWordWrap; // off / on / wordWrapColumn / bounded

  // 调试控制台（debug.console.*）
  final _debugConsoleFontFamily = TextEditingController();
  final _debugConsoleFontSize = TextEditingController();
  final _debugConsoleLineHeight = TextEditingController();

  @override
  void dispose() {
    _editorTabSize.dispose();
    _editorFontFamily.dispose();
    _editorFontSize.dispose();
    _editorFontWeight.dispose();
    _editorLineHeight.dispose();
    _terminalFontFamily.dispose();
    _terminalFontSize.dispose();
    _terminalFontWeight.dispose();
    _terminalLineHeight.dispose();
    _debugConsoleFontFamily.dispose();
    _debugConsoleFontSize.dispose();
    _debugConsoleLineHeight.dispose();
    super.dispose();
  }

  void _onFieldChanged(String _) => setState(() {});

  num? _toNum(String s) {
    if (s.trim().isEmpty) return null;
    return num.tryParse(s);
  }

  // 构造 VSCode 风格的 settings.json（扁平 key）
  Map<String, dynamic> _buildSettingsJson() {
    final map = {
      'editor.tabSize': _toNum(_editorTabSize.text),
      'editor.fontFamily': _editorFontFamily.text.trim(),
      'editor.wordWrap': _editorWordWrap,
      'editor.fontSize': _toNum(_editorFontSize.text),
      'editor.fontWeight': _toNum(_editorFontWeight.text),
      'editor.lineHeight': _toNum(_editorLineHeight.text),
      'editor.fontLigatures': _editorFontLigatures,
      'terminal.integrated.fontFamily': _terminalFontFamily.text.trim(),
      'terminal.integrated.fontSize': _toNum(_terminalFontSize.text),
      'terminal.integrated.fontWeight': _toNum(_terminalFontWeight.text),
      'terminal.integrated.lineHeight': _toNum(_terminalLineHeight.text),
      'terminal.integrated.fontLigatures.enabled': _terminalFontLigatures,
      'debug.console.fontFamily': _debugConsoleFontFamily.text.trim(),
      'debug.console.fontSize': _toNum(_debugConsoleFontSize.text),
      'debug.console.lineHeight': _toNum(_debugConsoleLineHeight.text),
    };
    return map;
  }

  // 清理空值，保持与示例风格一致
  dynamic _clean(dynamic v) {
    if (v is Map) {
      final m = <String, dynamic>{};
      v.forEach((k, val) {
        final cleaned = _clean(val);
        if (cleaned != null && cleaned != '') {
          m[k] = cleaned;
        } else if (val == false || val == 0 || val == 0.0) {
          m[k] = val;
        }
      });
      return m;
    } else if (v is String) {
      return v.trim();
    } else {
      return v;
    }
  }

  String get _prettySettingsJson =>
      const JsonEncoder.withIndent('  ').convert(_clean(_buildSettingsJson()));

  // 小部件构建
  Widget _numberField({
    required String label,
    required TextEditingController controller,
    String? suffix,
    String? tooltip,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: _onFieldChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        suffixIcon: tooltip == null
            ? null
            : Tooltip(
                message: tooltip!,
                child: const Icon(Icons.help_outline, size: 18),
              ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? tooltip,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: _onFieldChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: tooltip == null
            ? null
            : Tooltip(
                message: tooltip!,
                child: const Icon(Icons.help_outline, size: 18),
              ),
      ),
    );
  }

  Widget _boolSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? tooltip,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontFamily: 'PingFangSC')),
        ),
        if (tooltip != null) ...[
          Tooltip(
            message: tooltip!,
            child: const Icon(Icons.help_outline, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        Transform.scale(
          scale: 0.85, // 缩小整体开关尺寸
          child: Switch(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 缩小命中区域
            // 注意：Switch 不支持 visualDensity，已移除该参数
            value: value,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ),
      ],
    );
  }

  // 左栏：三块 ExpansionTile（编辑器设置 / 终端设置 / 调试控制台）
  Widget _leftPanel(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ExpansionTile(
          title: const Text(
            '编辑器设置（editor.*）',
            style: TextStyle(fontFamily: 'PingFangSC'),
          ),
          initiallyExpanded: true,
          children: [
            const SizedBox(height: 8),
            _numberField(
              label: '编辑器 Tab 大小',
              controller: _editorTabSize,
              suffix: 'spaces',
              tooltip: '每个 Tab 等效的空格数',
            ),
            const SizedBox(height: 12),
            _textField(
              label: '编辑器字体族',
              controller: _editorFontFamily,
              hint: '例: Maple Mono, PingFang SC',
              tooltip: '设置编辑器使用的字体族（多个字体用逗号分隔，靠前的字体优先使用）',
            ),
            const SizedBox(height: 12),
            // 将 editor.wordWrap 由下拉改为紧凑型单选行，避免弹出大菜单
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      '编辑器自动换行（editor.wordWrap）',
                      style: TextStyle(fontFamily: 'PingFangSC'),
                    ),
                    SizedBox(width: 6),
                    Tooltip(
                      message:
                          'off=不换行；on=按视口宽度换行；wordWrapColumn=按列宽换行；bounded=介于视口与列宽之间',
                      child: Icon(Icons.help_outline, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final v in const [
                      'off',
                      'on',
                      'wordWrapColumn',
                      'bounded',
                    ])
                      ChoiceChip(
                        label: Text(v),
                        selected: _editorWordWrap == v,
                        onSelected: (sel) {
                          setState(() {
                            _editorWordWrap = sel ? v : null;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '编辑器字体大小',
              suffix: 'px',
              controller: _editorFontSize,
              tooltip: '编辑器字体大小（px）',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '编辑器字体粗细',
              controller: _editorFontWeight,
              tooltip: '字体粗细（数值）',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '编辑器行高',
              controller: _editorLineHeight,
              tooltip: '编辑器每行的高度，不影响字体大小',
            ),
            const SizedBox(height: 12),
            _boolSwitch(
              label: '编辑器连字功能',
              value: _editorFontLigatures,
              onChanged: (v) => _editorFontLigatures = v,
              tooltip: '启用或禁用代码字体连字（如 =>、=== 的连写字形）',
            ),
            const SizedBox(height: 8),
          ],
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text(
            '终端设置（terminal.integrated.*）',
            style: TextStyle(fontFamily: 'PingFangSC'),
          ),
          initiallyExpanded: true,
          children: [
            const SizedBox(height: 8),
            _textField(
              label: '终端字体族',
              controller: _terminalFontFamily,
              hint: '例: Maple Mono, PingFang SC',
              tooltip: '终端面板使用的字体族（多个字体用逗号分隔，靠前的字体优先使用）',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '终端字体大小',
              controller: _terminalFontSize,
              suffix: 'px',
              tooltip: '终端字体大小（px）',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '终端字体粗细',
              controller: _terminalFontWeight,
              tooltip: '终端字体粗细',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '终端行高',
              controller: _terminalLineHeight,
              tooltip: '终端行高',
            ),
            const SizedBox(height: 12),
            _boolSwitch(
              label: '终端连字功能',
              value: _terminalFontLigatures,
              onChanged: (v) => _terminalFontLigatures = v,
              tooltip: '是否启用终端字体连字',
            ),
            const SizedBox(height: 8),
          ],
        ),
        const SizedBox(height: 12),
        // 新增 调试控制台 分组
        ExpansionTile(
          title: const Text(
            '调试控制台（debug.console.*）',
            style: TextStyle(fontFamily: 'PingFangSC'),
          ),
          initiallyExpanded: true,
          children: [
            const SizedBox(height: 8),
            _textField(
              label: '调试控制台字体族',
              controller: _debugConsoleFontFamily,
              hint: '例: Maple Mono, PingFang SC',
              tooltip: '调试控制台使用的字体族（多个字体用逗号分隔，靠前优先）',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '调试控制台字体大小',
              controller: _debugConsoleFontSize,
              suffix: 'px',
              tooltip: '调试控制台字体大小（px）',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: '调试控制台行高',
              controller: _debugConsoleLineHeight,
              tooltip: '调试控制台每行高度',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  // 右栏：只读 settings.json 预览（简易高亮）+ 行号
  Widget _rightPanel(BuildContext context) {
    final jsonStr = _prettySettingsJson;

    // 语法高亮分词
    TextSpan _spanFor(String s) {
      final spans = <TextSpan>[];
      final regex = RegExp(
        r'(".*?")|(:)|(\\{|\\}|\\[|\\])|(\\btrue\\b|\\bfalse\\b|\\bnull\\b)|(\\d+(\\.\\d+)?)|(\\s+)|([,])',
      );
      int index = 0;
      const baseCodeFont = TextStyle(
        fontFamily: 'MapleMono',
        fontSize: 14,
        height: 1.0,
      );
      final stringStyle = baseCodeFont.copyWith(
        color: Colors.lightBlue.shade800,
      ); // 字符串：浅蓝
      final puncStyle = baseCodeFont.copyWith(color: Colors.grey.shade600);
      final boolNullStyle = baseCodeFont.copyWith(
        color: Colors.indigo.shade700, // 将原紫色改为深蓝
        fontStyle: FontStyle.italic,
      );
      final numberStyle = baseCodeFont.copyWith(
        color: Colors.indigo.shade900,
      ); // 数字：深蓝

      Iterable<RegExpMatch> matches = regex.allMatches(s);
      for (final m in matches) {
        if (m.start > index) {
          spans.add(
            TextSpan(text: s.substring(index, m.start), style: baseCodeFont),
          );
        }
        final text = s.substring(m.start, m.end);
        TextStyle? style = baseCodeFont;

        if (m.group(1) != null) {
          style = stringStyle; // 字符串（键与值）
        } else if (m.group(2) != null ||
            m.group(3) != null ||
            m.group(8) != null) {
          style = puncStyle; // 冒号/括号/逗号
        } else if (m.group(4) != null) {
          style = boolNullStyle; // 布尔/null
        } else if (m.group(5) != null) {
          style = numberStyle; // 数字
        } else {
          style = baseCodeFont;
        }
        spans.add(TextSpan(text: text, style: style));
        index = m.end;
      }
      if (index < s.length) {
        spans.add(TextSpan(text: s.substring(index), style: baseCodeFont));
      }
      return TextSpan(children: spans);
    }

    // 生成带行号的行部件
    List<Widget> _buildNumberedLines(String s) {
      final lines = s.split('\n');
      final lineCount = lines.length;
      final digits = lineCount.toString().length;

      const codeStyle = TextStyle(
        fontFamily: 'MapleMono',
        fontSize: 14,
        height: 1.0,
      );

      return List<Widget>.generate(lineCount, (i) {
        final ln = i + 1;
        final lineText = lines[i];

        // 行号列：右对齐、固定最小宽度
        final lineNumber = Text(
          ln.toString().padLeft(digits, ' '),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'MapleMono',
            fontSize: 14,
            height: 1.0,
            color: Color(0xFF8A9096), // 次要颜色，稍深以提高清晰度
          ),
        );

        // 代码列：逐行再做一次高亮（给每行末尾补换行）
        final code = SelectableText.rich(
          _spanFor(lineText + (i == lineCount - 1 ? '' : '\n')),
          style: codeStyle,
        );

        return Container(
          color: i % 2 == 0
              ? Colors.transparent
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.08),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行号 gutter
              ConstrainedBox(
                // 行号列宽按字体像素估算，避免过宽/过窄
                constraints: BoxConstraints(minWidth: 10.0 + digits * 8.5),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: lineNumber,
                ),
              ),
              // 代码
              Expanded(child: code),
            ],
          ),
        );
      });
    }

    // 右侧代码框容器
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 顶部工具栏：标题 + 复制按钮
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'settings.json 预览',
                    style: TextStyle(
                      fontFamily: 'PingFangSC',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  message: '复制到剪贴板',
                  child: IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: jsonStr));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message:
                      '此处展示的是可直接粘贴到 VS Code 的 settings.json 内容；点击左侧复制按钮可复制全部文本。',
                  child: IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip:
                        '用户的 settings.json 文件在 C:\\Users\\用户名\\AppData\\Roaming\\Code\\User\\settings.json 下，项目的 settings.json 文件在 项目路径\\.vscode\\settings.json',
                    onPressed: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildNumberedLines(jsonStr),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 自绘无边框标题栏（含拖拽区 + 右上角窗口控制按钮）
  Widget _customTitleBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surface;
    final fg = cs.onSurface;

    return WindowTitleBarBox(
      child: Container(
        color: bg,
        height: 36,
        child: Row(
          children: [
            // 左边：拖拽区域 + 标题
            Expanded(
              child: MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'PingFangSC',
                        fontSize: 14,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 右边：最小化/最大化/关闭按钮
            const _WindowControls(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );

    return Scaffold(
      // 去掉系统 AppBar，采用无边框窗口 + 自绘标题栏
      body: Column(
        children: [
          // 采用无边框 + 自绘标题栏，不再需要为系统栏让位
          _customTitleBar(context),
          Expanded(
            child: Row(
              children: [
                // 左：设置
                Expanded(flex: 2, child: _leftPanel(context)),
                divider,
                // 右：只读 JSON 预览
                Expanded(flex: 3, child: _rightPanel(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowControls extends StatelessWidget {
  const _WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = cs.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HoverButton(
          semanticsLabel: '最小化',
          onPressed: () {
            windowManager.minimize();
          },
          builder: (hover) => Container(
            width: 46,
            height: 36,
            color: hover
                ? cs.surfaceVariant.withOpacity(0.6)
                : Colors.transparent,
            child: Icon(Icons.remove, size: 18, color: iconColor),
          ),
        ),
        _HoverButton(
          semanticsLabel: '最大化/还原',
          onPressed: () async {
            final isMax = await windowManager.isMaximized();
            if (isMax) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          builder: (hover) => Container(
            width: 46,
            height: 36,
            color: hover
                ? cs.surfaceVariant.withOpacity(0.6)
                : Colors.transparent,
            child: Icon(Icons.crop_square, size: 18, color: iconColor),
          ),
        ),
        _HoverButton(
          semanticsLabel: '关闭',
          onPressed: () {
            windowManager.close();
          },
          builder: (hover) => Container(
            width: 46,
            height: 36,
            color: hover ? const Color(0xFFe81123) : Colors.transparent,
            child: Icon(
              Icons.close,
              size: 18,
              color: hover ? Colors.white : iconColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverButton extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback onPressed;
  final String? semanticsLabel;

  const _HoverButton({
    required this.builder,
    required this.onPressed,
    this.semanticsLabel,
    super.key,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: widget.builder(_hover),
        ),
      ),
    );
  }
}
