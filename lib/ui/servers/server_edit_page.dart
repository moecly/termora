import 'package:animations/animations.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/section_header.dart';

/// Create/edit form for a [ServerConfig].
class ServerEditPage extends StatefulWidget {
  const ServerEditPage({super.key, this.server});

  /// Null means "create a new server".
  final ServerConfig? server;

  @override
  State<ServerEditPage> createState() => _ServerEditPageState();
}

class _ServerEditPageState extends State<ServerEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _privateKey;
  late final TextEditingController _passphrase;
  late final TextEditingController _note;

  AuthMethod _method = AuthMethod.password;
  bool _favorite = false;
  bool _rememberPassword = false;
  bool _rememberPassphrase = false;
  String? _groupId;
  bool _saving = false;

  bool get _isEditing => widget.server != null;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    _name = TextEditingController(text: s?.name ?? '');
    _host = TextEditingController(text: s?.host ?? '');
    _port = TextEditingController(text: (s?.port ?? 22).toString());
    _username = TextEditingController(text: s?.username ?? '');
    _password = TextEditingController();
    _privateKey = TextEditingController();
    _passphrase = TextEditingController();
    _note = TextEditingController(text: s?.note ?? '');
    _method = s?.authMethod ?? AuthMethod.password;
    _favorite = s?.favorite ?? false;
    _groupId = s?.groupId;
  }

  bool _loadedSecrets = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedSecrets) return;
    _loadedSecrets = true;
    final s = widget.server;
    final defaults = ServicesScope.of(context).settings.settings.rememberPasswordsByDefault;
    _rememberPassword = s?.rememberPassword ?? defaults;
    _rememberPassphrase = s?.rememberPassphrase ?? defaults;
    if (s != null) _loadSecrets(s.id);
  }

  Future<void> _loadSecrets(String id) async {
    final store = ServicesScope.of(context).secretStore;
    final password = await store.read('password:$id');
    final privateKey = await store.read('privateKey:$id');
    final passphrase = await store.read('passphrase:$id');
    if (!mounted) return;
    setState(() {
      if (password != null) _password.text = password;
      if (privateKey != null) _privateKey.text = privateKey;
      if (passphrase != null) _passphrase.text = passphrase;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _host,
      _port,
      _username,
      _password,
      _privateKey,
      _passphrase,
      _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validatePrivateKey(String text, String passphrase) {
    try {
      SSHKeyPair.fromPem(text, passphrase.isEmpty ? null : passphrase);
      return null;
    } catch (_) {
      return '私钥格式无效或口令错误';
    }
  }

  Future<void> _importKeyFromFile() async {
    final file = await openFile();
    if (file == null) return;
    final text = await file.readAsString();
    if (!mounted) return;
    setState(() => _privateKey.text = text);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final scope = ServicesScope.of(context);

    final id = widget.server?.id ?? newServerId();

    if (_method == AuthMethod.privateKey) {
      final keyText = _privateKey.text.trim();
      if (keyText.isEmpty) {
        final existing = await scope.secretStore.read('privateKey:$id');
        if (existing == null || existing.isEmpty) {
          _showError('请粘贴私钥内容或从文件导入');
          return;
        }
      } else {
        final error = _validatePrivateKey(keyText, _passphrase.text);
        if (error != null) {
          _showError(error);
          return;
        }
      }
    }

    setState(() => _saving = true);

    // Secrets
    if (_method == AuthMethod.password) {
      if (_rememberPassword && _password.text.isNotEmpty) {
        await scope.secretStore.write('password:$id', _password.text);
      } else {
        await scope.secretStore.delete('password:$id');
      }
    } else {
      final keyText = _privateKey.text.trim();
      if (keyText.isNotEmpty) {
        await scope.secretStore.write('privateKey:$id', keyText);
      }
      if (_passphrase.text.isNotEmpty) {
        await scope.secretStore.write('passphrase:$id', _passphrase.text);
      } else {
        await scope.secretStore.delete('passphrase:$id');
      }
    }

    final config = ServerConfig(
      id: id,
      name: _name.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      groupId: _groupId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      favorite: _favorite,
      authMethod: _method,
      rememberPassword: _rememberPassword,
      rememberPassphrase: _rememberPassphrase,
      lastConnectedAt: widget.server?.lastConnectedAt,
      createdAt: widget.server?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    await scope.servers.upsert(config);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final groups = scope.servers.groups;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑服务器' : '新增服务器'),
        actions: [
          SizedBox(
            width: 64,
            child: AnimatedSwitcher(
              duration: Motion.control,
              child: _saving
                  ? const Center(
                      key: ValueKey('saving'),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('save'),
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
            ),
          ),
          const SizedBox(width: Space.x2),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Space.x2),
          children: [
            _card(
              title: '基本信息',
              children: [
                _text(_name, '名称', validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return '请输入名称';
                  if (value.length > 64) return '名称不能超过 64 个字符';
                  return null;
                }),
                _text(_host, '主机', hint: 'IP 或域名', keyboardType: TextInputType.url, validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return '请输入主机地址';
                  if (RegExp(r'\s').hasMatch(value)) return '主机地址不能包含空白字符';
                  return null;
                }),
                _text(_port, '端口', keyboardType: TextInputType.number, validator: (v) {
                  final port = int.tryParse((v ?? '').trim());
                  if (port == null || port < 1 || port > 65535) return '端口需为 1-65535';
                  return null;
                }),
                _text(_username, '用户名', validator: (v) {
                  if ((v ?? '').trim().isEmpty) return '请输入用户名';
                  return null;
                }),
              ],
            ),
            _card(
              title: '认证',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                  child: SegmentedButton<AuthMethod>(
                    segments: const [
                      ButtonSegment(value: AuthMethod.password, label: Text('密码')),
                      ButtonSegment(value: AuthMethod.privateKey, label: Text('密钥')),
                    ],
                    selected: {_method},
                    onSelectionChanged: (s) => setState(() => _method = s.first),
                  ),
                ),
                const SizedBox(height: Space.x3),
                AnimatedSize(
                  duration: Motion.panel,
                  curve: Motion.emphasized,
                  child: PageTransitionSwitcher(
                    duration: Motion.tab,
                    transitionBuilder: (child, a, b) => SharedAxisTransition(
                      animation: a,
                      secondaryAnimation: b,
                      transitionType: SharedAxisTransitionType.vertical,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_method),
                      child: _method == AuthMethod.password
                          ? _passwordFields()
                          : _keyFields(),
                    ),
                  ),
                ),
              ],
            ),
            _card(
              title: '分组',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                  child: DropdownButtonFormField<String?>(
                    initialValue: _groupId,
                    decoration: const InputDecoration(labelText: '分组'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('未分组')),
                      for (final group in groups)
                        DropdownMenuItem<String?>(value: group.id, child: Text(group.name)),
                    ],
                    onChanged: (value) => setState(() => _groupId = value),
                  ),
                ),
              ],
            ),
            _card(
              title: '备注',
              children: [
                _text(_note, '备注（可选）', maxLines: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _favorite,
                    onChanged: (v) => setState(() => _favorite = v),
                    title: const Text('收藏'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordFields() {
    return Column(
      children: [
        _text(_password, '密码', obscure: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x3),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _rememberPassword,
            onChanged: (v) => setState(() => _rememberPassword = v),
            title: const Text('记住密码'),
          ),
        ),
      ],
    );
  }

  Widget _keyFields() {
    return Column(
      children: [
        _text(_privateKey, '私钥内容（PEM）', maxLines: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _importKeyFromFile,
              icon: const Icon(Icons.file_open_outlined, size: 18),
              label: const Text('从文件导入'),
            ),
          ),
        ),
        _text(_passphrase, '私钥口令（可选）', obscure: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x3),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _rememberPassphrase,
            onChanged: (v) => setState(() => _rememberPassphrase = v),
            title: const Text('记住口令'),
          ),
        ),
      ],
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: p.border),
        boxShadow: AppShadows.of(theme.brightness, 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, dense: true),
          ...children,
          const SizedBox(height: Space.x2),
        ],
      ),
    );
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    String? hint,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Space.x3,
        right: Space.x3,
        bottom: Space.x3,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      ),
    );
  }
}
