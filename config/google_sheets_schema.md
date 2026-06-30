# Google Sheets Database Schema

Create a Google Sheet with these 5 tabs exactly as named below.

---

## Tab 1: `Trends`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Unique ID e.g. `TRD_001` |
| trend_topic | TEXT | e.g. "Cottagecore Aesthetic" |
| category | TEXT | fashion / beauty / lifestyle / quotes / diy / wellness |
| source | TEXT | openai / serpapi / manual |
| score | NUMBER | Relevance score 1-10 |
| date_found | DATE | Auto-filled |
| used | TEXT | `no` / `yes` |

---

## Tab 2: `Content_Queue`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Unique ID e.g. `PIN_001` |
| trend_id | TEXT | Reference to Trends.id |
| title_idea | TEXT | Raw idea from Idea Generator |
| category | TEXT | content category |
| content_type | TEXT | quote / outfit / tip / diy / recipe / aesthetic |
| image_prompt | TEXT | DALL-E prompt from Prompt Generator |
| image_url | TEXT | Hosted image URL from Thumbnail Designer |
| pin_title | TEXT | Final SEO title (max 100 chars) |
| pin_description | TEXT | Final description (max 500 chars) |
| hashtags | TEXT | Space-separated hashtags |
| board_id | TEXT | Pinterest Board ID |
| board_name | TEXT | Human-readable board name |
| status | TEXT | new_idea / has_prompt / has_image / ready_to_post / posted / posted_buffer / failed |
| scheduled_time | DATETIME | When to post |
| posted_at | DATETIME | When actually posted |
| pin_id | TEXT | Pinterest Pin ID after posting |
| platform | TEXT | pinterest / buffer |
| error_notes | TEXT | Error message if failed |
| date_created | DATETIME | Auto-filled |


---

## Tab 3: `Analytics`
| Column | Type | Description |
|--------|------|-------------|
| date | DATE | Analytics date |
| pin_id | TEXT | Pinterest Pin ID |
| pin_title | TEXT | Pin title for reference |
| impressions | NUMBER | Total impressions |
| saves | NUMBER | Total saves/repins |
| clicks | NUMBER | Pin clicks |
| outbound_clicks | NUMBER | Clicks to linked URL |
| save_rate | NUMBER | saves/impressions * 100 |
| click_rate | NUMBER | clicks/impressions * 100 |

---

## Tab 4: `Config`
| Column | Type | Description |
|--------|------|-------------|
| key | TEXT | Config key |
| value | TEXT | Config value |

### Default Config Rows:
| key | value |
|-----|-------|
| POSTS_PER_RUN | 2 |
| MIN_QUEUE_SIZE | 5 |
| IDEAS_PER_TREND | 5 |
| POSTING_BOARDS | board_id_1,board_id_2 |
| GIRLS_NICHE_CATEGORIES | fashion,beauty,lifestyle,quotes,wellness,diy |

---

## Tab 5: `Logs`
| Column | Type | Description |
|--------|------|-------------|
| timestamp | DATETIME | Log time |
| workflow | TEXT | Which workflow logged |
| level | TEXT | INFO / WARN / ERROR |
| message | TEXT | Log message |
| details | TEXT | Extra JSON details |
