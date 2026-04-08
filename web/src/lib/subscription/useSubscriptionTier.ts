"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

export function useSubscriptionTier() {
  const [tier, setTier] = useState("free");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isActive = true;

    async function loadTier() {
      const supabase = createClient();

      if (!supabase) {
        if (isActive) setLoading(false);
        return;
      }

      const { data: userResult } = await supabase.auth.getUser();
      const user = userResult.user;

      if (!user) {
        if (isActive) setLoading(false);
        return;
      }

      const { data } = await supabase
        .from("cs_user_profiles")
        .select("subscription_tier")
        .eq("user_id", user.id)
        .maybeSingle();

      if (isActive) {
        setTier(data?.subscription_tier || "free");
        setLoading(false);
      }
    }

    loadTier();

    return () => {
      isActive = false;
    };
  }, []);

  return {
    tier,
    loading,
    hasPaidAccess: tier !== "free",
  };
}
