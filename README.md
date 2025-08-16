Finwise Hackathon Project Summary

Overview:
Finwise is a comprehensive personal finance and well-being management app built with Flutter and Firebase.
It integrates financial tracking, debt management, emotional well-being, gamification, and AI-powered insights
to help users achieve holistic financial health.

Key Features:

1. Personalized Financial Dashboard
- Displays user profile, financial health metrics, points, and badge tier.
- Central hub for accessing all major features.

2. Debt Mapping & Repayment Tracking
- Users can add, view, and manage debts.
- Tracks monthly repayments and cleared amounts.
- Allows marking debts as paid and removing debts.
- Progress bars visualize repayment status.
- Points awarded for repayments; badge tier updated accordingly.
- Debt notifications for unpaid installments.

3. Notifications System
- Alerts users about unpaid debts and mood logging reminders.
- Integrates with debt and mood tracking modules.

4. Mood Tracking & Well-being
- Users log daily moods and optional notes.
- Tracks mood streaks (consecutive days of logging).
- Points and badge tier awarded for mood logs.
- Well-being dashboard visualizes mood trends and stress levels using charts.

5. Virtual Wallet Simulation
- Users manage a simulated wallet: view balance, add transactions.
- Tracks transaction history and balance.
- Notifies users of low balance or large transactions.
- Points and badge tier awarded for saving actions.

6. Gamification: Points, Badges, Streaks
- Points awarded for positive financial and well-being actions.
- Badge tiers: Bronze, Silver, Gold, Platinum, Diamond (based on points).
- Streaks tracked for mood logging and other activities.
- Badge and points info stored in Firestore and displayed in UI.

7. AI-Powered Financial Insights
- Personalized questions generated based on user profile.
- AI provides tailored advice on investment, savings, debt management, and emergency fund strategies.
- Insights displayed in dedicated screen.

8. Financial Profile Management
- Users input and update financial details (income, expenses, risk level, etc.).
- Data used for personalized insights and dashboard metrics.

9. Well-being Dashboard
- Visualizes mood and financial trends together.
- Uses charts to show stress levels and mood history.

Technical Stack:
- Flutter (Dart) for cross-platform mobile UI.
- Firebase Firestore for data storage (users, debts, moods, wallet, gamification).
- Firebase Auth for user authentication.
- fl_chart for data visualization.
- Modular screens: home, debt mapping, mood tracking, wallet, notifications, AI insights, well-being dashboard.

User Flows:
- Onboarding: User signs up/logs in, sets up financial profile.
- Dashboard: User views summary, points, badge, and notifications.
- Debt Management: Add/manage debts, mark repayments, earn points.
- Mood Tracking: Log daily mood, earn points, build streaks.
- Wallet: Manage balance, add transactions, receive notifications.
- AI Insights: Answer questions, receive personalized advice.
- Well-being: View mood trends and stress analytics.

Gamification Logic:
- Points for actions (repayment, mood log, saving).
- Badge tier updates based on total points.
- Streaks tracked for consecutive actions.
- All gamification data stored in Firestore.

Summary:
Finwise is designed to empower users to manage their finances and emotional well-being in a unified, engaging, and insightful way. It leverages gamification and AI to motivate positive habits, track progress, and provide actionable advice, all within a clean and modern UI.
