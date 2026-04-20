# 🐓 Naatu Kozhi – Ecommerce Setup Guide

## Tech Stack
- **Frontend**: HTML, CSS, JavaScript (vanilla)
- **Backend**: Supabase (Auth + PostgreSQL Database)
- **Payments**: Razorpay

---

## Step 1: Supabase Setup

1. Go to https://supabase.com and create a free account
2. Click **"New Project"** and give it a name (e.g., `naatu-kozhi`)
3. Once the project is created, go to **SQL Editor**
4. Paste the entire contents of `supabase-setup.sql` and click **Run**
5. Go to **Project Settings → API** and copy:
   - `Project URL` → your `SUPABASE_URL`
   - `anon` key → your `SUPABASE_ANON_KEY`

---

## Step 2: Razorpay Setup

1. Go to https://razorpay.com and create an account
2. Complete KYC verification (required for live payments)
3. Go to **Settings → API Keys**
4. For testing: click **"Generate Test Key"**
5. Copy the **Key ID** → your `RAZORPAY_KEY_ID`
6. Keep the **Key Secret** safe (used on backend, not exposed in frontend)

> ⚠️ For production, you should create a backend endpoint (Node.js / Supabase Edge Function)
> to create Razorpay orders and verify payment signatures. See notes below.

---

## Step 3: Configure index.html

Open `index.html` and replace the 3 config values at the top of the `<script>` section:

```javascript
const SUPABASE_URL    = 'https://xxxx.supabase.co';        // Your Supabase URL
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1Ni...';        // Your Supabase anon key
const RAZORPAY_KEY_ID   = 'rzp_test_XXXXXXXXXXXXXXXX';    // Your Razorpay Key ID
```

---

## Step 4: Deploy

### Option A: Netlify (free, easiest)
1. Go to https://netlify.com
2. Drag and drop the `naatu-chicken-store/` folder
3. Your site goes live instantly!

### Option B: GitHub Pages
1. Push to a GitHub repo
2. Settings → Pages → Deploy from main branch

### Option C: Vercel
1. `npm i -g vercel` then `vercel` in the folder

---

## Features Included

| Feature | Status |
|---|---|
| Product catalog with 12 items | ✅ |
| Category filtering | ✅ |
| Sort by price / popularity | ✅ |
| Wishlist (localStorage) | ✅ |
| Add to cart / quantity control | ✅ |
| Cart sidebar | ✅ |
| Free delivery threshold (₹499) | ✅ |
| User registration & login | ✅ (Supabase Auth) |
| Order history | ✅ (Supabase DB) |
| Razorpay payment integration | ✅ |
| Responsive design | ✅ |
| Toast notifications | ✅ |
| Persistent cart (localStorage) | ✅ |

---

## Supabase Edge Function (Optional – Production Payments)

For secure production payments, create a Supabase Edge Function to:
1. Create a Razorpay order server-side
2. Verify `razorpay_signature` using HMAC-SHA256

```javascript
// supabase/functions/create-order/index.ts
import Razorpay from "npm:razorpay";

const rzp = new Razorpay({
  key_id: Deno.env.get("RAZORPAY_KEY_ID"),
  key_secret: Deno.env.get("RAZORPAY_KEY_SECRET"),
});

Deno.serve(async (req) => {
  const { amount } = await req.json();
  const order = await rzp.orders.create({
    amount: amount * 100,
    currency: "INR",
  });
  return new Response(JSON.stringify(order), {
    headers: { "Content-Type": "application/json" },
  });
});
```

---

## Support & Contact

Built for fresh country chicken ecommerce. Questions? Reach out or open a GitHub issue.
