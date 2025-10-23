import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medinova/home_screen.dart';
import 'package:medinova/login_screen.dart';
import 'package:medinova/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final supabase = Supabase.instance.client;
  final _formkey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();


  bool _isLoading = false;
  bool _obsecurePassword = true;
  bool _obsecureConfirmPassword = true;

  @override
  void dispose() {
    // TODO: implement dispose
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();

  }

    Future<void> _signUp()async{
      if(!_formkey.currentState!.validate()) return;

      if(_passwordController.text != _confirmPasswordController.text){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La contraeña no coincide'),
          backgroundColor: Colors.redAccent ,
          ),
          
        );

      return;



      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await supabase.auth.signUp(
          email:  _emailController.text.trim(),
          password: _passwordController.text);

      if(mounted){
          if(response.session != null){
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=> HomeScreen()),
    
            );
          }
          else{
             ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verifica tu email para continuar tu acceso'),
          backgroundColor: Colors.green,
          ),
          
        );

        Navigator.of(context).pop();



          }
      }
      } on Exception catch (e) {
        if(mounted){
          ScaffoldMessenger.of(
            context,
            ).showSnackBar(SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      finally{
        if(mounted){
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,

          ),




        ),

        child: SafeArea(child: Center(child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),

                  ),
                ],
              ),

              child: Icon(
              Icons.person_add_outlined,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
              ),
                

              ),

              SizedBox(height: 32,), 

              Text("Crear Usuario",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,

                ),
              ),
              SizedBox(height: 8),
              Text("Registrate para continuar",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),),

              SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formkey,
                  child: Column(children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText:  'Correo',
                        hintText: 'Ingresa tu correo',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                      
                        ),

                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Por favor ingresa tu correo';
                        }
                        if(!value.contains('@')){
                          return 'Por favor ingresa un correo valido';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                      TextFormField(
                      controller: _passwordController,
                      obscureText: _obsecurePassword,
                      decoration: InputDecoration(
                        labelText:  'Contraseña',
                        hintText: 'Ingresa su contraseña',
                        prefixIcon: Icon(Icons.password_outlined),
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            _obsecurePassword = !_obsecurePassword;
                          });
                        }, icon: 
                        Icon(
                          _obsecurePassword ? Icons.visibility_outlined  : Icons.visibility_off_outlined,

                        )),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                      
                        ),

                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Por favor ingresa tu contraseña';
                        }
                        
                        return null;
                      },
                    ),

                     SizedBox(height: 16),

                      TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obsecureConfirmPassword,
                      decoration: InputDecoration(
                        labelText:  'confirmacion de Contraseña',
                        hintText: 'Ingresa su contraseña nuevamente',
                        prefixIcon: Icon(Icons.password_outlined),
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            _obsecureConfirmPassword = !_obsecureConfirmPassword;
                          });
                        }, icon: 
                        Icon(
                          _obsecureConfirmPassword ? Icons.visibility_outlined  : Icons.visibility_off_outlined,

                        )),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                      
                        ),

                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Por favor confirma tu contraseña';
                        }
                        
                        return null;
                      },
                    ),








                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56 ,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp ,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          
                          ),
                            elevation: 0,
                        ),
                       child:  _isLoading 
                          ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color:  Colors.white,
                          strokeWidth: 2,
                        ),

                       )  :Text(
                        "Crear Usuario",   
                       style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        
                        
                       ), )
                     

                       ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Ya tienes un usuario?",
                        style: TextStyle(), ),
                        TextButton(onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
                        },child: Text("Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),

                        ))
                        
                      ],
                    )





                  ]),

                )


              ),


            ],
          ),
        ),)),


      ),
    );
  }
}