"use client";

import type { CSSProperties, MouseEvent, ReactNode } from "react";
import { useState } from "react";

type ExternalLinkProps = {
  href: string;
  children: ReactNode;
  className?: string;
  style?: CSSProperties;
  target?: "_blank" | "_self" | "_parent" | "_top";
  rel?: string;
  preflight?: boolean;
  onClick?: (event: MouseEvent<HTMLAnchorElement>) => void;
};

type CachedStatus = {
  status: string;
  checkedAt: number;
};

const CACHE_TTL_MS = 5 * 60 * 1000;
const clientCache = new Map<string, CachedStatus>();

function isHttpUrl(href: string) {
  return href.startsWith("http://") || href.startsWith("https://");
}

function shouldUseCache(entry?: CachedStatus) {
  if (!entry) return false;
  return Date.now() - entry.checkedAt <= CACHE_TTL_MS;
}

export default function ExternalLink({
  href,
  children,
  className,
  style,
  target = "_blank",
  rel,
  preflight = true,
  onClick,
}: ExternalLinkProps) {
  const [checking, setChecking] = useState(false);
  const resolvedRel = rel ?? (target === "_blank" ? "noopener noreferrer" : undefined);

  const openLink = (preopened?: Window | null) => {
    if (target === "_self") {
      window.location.href = href;
      return;
    }

    if (preopened && !preopened.closed) {
      try {
        preopened.location.href = href;
        return;
      } catch {
        try {
          preopened.close();
        } catch {
          // ignore
        }
      }
    }

    const win = window.open(href, target, "noopener,noreferrer");
    if (!win) {
      window.location.href = href;
    }
  };

  const handleClick = async (event: MouseEvent<HTMLAnchorElement>) => {
    onClick?.(event);
    if (event.defaultPrevented) return;

    if (!preflight || !isHttpUrl(href)) return;
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) return;
    if (checking) {
      event.preventDefault();
      return;
    }

    event.preventDefault();

    const preopened = target === "_blank" ? window.open("", "_blank", "noopener,noreferrer") : null;
    if (preopened) {
      try {
        preopened.opener = null;
      } catch {
        // ignore
      }
    }

    const cached = clientCache.get(href);
    if (shouldUseCache(cached)) {
      if (cached?.status === "ok" || cached?.status === "redirect" || cached?.status === "blocked") {
        openLink(preopened);
      } else {
        const proceed = window.confirm("This link looks unavailable right now. Open anyway?");
        if (proceed) {
          openLink(preopened);
        } else if (preopened && !preopened.closed) {
          preopened.close();
        }
      }
      return;
    }

    setChecking(true);
    try {
      const response = await fetch(`/api/link-health?url=${encodeURIComponent(href)}`, {
        cache: "no-store",
      });
      const data = await response.json();
      const status = typeof data?.status === "string" ? data.status : "error";
      clientCache.set(href, { status, checkedAt: Date.now() });

      if (status === "ok" || status === "redirect" || status === "blocked") {
        openLink(preopened);
        return;
      }

      const proceed = window.confirm("This link looks unavailable right now. Open anyway?");
      if (proceed) {
        openLink(preopened);
      } else if (preopened && !preopened.closed) {
        preopened.close();
      }
    } catch {
      const proceed = window.confirm("We could not verify this link right now. Open anyway?");
      if (proceed) {
        openLink(preopened);
      } else if (preopened && !preopened.closed) {
        preopened.close();
      }
    } finally {
      setChecking(false);
    }
  };

  return (
    <a href={href} className={className} style={style} target={target} rel={resolvedRel} onClick={handleClick}>
      {children}
    </a>
  );
}
