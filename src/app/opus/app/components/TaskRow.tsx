'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';
import { Task } from './types';

interface TaskRowProps {
  task: Task;
  index: number;
  onComplete: (id: string) => void;
  onFocus: (task: Task) => void;
}

const energyColors: Record<string, string> = {
  high: '#F5A623',
  medium: '#5B3FA6',
  low: '#7EC8A0',
};

export default function TaskRow({ task, index, onComplete, onFocus }: TaskRowProps) {
  const [completing, setCompleting] = useState(false);
  const [particles, setParticles] = useState<{ id: number; x: number; y: number }[]>([]);

  const handleComplete = () => {
    if (completing) return;
    setCompleting(true);
    const burst = Array.from({ length: 6 }, (_, i) => ({
      id: i,
      x: (Math.random() - 0.5) * 60,
      y: (Math.random() - 0.5) * 60,
    }));
    setParticles(burst);
    setTimeout(() => {
      onComplete(task.id);
    }, 500);
  };

  return (
    <motion.div
      layout
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: completing ? 0 : 1, x: completing ? 30 : 0 }}
      exit={{ opacity: 0, x: 40, transition: { duration: 0.3 } }}
      transition={{ delay: index * 0.06, duration: 0.35, ease: [0.34, 1.56, 0.64, 1] }}
      className="relative flex items-center gap-3 px-4 py-3 rounded-2xl cursor-pointer group"
      style={{ background: 'rgba(255,255,255,0.03)' }}
      onClick={() => onFocus(task)}
    >
      {/* Completion particles */}
      <AnimatePresence>
        {particles.map(p => (
          <motion.div
            key={p.id}
            className="absolute rounded-full pointer-events-none"
            style={{ width: 6, height: 6, background: '#F5A623', left: '50%', top: '50%' }}
            initial={{ opacity: 1, x: 0, y: 0, scale: 1 }}
            animate={{ opacity: 0, x: p.x, y: p.y, scale: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
          />
        ))}
      </AnimatePresence>

      {/* Check button */}
      <motion.button
        className="flex-shrink-0 w-6 h-6 rounded-full border-2 flex items-center justify-center"
        style={{
          borderColor: completing ? '#7EC8A0' : 'rgba(255,255,255,0.2)',
          background: completing ? '#7EC8A0' : 'transparent',
        }}
        whileTap={{ scale: 0.85 }}
        onClick={(e) => { e.stopPropagation(); handleComplete(); }}
        transition={{ duration: 0.15 }}
      >
        <AnimatePresence>
          {completing && (
            <motion.svg
              width="12" height="12" viewBox="0 0 12 12" fill="none"
              initial={{ pathLength: 0, opacity: 0 }}
              animate={{ pathLength: 1, opacity: 1 }}
              transition={{ duration: 0.25, ease: 'easeOut' }}
            >
              <motion.path
                d="M2 6L5 9L10 3"
                stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
                initial={{ pathLength: 0 }}
                animate={{ pathLength: 1 }}
                transition={{ duration: 0.25 }}
              />
            </motion.svg>
          )}
        </AnimatePresence>
      </motion.button>

      {/* Energy dot */}
      <div
        className="flex-shrink-0 w-2 h-2 rounded-full"
        style={{ background: energyColors[task.energy] }}
      />

      {/* Title */}
      <span
        className="flex-1 text-sm leading-snug truncate"
        style={{ color: task.energy === 'low' ? 'rgba(242,240,255,0.45)' : '#F2F0FF' }}
      >
        {task.title}
      </span>

      {/* Right side */}
      <div className="flex items-center gap-2 flex-shrink-0">
        {task.dueTime && (
          <span className="text-xs" style={{ color: 'rgba(242,240,255,0.35)' }}>
            {task.dueTime}
          </span>
        )}
        <span
          className="text-xs px-2 py-0.5 rounded-full"
          style={{
            background: task.projectColor + '22',
            color: task.projectColor,
          }}
        >
          {task.project}
        </span>
      </div>
    </motion.div>
  );
}
