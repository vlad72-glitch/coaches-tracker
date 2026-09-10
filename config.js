// Coaches Tracker — connection settings.
//
// url      = the project origin ONLY, no path on the end.
// anonKey  = the "Publishable key" from Project Settings → API Keys.
//            It starts sb_publishable_ and is safe to publish in a web page:
//            the protection comes from sign-ups being off and from the
//            ct_owners table, which only your own user id is in.
//
// NEVER put the Secret key (sb_secret_...) here.
//
// This is the same project that hosts the Win and Swim Trainings app. Its
// tables are named tr_*, the tracker's are ct_*, so nothing can collide.
window.CTRACK_CONFIG = {
  url: "https://wueuvwutbeqtyuhmhglh.supabase.co",
  anonKey: "sb_publishable_R_tOKzAJAPStxkO4v3q8ZQ_44Or6DeS"
};
