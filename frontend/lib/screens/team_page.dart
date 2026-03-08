import 'package:flutter/material.dart';
import '../components/header.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  final List<Map<String, String>> teamMembers = const [
    {
      'name': 'Aryan',
      'role': 'UI Designer & Team Leader',
      'description':
          'Aryan is the creative mastermind behind SplitPay\'s stunning user interface. As the team leader, he brings a vision of simplicity, elegance, and design consistency. With an eye for detail and a passion for user experience, Aryan ensures every pixel is perfectly placed. He believes that great design is invisible — it just works. His leadership keeps the team motivated and aligned towards creating something truly beautiful and functional.',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      'color': '0xFF4A90E2',
    },
    {
      'name': 'Deeksha',
      'role': 'Full Stack Developer',
      'description':
          'Deeksha is the bridge between frontend elegance and backend power. As a full-stack developer, she ensures that every feature works seamlessly from the user interface down to the database. With expertise in both worlds, Deeksha connects data and design with surgical precision. She\'s the problem solver who turns complex challenges into simple, elegant solutions. Her code is clean, efficient, and built to scale — making SplitPay fast, reliable, and secure.',
      'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop&crop=face',
      'color': '0xFFE91E63',
    },
    {
      'name': 'Harsh',
      'role': 'Frontend Developer',
      'description':
          'Harsh is the wizard who brings designs to life. As a frontend developer, he crafts clean, responsive, and lightning-fast user interfaces that make SplitPay feel intuitive and effortless. Every button, animation, and transition is thoughtfully implemented to enhance the user experience. Harsh obsesses over performance and accessibility, ensuring SplitPay runs smoothly on every device. His code isn\'t just functional — it\'s art in motion.',
      'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
      'color': '0xFF9C27B0',
    },
    {
      'name': 'Kanhaiya',
      'role': 'Backend Developer',
      'description':
          'Kanhaiya is the silent guardian of SplitPay\'s infrastructure. As a backend developer, he manages the server-side logic, databases, and APIs that power the entire application. Security, performance, and reliability are his top priorities. Kanhaiya architects systems that can handle thousands of users while keeping data safe and transactions secure. He\'s the one making sure everything runs smoothly behind the scenes — because the best backend is the one you never have to think about.',
      'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
      'color': '0xFF00BCD4',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final cardColor = theme.cardColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header Component
          const Header(
            title: "Our Team",
            heightFactor: 0.12,
          ),

          // Intro Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: FadeTransition(
              opacity: _animationController,
              child: Text(
                "Meet the brilliant minds behind SplitPay — a crew of passionate developers and designers committed to making bill splitting effortless.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          // Team Members List
          Expanded(
            child: ListView.builder(
              itemCount: teamMembers.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                final isEven = (index + 1) % 2 == 0;
                final Color memberColor = Color(int.parse(member['color']!));

                // Animation for each card
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / teamMembers.length) * 0.5,
                      ((index + 1) / teamMembers.length) * 0.5 + 0.5,
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                final slideAnimation = Tween<Offset>(
                  begin: isEven ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / teamMembers.length) * 0.5,
                      ((index + 1) / teamMembers.length) * 0.5 + 0.5,
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                final imageSection = Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Hero(
                      tag: 'member_${member['name']}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: memberColor.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: memberColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            member['image']!,
                            fit: BoxFit.cover,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      memberColor.withOpacity(0.3),
                                      memberColor.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: memberColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                final textSection = Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: memberColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                member['name']!,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: memberColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member['role']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: memberColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member['description']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.4)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: isEven
                            ? [textSection, imageSection]
                            : [imageSection, textSection],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

