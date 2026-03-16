'use client';
import { motion } from 'framer-motion';
import { Task } from './types';

const PROJECTS = [
  { id: '1', name: 'Work',       color: '#F5A623', icon: '💼', tasks: 12, today: 3 },
  { id: '2', name: 'Side proj',  color: '#5B3FA6', icon: '🚀', tasks: 5,  today: 1 },
  { id: '3', name: 'Learn',      color: '#7EC8A0', icon: '📚', tasks: 8,  today: 2 },
  { id: '4', name: 'Home',       color: '#FF6B6B', icon: '🏠', tasks: 4,  today: 0 },
];

const INBOX_TASKS: Partial<Task>[] = [
  { id: 'i1', title: 'Research competitors', energy: 'medium' },
  { id: 'i2', title: 'Buy new keyboard', energy: 'low' },
  { id: 'i3', title: 'Book dentist appointment', energy: 'low' },
  { id: 'i4', title: 'Review product spec', energy: 'high' },
  { id: 'i5', title: 'Update portfolio site', energy: 'medium' },
  { id: 'i6', title: 'Finish reading chapter', energy: 'low' },
];

export default function ProjectsView() {
  return (
    <div className="flex-1 overflow-y-auto px-4 pb-28 pt-2">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold" style={{ color: '#F2F0FF' }}>Projects</h1>
        <motion.button
          className="w-8 h-8 rounded-full flex items-center justify-center text-lg"
          style={{ background: 'rgba(245,166,35,0.15)', color: '#F5A623' }}
          whileTap={{ scale: 0.9 }}
        >
          +
        </motion.button>
      </div>

      {/* Project grid */}
      <div className="grid grid-cols-2 gap-3 mb-8">
        {PROJECTS.map((proj, i) => (
          <motion.div
            key={proj.id}
            className="rounded-2xl p-4 cursor-pointer"
            style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)' }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.08, type: 'spring', stiffness: 300, damping: 30 }}
            whileTap={{ scale: 0.97 }}
            whileHover={{ background: 'rgba(255,255,255,0.07)' }}
          >
            <div className="flex items-center gap-2 mb-3">
              <span className="text-lg">{proj.icon}</span>
              <div className="w-2 h-2 rounded-full" style={{ background: proj.color }} />
            </div>
            <p className="text-sm font-medium mb-1" style={{ color: '#F2F0FF' }}>{proj.name}</p>
            <p className="text-xs" style={{ color: 'rgba(242,240,255,0.4)' }}>
              {proj.tasks} tasks
            </p>
            {proj.today > 0 && (
              <div
                className="mt-2 text-xs px-2 py-0.5 rounded-full inline-block"
                style={{ background: proj.color + '20', color: proj.color }}
              >
                {proj.today} today
              </div>
            )}
          </motion.div>
        ))}

        {/* Locked 5th project (Pro upsell) */}
        <motion.div
          className="rounded-2xl p-4 cursor-pointer col-span-2"
          style={{
            background: 'rgba(255,255,255,0.02)',
            border: '1px dashed rgba(255,255,255,0.1)'
          }}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.35 }}
          whileTap={{ scale: 0.98 }}
        >
          <div className="flex items-center gap-3">
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center text-sm"
              style={{ background: 'rgba(245,166,35,0.1)', color: '#F5A623' }}
            >
              🔒
            </div>
            <div>
              <p className="text-sm font-medium" style={{ color: 'rgba(242,240,255,0.5)' }}>
                Unlock unlimited projects
              </p>
              <p className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>
                Upgrade to Pro · $8/mo
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Inbox section */}
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-base font-medium" style={{ color: 'rgba(242,240,255,0.7)' }}>
          Inbox
        </h2>
        <span className="text-xs px-2 py-0.5 rounded-full" style={{ background: 'rgba(255,255,255,0.07)', color: 'rgba(242,240,255,0.4)' }}>
          {INBOX_TASKS.length}
        </span>
      </div>
      <div className="flex flex-col gap-2">
        {INBOX_TASKS.map((t, i) => {
          const dotColor = t.energy === 'high' ? '#F5A623' : t.energy === 'medium' ? '#5B3FA6' : '#7EC8A0';
          return (
            <motion.div
              key={t.id}
              className="flex items-center gap-3 px-4 py-3 rounded-2xl"
              style={{ background: 'rgba(255,255,255,0.03)' }}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.4 + i * 0.05 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="w-2 h-2 rounded-full flex-shrink-0" style={{ background: dotColor }} />
              <span className="text-sm flex-1" style={{ color: '#F2F0FF' }}>{t.title}</span>
              <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>→</span>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
