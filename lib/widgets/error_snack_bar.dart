import 'package:flutter/material.dart';

//使用自訂的snackBar記得加上ScaffoldMessenger.of(context).showSnackBar();
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    super.duration = const Duration(seconds: 3),
    required String message,
  }) : super(
         content: Row(
           children: [
             const Icon(
               Icons.error_outline_rounded,
               color: Colors.white,
               size: 20,
             ),
             const SizedBox(width: 10),
             Expanded(
               child: Text(
                 message,
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 14,
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ),
           ],
         ),
         backgroundColor: const Color(0xFF9B2335),
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         margin: const EdgeInsets.all(16),
         elevation: 4,
       );
}
