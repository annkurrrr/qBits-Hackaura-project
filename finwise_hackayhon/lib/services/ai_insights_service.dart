class AIInsightsService {
  // Suggest study modules based on user answers
  static List<Map<String, String>> suggestStudyModules(
    Map<String, String> userAnswers,
  ) {
    final modules = <Map<String, String>>[];
    final answersText = userAnswers.values.join(' ').toLowerCase();
    if (answersText.contains('debt') || answersText.contains('loan')) {
      modules.add({
        'title': 'Debt Management 101',
        'url': 'https://www.youtube.com/results?search_query=debt+management',
      });
      modules.add({
        'title': 'Smart Loan Repayment Strategies',
        'url': 'https://www.google.com/search?q=loan+repayment+strategies',
      });
    }
    if (answersText.contains('invest') ||
        answersText.contains('stock') ||
        answersText.contains('mutual fund')) {
      modules.add({
        'title': 'Introduction to Investing',
        'url':
            'https://www.youtube.com/results?search_query=investing+for+beginners',
      });
      modules.add({
        'title': 'Mutual Funds & Stock Market Basics',
        'url':
            'https://www.google.com/search?q=mutual+funds+stock+market+basics',
      });
    }
    if (answersText.contains('save') || answersText.contains('budget')) {
      modules.add({
        'title': 'Effective Budgeting Techniques',
        'url':
            'https://www.youtube.com/results?search_query=budgeting+techniques',
      });
      modules.add({
        'title': 'Building a Savings Habit',
        'url': 'https://www.google.com/search?q=how+to+build+savings+habit',
      });
    }
    if (answersText.contains('insurance')) {
      modules.add({
        'title': 'Understanding Insurance',
        'url': 'https://www.youtube.com/results?search_query=insurance+basics',
      });
    }
    if (answersText.contains('stress') ||
        answersText.contains('anxiety') ||
        answersText.contains('mental')) {
      modules.add({
        'title': 'Managing Financial Stress',
        'url':
            'https://www.youtube.com/results?search_query=managing+financial+stress',
      });
      modules.add({
        'title': 'Mindfulness for Money Management',
        'url':
            'https://www.google.com/search?q=mindfulness+for+money+management',
      });
    }
    if (modules.isEmpty) {
      modules.add({
        'title': 'Personal Finance Fundamentals',
        'url':
            'https://www.youtube.com/results?search_query=personal+finance+basics',
      });
    }
    return modules;
  }

  // Generate personalized questions based on user profile
  static List<String> generatePersonalizedQuestions(
    Map<String, dynamic> profileData,
  ) {
    List<String> questions = [];

    // Income-based questions
    double currentIncome = (profileData['currentIncome'] ?? 0).toDouble();
    double familyIncome = (profileData['familyIncome'] ?? 0).toDouble();

    if (currentIncome < 50000) {
      questions.add(
        "How do you manage expenses with your current income level?",
      );
      questions.add("What are your biggest financial challenges right now?");
    } else if (currentIncome > 100000) {
      questions.add("What investment opportunities are you considering?");
      questions.add("How are you planning for wealth preservation?");
    }

    // Family status questions
    String maritalStatus = profileData['maritalStatus'] ?? '';
    bool isParent = profileData['isParent'] ?? false;

    if (isParent) {
      questions.add("Are you saving for your children's education?");
      questions.add("How do you balance family expenses with savings?");
    }

    if (maritalStatus == 'Married') {
      questions.add("How do you and your partner manage shared finances?");
      questions.add("What are your joint financial goals?");
    }

    // Financial status questions
    String financialStatus = profileData['financialStatus'] ?? '';

    if (financialStatus == 'In Debt') {
      questions.add("What's your debt repayment strategy?");
      questions.add("How much debt do you currently have?");
    } else if (financialStatus == 'Saving Well') {
      questions.add("What's your next financial milestone?");
      questions.add("How do you maintain your saving habits?");
    }

    // Goals-based questions
    String goals = profileData['financialGoals'] ?? '';
    if (goals.toLowerCase().contains('house')) {
      questions.add("What's your timeline for buying a house?");
      questions.add("How much down payment are you targeting?");
    }
    if (goals.toLowerCase().contains('retirement')) {
      questions.add("At what age do you plan to retire?");
      questions.add("What's your current retirement savings?");
    }

    // Add general questions if we don't have enough
    if (questions.length < 3) {
      questions.addAll([
        "What's your biggest financial worry?",
        "How do you handle unexpected expenses?",
        "What financial skill would you like to improve?",
      ]);
    }

    return questions.take(5).toList(); // Limit to 5 questions
  }

  // Generate personalized insights based on profile and answers
  static Map<String, dynamic> generateInsights(
    Map<String, dynamic> profileData,
    Map<String, String> userAnswers,
  ) {
    final Map<String, dynamic> insights = {
      'summary': '',
      'recommendations': <String>[],
      'nextSteps': <String>[],
      'riskLevel': '',
      'priorityAreas': <String>[],
    };

    // Analyze income situation
    double currentIncome = (profileData['currentIncome'] ?? 0).toDouble();
    double familyIncome = (profileData['familyIncome'] ?? 0).toDouble();

    if (currentIncome < 50000) {
      insights['priorityAreas'].add('Income Growth');
      insights['recommendations'].add(
        'Focus on building emergency fund (3-6 months expenses)',
      );
      insights['recommendations'].add(
        'Consider upskilling for better job opportunities',
      );
    } else if (currentIncome > 100000) {
      insights['priorityAreas'].add('Wealth Building');
      insights['recommendations'].add('Maximize retirement contributions');
      insights['recommendations'].add('Diversify investment portfolio');
    }

    // Analyze financial status
    String financialStatus = profileData['financialStatus'] ?? '';
    if (financialStatus == 'In Debt') {
      insights['priorityAreas'].add('Debt Management');
      insights['recommendations'].add('Create debt repayment plan');
      insights['recommendations'].add(
        'Consider debt consolidation if beneficial',
      );
    }

    // Analyze family situation
    bool isParent = profileData['isParent'] ?? false;
    if (isParent) {
      insights['priorityAreas'].add('Family Planning');
      insights['recommendations'].add('Start education fund for children');
      insights['recommendations'].add('Review life insurance coverage');
    }

    // Generate summary
    insights['summary'] = _generateSummary(profileData, insights);

    // Generate next steps
    insights['nextSteps'] = _generateNextSteps(insights['recommendations']);

    // Determine risk level
    insights['riskLevel'] = _determineRiskLevel(profileData);

    return insights;
  }

  static String _generateSummary(
    Map<String, dynamic> profileData,
    Map<String, dynamic> insights,
  ) {
    final List priorities = insights['priorityAreas'] ?? [];

    if (priorities.contains('Debt Management')) {
      return "Your profile shows you're working through debt. Focus on creating a solid repayment plan while building emergency savings.";
    } else if (priorities.contains('Income Growth')) {
      return "With your current income level, prioritize building financial security through emergency funds and skill development.";
    } else if (priorities.contains('Wealth Building')) {
      return "You're in a great position to build wealth. Focus on maximizing investments and tax-advantaged accounts.";
    } else {
      return "Based on your profile, you're on a solid financial path. Continue building on your strengths while addressing areas for improvement.";
    }
  }

  static List<String> _generateNextSteps(List<dynamic> recommendations) {
    final List<String> nextSteps = <String>[];
    if (recommendations.isNotEmpty) {
      nextSteps.add("Review and prioritize the recommendations above");
      nextSteps.add("Set specific, measurable financial goals");
      nextSteps.add("Create a monthly budget and track expenses");
      nextSteps.add("Schedule regular financial check-ins");
    }
    return nextSteps;
  }

  static String _determineRiskLevel(Map<String, dynamic> profileData) {
    final String status = profileData['financialStatus'] ?? '';
    final double income = (profileData['currentIncome'] ?? 0).toDouble();

    if (status == 'In Debt' || income < 50000) {
      return 'Conservative';
    } else if (status == 'Stable' && income > 50000) {
      return 'Moderate';
    } else if (status == 'Growing' && income > 100000) {
      return 'Aggressive';
    } else {
      return 'Moderate';
    }
  }
}
