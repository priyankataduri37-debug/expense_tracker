import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/services/local_data_reset_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/csv_export_service.dart';
import 'data/repositories/budget_repository.dart';
import 'providers/budget_provider.dart';
import 'providers/history_provider.dart';
import 'providers/sync_provider.dart';
import 'data/repositories/sync_meta_repository.dart';
import 'data/remote/transaction_remote_source.dart';
import 'sync/sync_service.dart';
import 'data/local/ownership.dart';
import 'data/local/connection.dart';
import 'data/local/database.dart';
import 'data/remote/auth_service.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final db = AppDatabase(openConnection());

  // Created before the repository so the repository can ask it for the user id.
  final authProvider = AuthProvider(AuthService());

  final repo = TransactionRepository(db, userId: () => authProvider.userId);

  final budgetRepo = BudgetRepository(db, userId: () => authProvider.userId);

  final syncMeta = SyncMetaRepository(db);

  final localDataResetService = LocalDataResetService(db, syncMeta: syncMeta);

  final syncService = SyncService(
    repo,
    TransactionRemoteSource(),
    syncMeta,
    userId: () => authProvider.userId,
  );

  final backupService = BackupService(
    db,
    userId: () => authProvider.userId,
    syncMeta: syncMeta,
  );

  final csvExportService = CsvExportService(
    db,
    userId: () => authProvider.userId,
  );

  final ownership = LocalOwnership(db);

  void claimIfSignedIn() {
    if (authProvider.status == AuthStatus.signedIn) {
      ownership.claimLocalRows(authProvider.userId);
    }
  }

  authProvider.addListener(claimIfSignedIn); // runs when someone logs in
  claimIfSignedIn(); // runs at startup if already logged in

  runApp(
    MultiProvider(
      providers: [
        Provider<SyncService>.value(value: syncService),
        Provider<AppDatabase>.value(value: db),
        Provider<TransactionRepository>.value(value: repo),
        Provider<BudgetRepository>.value(value: budgetRepo),
        Provider<BackupService>.value(value: backupService),
        Provider<CsvExportService>.value(value: csvExportService),
        Provider<LocalDataResetService>.value(value: localDataResetService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(CategoryRepository(db)),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountProvider(AccountRepository(db)),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // When the user changes, the key changes, and Flutter throws away the old
    // providers and builds new ones that query for the new user.
    final uid = context.select<AuthProvider, String>((a) => a.userId);

    return MultiProvider(
      key: ValueKey(uid),
      providers: [
        ChangeNotifierProvider(
          create: (ctx) =>
              TransactionProvider(ctx.read<TransactionRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => DashboardProvider(ctx.read<TransactionRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => BudgetProvider(
            ctx.read<BudgetRepository>(),
            ctx.read<TransactionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) => SyncProvider(
            ctx.read<SyncService>(),
            ctx.read<TransactionRepository>(),
            enabled: uid != 'local',
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => HistoryProvider(ctx.read<TransactionRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',

        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),

        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),

        themeMode: context.watch<SettingsProvider>().themeMode,

        home: const AuthGate(),
      ),
    );
  }
}
