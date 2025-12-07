import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../models/job_post.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});
  @override State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
    void _showJobDetail(JobPost job) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${job.pay}  ·  ${job.location}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact: ${job.contact}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.desc,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

  @override
  Widget build(BuildContext context) {
    final List<JobPost> jobs = List.of(AppState.I.jobs)
      ..sort((a,b)=> b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Part-time Jobs'),
        actions: [
          // Only show add button for admin users
          if (AppState.I.isAdmin)
            IconButton(
              onPressed: ()=> Navigator.pushNamed(context, '/add-job').then((_){ setState((){}); }),
              icon: const Icon(Icons.add),
              tooltip: 'Post Job',
            )
        ],
      ),
      body: jobs.isEmpty
        ? const Center(child: Text('No jobs yet'))
        : ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, __)=> const SizedBox(height: 6),
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i){
              final j = jobs[i];
              return Card(
                child: ListTile(
                  title: Text('${j.title}  ·  ${j.pay}'),
                  subtitle: Text('${j.location}\n${j.desc}', maxLines: 3, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  trailing: Text(j.createdAt.toIso8601String().substring(0,10), style: const TextStyle(fontSize: 12)),
                    onTap: () => _showJobDetail(j),
                ),
              );
            },
          ),
    );
  }
}