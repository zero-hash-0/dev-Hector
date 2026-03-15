'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';
import MomentumRing from './MomentumRing';
import TaskRow from './TaskRow';
import { Task } from './types';

interface TodayViewProps {
  tasks: Task[];
  momentum: number;
  streak: number;
  onComplete: (id: string) => void;
  onFocus: (task: Task) => void;
  onMorningBrief: () => void;
}

export default function TodayView({ tasks, momentum, streak, onComplete, onFocus, onMorningBrief }: TodayViewProps) {
  const [showLater, setShowLater] = useState(false);

  const todayTasks = tasks.filter(t => t.status === 'today');
  const laterTasks = tasks.filter(t => t.status === 'later');
  const doneTasks = tasks.filter(t => t.status === 'done');
  const allDone = todayTasks.length === 0 && doneTasks.length > 0;

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

  return (
    <div className="flex-1 overflow-y-auto pb-28">
      {/* Header */}
      <div className="px-5 pt-6 pb-4">
        <div className="flex items-start justify-between mb-6">
          <div>
            <motion.p
              className="text-sm mb-0.5"
              style={{ color: 'rgba(242,240,255,0.4)' }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
            >
              {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
            </motion.p>
            <motion.h1
              className="text-2xl font-semibold"
              style={{ color: '#F2F0FF' }}
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15, type: 'spring', stiffness: 300 }}
            >
              {greeting}.
            </motion.h1>
          </div>
          <motion.button
            className="w-8 h-8 rounded-full flex items-center justify-center"
            style={{ background: 'rgba(255,255,255,0.06)', color: 'rgba(242,240,255,0.5)' }}
            whileTap={{ scale: 0.9 }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.2 }}
          >
            ⚙
          </motion.button>
        </div>

        {/* Stats bar */}
        <motion.div
          className="rounded-3xl p-4 flex items-center gap-4"
          style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)' }}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25, type: 'spring', stiffness: 280 }}
        >
          {/* Momentum ring */}
          <div className="flex flex-col items-center">
            <MomentumRing score={momentum} size={80} />
            <p className="text-xs mt-1" style={{ color: 'rgba(242,240,255,0.35)' }}>Momentum</p>
          </div>

          <div className="w-px h-12 self-center" style={{ background: 'rgba(255,255,255,0.08)' }} />

          {/* Streak */}
          <div className="flex flex-col items-center flex-1">
            <div className="flex items-center gap-1.5 mb-1">
              <span className="text-2xl font-semibold" style={{ color: '#F5A623' }}>🔥</span>
              <span className="text-2xl font-semibold" style={{ color: '#F5A623' }}>{streak}</span>
            </div>
            <p className="text-xs" style={{ color: 'rgba(242,240,255,0.35)' }}>day streak</p>
            <div className="flex gap-1 mt-2">
              {Array.from({ length: 7 }).map((_, i) => (
                <div
                  key={i}
                  className="w-2 h-2 rounded-full"
                  style={{ background: i < (streak % 7 || 7) ? '#F5A623' : 'rgba(255,255,255,0.1)' }}
                />
              ))}
            </div>
          </div>

          <div className="w-px h-12 self-center" style={{ background: 'rgba(255,255,255,0.08)' }} />

          {/* Today progress */}
          <div className="flex flex-col items-center flex-1">
            <div className="flex items-baseline gap-1">
              <span className="text-2xl font-semibold" style={{ color: '#7EC8A0' }}>{doneTasks.length}</span>
              <span className="text-sm" style={{ color: 'rgba(242,240,255,0.4)' }}>of {todayTasks.length + doneTasks.length}</span>
            </div>
            <p className="text-xs mt-0.5" style={{ color: 'rgba(242,240,255,0.35)' }}>today</p>
            {/* Mini progress bar */}
            <div className="w-full mt-2 rounded-full overflow-hidden" style={{ height: 3, background: 'rgba(255,255,255,0.1)' }}>
              <motion.div
                className="h-full rounded-full"
                style={{ background: '#7EC8A0' }}
                initial={{ width: 0 }}
                animate={{ width: `${((doneTasks.length / Math.max(todayTasks.length + doneTasks.length, 1)) * 100)}%` }}
                transition={{ duration: 1, delay: 0.6, ease: 'easeOut' }}
              />
            </div>
          </div>
        </motion.div>
      </div>

      {/* Morning brief CTA (show if not done) */}
      {todayTasks.length === 0 && doneTasks.length === 0 && (
        <motion.div
          className="mx-5 mb-4"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <motion.button
            className="w-full py-4 rounded-2xl text-sm font-semibold flex items-center justify-center gap-2"
            style={{ background: 'linear-gradient(135deg, #F5A623 0%, #FF6B6B 100%)', color: '#0F0E11' }}
            whileTap={{ scale: 0.98 }}
            onClick={onMorningBrief}
          >
            ☀️ Start your morning brief
          </motion.button>
        </motion.div>
      )}

      {/* All done state */}
      <AnimatePresence>
        {allDone && (
          <motion.div
            className="mx-5 mb-6 rounded-3xl p-6 text-center"
            style={{
              background: 'linear-gradient(135deg, rgba(126,200,160,0.12) 0%, rgba(91,63,166,0.12) 100%)',
              border: '1px solid rgba(126,200,160,0.2)',
            }}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="text-3xl mb-2">✓</div>
            <p className="font-semibold text-base mb-1" style={{ color: '#F2F0FF' }}>All done for today.</p>
            <p className="text-xs" style={{ color: 'rgba(242,240,255,0.45)' }}>
              You showed up. That&apos;s what matters.
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Today tasks */}
      {todayTasks.length > 0 && (
        <div className="px-4 mb-2">
          <div className="flex items-center justify-between px-1 mb-3">
            <span className="text-xs uppercase tracking-widest font-medium" style={{ color: 'rgba(242,240,255,0.3)' }}>
              Today
            </span>
            <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>
              {todayTasks.length} remaining
            </span>
          </div>
          <div className="flex flex-col gap-1.5">
            <AnimatePresence mode="popLayout">
              {todayTasks.map((task, i) => (
                <TaskRow
                  key={task.id}
                  task={task}
                  index={i}
                  onComplete={onComplete}
                  onFocus={onFocus}
                />
              ))}
            </AnimatePresence>
          </div>
        </div>
      )}

      {/* Done tasks (collapsed) */}
      {doneTasks.length > 0 && (
        <motion.div
          className="px-4 mt-4 mb-2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
        >
          <div className="flex items-center gap-2 px-1 mb-2">
            <span className="text-xs uppercase tracking-widest font-medium" style={{ color: 'rgba(242,240,255,0.2)' }}>
              Done
            </span>
            <span className="text-xs px-2 py-0.5 rounded-full" style={{ background: 'rgba(126,200,160,0.15)', color: '#7EC8A0' }}>
              {doneTasks.length}
            </span>
          </div>
          {doneTasks.map((task, i) => (
            <motion.div
              key={task.id}
              className="flex items-center gap-3 px-4 py-2.5 rounded-xl mb-1"
              style={{ opacity: 0.4 }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.4 }}
              transition={{ delay: 0.5 + i * 0.05 }}
            >
              <div className="w-5 h-5 rounded-full flex items-center justify-center" style={{ background: '#7EC8A0' }}>
                <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                  <path d="M2 5L4 7L8 3" stroke="#0F0E11" strokeWidth="1.5" strokeLinecap="round" />
                </svg>
              </div>
              <span className="text-sm line-through" style={{ color: 'rgba(242,240,255,0.5)' }}>{task.title}</span>
            </motion.div>
          ))}
        </motion.div>
      )}

      {/* Later section */}
      {laterTasks.length > 0 && (
        <div className="px-4 mt-4">
          <button
            className="flex items-center justify-between w-full px-1 mb-2"
            onClick={() => setShowLater(s => !s)}
          >
            <span className="text-xs uppercase tracking-widest font-medium" style={{ color: 'rgba(242,240,255,0.3)' }}>
              Later
            </span>
            <span className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>
              {laterTasks.length} {showLater ? '↑' : '↓'}
            </span>
          </button>
          <AnimatePresence>
            {showLater && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="overflow-hidden"
              >
                {laterTasks.map((task, i) => (
                  <TaskRow key={task.id} task={task} index={i} onComplete={onComplete} onFocus={onFocus} />
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      )}
    </div>
  );
}
