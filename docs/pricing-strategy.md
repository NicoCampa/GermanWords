# Worty Pricing Strategy

## Gemini Flash Lite API Costs

| | Per 1M Tokens |
|---|---|
| **Input** | $0.075 |
| **Output** | $0.30 |

---

## Per-Feature Token Estimates

### Chat (ChatViewModel)
| Component | Tokens |
|---|---|
| System prompt (with word context) | 150–300 |
| Conversation history (up to 12 msgs) | 600–1,200 |
| User message | 20–50 |
| **Total input per request** | **~800–1,500** |
| **Output (maxOutputTokens=320)** | **~200–320** |
| **Cost per message** | **~$0.00014** |

### Word Detective Game (5 rounds)
| Component | Tokens |
|---|---|
| System prompt per round | ~80 |
| User message per round | ~30 |
| Output per round (clue) | ~50 |
| **Total per game (5 rounds)** | **~550 in / ~250 out** |
| **Cost per game** | **~$0.00012** |

### Word Quest (5 beats, narrative game)
| Component | Tokens |
|---|---|
| System prompt + story context per beat | 500–1,300 |
| Output per beat (narrative + challenge) | 200–320 |
| **Total per game (5 beats)** | **~4,000 in / ~1,300 out** |
| **Cost per game** | **~$0.00069** |

---

## Monthly Cost Per User

| User Type | Behavior | API Cost/Month |
|---|---|---|
| **Casual** | 3 days/week, 2 chats + 1 game/day | ~$0.02 |
| **Regular** | Daily, 5 chats + 1 game/day | ~$0.05 |
| **Power** | Daily, 10+ chats + 2–3 games/day | ~$0.12–0.15 |
| **Whale** | Heavy chat + all games daily | ~$0.25 |

**Average blended cost: ~$0.05/user/month** (assuming typical mix of casual + active users)

---

## Recommended Pricing Tiers

### Free Tier (no payment required)
- All core features: daily word, browse words, word detail, SRS reviews
- **5 AI chat messages per day**
- **2 AI game sessions per day** (Word Detective or Word Quest)
- Speech synthesis (no API cost — on-device)
- Notifications

**Your cost per free user: ~$0.01–0.02/month (effectively negligible)**

### Premium — Monthly: $0.99/month
- Unlimited AI chat messages
- Unlimited AI game sessions
- Priority response time (no 1.5s cooldown)
- Future premium features (e.g., custom word lists, advanced stats)

**Margin at $0.99 (Apple takes 15%):**

| Scenario | Revenue After Apple 15% | API Cost | Gross Profit | Margin |
|---|---|---|---|---|
| Regular user | $0.84 | $0.05 | $0.79 | **94.0%** |
| Power user | $0.84 | $0.15 | $0.69 | **82.1%** |
| Whale user | $0.84 | $0.25 | $0.59 | **70.2%** |

### Premium — Yearly: $6.99/year ($0.58/month)
- Same as monthly but 41% cheaper
- Best value positioning — anchor against monthly

**Margin at $6.99/year (Apple takes 15%):**

| Scenario | Revenue After Apple 15% | Annual API Cost | Gross Profit | Margin |
|---|---|---|---|---|
| Regular user | $5.94 | $0.60 | $5.34 | **89.9%** |
| Power user | $5.94 | $1.80 | $4.14 | **69.7%** |

### Premium — Lifetime: $14.99
- One-time purchase, premium forever
- Break-even vs yearly after ~2 years of use

**Margin analysis (assuming 2-year active use, Apple takes 15%):**

| Scenario | Revenue After Apple 15% | 2-Year API Cost | Gross Profit |
|---|---|---|---|
| Regular user | $12.74 | $1.20 | $11.54 |
| Power user | $12.74 | $3.60 | $9.14 |

---

## Revenue Projections

### At 1,000 MAU
Assuming **8% conversion** ($0.99 price point drives higher conversion than $2.99):

| | Free (920) | Premium (80) | Total |
|---|---|---|---|
| Monthly revenue (after Apple 15%) | $0 | ~$67 (mix of monthly + yearly) | ~$67 |
| Monthly API cost | ~$13.80 | ~$6.00 | ~$20 |
| **Net profit** | | | **~$47** |

### At 10,000 MAU (10% conversion)
| | Free (9,000) | Premium (1,000) | Total |
|---|---|---|---|
| Monthly revenue (after Apple 15%) | $0 | ~$840 | ~$840 |
| Monthly API cost | ~$135 | ~$75 | ~$210 |
| **Net profit** | | | **~$630** |

### At 50,000 MAU (12% conversion)
| | Free (44,000) | Premium (6,000) | Total |
|---|---|---|---|
| Monthly revenue (after Apple 15%) | $0 | ~$5,040 | ~$5,040 |
| Monthly API cost | ~$660 | ~$450 | ~$1,110 |
| **Net profit** | | | **~$3,930** |

> **Note:** The $0.99 price point is expected to drive 2–3x higher conversion than $2.99,
> but total revenue per user is lower. The low API cost of Flash Lite makes this viable —
> even at thin per-user margins, the model stays profitable at every scale.

---

## Rate Limiting Strategy

| Tier | Chat/Day | Games/Day | Cooldown | Session Cap |
|---|---|---|---|---|
| **Free** | 5 messages | 2 games | 1.5s | 60 |
| **Premium** | Unlimited | Unlimited | 0.5s | 200 |

### Implementation Notes
- Track daily counts in `UserProgress` (reset at midnight)
- Show a soft paywall when free limit is reached: "Upgrade to keep chatting with Worty!"
- Games count as 1 session regardless of rounds (5 rounds = 1 game)

---

## Cost Protection / Abuse Prevention

1. **maxOutputTokens cap**: Already set to 320 — keeps output costs predictable
2. **Session cap**: 60 requests/session (free), 200 (premium)
3. **Daily caps for free tier**: Natural cost ceiling of ~$0.001/user/day
4. **Conversation history limit**: Only send last 12 messages to Gemini (already implemented)
5. **Monitor**: Track per-user daily API calls via analytics. Flag users exceeding 50 requests/day for review

---

## Why Gemini Flash Lite Is Ideal

| Factor | Impact |
|---|---|
| $0.075/1M input | ~50x cheaper than GPT-4, ~17x cheaper than Gemini Pro |
| $0.30/1M output | Still extremely cheap for short responses |
| Quality | Sufficient for vocabulary tutoring, clue generation, and short narratives |
| Latency | Fast enough for interactive chat and games |
| Free tier available | 15 RPM free tier for development/testing |

At current pricing, even if every free user hits their daily cap, the API cost is ~$0.001/user/day — meaning **1,000 free users cost you only ~$30/month**. The premium tier covers this many times over.

---

## Summary

| Metric | Value |
|---|---|
| Average API cost per user/month | ~$0.05 |
| Monthly subscription price | $0.99 |
| Apple commission | **15%** |
| Gross margin (after Apple cut) | **70–94%** |
| Break-even free users per 1 premium | ~40 free users |
| Launch pricing | $0.99/mo, $6.99/yr, $14.99 lifetime |
