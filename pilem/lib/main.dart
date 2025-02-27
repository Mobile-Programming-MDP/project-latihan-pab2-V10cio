import 'package:flutter/material.dart'; 
import 'package:pilem/screens/home_screen.dart'; 
import 'package:pilem/screens/search_screen.dart'; 
import 'package:pilem/screens/favorite_screen.dart'; 
 
void main() => runApp(const MyApp()); 
 
class MyApp extends StatelessWidget { 
  const MyApp({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      debugShowCheckedModeBanner: false, 
      title: 'Pilem', 
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), 
        useMaterial3: true, 
      ), 
      home: const MainScreen(), 
    ); 
  } 
} 
 
class MainScreen extends StatefulWidget { 
  const MainScreen({super.key}); 
 
  @override 
  MainScreenState createState() => MainScreenState(); 
} 
 
class MainScreenState extends State<MainScreen> { 
  int _selectedIndex = 0; 
 
  final List<Widget> _screens = [ 
    HomeScreen(), 
    const SearchScreen(), 
    const FavoriteScreen(), 
  ]; 
 
  void _onItemTapped(int index) { 
    setState(() { 
      _selectedIndex = index; 
    }); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      body: _screens[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar( 
        currentIndex: _selectedIndex, 
        onTap: _onItemTapped, 
        items: const <BottomNavigationBarItem>[ 
          BottomNavigationBarItem( 
            icon: Icon(Icons.home), 
            label: 'Home', 
          ), 
          BottomNavigationBarItem( 
            icon: Icon(Icons.search), 
            label: 'Search', 
          ), 
          BottomNavigationBarItem( 
            icon: Icon(Icons.favorite), 
            label: 'Favorite', 
          ), 
        ], 
      ), 
    ); 
  } 
} 