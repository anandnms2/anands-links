import { useEffect, useRef } from "react";
import { signIn } from "next-auth/react";
import CenteredForm from "@/components/CenteredForm";
import getServerSideProps from "@/lib/client/getServerSideProps";

// Direct SSO entry point: https://<domain>/sso goes straight to Authentik.
// Optional: /sso?next=/links to land on a specific page afterwards.
export default function Sso() {
  const started = useRef(false);

  useEffect(() => {
    if (started.current) return;
    started.current = true;

    const next = new URLSearchParams(window.location.search).get("next");
    const callbackUrl = next && next.startsWith("/") ? next : "/dashboard";

    signIn("authentik", { callbackUrl }).catch(() => {
      window.location.href = "/login";
    });
  }, []);

  return (
    <CenteredForm text="Redirecting to Anands SSO…">
      <noscript>
        <a href="/login" className="text-primary text-center block">
          Continue to sign in
        </a>
      </noscript>
    </CenteredForm>
  );
}

export { getServerSideProps };
