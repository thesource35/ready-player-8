# ConstructionOS — In-App Purchase Setup Guide

## App Store Connect > Your App > Subscriptions

### Step 1: Create Subscription Group
- Name: **ConstructionOS Plans**

### Step 2: Add Products

| Reference Name | Product ID | Price | Duration |
|---|---|---|---|
| Field Worker Monthly | `com.constructionos.fieldworker.monthly` | $9.99 | 1 Month |
| Field Worker Annual | `com.constructionos.fieldworker.annual` | $99.99 | 1 Year |
| Project Manager Monthly | `com.constructionos.pm.monthly` | $24.99 | 1 Month |
| Project Manager Annual | `com.constructionos.pm.annual` | $249.99 | 1 Year |
| Company Owner Monthly | `com.constructionos.owner.monthly` | $49.99 | 1 Month |
| Company Owner Annual | `com.constructionos.owner.annual` | $499.99 | 1 Year |

### Step 3: Create Verification Badge Group
- Name: **Verification Badges**

| Reference Name | Product ID | Price | Duration |
|---|---|---|---|
| Licensed Verified | `com.constructionos.verified.licensed` | $27.99 | 1 Month |
| Company Verified | `com.constructionos.verified.company` | $49.99 | 1 Month |

### Step 4: For Each Product
1. Add **Display Name** (e.g., "Field Worker Plan")
2. Add **Description** (e.g., "Full access to all 31 tabs, 56 AI tools, and unlimited projects")
3. Set **Price**
4. Add **Screenshot** of the subscription paywall screen
5. Add **Review Notes**: "Subscription provides access to premium construction management features"

### Step 5: Accept Paid Apps Agreement
- Go to App Store Connect > **Business** > **Agreements, Tax, and Banking**
- Accept **Paid Applications** agreement
- Fill in bank account and tax information

### Step 6: Test in Sandbox
- Create a sandbox tester account in App Store Connect > Users and Access > Sandbox
- On your test device, sign out of App Store, sign in with sandbox account
- Test purchase flows

## Important Notes
- Products must be "Ready to Submit" status before app review
- Each product needs a screenshot
- Apple takes 30% first year, 15% after (Small Business Program)
- You qualify for 15% rate if earning under $1M/year
