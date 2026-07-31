// supabase/functions/notify-admin/index.ts
//
// Envoie un email à contact@race-senegal.sn à chaque nouvelle inscription
// (table auth.users) ou nouvelle demande d'abonnement (table
// public.subscription_requests), via le SMTP Nindohost déjà utilisé pour
// les emails de confirmation Supabase.
//
// Déclenchée par un "Database Webhook" configuré dans le tableau de bord
// Supabase (Database > Webhooks), pas par le site directement.

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ADMIN_EMAIL = "contact@race-senegal.sn";

serve(async (req) => {
  try {
    const payload = await req.json();
    const table = payload.table;
    const record = payload.record;

    // Client Supabase interne (clé service_role injectée automatiquement
    // par Supabase dans chaque Edge Function, pas besoin de la configurer).
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    let subject = "";
    let body = "";

    if (table === "users") {
      // Déclenché sur auth.users (nouvelle inscription)
      subject = "🆕 Nouvelle inscription — RACE-SEN-LUDO";
      body =
        `Un nouveau compte vient de s'inscrire sur RACE-SEN-LUDO.\n\n` +
        `Email : ${record.email}\n` +
        `Date : ${record.created_at}\n`;
    } else if (table === "subscription_requests") {
      // Déclenché sur public.subscription_requests (demande d'abonnement)
      const { data: profile } = await supabase
        .from("profiles")
        .select("display_name")
        .eq("id", record.user_id)
        .single();
      subject = "💳 Nouvelle demande d'abonnement — RACE-SEN-LUDO";
      body =
        `Une nouvelle demande d'abonnement vient d'être soumise.\n\n` +
        `Compte : ${profile?.display_name || record.user_id}\n` +
        `Note laissée par le joueur : ${record.note || "(aucune)"}\n` +
        `Date : ${record.created_at}\n\n` +
        `Pense à l'activer depuis l'espace Administration du jeu.`;
    } else {
      return new Response("ignored (table non gérée)", { status: 200 });
    }

    const client = new SMTPClient({
      connection: {
        hostname: Deno.env.get("SMTP_HOST")!,
        port: Number(Deno.env.get("SMTP_PORT") || "465"),
        tls: true,
        auth: {
          username: Deno.env.get("SMTP_USER")!,
          password: Deno.env.get("SMTP_PASS")!,
        },
      },
    });

    await client.send({
      from: Deno.env.get("SMTP_USER")!,
      to: ADMIN_EMAIL,
      subject,
      content: body,
    });
    await client.close();

    return new Response("sent", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("error: " + (e as Error).message, { status: 500 });
  }
});
