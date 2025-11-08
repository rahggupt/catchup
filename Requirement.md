Here is the updated Product Requirements Document, integrating your new functionality.

-----

## 1\. Product Summary

### Product Name

Project: Mindmap Aggregator

### Vision & Problem

To create a personalized and collaborative knowledge-building tool. Users are inundated with information from various online sources but lack an effective way to curate, organize, synthesize, and collaboratively build upon this knowledge.

This product solves this by merging three concepts:

1.  **A Personalized News Aggregator:** A content feed populated *only* from sources the user trusts.
2.  **A Collaborative "Read-it-Later" App:** A robust "Collections" system for saving articles into private or shared folders.
3.  **A "Mind Map" AI:** A conversational AI that can answer questions and synthesize information based *only* on the knowledge base the user and their friends have curated.

-----

## 2\. Core Epics & Features

### Epic 0: User Authentication (New)

Handles user sign-up, login, and identity.

| Feature ID | Feature Name | Description |
| :--- | :--- | :--- |
| F0.1 | Standard Signup | The app must provide a signup page that captures the user's **Email**, **Phone Number**, **First Name**, and **Last Name**. |
| F0.2 | Social Login | The app must support one-click login/signup using a **Gmail (Google) account** (OAuth). |
| F0.3 | Standard Login | A login page for returning users to sign in with their email and password. |

-----

### Epic 1: Personalized Content Feed

The main screen where users discover content from their designated sources.

| Feature ID | Feature Name | Description |
| :--- | :--- | :--- |
| F1.1 | Custom Source Aggregation | The main feed ("All Sources") shall display articles exclusively from the news sources (e.g., *Wired*, *MIT Tech Review*) that the user has added in their Profile. |
| F1.2 | Article Card Actions (Tap) | Each article card in the feed must have three primary actions: <br> 1. **Tap to Read:** Opens the full article in an in-app browser/webview. <br> 2. **Add to Collection (Button):** Initiates the flow to save the article. <br> 3. **Dismiss (Button):** Removes the article from the feed. |
| F1.3 | Topic-Based Filtering | The feed must have filter tabs at the top (e.g., "All Sources," "AI Topics," "Tech") to allow users to narrow the feed based on pre-defined interests. |
| F1.4 | Social Feed Filter | The feed must include a "Friends' Adds" filter tab. This tab will show a feed of articles that the user's friends have recently added to shared collections. |
| F1.5 | **Swipe-to-Add (New)** | On the main feed, a **right swipe** on an article card shall initiate the 'Add to Collection' flow, prompting the user to select which collection to add it to. |
| F1.6 | **Swipe-to-Dismiss (New)** | On the main feed, a **left swipe** on an article card shall dismiss (reject/ignore) the article, removing it from the user's feed. |

-----

### Epic 2: Collections (The Knowledge Base)

The core "Mind Map" feature where saved articles are organized, stored, and shared.

| Feature ID | Feature Name | Description |
| :--- | :--- | :--- |
| F2.1 | Collection Creation | Users must be able to create new collections. Each collection will act as a folder for saved articles. |
| F2.2 | Collection Privacy Tiers | When creating or editing a collection, the user must be able to set its privacy level: <br> 1. **Private:** Only visible and accessible to the creator. <br> 2. **Invite-Only (Collaborative):** Shared with specific friends. All invited members can view and add articles. <br> 3. **Shareable Link (Public):** Generates a public URL for a read-only view. |
| F2.3 | Add to Collection Flow | When a user "Adds to Collection" (F1.2, F1.5), they must be presented with a list of their existing collections to choose from. |
| F2.4 | Collection Statistics | Collections listed on the "Collections" screen shall display metadata, such as the number of articles, comments, and collaborators. |

-----

### Epic 3: "Ask AI" (Conversational RAG)

The AI chat interface that synthesizes information from the user's curated knowledge base.

| Feature ID | Feature Name | Description |
| :--- | :--- | :--- |
| F3.1 | Conversational Interface | A chat screen where the user can ask questions in natural language. |
| F3.2 | RAG on Collections | The AI's responses must be generated based *only* on the content of the articles stored in the user's collections. |
| F3.3 | Source Citation | AI-generated responses must include citations linking back to the specific articles from the collections that were used to formulate the answer. |
| F3.4 | Default Context (All) | By default, the AI shall query *all* collections the user has access to (both private and shared) to find an answer. |

-----

### Epic 4: Profile & Settings

User-specific configuration and management.

| Feature ID | Feature Name | Description |
| :--- | :--- | :--- |
| F4.1 | User Statistics | The Profile screen shall display user-level stats, including "Articles" saved, "Collections" created, and "Chats" initiated. |
| F4.2 | **Source Management (Updated)** | Users must be able to **manually add** new sources (e.g., via URL/name) and **remove** (or toggle off) existing sources to fully control their feed. |
| F4.3 | Topic Tagging | When adding a source, the user should be able to tag it with relevant topics (e.g., "Science," "Innovation"). This powers the feed filters (F1.3). |
| F4.4 | **AI Provider Config (Updated)** | Provide a "Bring Your Own Key" (BYOK) model: <br> 1. **Default:** Use **Perplexity** as the default, pre-configured AI provider. <br> 2. **Customize:** Allow the user to select other providers (e.g., **Gemini**, **OpenAI**, Anthropic) and enter their own API key. |
| F4.5 | Account Actions | Provide standard account management functions: "Export Data" and "Logout." |

-----

### Epic 5: Social & Notifications

Features related to the collaborative and multi-user aspects of the app.

| Feature ID | Feature Name | Description |
| :--- | :--- | :--- |
| F5.1 | Friend System | A system for users to add/manage friends. This is a prerequisite for "Invite-Only" collections (F2.2) and the "Friends' Adds" feed (F1.4). |
| F5.2 | Friend Update Notifications | In Settings, provide a toggle for "Friend Updates" to "get notified when friends save articles" to collections they share. |
| F5.3 | Anonymous Adds | In Settings, provide a toggle for "Anonymous Adds" to "hide your name when adding to shared collections." |

-----

## 3\. Non-Functional & Technical Requirements (New Section)

| ID | Category | Requirement |
| :--- | :--- | :--- |
| T.1 | **Vector Database** | The system must use the user's existing **Qdrant** instance as the vector store for all embedding storage and retrieval (RAG) operations. |
| T.2 | **Performance** | Feed loading and swipe-to-action gestures must be responsive and feel instantaneous (e.g., \< 200ms UI response). |

-----

## 4\. Key User Flows & Open Questions

  * All user flows from the previous PRD remain valid. The new swipe gestures (F1.5, F1.6) provide alternative paths for the *Saving an Article* flow.
  * **[REQ] AI Collection Filtering:** The "Ask AI" screen **must** include a filter. The user needs the ability to switch the AI's context from "All Collections" to a *single, specific collection*.
  * **[Q] How are friends added (F5.1)?** (e.g., email invite, username search).
  * **[Q] How are new sources added (F4.2)?** Is it by domain URL (e.g., `wired.com`), or by searching an app-level directory of sources?

Would you like to refine any of these epics or add more features?