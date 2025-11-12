import 'package:flutter/material.dart';
import 'package:medinova/models/role.dart';

class RoleDropdown extends StatefulWidget {
  final Role? selectedRole;
  final Function(Role?) onChanged;
  final List<Role> roles;

  const RoleDropdown({
    super.key,
    required this.selectedRole,
    required this.onChanged,
    required this.roles,
  });

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButtonFormField<Role>(
        initialValue: widget.selectedRole,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: 'Seleccionar Rol',
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(
            Icons.person_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        items: widget.roles.map((Role role) {
          return DropdownMenuItem<Role>(
            value: role,
            child: Row(
              children: [
                Icon(
                  _getRoleIcon(role.nombreRol),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 12),
                Text(
                  role.nombreRol,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
        validator: (value) {
          if (value == null) {
            return 'Por favor selecciona un rol';
          }
          return null;
        },
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  IconData _getRoleIcon(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'usuario app':
        return Icons.person;
      case 'usuario clínica':
        return Icons.local_hospital;
      case 'doctor':
        return Icons.medical_services;
      default:
        return Icons.person_outline;
    }
  }
}
