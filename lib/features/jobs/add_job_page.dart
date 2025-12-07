import 'package:flutter/material.dart';
import '../../core/app_state.dart';

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});
  @override State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _pay = TextEditingController();
  final _contact = TextEditingController();
  final _loc = TextEditingController();
  final _desc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Job')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title(e.g.: Moving helper)'), validator: _v),
            TextFormField(controller: _pay, decoration: const InputDecoration(labelText: 'Payment(e.g.: \$20/h or \$50)'), validator: _v),
            TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact'), validator: _v),
            TextFormField(controller: _loc, decoration: const InputDecoration(labelText: 'Location'), validator: _v),
            TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 4),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if(!_form.currentState!.validate()) return;
                await AppState.I.addJob(
                  title: _title.text.trim(),
                  pay: _pay.text.trim(),
                  contact: _contact.text.trim(),
                  location: _loc.text.trim(),
                  desc: _desc.text.trim(),
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  String? _v(String? v) => (v==null || v.trim().isEmpty) ? 'Required' : null;
}