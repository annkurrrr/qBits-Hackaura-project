import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finwise_hackayhon/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class FinancialProfileScreen extends StatefulWidget {
  const FinancialProfileScreen({super.key});

  @override
  State<FinancialProfileScreen> createState() => _FinancialProfileScreenState();
}

class _FinancialProfileScreenState extends State<FinancialProfileScreen> {
  final _currentIncomeController = TextEditingController();
  final _familyIncomeController = TextEditingController();
  final _financialGoalController = TextEditingController();

  String _selectedFinancialStatus = 'Stable';
  String _selectedMaritalStatus = 'Single';
  bool _isParent = false;
  bool _loadingProfile = true;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('financial_profile')
          .doc('profile')
          .get();
      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        setState(() {
          _currentIncomeController.text =
              data['currentIncome']?.toString() ?? '';
          _familyIncomeController.text = data['familyIncome']?.toString() ?? '';
          _financialGoalController.text = data['financialGoals'] ?? '';
          _selectedFinancialStatus = data['financialStatus'] ?? 'Stable';
          _selectedMaritalStatus = data['maritalStatus'] ?? 'Single';
          _isParent = data['isParent'] ?? false;
          _loadingProfile = false;
        });
      } else {
        setState(() {
          _loadingProfile = false;
        });
      }
    } else {
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  final List<String> _financialStatusOptions = [
    'Stable',
    'Growing',
    'Challenging',
    'In Debt',
    'Saving Well',
  ];

  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'In a Relationship',
  ];

  @override
  void dispose() {
    _currentIncomeController.dispose();
    _familyIncomeController.dispose();
    _financialGoalController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    // Simple validation - just check if fields are not empty
    if (_currentIncomeController.text.isEmpty ||
        _familyIncomeController.text.isEmpty ||
        _financialGoalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save financial profile to Firestore
        await AuthService.saveFinancialProfile(
          uid: user.uid,
          currentIncome: double.parse(_currentIncomeController.text),
          financialStatus: _selectedFinancialStatus,
          familyIncome: double.parse(_familyIncomeController.text),
          maritalStatus: _selectedMaritalStatus,
          isParent: _isParent,
          financialGoals: _financialGoalController.text,
        );

        // Navigate to Home after save
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Financial Profile',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.analytics,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tell us about your finances',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This helps us provide personalized financial advice',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Current Income
                    TextFormField(
                      controller: _currentIncomeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Current Monthly Income',
                        hintText: 'Enter your monthly income',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: '₹',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Financial Status
                    DropdownButtonFormField<String>(
                      value: _selectedFinancialStatus,
                      decoration: InputDecoration(
                        labelText: 'Financial Status',
                        hintText: 'Select your financial status',
                        prefixIcon: const Icon(Icons.trending_up),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      items: _financialStatusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFinancialStatus = newValue!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Family Income
                    TextFormField(
                      controller: _familyIncomeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Family Monthly Income',
                        hintText: 'Enter total family monthly income',
                        prefixIcon: const Icon(Icons.family_restroom),
                        suffixText: '₹',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Marital Status
                    DropdownButtonFormField<String>(
                      value: _selectedMaritalStatus,
                      decoration: InputDecoration(
                        labelText: 'Marital Status',
                        hintText: 'Select your marital status',
                        prefixIcon: const Icon(Icons.favorite),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      items: _maritalStatusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMaritalStatus = newValue!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Parent Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF9FAFB),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.child_care,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Are you a parent?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Switch(
                            value: _isParent,
                            onChanged: (bool value) {
                              setState(() {
                                _isParent = value;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Financial Goals
                    TextFormField(
                      controller: _financialGoalController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Financial Goals',
                        hintText: 'What are your main financial goals?',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Skip Button
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile setup skipped'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
