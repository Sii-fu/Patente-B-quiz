# Video Library Database Setup Guide

## Database Schema
The video library uses two tables in Supabase:
1. `video_categories` - Categories for organizing videos
2. `videos` - Individual video records

## Sample Data Script

Run this SQL in your Supabase SQL Editor to populate with sample data:

```sql
-- Insert Video Categories
INSERT INTO public.video_categories (name_it, name_en, name_bn, display_order) VALUES
('Segnali Stradali', 'Road Signs', 'রাস্তার চিহ্ন', 1),
('Norme di Circolazione', 'Traffic Rules', 'ট্রাফিক নিয়ম', 2),
('Precedenza', 'Right of Way', 'অগ্রাধিকার', 3),
('Sosta e Fermata', 'Parking & Stopping', 'পার্কিং এবং থামানো', 4),
('Sorpasso', 'Overtaking', 'ওভারটেকিং', 5),
('Parti del Veicolo', 'Vehicle Parts', 'গাড়ির অংশ', 6),
('Sicurezza Stradale', 'Road Safety', 'রাস্তার নিরাপত্তা', 7),
('Comportamento in Emergenza', 'Emergency Behavior', 'জরুরী আচরণ', 8);

-- Insert Sample Videos (Replace with real YouTube URLs)
-- Category 1: Road Signs
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(1, 'Segnali di Pericolo', 'Danger Signs', 'বিপদ চিহ্ন', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 15, 1),
(1, 'Segnali di Divieto', 'Prohibition Signs', 'নিষেধ চিহ্ন', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 12, 2),
(1, 'Segnali di Obbligo', 'Mandatory Signs', 'বাধ্যতামূলক চিহ্ন', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 10, 3);

-- Category 2: Traffic Rules
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(2, 'Limiti di Velocità', 'Speed Limits', 'গতি সীমা', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 8, 1),
(2, 'Distanze di Sicurezza', 'Safety Distances', 'নিরাপত্তা দূরত্ব', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 7, 2),
(2, 'Uso delle Luci', 'Light Usage', 'আলো ব্যবহার', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 9, 3);

-- Category 3: Right of Way
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(3, 'Incroci con Semaforo', 'Intersections with Traffic Lights', 'ট্রাফিক লাইট সহ মোড়', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 11, 1),
(3, 'Incroci senza Semaforo', 'Intersections without Lights', 'লাইট ছাড়া মোড়', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 13, 2),
(3, 'Rotatorie', 'Roundabouts', 'গোলচত্বর', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 6, 3);

-- Category 4: Parking & Stopping
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(4, 'Regole di Sosta', 'Parking Rules', 'পার্কিং নিয়ম', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 10, 1),
(4, 'Divieti di Sosta', 'No Parking Zones', 'পার্কিং নিষিদ্ধ এলাকা', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 8, 2);

-- Category 5: Overtaking
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(5, 'Quando Sorpassare', 'When to Overtake', 'কখন ওভারটেক করবেন', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 12, 1),
(5, 'Divieto di Sorpasso', 'No Overtaking', 'ওভারটেক নিষিদ্ধ', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 9, 2);

-- Category 6: Vehicle Parts
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(6, 'Freni e Sistema Frenante', 'Brakes and Braking System', 'ব্রেক এবং ব্রেকিং সিস্টেম', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 14, 1),
(6, 'Pneumatici', 'Tires', 'টায়ার', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 11, 2),
(6, 'Luci del Veicolo', 'Vehicle Lights', 'গাড়ির লাইট', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 7, 3);

-- Category 7: Road Safety
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(7, 'Cinture di Sicurezza', 'Seat Belts', 'সিট বেল্ট', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 6, 1),
(7, 'Airbag e Dispositivi di Sicurezza', 'Airbags and Safety Devices', 'এয়ারব্যাগ এবং নিরাপত্তা ডিভাইস', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 8, 2),
(7, 'Guida Sicura', 'Safe Driving', 'নিরাপদ ড্রাইভিং', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 15, 3);

-- Category 8: Emergency Behavior
INSERT INTO public.videos (category_id, title_it, title_en, title_bn, youtube_url, duration_minutes, display_order) VALUES
(8, 'Incidenti Stradali', 'Road Accidents', 'সড়ক দুর্ঘটনা', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 10, 1),
(8, 'Primo Soccorso', 'First Aid', 'প্রাথমিক চিকিৎসা', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 12, 2);
```

## Important Notes

### 1. YouTube URLs
Replace `dQw4w9WgXcQ` with real video IDs from your YouTube channel or playlist. The app supports:
- Full URLs: `https://www.youtube.com/watch?v=VIDEO_ID`
- Short URLs: `https://youtu.be/VIDEO_ID`
- Video IDs only: `VIDEO_ID`

### 2. Thumbnails
The app automatically fetches thumbnails from YouTube using:
```
https://img.youtube.com/vi/{VIDEO_ID}/hqdefault.jpg
```

If you want custom thumbnails, add the `thumbnail_url` column value.

### 3. Duration
The `duration_minutes` field is optional but recommended for better UX. It shows as "X min" on video cards.

### 4. Display Order
Videos are sorted by `display_order` within each category. Lower numbers appear first.

## Verifying Data

Run this query to check your data:

```sql
SELECT 
  vc.name_it as category,
  COUNT(v.id) as video_count
FROM video_categories vc
LEFT JOIN videos v ON v.category_id = vc.id
GROUP BY vc.id, vc.name_it, vc.display_order
ORDER BY vc.display_order;
```

Expected output should show each category with its video count.

## Testing the Feature

1. **Navigate to Video Library** from Dashboard
2. **Check Categories** - Should display all 8 categories
3. **View Videos** - Horizontal scrolling list under each category
4. **Tap Video** - Opens YouTube player
5. **Test Offline** - Should show "No Internet Connection" error

## Troubleshooting

### No videos showing
- Check RLS policies are enabled
- Verify user is authenticated
- Check Supabase logs for errors

### Videos won't play
- Verify YouTube URLs are valid
- Check video is not private/blocked
- Ensure `youtube_player_flutter` package is installed

### Categories not showing
- Check `video_categories` table has data
- Verify `display_order` is set correctly
- Check foreign key `category_id` in videos matches

## Production Data

For production, you should:
1. Create real YouTube videos or use existing educational content
2. Ensure all videos have proper translations (it, en, bn)
3. Set accurate duration times
4. Test all videos are accessible and not region-blocked
5. Consider creating a CMS for managing video content

## Example Real YouTube URLs

Italian Driving License videos (search on YouTube):
- "patente b segnali stradali"
- "patente b precedenza"
- "patente b quiz"
- "scuola guida online"

Make sure you have permission to use any third-party content!
