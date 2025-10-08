import 'dart:async';
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

  //lista de resultados de escaneo
  var _ResultadosScan =   <ScanResult>[];

  //sacando la suscripcion para evitar errores y poder usarla despues
  StreamSubscription<List<ScanResult>>? _dispositivosSub;


  //Aqui va la logica de la app
  //variables, controladores, funciones, etc
  @override
  void initState() {
    
    super.initState();
  }

  //dispose sirve para liberar recursos
  @override
  void dispose() {
    //cerramos la suscripcion
    _dispositivosSub?.cancel();
    super.dispose();
  }




  //funcion para mostrar en pantalla
  final TextEditingController _logController = TextEditingController();

  void mostrarEnPantalla(String mensaje) {
    setState(() {
      _logController.text += "$mensaje\n";
    });
    log(mensaje); // sigue mostrando en consola
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

                setState(() =>_ResultadosScan = resultados);
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


  //contruccion del boton
  @override
  Widget build(BuildContext context) {
    //EL return scaffold se usa para crear estructuras en la app
    //creamos un boton de accion y cuando se precione llamamos a la funcion
    return Scaffold(
      //titulo de ventana
      appBar: AppBar(
        title: const Text('Dispositivos'),
        ) ,
      //cuerpo de la ventana lista separada
      body: ListView.separated(
        //construimos la lista de resultados

        //itemCount es la cantidad de elementos en la lista
        itemCount: _ResultadosScan.length,
        itemBuilder: (context, index) {
          final resultado = _ResultadosScan[index];
          return ListTile(
            title: Text(resultado.device.advName),
            subtitle: Text(resultado.device.platformName),
            );
          },
          separatorBuilder: (context, index) => const Divider(height: 1),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enableFlutterBle,
        child: const Icon(Icons.bluetooth),
        ),

        //aqui creamos la barra superior de la app ademas de agregarle un titulo
        //y centrarlo y

        /*
          body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _logController,
        readOnly: true,
        maxLines: null,
        decoration: const InputDecoration(
          labelText: "Logs",
          border: OutlineInputBorder(),
        ),
      ),
    ),

    */
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