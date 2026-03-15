'use client';
import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';

const FEATURES = [
  {
    icon: '⚡',
    title: 'Energy-based planning',
    desc: 'Tell Opus how you feel. It builds your day around your actual capacity — not an arbitrary priority list.',
    color: '#F5A623',
  },
  {
    icon: '◉',
    title: 'Momentum score',
    desc: 'A single living number that rises with consistency, not just output. Miss a day and it decays gently — never zeroes.',
    color: '#5B3FA6',
  },
  {
    icon: '◎',
    title: 'Deep focus mode',
    desc: 'One task. Full screen. Timer running. Everything else disappears until you\'re done.',
    color: '#7EC8A0',
  },
];

const VALID_CODES = (process.env.NEXT_PUBLIC_BETA_INVITE_CODES || 'OPUS-BETA-001,OPUS-BETA-002,OPUS-BETA-003,OPUS-BETA-004,OPUS-BETA-005').split(',').map(c => c.trim().toUpperCase());

export default function OpusLandingPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [emailState, setEmailState] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [showCodeEntry, setShowCodeEntry] = useState(false);
  const [inviteCode, setInviteCode] = useState('');
  const [codeState, setCodeState] = useState<'idle' | 'error'>('idle');

  const handleWaitlist = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || emailState === 'loading') return;
    setEmailState('loading');
    try {
      const res = await fetch('/api/waitlist', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      if (res.ok) { setEmailState('success'); }
      else { setEmailState('error'); }
    } catch {
      setEmailState('error');
    }
  };

  const handleInviteCode = (e: React.FormEvent) => {
    e.preventDefault();
    const code = inviteCode.trim().toUpperCase();
    if (VALID_CODES.includes(code)) {
      document.cookie = `opus_invite=${code}; path=/; max-age=${60 * 60 * 24 * 365}`;
      router.push('/opus/app');
    } else {
      setCodeState('error');
      setTimeout(() => setCodeState('idle'), 2000);
    }
  };

  return (
    <main
      className="min-h-screen flex flex-col overflow-x-hidden"
      style={{
        background: '#0A090D',
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
      }}
    >
      {/* Background gradients */}
      <div className="fixed inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        <div style={{ position: 'absolute', top: '-10%', left: '20%', width: 600, height: 600, borderRadius: '50%', background: 'radial-gradient(circle, rgba(91,63,166,0.14) 0%, transparent 70%)', filter: 'blur(40px)' }} />
        <div style={{ position: 'absolute', top: '40%', right: '10%', width: 400, height: 400, borderRadius: '50%', background: 'radial-gradient(circle, rgba(245,166,35,0.08) 0%, transparent 70%)', filter: 'blur(40px)' }} />
        <div style={{ position: 'absolute', bottom: '10%', left: '30%', width: 500, height: 300, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,107,107,0.06) 0%, transparent 70%)', filter: 'blur(60px)' }} />
      </div>

      {/* Nav */}
      <nav className="relative z-10 flex items-center justify-between px-8 py-6 max-w-5xl mx-auto w-full">
        <span className="text-lg font-semibold tracking-tight" style={{ color: '#F2F0FF' }}>
          Opus
        </span>
        <motion.button
          className="text-sm px-4 py-2 rounded-full"
          style={{ background: 'rgba(255,255,255,0.06)', color: 'rgba(242,240,255,0.6)', border: '1px solid rgba(255,255,255,0.08)' }}
          whileTap={{ scale: 0.96 }}
          onClick={() => setShowCodeEntry(true)}
        >
          I have an invite →
        </motion.button>
      </nav>

      {/* Hero */}
      <section className="relative z-10 flex flex-col items-center text-center px-6 pt-16 pb-24 max-w-3xl mx-auto w-full">
        {/* Badge */}
        <motion.div
          className="flex items-center gap-2 px-3 py-1.5 rounded-full mb-8 text-xs font-medium"
          style={{ background: 'rgba(245,166,35,0.1)', border: '1px solid rgba(245,166,35,0.2)', color: '#F5A623' }}
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <span className="w-1.5 h-1.5 rounded-full bg-current animate-pulse" />
          Closed beta — invites going out now
        </motion.div>

        {/* Headline */}
        <motion.h1
          className="text-5xl font-semibold leading-tight mb-6"
          style={{ color: '#F2F0FF', letterSpacing: '-0.03em' }}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
        >
          The task app that works
          <br />
          <span style={{ background: 'linear-gradient(135deg, #F5A623, #FF6B6B)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            with your energy.
          </span>
        </motion.h1>

        <motion.p
          className="text-lg leading-relaxed mb-10 max-w-xl"
          style={{ color: 'rgba(242,240,255,0.5)' }}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          Most task apps treat you like a machine. Opus treats you like a human.
          Plan your day around how you actually feel — not how you wish you felt.
        </motion.p>

        {/* Waitlist form */}
        <motion.div
          className="w-full max-w-md"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <AnimatePresence mode="wait">
            {emailState === 'success' ? (
              <motion.div
                key="success"
                className="flex flex-col items-center gap-2 py-4"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
              >
                <div className="text-3xl mb-1">✓</div>
                <p className="font-medium" style={{ color: '#7EC8A0' }}>You&apos;re on the list.</p>
                <p className="text-sm" style={{ color: 'rgba(242,240,255,0.4)' }}>
                  We&apos;ll send your invite code when it&apos;s ready.
                </p>
              </motion.div>
            ) : (
              <motion.form key="form" onSubmit={handleWaitlist} className="flex gap-2">
                <input
                  type="email"
                  required
                  placeholder="your@email.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  className="flex-1 px-4 py-3.5 rounded-2xl text-sm outline-none"
                  style={{
                    background: 'rgba(255,255,255,0.06)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    color: '#F2F0FF',
                  }}
                />
                <motion.button
                  type="submit"
                  className="px-5 py-3.5 rounded-2xl text-sm font-semibold flex-shrink-0"
                  style={{
                    background: emailState === 'loading'
                      ? 'rgba(255,255,255,0.1)'
                      : 'linear-gradient(135deg, #F5A623, #FF6B6B)',
                    color: emailState === 'loading' ? 'rgba(242,240,255,0.4)' : '#0F0E11',
                  }}
                  whileTap={{ scale: 0.97 }}
                  disabled={emailState === 'loading'}
                >
                  {emailState === 'loading' ? '...' : 'Join waitlist'}
                </motion.button>
              </motion.form>
            )}
          </AnimatePresence>
          {emailState === 'error' && (
            <p className="text-xs mt-2 text-center" style={{ color: '#FF6B6B' }}>
              Something went wrong. Try again.
            </p>
          )}
          <p className="text-xs mt-3 text-center" style={{ color: 'rgba(242,240,255,0.25)' }}>
            No spam. Invite code sent when your spot is ready.
          </p>
        </motion.div>
      </section>

      {/* Feature cards */}
      <section className="relative z-10 max-w-4xl mx-auto w-full px-6 pb-24">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {FEATURES.map((f, i) => (
            <motion.div
              key={f.title}
              className="rounded-3xl p-6"
              style={{
                background: 'rgba(255,255,255,0.03)',
                border: '1px solid rgba(255,255,255,0.07)',
              }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 + i * 0.1, type: 'spring', stiffness: 200 }}
            >
              <div
                className="w-10 h-10 rounded-2xl flex items-center justify-center text-xl mb-4"
                style={{ background: f.color + '18', color: f.color }}
              >
                {f.icon}
              </div>
              <h3 className="font-semibold mb-2 text-sm" style={{ color: '#F2F0FF' }}>{f.title}</h3>
              <p className="text-xs leading-relaxed" style={{ color: 'rgba(242,240,255,0.45)' }}>{f.desc}</p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Social proof / stat row */}
      <section className="relative z-10 max-w-2xl mx-auto w-full px-6 pb-32 text-center">
        <div className="flex items-center justify-center gap-12 flex-wrap">
          {[
            { value: '< 60s', label: 'onboarding' },
            { value: '7', label: 'task daily cap' },
            { value: '90d', label: 'streak heatmap' },
          ].map(stat => (
            <div key={stat.label} className="flex flex-col items-center">
              <span className="text-2xl font-semibold mb-1" style={{ color: '#F2F0FF' }}>{stat.value}</span>
              <span className="text-xs" style={{ color: 'rgba(242,240,255,0.35)' }}>{stat.label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 border-t pb-10 pt-8 text-center px-6" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
        <p className="text-xs" style={{ color: 'rgba(242,240,255,0.2)' }}>
          © 2026 Opus. Work that means something.
        </p>
      </footer>

      {/* Invite code drawer */}
      <AnimatePresence>
        {showCodeEntry && (
          <>
            <motion.div
              className="fixed inset-0 z-40"
              style={{ background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)' }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => { setShowCodeEntry(false); setCodeState('idle'); setInviteCode(''); }}
            />
            <motion.div
              className="fixed inset-x-0 bottom-0 z-50 rounded-t-3xl p-8 max-w-lg mx-auto"
              style={{
                background: 'linear-gradient(180deg, #1E1B2C 0%, #16141F 100%)',
                boxShadow: '0 -30px 80px rgba(0,0,0,0.6)',
                border: '1px solid rgba(255,255,255,0.08)',
                borderBottom: 'none',
              }}
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', stiffness: 420, damping: 42 }}
            >
              <div className="flex justify-center mb-4">
                <div className="w-8 h-1 rounded-full" style={{ background: 'rgba(255,255,255,0.15)' }} />
              </div>
              <h2 className="text-xl font-semibold mb-1" style={{ color: '#F2F0FF' }}>Enter your invite code</h2>
              <p className="text-sm mb-6" style={{ color: 'rgba(242,240,255,0.4)' }}>
                Codes are in the format <span style={{ color: 'rgba(242,240,255,0.6)', fontFamily: 'monospace' }}>OPUS-BETA-XXX</span>
              </p>
              <form onSubmit={handleInviteCode} className="flex flex-col gap-3">
                <input
                  autoFocus
                  type="text"
                  placeholder="OPUS-BETA-001"
                  value={inviteCode}
                  onChange={e => { setInviteCode(e.target.value.toUpperCase()); setCodeState('idle'); }}
                  className="w-full px-4 py-4 rounded-2xl text-base outline-none text-center font-mono tracking-widest uppercase"
                  style={{
                    background: 'rgba(255,255,255,0.06)',
                    border: `1px solid ${codeState === 'error' ? '#FF6B6B' : 'rgba(255,255,255,0.1)'}`,
                    color: '#F2F0FF',
                    letterSpacing: '0.15em',
                  }}
                  maxLength={14}
                />
                <AnimatePresence>
                  {codeState === 'error' && (
                    <motion.p
                      className="text-xs text-center"
                      style={{ color: '#FF6B6B' }}
                      initial={{ opacity: 0, y: -4 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0 }}
                    >
                      Invalid code. Check your invite email and try again.
                    </motion.p>
                  )}
                </AnimatePresence>
                <motion.button
                  type="submit"
                  className="w-full py-4 rounded-2xl text-sm font-semibold"
                  style={{
                    background: inviteCode.length >= 3
                      ? 'linear-gradient(135deg, #F5A623, #FF6B6B)'
                      : 'rgba(255,255,255,0.06)',
                    color: inviteCode.length >= 3 ? '#0F0E11' : 'rgba(242,240,255,0.25)',
                  }}
                  whileTap={{ scale: 0.97 }}
                >
                  Access Opus →
                </motion.button>
              </form>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </main>
  );
}
