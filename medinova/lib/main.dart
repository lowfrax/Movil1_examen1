import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  //inicio de la app
  // importar la libreria de flutter blue plus
    //este fragmento de codigo es para ver los logs en consola
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color:false);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //Scaffold sirbe para crear la estructura basica de la app y le damos
      //extract widget para crear un widget aparte y agregamos const para
      //optimizar el codigo
      home: const HomeScreen(),
    );
  }
}

//convertimos en un statefull widget para manejar estados
//y asi poder manejar la logica de la app
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //Aqui va la logica de la app
  //variables, controladores, funciones, etc
  @override
  void initState() {
    
    super.initState();
  }

  //funcion que sirve para habilitar el bluetooth
  //y verificar si el dispositivo soporta bluetooth
  Future<void> _enableFlutterBle() async {
    //intancia no modificable que determina por medio de la libreria
    //si el dispositivo soporta bluetoth
    final esSoportado = await FlutterBluePlus.isSupported == false;
    //si el dispositivo no soporta bluetoth
    if (esSoportado) {
    log("Bluetooth no soportado por el dispositivo");
    return;
    }//en caso de que si soporte bluetoth
    else{
      log('Bluetoth si soportado :) ');

       //determina la situacion actual del adaptador
       final estado = FlutterBluePlus.adapterState.first;
       log(estado.toString());

        //si el adaptador no esta encendido
        if (estado != BluetoothAdapterState.on) {
          log('Bluetooth apagado');
          return;
        }


      
       //suscripcion recibe todos los dispositivos en el area 
       //bluetoth
              final suscripcion = FlutterBluePlus.onScanResults.listen((resultados) {

                if (resultados.isNotEmpty) {
                    ScanResult r = resultados.last; // the most recently found device
                    log('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
                }
            },
            onError: (e) => print(e),
        );







       //imprime la situacion actual del estado

      /*
       final subscription = FlutterBluePlus.adapterState.listen((
        BluetoothAdapterState state,
        ) {
          //cambiamos el print por log para que muestre mas info
          //este log muestra el estado actual de state
        log(state.toString());
        if (state == BluetoothAdapterState.on) {
            // si el adaptador bluetoth esta encendido
        } else {
            // en caso de que no mostrar un error al usuario
        }
    });

    */

    }
    
    
   



  }




  @override
  Widget build(BuildContext context) {
    //EL return scaffold se usa para crear estructuras en la app
    //creamos un boton de accion y cuando se precione llamamos a la funcion
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _enableFlutterBle,
        ),


    );
    
  }
}


//Inicio de la la logica inicial de la app por defecto
/*
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

 

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
*///Fin de la logica inicial de la app por defecto