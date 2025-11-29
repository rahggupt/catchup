# CatchUp Landing Page for Shareable Links

This is a simple landing page that creates **clickable HTTPS links** that redirect to your app.

## 🚀 Setup (5 minutes, FREE)

### Step 1: Create GitHub Repository

1. Go to https://github.com
2. Click **"New Repository"**
3. Name: `catchup-share`
4. Set to **Public**
5. Click **"Create repository"**

### Step 2: Upload Files

1. Upload `index.html` to the repository
2. Commit the file

### Step 3: Enable GitHub Pages

1. Go to repository **Settings**
2. Scroll to **"Pages"** section (left sidebar)
3. Under "Source", select: **main branch**
4. Click **Save**
5. Wait 2-3 minutes
6. Your page will be live at: `https://YOUR_USERNAME.github.io/catchup-share/`

### Step 4: Test It

Visit: `https://YOUR_USERNAME.github.io/catchup-share/?c=79syv8000000`

Should show a nice page with "Open in CatchUp" button!

---

## 🔗 Update Your App

### Update Share Link Format

In `lib/shared/services/supabase_service.dart`, change:

```dart
// From:
return 'catchup://c/$token';

// To:
return 'https://YOUR_USERNAME.github.io/catchup-share/?c=$token';
```

Replace `YOUR_USERNAME` with your actual GitHub username.

---

## ✅ How It Works

### Before (Not Clickable):
```
Check out my collection!
catchup://c/79syv8000000  ← Plain text, not clickable
```

### After (Clickable!):
```
Check out my collection!
https://YOUR_USERNAME.github.io/catchup-share/?c=79syv8000000
↑ Blue, clickable!
```

When clicked:
1. Opens beautiful landing page
2. Shows "Open in CatchUp" button
3. Button triggers: `catchup://c/79syv8000000`
4. App opens! ✅

---

## 🎨 Customize

Edit `index.html` to change:
- Colors
- Text
- Logo
- Instructions

---

## 💰 Cost

**$0** - GitHub Pages is completely FREE!

---

## 🔐 Security

- Links work only if someone has your app installed
- No data is stored or collected
- Pure client-side HTML/JavaScript

---

## 📱 User Experience

### Friend receives message:
```
Check out my collection "Tech News"!
https://yourusername.github.io/catchup-share/?c=79syv8000000
```

### Friend clicks link:
1. Beautiful landing page opens
2. "Open in CatchUp" button
3. Clicks button
4. App opens to collection! ✅

Much better than long-pressing plain text!

---

## ⚡ Quick Alternative

If you don't want to set up GitHub Pages, use this **immediate workaround**:

### Share Instructions Instead of Links:

```
Check out my collection "Tech News"!

To open:
1. Long press the link below
2. Select "Open" or "Open link"

catchup://c/79syv8000000

Don't have CatchUp? Let me know!
```

This makes it clear how to use the non-clickable link.

