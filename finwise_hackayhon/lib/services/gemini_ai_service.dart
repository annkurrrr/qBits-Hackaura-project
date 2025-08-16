import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiAIService {
  static Future<String> generateChatbotResponse(String userMessage) async {
    // Prompt Gemini to act as a financial + emotional well-being coach
    final prompt =
        '''
You are a friendly and expert personal financial and emotional well-being coach. Answer questions related to fintech, personal finance, investing, saving, budgeting, loans, credit, insurance, money management, and emotional well-being. You can also help with stress, anxiety, motivation, and mental health as it relates to finances.

If the user expresses stress, anxiety, or negative emotions, respond with empathy and offer practical emotional support, stress management tips, and encouragement. If the user asks for financial advice, provide clear, actionable suggestions. If both are relevant, combine financial and emotional advice in your answer.

User: $userMessage

Respond in a helpful, clear, and concise way, blending financial expertise and emotional support as needed.
''';
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? 'Sorry, I could not generate a response.';
  }

  static Future<String> generateChatbotResponseWithProfile(
    String userMessage,
    Map<String, dynamic> profileData,
  ) async {
    // Prompt Gemini to act as a financial + emotional well-being coach with user profile context
    final prompt =
        '''
You are a friendly and expert personal financial and emotional well-being coach. Answer questions related to fintech, personal finance, investing, saving, budgeting, loans, credit, insurance, money management, and emotional well-being. You can also help with stress, anxiety, motivation, and mental health as it relates to finances.

Here is the user's financial profile:
- Current Monthly Income: ₹${profileData['currentIncome'] ?? 'Unknown'}
- Family Monthly Income: ₹${profileData['familyIncome'] ?? 'Unknown'}
- Financial Status: ${profileData['financialStatus'] ?? 'Unknown'}
- Marital Status: ${profileData['maritalStatus'] ?? 'Unknown'}
- Is Parent: ${profileData['isParent'] ?? 'Unknown'}
- Financial Goals: ${profileData['financialGoals'] ?? 'Unknown'}

User: $userMessage

If the user expresses stress, anxiety, or negative emotions, respond with empathy and offer practical emotional support, stress management tips, and encouragement. If the user asks for financial advice, provide clear, actionable suggestions. If both are relevant, combine financial and emotional advice in your answer. Use their financial profile to personalize your advice.

Respond in a helpful, clear, and concise way, blending financial expertise and emotional support as needed.
''';
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? 'Sorry, I could not generate a response.';
  }

  static const String _apiKey =
      'YOUR_GEMINI_API_KEY'; // Replace with actual API key
  static late final GenerativeModel _model;

  static void initialize() {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      // Do not initialize Gemini model if API key is missing
      return;
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  static Future<Map<String, dynamic>> generateFinancialInsights({
    required Map<String, dynamic> profileData,
    required Map<String, String> userAnswers,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      // Return fallback insights if API key is missing
      return {
        'summary':
            'AI features are disabled. Please configure your Gemini API key to get personalized insights.',
        'riskProfile': 'Unknown',
        'priorityAreas': ['N/A'],
        'recommendations': ['AI recommendations unavailable.'],
        'nextSteps': ['Enable AI by adding your Gemini API key.'],
        'investmentAdvice': 'N/A',
        'savingsStrategy': 'N/A',
        'debtManagement': 'N/A',
        'emergencyFund': 'N/A',
      };
    }
    try {
      // Create a comprehensive prompt for Gemini
      final prompt = _buildPrompt(profileData, userAnswers);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      if (response.text != null) {
        return _parseAIResponse(response.text!);
      } else {
        throw Exception('No response from AI service');
      }
    } catch (e) {
      // Check for HTTP 503 error and handle gracefully
      if (e.toString().contains('503')) {
        return {
          'summary':
              'Gemini AI service is temporarily unavailable (503 error). Please try again later.',
          'riskProfile': 'Unavailable',
          'priorityAreas': ['N/A'],
          'recommendations': ['AI service is down.'],
          'nextSteps': ['Try again later.'],
          'investmentAdvice': 'N/A',
          'savingsStrategy': 'N/A',
          'debtManagement': 'N/A',
          'emergencyFund': 'N/A',
        };
      }
      throw Exception('Failed to generate AI insights: ${e.toString()}');
    }
  }

  static String _buildPrompt(
    Map<String, dynamic> profileData,
    Map<String, String> userAnswers,
  ) {
    final lastWeekExpense = userAnswers['lastWeekExpense'];
    if (lastWeekExpense != null) {
      return '''
You are a professional financial advisor. Analyze the following user profile and answers to provide personalized weekly spending advice.

USER PROFILE:
- Current Monthly Income: ₹${profileData['currentIncome'] ?? 0}

USER ANSWERS:
- Last Week's Spending: ₹$lastWeekExpense

Based on the user's income and last week's spending, provide:
1. Advice on how much they can safely spend in the next week.
2. If their spending is too high, suggest how much they should reduce.
3. Practical tips for managing weekly expenses.

Return your answer in the following JSON format:
{
  "summary": "A 2-3 sentence summary of their weekly spending situation",
  "safeSpendingNextWeek": "Recommended safe spending amount for next week",
  "reductionAdvice": "How much to reduce if needed",
  "tips": ["Tip 1", "Tip 2", "Tip 3"]
}

Make the advice specific, actionable, and easy to follow.
''';
    }
    // Default prompt for other cases
    return '''
You are a professional financial advisor. Analyze the following user profile and answers to provide personalized financial insights.

USER PROFILE:
- Current Monthly Income: ₹${profileData['currentIncome'] ?? 0}
- Family Monthly Income: ₹${profileData['familyIncome'] ?? 0}
- Financial Status: ${profileData['financialStatus'] ?? 'Unknown'}
- Marital Status: ${profileData['maritalStatus'] ?? 'Unknown'}
- Is Parent: ${profileData['isParent'] ?? false}
- Financial Goals: ${profileData['financialGoals'] ?? 'Not specified'}

USER ANSWERS:
${userAnswers.entries.map((e) => 'Q: ${e.key}\nA: ${e.value}').join('\n\n')}

Please provide a comprehensive financial analysis in the following JSON format:
{
  "summary": "A 2-3 sentence summary of the user's financial situation",
  "riskProfile": "Conservative/Moderate/Aggressive based on income, status, and goals",
  "priorityAreas": ["Area 1", "Area 2", "Area 3"],
  "recommendations": [
    "Specific, actionable recommendation 1",
    "Specific, actionable recommendation 2",
    "Specific, actionable recommendation 3"
  ],
  "nextSteps": [
    "Immediate next step 1",
    "Immediate next step 2",
    "Immediate next step 3"
  ],
  "investmentAdvice": "Personalized investment strategy based on risk profile",
  "savingsStrategy": "Tailored savings approach for their income level",
  "debtManagement": "Debt management advice if applicable",
  "emergencyFund": "Emergency fund recommendation based on their situation"
}

Make the advice practical, specific to their situation, and actionable. Consider their income level, family status, and goals.
''';
  }

  static Map<String, dynamic> _parseAIResponse(String aiResponse) {
    try {
      // Try to extract JSON from the response
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        // Actually parse the JSON response
        return _safeJsonDecode(jsonString);
      }
    } catch (e) {
      // If parsing fails, return fallback
    }
    throw Exception('Failed to parse AI response. Please try again.');
  }

  static Map<String, dynamic> _safeJsonDecode(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // If parsing fails, return a fallback
      return {
        'summary': 'AI-generated financial insights based on your profile',
      };
    }
  }

  static Future<List<String>> generateFollowUpQuestions({
    required Map<String, dynamic> profileData,
    required Map<String, String> userAnswers,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      // Return fallback questions if API key is missing
      return [
        'AI features are disabled. Please configure your Gemini API key to get follow-up questions.',
      ];
    }
    try {
      final prompt =
          '''
Based on this user's financial profile and answers, generate 3-5 follow-up questions to better understand their situation and provide more targeted advice.

Profile: ${profileData.toString()}
Answers: ${userAnswers.toString()}

Generate questions that are:
1. Relevant to their specific financial situation
2. Helpful for creating a more detailed financial plan
3. Easy to understand and answer

Return only the questions, one per line, without numbering or formatting.
''';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      if (response.text != null) {
        final questions = response.text!
            .split('\n')
            .where((q) => q.trim().isNotEmpty)
            .take(5)
            .toList();
        if (questions.isNotEmpty) {
          return questions;
        }
      }
      throw Exception('Failed to generate follow-up questions');
    } catch (e) {
      throw Exception(
        'Failed to generate follow-up questions: ${e.toString()}',
      );
    }
  }
}
