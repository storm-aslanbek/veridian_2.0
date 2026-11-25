import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

import '../../services/local_storage_service.dart';
import '../../widgets/banking_panel.dart';

class AccessCode {
  static final _pattern = RegExp(r'^[0-9]{4}$');
  static String _key(String userId) => 'app_pin_user_$userId';
  static const _enabledPrefix = 'app_pin_enabled_';
  static String _enabledKey(String userId) => '$_enabledPrefix$userId';

  static bool get hasSavedSignIn {
    if ((LocalStorageService.getString('auth_token') ?? '').isEmpty) {
      return false;
    }
    return LocalStorageService.instance.getKeys().any((key) =>
        key.startsWith(_enabledPrefix) &&
        enabled(key.substring(_enabledPrefix.length)));
  }

  static String? read(String userId) =>
      _valid(LocalStorageService.getString(_key(userId)));
  static bool enabled(String userId) =>
      LocalStorageService.getBool(_enabledKey(userId)) == true &&
      read(userId) != null;

  static Future<bool> save(String userId, String code) async =>
      await LocalStorageService.saveString(_key(userId), code) &&
      await LocalStorageService.saveBool(_enabledKey(userId), true);

  static Future<void> disable(String userId) async {
    await LocalStorageService.saveBool(_enabledKey(userId), false);
    await LocalStorageService.remove(_key(userId));
  }

  static String? _valid(String? value) =>
      value != null && _pattern.hasMatch(value) ? value : null;
}

class AccessCodeForm extends StatefulWidget {
  const AccessCodeForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onEntered,
    this.footer,
    this.extraKey,
    this.busy = false,
  });

  final String title;
  final String subtitle;
  final Future<String?> Function(String) onEntered;
  final Widget? footer;
  final Widget? extraKey;
  final bool busy;

  @override
  State<AccessCodeForm> createState() => _AccessCodeFormState();
}

class _AccessCodeFormState extends State<AccessCodeForm> {
  String _digits = '';
  String? _error;
  bool _submitting = false;

  Future<void> _add(int number) async {
    if (_submitting || widget.busy || _digits.length == 4) return;
    setState(() {
      _error = null;
      _digits += number.toString();
    });
    if (_digits.length != 4) return;
    setState(() => _submitting = true);
    final error = await widget.onEntered(_digits);
    if (!mounted) return;
    setState(() {
      _digits = '';
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = !_submitting && !widget.busy;
    return PopScope(
      canPop: enabled,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 32)
                              .clamp(0.0, double.infinity)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const BankingIcon(Icons.lock_rounded, size: 56),
                          const SizedBox(height: 18),
                          Text(widget.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(widget.subtitle, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          Semantics(
                            label: uiText(
                                'Введено цифр: {0} из 4', _digits.length),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              for (var index = 0; index < 4; index++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 7),
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < _digits.length
                                        ? colors.primary
                                        : colors.surfaceContainerHighest,
                                    border: Border.all(color: colors.outline),
                                  ),
                                ),
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _error == null
                                ? const SizedBox(height: 18)
                                : Semantics(
                                    liveRegion: true,
                                    child: Text(_error!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: colors.error)),
                                  ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 288),
                            child: Column(children: [
                              for (var row = 0; row < 3; row++)
                                Row(children: [
                                  for (var col = 1; col <= 3; col++)
                                    _number(row * 3 + col, enabled),
                                ]),
                              Row(children: [
                                Expanded(
                                    child: IgnorePointer(
                                  ignoring: !enabled,
                                  child: widget.extraKey ??
                                      const SizedBox.shrink(),
                                )),
                                _number(0, enabled),
                                Expanded(
                                  child: IconButton(
                                    tooltip: uiText('Удалить цифру'),
                                    onPressed: enabled && _digits.isNotEmpty
                                        ? () => setState(() => _digits = _digits
                                            .substring(0, _digits.length - 1))
                                        : null,
                                    icon: const Icon(Icons.backspace_rounded),
                                  ),
                                ),
                              ]),
                            ]),
                          ),
                          if (widget.footer != null) ...[
                            const SizedBox(height: 12),
                            IgnorePointer(
                                ignoring: !enabled, child: widget.footer!),
                          ],
                        ],
                      ),
                    ),
                  )),
        ),
      ),
    );
  }

  Widget _number(int number, bool enabled) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 48),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            onPressed: enabled ? () => _add(number) : null,
            child: Text('$number'),
          ),
        ),
      );
}
