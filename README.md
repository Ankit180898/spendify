## Spendify — Smart Expense Tracker
![spendify_bg](https://github.com/user-attachments/assets/07e5c3c3-f463-4c25-8f2f-34820a92d602)

## Introduction

Spendify is a full-featured personal finance app built with Flutter. It helps you track income and expenses, set budgets, manage savings goals, split bills with friends, and gain intelligent insights into your spending — all backed by Supabase and powered by a clean GetX architecture.

---

## Features

### Expense & Income Tracking
- Log expenses and income with category, amount, date, and description
- Edit or delete any transaction
- Filter and sort by date, category, or type
- Paginated transaction history

### Voice Input
- Hands-free expense logging using speech-to-text
- Auto-detects amount, category, and transaction type from natural language

### SMS Import
- Scans SMS messages from the last 30 days
- Auto-extracts amounts, merchants, and categories from bank/UPI messages
- Duplicate detection to prevent re-imports
- Manual review before bulk import

### Budget Limits
- Set spending limits per category (weekly or monthly)
- Compact table view showing limit vs. current spending
- Visual alerts when approaching or exceeding a limit
- Gradient summary card showing total budget and remaining amount

### Savings Goals
- Create goals with a name, target amount, emoji, and optional target date
- Track progress with visual progress bars
- Add contributions at any time via "Add money" button
- Deadline countdown tracking

### Group Splits
- Create groups for shared expenses
- Invite members via unique invite codes
- Add split expenses with category and date
- Automatic equal-split calculation
- Track who paid and who owes
- Mark settlements and track simplified debts
- Real-time balance updates

### Statistics & Analytics
- Monthly income vs. expense trends
- Tab-based view (expenses / income)
- Spending breakdown by category
- Top spending categories
- Navigate across months with a date picker
- Powered by Syncfusion charts

### Insights
- Spending spike alerts
- Budget utilization analysis
- Savings progress tracking
- Income vs. expense comparison
- Category-specific recommendations

### Notifications
- Budget limit alerts (approaching & exceeded)
- Savings goal deadline reminders
- Weekly digest and monthly recap
- Spend spike alerts
- Group split notifications
- Milestone celebrations

### Home Dashboard
- Personalized greeting (morning / afternoon / evening)
- Total balance with visibility toggle
- Monthly income/expense summary card
- Insights strip with actionable tips
- Budget alerts banner
- Savings goal progress banner
- Recent transactions list
- Speed dial FAB for quick entry (expense, income, or split bill)

### Profile & Settings
- Edit name and occupation
- Currency and budget preferences
- Category customization
- Dark / light mode toggle
- Logout

### Authentication
- Email / password sign-up and login
- Google OAuth
- Apple Sign-In
- Guided onboarding with currency selection, budget setup, and category preferences

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| State Management | GetX |
| Backend & Database | Supabase |
| Authentication | Supabase Auth (Email, Google, Apple) |
| Charts | Syncfusion Flutter Charts |
| Voice Input | speech_to_text |
| SMS Parsing | flutter_sms_inbox |
| Notifications | flutter_local_notifications |
| Home Widget | home_widget |
| Connectivity | connectivity_plus |

---

## Project Structure

```
lib/
├── controller/        # GetX controllers (state management)
├── model/             # Data models
├── services/          # Business logic (insights, voice, SMS, notifications)
├── view/
│   ├── auth/          # Login, register, forgot password
│   ├── home/          # Home dashboard
│   ├── wallet/        # Transactions, statistics, SMS import
│   ├── goals/         # Budget limits & savings goals
│   ├── splits/        # Group expense splitting
│   ├── profile/       # Profile & settings
│   ├── onboarding/    # Onboarding flow
│   └── landing/       # Splash & get started
├── widgets/           # Reusable UI components
├── routes/            # Named routes
├── config/            # Theme & colors
└── utils/             # Utility functions
```

---

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Ankit180898/spendify.git
   ```
2. Navigate to the project directory:
   ```bash
   cd spendify
   ```
3. Create a `.env` file with your Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

---

## Contributions

Contributions are welcome! Fork the repository and open a pull request with your changes. For bugs or feature requests, please open an issue on GitHub.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
