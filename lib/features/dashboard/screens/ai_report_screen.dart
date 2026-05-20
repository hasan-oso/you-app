import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/core/widgets/glass_card.dart';

class AIReportScreen extends StatelessWidget {
  const AIReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0518), // Deep Royal Purple
              Colors.black
            ], 
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                      onPressed: () => Get.back(),
                    ),
                    Text(
                      "strategic_report_title".tr.toUpperCase(),
                      style: TextStyle(
                        color: Colors.amberAccent[100],
                        fontSize: 16,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          BoxShadow(color: Colors.amber.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 1)
                        ]
                      ),
                    ),
                    const SizedBox(width: 40), // Balance
                  ],
                ),
                
                const SizedBox(height: 30),

                // Report Container with Neon Glow
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3), width: 1),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.amberAccent.withValues(alpha: 0.15),
                           blurRadius: 30,
                           spreadRadius: 2,
                         ),
                      ],
                    ),
                    child: GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Header
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(Icons.insights, color: Colors.amber, size: 32),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Markdown-like Report Text
                            SelectableText(
                              userController.healthReport.value,
                              textAlign: Get.locale?.languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.6,
                                fontFamily: 'Roboto', 
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Footer Motto
                            Center(
                              child: Text(
                                "YOU GUARD INTELLIGENCE",
                                style: TextStyle(
                                  color: Colors.white12,
                                  fontSize: 10,
                                  letterSpacing: 4.0,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
