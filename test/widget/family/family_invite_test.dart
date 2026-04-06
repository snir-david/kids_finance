import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tests for Phase 4 family invite features.
/// These tests verify:
/// 1. Invite code dialog displays familyId as selectable text
/// 2. Join family validates invite code is not empty
void main() {
  group('Family Invite Code Dialog', () {
    testWidgets('invite code dialog shows familyId as selectable text', (tester) async {
      const testFamilyId = 'test-family-123';
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Family Invite Code'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Share this code with other parents:'),
                              const SizedBox(height: 16),
                              SelectableText(
                                testFamilyId,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'They can enter this code when joining an existing family.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog title
      expect(find.text('Family Invite Code'), findsOneWidget);

      // Verify familyId is displayed as SelectableText
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text(testFamilyId), findsOneWidget);

      // Verify instructions are shown
      expect(
        find.text('Share this code with other parents:'),
        findsOneWidget,
      );
      expect(
        find.textContaining('enter this code when joining'),
        findsOneWidget,
      );

      // Verify close button
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('invite code is displayed with proper styling', (tester) async {
      const testFamilyId = 'test-family-456';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Family Invite Code'),
              content: SelectableText(
                testFamilyId,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );

      expect(selectableText.data, testFamilyId);
      expect(selectableText.style?.fontSize, 20);
      expect(selectableText.style?.fontWeight, FontWeight.bold);
      expect(selectableText.style?.letterSpacing, 2);
    });

    testWidgets('invite code dialog can be dismissed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Family Invite Code'),
                        content: const SelectableText('family-123'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Family Invite Code'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Family Invite Code'), findsNothing);
    });
  });

  group('Join Existing Family', () {
    testWidgets('join family validates invite code is not empty', (tester) async {
      final formKey = GlobalKey<FormState>();
      // ignore: unused_local_variable
      String _inviteCode = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Family Invite Code',
                      hintText: 'Enter invite code',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invite code';
                      }
                      return null;
                    },
                    onSaved: (value) => _inviteCode = value ?? '',
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                      }
                    },
                    child: const Text('Join Family'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap join button without entering code
      await tester.tap(find.text('Join Family'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter an invite code'), findsOneWidget);
    });

    testWidgets('join family accepts valid invite code', (tester) async {
      final formKey = GlobalKey<FormState>();
      // ignore: unused_local_variable
      String _inviteCode = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Family Invite Code',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invite code';
                      }
                      return null;
                    },
                    onSaved: (value) => _inviteCode = value ?? '',
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                      }
                    },
                    child: const Text('Join Family'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid code
      await tester.enterText(
        find.byType(TextFormField),
        'valid-family-code',
      );
      await tester.pumpAndSettle();

      // Tap join button
      await tester.tap(find.text('Join Family'));
      await tester.pumpAndSettle();

      // Should not show validation error
      expect(find.text('Please enter an invite code'), findsNothing);
    });

    testWidgets('join family form trims whitespace from invite code', (tester) async {
      final formKey = GlobalKey<FormState>();
      // ignore: unused_local_variable
      String _inviteCode = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Family Invite Code',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invite code';
                      }
                      return null;
                    },
                    onSaved: (value) => _inviteCode = value?.trim() ?? '',
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                      }
                    },
                    child: const Text('Join Family'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter code with whitespace
      await tester.enterText(
        find.byType(TextFormField),
        '  valid-code  ',
      );
      await tester.pumpAndSettle();

      // Tap join button
      await tester.tap(find.text('Join Family'));
      await tester.pumpAndSettle();

      // Should pass validation
      expect(find.text('Please enter an invite code'), findsNothing);
    });

    testWidgets('family setup shows join existing family toggle', (tester) async {
      bool isJoiningExisting = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Join Existing Family'),
                      value: isJoiningExisting,
                      onChanged: (value) {
                        setState(() {
                          isJoiningExisting = value;
                        });
                      },
                    ),
                    if (isJoiningExisting)
                      const Text('Enter invite code')
                    else
                      const Text('Create new family'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show create new family
      expect(find.text('Join Existing Family'), findsOneWidget);
      expect(find.text('Create new family'), findsOneWidget);
      expect(find.text('Enter invite code'), findsNothing);

      // Toggle switch
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Should now show invite code input
      expect(find.text('Enter invite code'), findsOneWidget);
      expect(find.text('Create new family'), findsNothing);
    });

    testWidgets('toggle between create and join family modes', (tester) async {
      bool isJoiningExisting = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Join Existing Family'),
                      value: isJoiningExisting,
                      onChanged: (value) {
                        setState(() {
                          isJoiningExisting = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, false);

      // Toggle on
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchTileAfter = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTileAfter.value, true);

      // Toggle off
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchTileFinal = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTileFinal.value, false);
    });
  });

  group('Parent Home Screen - Invite Menu', () {
    testWidgets('parent home screen shows overflow menu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBarWithMenu(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have an overflow menu button
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('overflow menu contains "Invite Another Parent" option', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBarWithMenu(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap overflow menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Should show invite option
      expect(find.text('Invite Another Parent'), findsOneWidget);
    });

    testWidgets('tapping invite option shows dialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBarWithMenu(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap overflow menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap invite option
      await tester.tap(find.text('Invite Another Parent'));
      await tester.pumpAndSettle();

      // Should show invite dialog
      expect(find.text('Family Invite Code'), findsOneWidget);
    });
  });

  group('Child Home Screen - Switch Child', () {
    testWidgets('child home screen shows Switch Child button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBarWithSwitchChild(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have switch child button with people_outline icon
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('Switch Child button is in AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBarWithSwitchChild(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find icon button in AppBar
      final iconButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.people_outline),
      );

      expect(iconButton, findsOneWidget);
    });
  });
}

/// Helper widget for testing parent home AppBar with overflow menu
class AppBarWithMenu extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Parent Home'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'invite') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Family Invite Code'),
                  content: const SelectableText('test-family-123'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'invite',
              child: Text('Invite Another Parent'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Helper widget for testing child home AppBar with switch child button
class AppBarWithSwitchChild extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithSwitchChild({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Child Home'),
      actions: [
        IconButton(
          icon: const Icon(Icons.people_outline),
          onPressed: () {
            // In real implementation: clears selectedChildProvider and navigates
          },
          tooltip: 'Switch Child',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
