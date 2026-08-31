import 'package:flutter/material.dart';

import 'ad_config.dart';
import 'ad_service.dart';

class PrivacyOptionsTile extends StatefulWidget {
  const PrivacyOptionsTile({super.key});

  @override
  State<PrivacyOptionsTile> createState() => _PrivacyOptionsTileState();
}

class _PrivacyOptionsTileState extends State<PrivacyOptionsTile> {
  bool _required = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!AdConfig.isSupportedPlatform) {
      if (mounted) {
        setState(() {
          _required = false;
          _loading = false;
        });
      }
      return;
    }

    final required = await AdService.instance.isPrivacyOptionsRequired();
    if (!mounted) return;

    setState(() {
      _required = required;
      _loading = false;
    });
  }

  Future<void> _showPrivacyOptions() async {
    final error = await AdService.instance.showPrivacyOptionsForm();
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open privacy choices: ${error.message}')),
      );
      return;
    }

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_required) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: ListTile(
          leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF64B5F6)),
          title: const Text(
            'Privacy choices',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Manage advertising privacy preferences',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          onTap: _showPrivacyOptions,
        ),
      ),
    );
  }
}
