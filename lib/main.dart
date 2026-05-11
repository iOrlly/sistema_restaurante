import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/registrar_venda_screen.dart';
import 'screens/registrar_producao_screen.dart';
import 'screens/registrar_faturamento_screen.dart';
import 'screens/fechamento_caixa_screen.dart';
import 'screens/terceirizados_screen.dart';
import 'screens/funcionarios_screen.dart';
import 'screens/produtos_screen.dart';
import 'screens/relatorios_screen.dart';
import 'screens/estoque_screen.dart';
import 'screens/home_screen.dart';

/// Ponto de entrada principal da aplicação Controle Restaurante.
/// Inicializa o app Flutter com tema e rotas configuradas.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

/// Widget raiz da aplicação.
/// Define o tema Material Design e as rotas para navegação entre telas.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Restaurante',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD32F2F), // Vermelho Brasa
        scaffoldBackgroundColor: const Color(0xFF121212), // Preto Carvão
        cardColor: const Color(0xFF1E1E1E), // Cinza Escuro
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFFFFB300), // Amarelo Chama
          surface: const Color(0xFF1E1E1E),
          error: Colors.redAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFFD32F2F),
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          shadowColor: const Color(0xFFD32F2F).withOpacity(0.1),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          labelLarge: TextStyle(color: Color(0xFFFFB300)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Color(0xFFFFB300),
          unselectedItemColor: Colors.grey,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2C2C2C),
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.black),
          secondarySelectedColor: const Color(0xFFFFB300),
        ),
      ),
      home: const MainNavigationWrapper(),
      routes: {
        '/registrar_venda': (context) => const RegistrarVendaScreen(),
        '/registrar_producao': (context) => const RegistrarProducaoScreen(),
        '/registrar_faturamento': (context) => const RegistrarFaturamentoScreen(),
        '/fechamento_caixa': (context) => const FechamentoCaixaScreen(),
        '/terceirizados': (context) => const TerceirizadosScreen(),
        '/funcionarios': (context) => const FuncionariosScreen(),
        '/produtos': (context) => const ProdutosScreen(),
        '/relatorios': (context) => const RelatoriosScreen(),
        '/estoque': (context) => const EstoqueScreen(),
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FuncionariosScreen(),
    const RelatoriosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Funcionários'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
        ],
      ),
    );
  }
}
