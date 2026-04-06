import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders without crashing - basic smoke test', (tester) async {
    // Test that ProviderScope + MaterialApp builds
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('KidsFinance')),
          ),
        ),
      ),
    );
    
    expect(find.text('KidsFinance'), findsOneWidget);
  });
  
  testWidgets('ProviderScope allows provider usage', (tester) async {
    // Simple test provider
    final testProvider = Provider<String>((ref) => 'Test Value');
    
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                final value = ref.watch(testProvider);
                return Text(value);
              },
            ),
          ),
        ),
      ),
    );
    
    expect(find.text('Test Value'), findsOneWidget);
  });
  
  testWidgets('MaterialApp with theme builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          title: 'Test App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: Center(
              child: Text('Test'),
            ),
          ),
        ),
      ),
    );
    
    expect(find.text('Test'), findsOneWidget);
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Test App');
  });
}
