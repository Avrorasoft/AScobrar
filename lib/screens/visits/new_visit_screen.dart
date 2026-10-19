import 'package:flutter/material.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../models/visit_model.dart';
import '../../widgets/emoji_header.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

/// 🚗 Registro de visita del cobrador con GPS
class NewVisitScreen extends StatefulWidget {
  final String loanId;
  final String clientId;
  final String clientName;

  const NewVisitScreen({
    super.key,
    required this.loanId,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  VisitResult _result = VisitResult.notHome;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // TODO: Guardar visita con GPS actual
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06B6D4), Color(0xFF84CC16)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('←',
                            style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: EmojiHeader(emoji: '🚗', title: 'Registrar Visita'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cliente: ${widget.clientName}',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: 20),
                        Text('📋 Resultado de la visita',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: 12),
                        _resultOption(VisitResult.paid, '✅ Pagó', 'El cliente realizó el pago'),
                        _resultOption(VisitResult.promise, '📝 Promesa', 'Prometió pagar en fecha'),
                        _resultOption(VisitResult.notHome, '🚪 No estaba', 'No se encontró al cliente'),
                        _resultOption(VisitResult.stillOverdue, '🚨 Sigue en mora', 'No hay compromiso de pago'),
                        const SizedBox(height: 20),
                        Text('📝 Notas', style: AppTypography.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notes,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Observaciones de la visita...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: GradientButton(
                            label: 'Guardar Visita',
                            emoji: '🚗',
                            isLoading: _saving,
                            onTap: _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultOption(VisitResult result, String title, String subtitle) {
    final isSelected = _result == result;
    return GestureDetector(
      onTap: () => setState(() => _result = result),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primary : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}