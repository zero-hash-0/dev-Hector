'use client';
import { motion } from 'framer-motion';

const TROPHIES = [
  { id: 't1', icon: '🥇', title: 'First 10',    desc: 'Completed your first 10 tasks.',     earned: true },
  { id: 't2', icon: '🔥', title: '7-day streak', desc: 'Showed up every day for a week.',    earned: true },
  { id: 't3', icon: '🏅', title: 'Centurion',   desc: '100 tasks completed.',                earned: true },
  { id: 't4', icon: '🚀', title: 'Ship it',      desc: 'Completed 5 high-energy tasks in a day.', earned: false },
  { id: 't5', icon: '🌊', title: '30-day flow',  desc: 'Active 30 days in a row.',           earned: false },
  { id: 't6', icon: '⚡', title: 'Early bird',   desc: 'Completed morning brief 10 days straight.', earned: false },
];

const INSIGHTS = [
  "You're 3× more productive on Tuesday mornings.",
  "High-energy tasks take you avg. 42 min. You estimate 60.",
  "You complete 80% of tasks you add to Today. That's elite.",
];

// Generate 90-day heatmap data
function generateHeatmap() {
  const days = [];
  for (let i = 89; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const rand = Math.random();
    days.push({
      date: d,
      count: i > 2 ? (rand > 0.25 ? Math.floor(rand * 7) + 1 : 0) : 0,
    });
  }
  return days;
}

const heatmapData = generateHeatmap();

function getHeatColor(count: number) {
  if (count === 0) return 'rgba(255,255,255,0.06)';
  if (count <= 2) return 'rgba(91,63,166,0.5)';
  if (count <= 4) return 'rgba(245,166,35,0.55)';
  return 'rgba(245,166,35,0.9)';
}

export default function ProfileView() {
  const totalDone = 124;
  const streak = 14;
  const avgPerDay = 4.1;

  // Week labels
  const weeks: typeof heatmapData[] = [];
  for (let i = 0; i < heatmapData.length; i += 7) {
    weeks.push(heatmapData.slice(i, i + 7));
  }

  return (
    <div className="flex-1 overflow-y-auto pb-28">
      {/* Hero header */}
      <div
        className="px-6 pt-6 pb-8"
        style={{ background: 'linear-gradient(180deg, rgba(91,63,166,0.15) 0%, transparent 100%)' }}
      >
        <div className="flex items-start justify-between mb-6">
          <div>
            <h1 className="text-2xl font-semibold" style={{ color: '#F2F0FF' }}>Alex Rivera</h1>
            <p className="text-xs mt-1" style={{ color: 'rgba(242,240,255,0.4)' }}>Member since Jan 2026</p>
          </div>
          <motion.button
            className="w-9 h-9 rounded-full flex items-center justify-center text-sm"
            style={{ background: 'rgba(245,166,35,0.1)', color: '#F5A623' }}
            whileTap={{ scale: 0.9 }}
          >
            ↗
          </motion.button>
        </div>

        {/* Stats row */}
        <div className="grid grid-cols-3 gap-3">
          {[
            { label: 'Streak', value: `${streak}d`, color: '#F5A623', icon: '🔥' },
            { label: 'Completed', value: totalDone, color: '#7EC8A0', icon: '✓' },
            { label: 'Avg / day', value: avgPerDay, color: '#5B3FA6', icon: '⚡' },
          ].map((stat, i) => (
            <motion.div
              key={stat.label}
              className="rounded-2xl p-3 text-center"
              style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)' }}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
            >
              <div className="text-lg mb-1">{stat.icon}</div>
              <div className="text-xl font-semibold" style={{ color: stat.color }}>{stat.value}</div>
              <div className="text-xs mt-0.5" style={{ color: 'rgba(242,240,255,0.4)' }}>{stat.label}</div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Heatmap */}
      <div className="px-6 mb-8">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-medium" style={{ color: 'rgba(242,240,255,0.6)' }}>Last 90 days</h2>
          <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>
            {heatmapData.filter(d => d.count > 0).length} active days
          </span>
        </div>
        <motion.div
          className="flex gap-1"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
        >
          {weeks.map((week, wi) => (
            <div key={wi} className="flex flex-col gap-1 flex-1">
              {week.map((day, di) => (
                <motion.div
                  key={di}
                  className="rounded-sm"
                  style={{
                    background: getHeatColor(day.count),
                    aspectRatio: '1',
                    width: '100%',
                  }}
                  initial={{ opacity: 0, scale: 0 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.3 + (wi * 7 + di) * 0.004, type: 'spring', stiffness: 400 }}
                  title={`${day.count} tasks`}
                />
              ))}
            </div>
          ))}
        </motion.div>
        <div className="flex justify-between mt-2">
          <span className="text-xs" style={{ color: 'rgba(242,240,255,0.2)' }}>Jan</span>
          <span className="text-xs" style={{ color: 'rgba(242,240,255,0.2)' }}>Mar</span>
        </div>
      </div>

      {/* Trophies */}
      <div className="px-6 mb-8">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-medium" style={{ color: 'rgba(242,240,255,0.6)' }}>Trophies</h2>
          <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>
            {TROPHIES.filter(t => t.earned).length}/{TROPHIES.length}
          </span>
        </div>
        <div className="grid grid-cols-3 gap-3">
          {TROPHIES.map((t, i) => (
            <motion.div
              key={t.id}
              className="rounded-2xl p-3 text-center"
              style={{
                background: t.earned ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.02)',
                border: `1px solid ${t.earned ? 'rgba(245,166,35,0.2)' : 'rgba(255,255,255,0.05)'}`,
                opacity: t.earned ? 1 : 0.4,
              }}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: t.earned ? 1 : 0.4, scale: 1 }}
              transition={{ delay: 0.4 + i * 0.07, type: 'spring' }}
            >
              <div className="text-2xl mb-1">{t.icon}</div>
              <div className="text-xs font-medium" style={{ color: '#F2F0FF' }}>{t.title}</div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Insights */}
      <div className="px-6 mb-6">
        <h2 className="text-sm font-medium mb-3" style={{ color: 'rgba(242,240,255,0.6)' }}>Insights</h2>
        <div className="flex flex-col gap-3">
          {INSIGHTS.map((insight, i) => (
            <motion.div
              key={i}
              className="rounded-2xl px-4 py-3"
              style={{
                background: 'rgba(91,63,166,0.12)',
                border: '1px solid rgba(91,63,166,0.2)',
              }}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.6 + i * 0.1 }}
            >
              <p className="text-sm leading-relaxed" style={{ color: 'rgba(242,240,255,0.75)' }}>
                &ldquo;{insight}&rdquo;
              </p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Pro plan */}
      <div className="px-6">
        <div
          className="rounded-2xl px-4 py-3 flex items-center justify-between"
          style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.06)' }}
        >
          <div>
            <p className="text-sm" style={{ color: '#F2F0FF' }}>Pro Plan</p>
            <p className="text-xs" style={{ color: 'rgba(242,240,255,0.4)' }}>Renews Apr 15</p>
          </div>
          <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>›</span>
        </div>
      </div>
    </div>
  );
}
