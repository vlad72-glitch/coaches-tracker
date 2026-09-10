# Coaches Tracker — turning on sync

The tracker now keeps its data in Supabase instead of only in one browser, so
your phone and your laptop show the same thing.

It shares the project that already runs the Win and Swim Trainings app
(`wueuvwutbeqtyuhmhglh`). The tracker's tables are all named `ct_something` and
the Trainings ones are `tr_something`, so nothing can collide.

**Why the extra care about access:** that project has login accounts for your
coaches, because the Trainings app needs them. Pay rates and payouts must not be
visible to them. So the rules are not "anyone signed in can read this", they are
"only user ids listed in `ct_owners` can read this", and only you go in there.

---

## 1. Create the tables

1. Open the project: https://supabase.com/dashboard/project/wueuvwutbeqtyuhmhglh
2. **SQL Editor** in the sidebar.
3. Open `supabase-schema.sql` from this folder, copy all of it, paste, **Run**.
4. You should see `Success. No rows returned`.

Safe to run again any time. It never overwrites your data.

## 2. Put yourself on the owners list

You almost certainly already have a login in this project from the Trainings
app. Run this in the SQL Editor with your own email:

```sql
insert into public.ct_owners (user_id)
select id from auth.users where email = 'you@example.com'
on conflict (user_id) do nothing;

-- check it
select u.email, o.added_at
from public.ct_owners o join auth.users u on u.id = o.user_id;
```

If you have no login yet: **Authentication** → **Users** → **Add user** →
**Create new user**, tick **Auto Confirm User**, then run the SQL above.

Only add yourself. Anyone on this list can see every rate and payout.

## 3. Check the lock actually holds

Worth doing once, because getting this wrong is the whole risk. In the SQL
Editor:

```sql
select tablename,
       (select relrowsecurity from pg_class c
          join pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public' and c.relname = tablename) as rls_on
from pg_tables where schemaname = 'public' and tablename like 'ct_%';
```

Both `ct_owners` and `ct_state` must show `rls_on = true`.

## 4. Upload the app

Upload these to https://github.com/vlad72-glitch/coaches-tracker (Add file →
Upload files):

- `index.html`
- `config.js`  ← new
- `sw.js`
- `supabase-schema.sql`
- `SETUP.md`

Give it about a minute, then open https://vlad72-glitch.github.io/coaches-tracker/

## 5. First sign-in on your phone

Your phone still has months of data saved locally. The first time you sign in,
if the online copy is empty, the app asks whether to upload what is on the
device. **Say yes on the phone first**, before signing in anywhere else. That
way your real history becomes the starting point instead of being replaced by an
empty document.

After that, sign in on the laptop and it will pull the same data down.

---

## Things worth knowing

**The project pauses.** Supabase pauses free projects after about a week of no
use. That is exactly what had happened when this was set up: the Trainings app
was down too. If you only open the tracker at month end, expect to hit the
dashboard and press **Restore** first. If that gets annoying, moving the tracker
to a project you touch more often is the fix.

**Offline.** If the network or the project is down, the app falls back to the
last copy saved in that browser and the pill in the toolbar reads `offline`.
Edits made then are kept locally and are NOT pushed later, so avoid editing
while it says `offline`.

**Two devices at once.** Writes carry the timestamp of the version they were
based on. If the other device saved first, your write is refused, the newer
version is loaded, and you are told to redo the last edit. Nothing is silently
overwritten, but the losing edit does have to be redone.

**The publishable key in `config.js` is meant to be public.** The protection is
sign-ups being off plus the `ct_owners` gate. Never put the secret key
(`sb_secret_...`) in any file in this folder.
