import 'package:appcast_generator/appcast_generator.dart';
import 'package:example/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton.large(
          onPressed: () async => ref.read(xMLAppCastProvider.notifier).parse(),
          child: Text('PARSE'),
        ),
        body: Center(
          child: ref.watch(xMLAppCastProvider).when(
                data: (appCast) {
                  if (appCast == null) return Text('Parse XML File\nassets/appcast.xml', textAlign: TextAlign.center);
                  return Padding(padding: const EdgeInsets.all(20), child: AppCastContent(appCast: appCast));
                },
                error: (err, _) => Text('error: $err'),
                loading: () => CircularProgressIndicator(),
              ),
        ),
      ),
    );
  }
}

class AppCastContent extends StatelessWidget {
  const AppCastContent({super.key, required this.appCast});

  final Appcast appCast;

  @override
  Widget build(BuildContext context) {
    final bold = TextStyle(fontWeight: FontWeight.bold);
    return SizedBox(
      width: MediaQuery.of(context).size.width / 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('XML - APP CAST', style: bold),
          ),
          Text('Title: ${appCast.meta.title}'),
          Text('Description: ${appCast.meta.description}'),
          SizedBox(height: 8),
          Text('Language: ${appCast.meta.language}'),
          Text('Link: ${appCast.meta.link}'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('ITEMS', style: bold),
            trailing: Text('Length: ${appCast.items.length}'),
          ),
          Flexible(
            child: Center(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: appCast.items.length,
                itemBuilder: (context, index) {
                  final item = appCast.items[index];
                  return Card(
                    elevation: 0,
                    color: Colors.purple.shade50,
                    child: ListTile(
                      horizontalTitleGap: 0,
                      leading: Text((index + 1).toString()),
                      title: Text(item.title ?? ''),
                      subtitle: Text(item.releaseNotesURL ?? ''),
                      trailing: Text(item.dateString ?? ''),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
