import OpusApp from './components/OpusApp';

export const metadata = {
  title: 'Opus — Task Management Redesigned',
  description: 'The task app built around human energy, not task volume.',
};

export default function OpusPage() {
  return (
    <>
      {/* ── Mobile: full-screen app, no chrome ── */}
      <div
        className="md:hidden"
        style={{
          position: 'fixed',
          inset: 0,
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          background: '#0F0E11',
        }}
      >
        <OpusApp />
      </div>

      {/* ── Desktop: phone-frame preview ── */}
      <main
        className="hidden md:flex min-h-screen items-center justify-center"
        style={{
          background:
            'radial-gradient(ellipse at 30% 20%, rgba(91,63,166,0.18) 0%, transparent 50%), radial-gradient(ellipse at 80% 80%, rgba(245,166,35,0.1) 0%, transparent 50%), #08070A',
        }}
      >
        {/* Ambient glow */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              'radial-gradient(ellipse 600px 400px at 50% 50%, rgba(91,63,166,0.08) 0%, transparent 70%)',
          }}
        />

        {/* Desktop label */}
        <div className="absolute top-8 left-1/2 -translate-x-1/2 text-center pointer-events-none">
          <p
            className="text-sm font-semibold tracking-widest uppercase"
            style={{ color: 'rgba(242,240,255,0.2)', letterSpacing: '0.2em' }}
          >
            Opus
          </p>
        </div>

        {/* Phone frame */}
        <div className="relative" style={{ width: 390, height: 844 }}>
          {/* Outer shell */}
          <div
            className="absolute inset-0 rounded-[52px] pointer-events-none z-10"
            style={{
              boxShadow: `
                0 0 0 1px rgba(255,255,255,0.12),
                0 0 0 10px #1A1825,
                0 0 0 11px rgba(255,255,255,0.06),
                0 40px 120px rgba(0,0,0,0.8),
                0 20px 60px rgba(0,0,0,0.5),
                inset 0 0 0 1px rgba(255,255,255,0.04)
              `,
            }}
          />

          {/* Notch */}
          <div
            className="absolute top-0 left-1/2 -translate-x-1/2 z-20 pointer-events-none"
            style={{
              width: 120,
              height: 34,
              background: '#1A1825',
              borderBottomLeftRadius: 20,
              borderBottomRightRadius: 20,
            }}
          />

          {/* Screen */}
          <div
            className="absolute inset-0 rounded-[52px] overflow-hidden flex flex-col"
            style={{ paddingTop: 50, paddingBottom: 0 }}
          >
            <OpusApp />
          </div>

          {/* Side buttons */}
          <div className="absolute pointer-events-none" style={{ left: -3, top: 130, width: 3, height: 36, background: '#2A2838', borderRadius: '2px 0 0 2px' }} />
          <div className="absolute pointer-events-none" style={{ left: -3, top: 180, width: 3, height: 56, background: '#2A2838', borderRadius: '2px 0 0 2px' }} />
          <div className="absolute pointer-events-none" style={{ left: -3, top: 248, width: 3, height: 56, background: '#2A2838', borderRadius: '2px 0 0 2px' }} />
          <div className="absolute pointer-events-none" style={{ right: -3, top: 180, width: 3, height: 76, background: '#2A2838', borderRadius: '0 2px 2px 0' }} />
        </div>

        {/* Feature callouts */}
        <div className="absolute left-1/2 bottom-8 -translate-x-1/2 flex items-center gap-8 pointer-events-none">
          {['Energy-based planning', 'Momentum score', 'Focus mode', '14-day streak'].map((label) => (
            <div key={label} className="flex items-center gap-1.5">
              <div className="w-1 h-1 rounded-full" style={{ background: '#F5A623' }} />
              <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>{label}</span>
            </div>
          ))}
        </div>
      </main>
    </>
  );
}
