# Mauban Chess Club Website

A responsive club website using GitHub Pages for hosting and Supabase for authentication and shared club data.

## 1. Set up the Supabase database

1. Open your [Supabase project](https://supabase.com/dashboard/project/rrgpriawnmbhuzfxfnju).
2. Open **SQL Editor** and choose a new query.
3. Open `supabase/schema.sql` in this repository and copy the complete script.
4. Paste it into the SQL Editor and click **Run**.
5. Keep Row Level Security enabled. Never place a Supabase secret or service-role key in website files.

## 2. Create the first administrator

1. Open the published website and register an account using the email address you want to use as the club's first administrator.
2. Confirm the email if Supabase requires it.
3. In Supabase **SQL Editor**, run the following after replacing the sample email:

```sql
update public.profiles
set role = 'super_admin', status = 'approved'
where email = 'YOUR-ADMIN-EMAIL-HERE';
```

4. Sign out and sign in again. The account menu should show the administrator dashboard.
5. To add another administrator, have that person register their own account. After their account is approved, a super administrator can change that profile's role to `admin` in the Supabase Table Editor. Each administrator should use an individual account.

## 3. Publish using GitHub Pages

1. Open this repository on GitHub.
2. Go to **Settings → Pages**.
3. Under **Build and deployment**, select **Deploy from a branch**.
4. Select branch **main** and folder **/(root)**, then save.
5. Wait for the deployment to finish. GitHub will display the website address in the Pages section.

## Included in this first version

- Responsive public club homepage
- Member registration and sign-in
- New member accounts start as pending
- Admin approval of new registrations
- Multiple individual administrator accounts supported by database roles
- Tournament creation and public tournament list
- Player records and Elementary, Secondary and OPEN categories
- Public local-rating list with search
- Pairing/result display when records are added to the database

## Current limitations

- Pairings and results can currently be stored in the database, but a dedicated admin screen for generating/editing pairings and entering results is not included yet.
- Standings and chess tie-break calculations are not implemented yet.
- Local rating values are entered by an administrator. Automatic rating-change calculations and FIDE rating calculations are not implemented.
- The public member count may show a dash until a public-safe count view is added; private member profile details are not exposed publicly.

The Supabase publishable key in `app.js` is intended for public client use. The database must have the provided Row Level Security policies installed before the site is used.