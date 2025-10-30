import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medinova/home_screen.dart';
import 'package:medinova/login_screen.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:medinova/custom_transitions.dart';
import 'package:medinova/models/role.dart';
import 'package:medinova/services/role_service.dart';
import 'package:medinova/widgets/role_dropdown.dart';
import 'package:medinova/widgets/persona_text_field.dart';
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obsecurePassword = true;
  bool _obsecureConfirmPassword = true;

  // Variables para código de país
  String _selectedCountryCode = '+504';
  final List<String> _countryCodes = ['+504', '+1', '+52', '+57', '+51', '+56'];

  // Variables para roles
  List<Role> _roles = [];
  Role? _selectedRole;
  bool _loadingRoles = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RoleService.getRoles();
      setState(() {
        _roles = roles;
        _loadingRoles = false;
      });
    } catch (e) {
      print('Error cargando roles: $e');
      setState(() {
        _loadingRoles = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formkey.currentState!.validate()) return;

    // Reproducir sonido
    await SoundHelper.playSelectSound();

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La contraseña no coincide'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona un rol'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar si el email ya existe
      final emailExists = await RoleService.checkEmailExists(
        _emailController.text.trim(),
      );
      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Este email ya está registrado'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Concatenar código de país con el número de teléfono
      final fullPhoneNumber =
          _selectedCountryCode.replaceAll('+', '') +
          _phoneController.text.trim();

      // Verificar si el teléfono ya existe
      final phoneExists = await RoleService.checkPhoneExists(fullPhoneNumber);
      if (phoneExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Este teléfono ya está registrado'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'display_name': _nameController.text.trim(),
          'phone': fullPhoneNumber,
        },
      );

      if (mounted) {
        // Insertar el perfil en la tabla public.perfil con el rol seleccionado
        try {
          await supabase.from('perfil').insert({
            'nombre': _nameController.text.trim(),
            'password': _passwordController.text,
            'email': _emailController.text.trim(),
            'telefono': fullPhoneNumber,
            'id_rol': _selectedRole!.id, // Usar el ID del rol seleccionado
          });
          print(
            'Perfil insertado en public.perfil con rol: ${_selectedRole!.nombreRol}',
          );
        } catch (e) {
          print('Error insertando en perfil: $e');
          // no interrumpimos el flujo de signup por fallo en insert, pero podrías manejarlo aquí
        }

        if (response.session != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verifica tu email para continuar tu acceso'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          SafeArea(
            child: SingleChildScrollView(
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

                  SizedBox(height: 32),

                  Text(
                    "Crear Usuario",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Registrate para continuar",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

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
                      child: Column(
                        children: [
                          PersonaTextField(
                            controller: _nameController,
                            labelText: 'Nombre',
                            hintText: 'Ingresa tu nombre completo',
                            prefixIcon: Icons.person_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // Campo de teléfono con código de país
                          Row(
                            children: [
                              // Selector de código de país
                              Container(
                                width: 100,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCountryCode,
                                  decoration: InputDecoration(
                                    labelText: 'Código',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: _countryCodes.map((String code) {
                                    return DropdownMenuItem<String>(
                                      value: code,
                                      child: Text(
                                        code,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCountryCode = newValue!;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              // Campo de número de teléfono
                              Expanded(
                                child: PersonaTextField(
                                  controller: _phoneController,
                                  labelText: 'Teléfono',
                                  hintText: '88578125',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu teléfono';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Combo box para selección de roles
                          if (_loadingRoles)
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                ),
                                color: Colors.grey[50],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Cargando roles...',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            RoleDropdown(
                              selectedRole: _selectedRole,
                              onChanged: (Role? role) {
                                setState(() {
                                  _selectedRole = role;
                                });
                              },
                              roles: _roles,
                            ),

                          SizedBox(height: 16),

                          PersonaTextField(
                            controller: _emailController,
                            labelText: 'Correo',
                            hintText: 'Ingresa tu correo',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo';
                              }
                              if (!value.contains('@')) {
                                return 'Por favor ingresa un correo válido';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          PersonaTextField(
                            controller: _passwordController,
                            labelText: 'Contraseña',
                            hintText: 'Ingresa tu contraseña',
                            prefixIcon: Icons.password_outlined,
                            obscureText: _obsecurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obsecurePassword = !_obsecurePassword;
                                });
                              },
                              icon: Icon(
                                _obsecurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          PersonaTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirmación de Contraseña',
                            hintText: 'Ingresa tu contraseña nuevamente',
                            prefixIcon: Icons.password_outlined,
                            obscureText: _obsecureConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obsecureConfirmPassword =
                                      !_obsecureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obsecureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor confirma tu contraseña';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Crear Usuario",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Ya tienes un usuario?", style: TextStyle()),
                              TextButton(
                                onPressed: () async {
                                  await SoundHelper.playSelectSound();
                                  Navigator.push(
                                    context,
                                    CustomPageRoute(
                                      child: LoginScreen(),
                                      transitionType: 'slideDiagonal',
                                      duration: Duration(milliseconds: 400),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const MusicControlWidget(),
        ],
      ),
    );
  }
}
