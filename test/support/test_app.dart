import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:booknest/data/auth_api.dart';
import 'package:booknest/data/book.dart';
import 'package:booknest/data/file_api.dart';
import 'package:booknest/data/loan.dart';
import 'package:booknest/data/token_store.dart';
import 'package:booknest/models/book_list_model.dart';
import 'package:booknest/models/loans_model.dart';
import 'package:booknest/models/offline_status.dart';
import 'package:booknest/models/session_model.dart';
import 'package:booknest/router.dart';

import 'fakes.dart';

/// Экран теста как у телефона (411×914 dp, плотность Pixel), а не 800×600:
/// ленивые списки строят только видимое, и размер влияет на то, что найдётся.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Приложение целиком — та же карта маршрутов (appRoutes) и те же модели,
/// что собирает main(), но хранилища подставные. Отличие от main() ровно
/// одно — источник данных; ради этого корень композиции и выделялся на L4.
class TestApp {
  TestApp({
    List<Book> mine = const [],
    List<Book> community = const [],
    List<Loan> lent = const [],
    List<Loan> borrowed = const [],
    http.Client? authClient,
  }) : library = FakeBookRepository(mine),
       communityRepo = FakeBookRepository(community),
       loans = FakeLoanRepository(lent: lent, borrowed: borrowed),
       authClient =
           authClient ?? MockClient((_) async => http.Response('', 500));

  final FakeBookRepository library;
  final FakeBookRepository communityRepo;
  final FakeLoanRepository loans;
  final http.Client authClient;
  final offline = OfflineStatus();
  final session = SessionModel();

  late final GoRouter router;

  /// Запуск на «телефоне»: дерево построено, первая загрузка обработана.
  Future<void> start(
    WidgetTester tester, {
    String initialLocation = '/books',
  }) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(build(initialLocation: initialLocation));
    await tester.pump(); // первый кадр: модели созданы, load() стартовал
    await tester.pump(); // ответ подставного хранилища (микрозадачи)
  }

  Widget build({String initialLocation = '/books'}) {
    router = GoRouter(initialLocation: initialLocation, routes: appRoutes);
    final tokens = TokenStore();
    return MultiProvider(
      providers: [
        Provider<AuthApi>(
          create: (_) => AuthApi('http://api.test', tokens, client: authClient),
        ),
        Provider<FileApi>(create: (_) => FileApi('http://api.test', tokens)),
        ChangeNotifierProvider.value(value: offline),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => LibraryModel(library)..load()),
        ChangeNotifierProvider(
          create: (_) => CommunityModel(communityRepo)..load(),
        ),
        ChangeNotifierProvider(create: (_) => LoansModel(loans)..load()),
      ],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F5D50)),
        ),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    );
  }
}
