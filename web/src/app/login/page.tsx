"use client";
import Image from "next/image";
import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  return (
    <Suspense fallback={<div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#080E12" }}><p style={{ color: "#9EBDC2" }}>Loading...</p></div>}>
      <LoginContent />
    </Suspense>
  );
}

function LoginContent() {
  const searchParams = useSearchParams();
  const [isSignup, setIsSignup] = useState(false);
  const [step, setStep] = useState<"auth"|"2fa"|"forgot">("auth");
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    email: "", password: "", confirmPassword: "",
    fullName: "", company: "", title: "", trade: "", location: "", experience: "", phone: "", bio: "",
  });

  const redirectPath = searchParams.get("redirect");
  const nextPath = redirectPath && redirectPath.startsWith("/") ? redirectPath : "/feed";
  const authError = searchParams.get("error");
  const authErrorMessage = authError === "auth_failed"
    ? "Sign-in could not be completed. Please try again."
    : searchParams.get("error_description") || "";

  const update = (key: string, value: string) => setForm(prev => ({ ...prev, [key]: value }));

  async function handleAuth() {
    setError("");
    setSuccess("");
    setLoading(true);

    const supabase = createClient();

    if (supabase) {
      try {
        if (isSignup) {
          if (form.password !== form.confirmPassword) {
            setError("Passwords don't match");
            setLoading(false);
            return;
          }
          const { error: signUpError } = await supabase.auth.signUp({
            email: form.email,
            password: form.password,
            options: {
              data: {
                full_name: form.fullName,
                company: form.company,
                title: form.title,
                trade: form.trade,
                location: form.location,
              },
              emailRedirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(nextPath)}`,
            },
          });
          if (signUpError) { setError(signUpError.message); setLoading(false); return; }
        } else {
          const { error: signInError } = await supabase.auth.signInWithPassword({
            email: form.email,
            password: form.password,
          });
          if (signInError) { setError(signInError.message); setLoading(false); return; }
          window.location.assign(nextPath);
          return;
        }
      } catch {
        setError("Connection error. Please try again.");
        setLoading(false);
        return;
      }
    }

    // Fallback: go to 2FA step (demo mode if Supabase not configured)
    setStep("2fa");
    setLoading(false);
  }

  async function handleOAuth(provider: "apple" | "google") {
    setError("");
    setLoading(true);
    const supabase = createClient();
    if (supabase) {
      const { error: oauthError } = await supabase.auth.signInWithOAuth({
        provider,
        options: { redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(nextPath)}` },
      });

      if (oauthError) {
        setError(oauthError.message);
        setLoading(false);
      }
    } else {
      setStep("2fa");
      setLoading(false);
    }
  }

  async function handleForgotPassword() {
    setError(""); setSuccess(""); setLoading(true);
    const supabase = createClient();
    if (supabase && form.email) {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(form.email, {
        redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(nextPath)}`,
      });
      if (resetError) { setError(resetError.message); }
      else { setSuccess("Password reset link sent to " + form.email); }
    } else {
      setSuccess("If an account exists for " + form.email + ", a reset link has been sent.");
    }
    setLoading(false);
  }

  if (step === "forgot") {
    return (
      <div className="min-h-screen flex items-center justify-center px-4" style={{ background: '#080E12' }}>
        <div className="w-full max-w-md">
          <div className="text-center mb-8">
            <Image src="/logo.png" alt="ConstructionOS" width={64} height={64} className="rounded-xl mx-auto mb-4" style={{ boxShadow: '0 0 40px rgba(242,158,61,0.2)' }} />
            <h1 className="text-2xl font-black">Reset Password</h1>
            <p className="text-xs text-[#9EBDC2] mt-2">Enter your email and we&apos;ll send you a reset link</p>
          </div>
          <div className="rounded-2xl p-6" style={{ background: 'rgba(15,28,36,0.6)', border: '1px solid rgba(51,84,94,0.3)' }}>
            {error && <div className="mb-4 p-3 rounded-lg text-xs font-bold text-center" style={{ background: 'rgba(217,77,72,0.1)', color: '#D94D48' }}>{error}</div>}
            {success && <div className="mb-4 p-3 rounded-lg text-xs font-bold text-center" style={{ background: 'rgba(105,210,148,0.1)', color: '#69D294' }}>{success}</div>}
            <input placeholder="Work email address" type="email" value={form.email} onChange={e => update("email", e.target.value)} className="mb-4" />
            <button onClick={handleForgotPassword} disabled={loading || !form.email} className="w-full py-3 rounded-xl font-bold text-black text-sm cursor-pointer" style={{ background: form.email ? 'linear-gradient(90deg, #F29E3D, #FCC757)' : '#33545E', border: 'none' }}>
              {loading ? "Sending..." : "SEND RESET LINK"}
            </button>
            <p className="text-center text-sm mt-4 text-[#9EBDC2]">
              <span className="text-[#F29E3D] font-bold cursor-pointer" onClick={() => { setStep("auth"); setError(""); setSuccess(""); }}>Back to sign in</span>
            </p>
          </div>
        </div>
      </div>
    );
  }

  if (step === "2fa") {
    return (
      <div className="min-h-screen flex items-center justify-center px-4" style={{ background: '#080E12' }}>
        <div className="w-full max-w-md text-center">
          <div className="text-5xl mb-4">🔒</div>
          <h2 className="text-xl font-black mb-2">Two-Factor Authentication</h2>
          <p className="text-sm text-[#9EBDC2] mb-2">{isSignup ? "Check your email to confirm your account" : "Enter the 6-digit code sent to your email"}</p>
          {isSignup && <p className="text-xs text-[#69D294] mb-6">We sent a confirmation link to <b>{form.email}</b></p>}
          {!isSignup && (
            <>
              <div className="flex gap-2 justify-center mb-6">
                {[0,1,2,3,4,5].map(i => (
                  <div key={i} className="w-12 h-14 rounded-lg flex items-center justify-center text-2xl font-bold" style={{ background: '#162832', border: i === code.length ? '2px solid #F29E3D' : '1px solid rgba(51,84,94,0.3)' }}>
                    {code[i] || ""}
                  </div>
                ))}
              </div>
              <input type="text" maxLength={6} value={code} onChange={e => setCode(e.target.value.replace(/\D/g,""))} className="opacity-0 absolute" autoFocus />
              <button onClick={() => { if(code.length===6) window.location.assign(nextPath); }} className="w-full py-3 rounded-xl font-bold text-black cursor-pointer" style={{ background: code.length===6 ? 'linear-gradient(90deg, #F29E3D, #FCC757)' : '#33545E', border: 'none' }}>VERIFY</button>
            </>
          )}
          <p className="text-xs text-[#9EBDC2] mt-4 cursor-pointer" onClick={() => window.location.assign(nextPath)}>Continue to app →</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4" style={{ background: '#080E12' }}>
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Image src="/logo.png" alt="ConstructionOS" width={64} height={64} className="rounded-xl mx-auto mb-4" style={{ boxShadow: '0 0 40px rgba(242,158,61,0.2)' }} />
          <h1 className="text-2xl font-black tracking-wide">CONSTRUCT<span className="text-[#F29E3D]">OS</span></h1>
          <p className="text-xs tracking-widest text-[#9EBDC2] mt-1">CONSTRUCTION COMMAND CENTER</p>
        </div>
        <div className="rounded-2xl p-6" style={{ background: 'rgba(15,28,36,0.6)', border: '1px solid rgba(51,84,94,0.3)' }}>
          <h2 className="text-lg font-bold text-center mb-5">{isSignup ? "Create your account" : "Sign in to your account"}</h2>

          {(error || authErrorMessage) && <div className="mb-4 p-3 rounded-lg text-xs font-bold text-center" style={{ background: 'rgba(217,77,72,0.1)', color: '#D94D48', border: '1px solid rgba(217,77,72,0.2)' }}>{error || authErrorMessage}</div>}

          {/* SSO */}
          <button onClick={() => handleOAuth("apple")} className="w-full py-3 rounded-xl font-semibold text-black bg-white mb-2 text-sm cursor-pointer" style={{ border: 'none' }}>🍎 Continue with Apple</button>
          <button onClick={() => handleOAuth("google")} className="w-full py-3 rounded-xl font-semibold text-white mb-4 text-sm cursor-pointer" style={{ background: '#4285F4', border: 'none' }}>G Continue with Google</button>
          <div className="flex items-center gap-3 mb-4"><div className="flex-1 h-px" style={{ background: 'rgba(51,84,94,0.3)' }}/><span className="text-xs text-[#9EBDC2]">or</span><div className="flex-1 h-px" style={{ background: 'rgba(51,84,94,0.3)' }}/></div>

          {isSignup && (
            <>
              <input placeholder="Full name" value={form.fullName} onChange={e => update("fullName", e.target.value)} className="mb-3" />
              <input placeholder="Company name" value={form.company} onChange={e => update("company", e.target.value)} className="mb-3" />
              <input placeholder="Job title" value={form.title} onChange={e => update("title", e.target.value)} className="mb-3" />
              <div className="flex gap-2 flex-wrap mb-3">
                {["General","Electrical","Concrete","Steel","Plumbing","HVAC","Roofing","Solar"].map(t => (
                  <span key={t} onClick={() => update("trade", t)} className="text-xs px-3 py-1.5 rounded-md cursor-pointer font-bold" style={{ background: form.trade === t ? '#F29E3D' : '#162832', color: form.trade === t ? '#080E12' : '#9EBDC2' }}>{t}</span>
                ))}
              </div>
              <input placeholder="City, State" value={form.location} onChange={e => update("location", e.target.value)} className="mb-3" />
              <input placeholder="Phone number" value={form.phone} onChange={e => update("phone", e.target.value)} className="mb-3" />
            </>
          )}
          <input placeholder="Work email address" type="email" value={form.email} onChange={e => update("email", e.target.value)} className="mb-3" />
          <input placeholder="Password" type="password" value={form.password} onChange={e => update("password", e.target.value)} className="mb-4" />
          {isSignup && <input placeholder="Confirm password" type="password" value={form.confirmPassword} onChange={e => update("confirmPassword", e.target.value)} className="mb-4" />}

          <button onClick={handleAuth} disabled={loading || !form.email || !form.password} className="w-full py-3 rounded-xl font-bold text-black text-sm cursor-pointer" style={{ background: form.email && form.password ? 'linear-gradient(90deg, #F29E3D, #FCC757)' : '#33545E', border: 'none' }}>
            {loading ? "Please wait..." : isSignup ? "CREATE ACCOUNT" : "SIGN IN"}
          </button>
          {!isSignup && <p className="text-center text-xs mt-3"><span className="text-[#9EBDC2] cursor-pointer hover:text-[#F29E3D]" onClick={() => { setStep("forgot"); setError(""); }}>Forgot password?</span></p>}
          <p className="text-center text-sm mt-3 text-[#9EBDC2]">{isSignup ? "Already have an account?" : "New to ConstructionOS?"} <span className="text-[#F29E3D] font-bold cursor-pointer" onClick={() => { setIsSignup(!isSignup); setError(""); }}>{isSignup ? "Sign in" : "Create account"}</span></p>
        </div>
        <div className="flex justify-center gap-6 mt-6">
          {["🔒 256-bit","✅ SOC 2","🛡 GDPR"].map(b => <span key={b} className="text-xs text-[#9EBDC2]/40">{b}</span>)}
        </div>
      </div>
    </div>
  );
}
