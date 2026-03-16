'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useState, useEffect } from 'react';
import { Task } from './types';

interface FocusModeProps {
  task: Task;
  onDone: () => void;
  onExit: () => void;
}

export default function FocusMode({ task, onDone, onExit }: FocusModeProps) {
  const DURATION = 25 * 60;
  const [seconds, setSeconds] = useState(DURATION);
  const [running, setRunning] = useState(true);
  const [showCapture, setShowCapture] = useState(false);
  const [captureText, setCaptureText] = useState('');
  const [showDoneBloom, setShowDoneBloom] = useState(false);

  useEffect(() => {
    if (!running) return;
    const t = setInterval(() => {
      setSeconds(s => {
        if (s <= 1) { clearInterval(t); setRunning(false); return 0; }
        return s - 1;
      });
    }, 1000);
    return () => clearInterval(t);
  }, [running]);

  const mins = Math.floor(seconds / 60).toString().padStart(2, '0');
  const secs = (seconds % 60).toString().padStart(2, '0');
  const progress = 1 - seconds / DURATION;

  const energyColor = task.energy === 'high' ? '#F5A623' : task.energy === 'medium' ? '#5B3FA6' : '#7EC8A0';

  const handleDone = () => {
    setShowDoneBloom(true);
    setTimeout(() => { setShowDoneBloom(false); onDone(); }, 900);
  };

  return (
    <motion.div
      className="absolute inset-0 z-50 flex flex-col overflow-hidden"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: { duration: 0.4 } }}
    >
      {/* Animated gradient background */}
      <motion.div
        className="absolute inset-0"
        animate={{
          background: [
            'linear-gradient(160deg, #1A0A3D 0%, #0F0E11 100%)',
            'linear-gradient(160deg, #0F0E11 0%, #2A1A5E 100%)',
            'linear-gradient(160deg, #1A0A3D 0%, #0F0E11 100%)',
          ]
        }}
        transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
      />

      {/* Done bloom overlay */}
      <AnimatePresence>
        {showDoneBloom && (
          <motion.div
            className="absolute inset-0 z-10 flex items-center justify-center"
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 2 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.8, ease: 'easeOut' }}
            style={{ background: 'radial-gradient(circle, rgba(245,166,35,0.4) 0%, transparent 70%)' }}
          />
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="relative z-10 flex items-center justify-between px-6 pt-6 pb-2">
        <motion.button
          className="text-xs px-3 py-1.5 rounded-full"
          style={{ background: 'rgba(255,255,255,0.07)', color: 'rgba(242,240,255,0.4)' }}
          whileTap={{ scale: 0.95 }}
          onClick={onExit}
        >
          ← Exit focus
        </motion.button>
        <div className="w-2 h-2 rounded-full animate-pulse" style={{ background: energyColor }} />
      </div>

      {/* Main content */}
      <div className="relative z-10 flex-1 flex flex-col items-center justify-center px-8 text-center">
        {/* Project label */}
        <motion.span
          className="text-xs uppercase tracking-widest mb-6"
          style={{ color: 'rgba(242,240,255,0.3)' }}
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          {task.project}
        </motion.span>

        {/* Task title */}
        <motion.h1
          className="text-2xl font-semibold leading-tight mb-12"
          style={{ color: '#F2F0FF' }}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, type: 'spring', stiffness: 200 }}
        >
          {task.title}
        </motion.h1>

        {/* Timer circle */}
        <motion.div
          className="relative mb-12"
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4 }}
        >
          <svg width="160" height="160" style={{ transform: 'rotate(-90deg)' }}>
            <circle cx="80" cy="80" r="70" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="4" />
            <motion.circle
              cx="80" cy="80" r="70" fill="none"
              stroke={energyColor}
              strokeWidth="4"
              strokeLinecap="round"
              strokeDasharray={2 * Math.PI * 70}
              strokeDashoffset={(1 - progress) * 2 * Math.PI * 70}
              style={{ opacity: 0.7 }}
            />
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-3xl font-semibold tabular-nums" style={{ color: '#F2F0FF' }}>
              {mins}:{secs}
            </span>
            <button
              className="text-xs mt-1"
              style={{ color: 'rgba(242,240,255,0.3)' }}
              onClick={() => setRunning(r => !r)}
            >
              {running ? 'pause' : 'resume'}
            </button>
          </div>
        </motion.div>

        {/* Pomodoro dots */}
        <div className="flex gap-2 mb-12">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className="w-2 h-2 rounded-full"
              style={{ background: i === 0 ? energyColor : 'rgba(255,255,255,0.12)' }}
            />
          ))}
        </div>
      </div>

      {/* Bottom actions */}
      <div className="relative z-10 px-6 pb-8 flex flex-col gap-3">
        <motion.button
          className="w-full py-4 rounded-2xl text-sm font-semibold"
          style={{ background: 'linear-gradient(135deg, #F5A623, #FF6B6B)', color: '#0F0E11' }}
          whileTap={{ scale: 0.97 }}
          onClick={handleDone}
        >
          Done ✓
        </motion.button>
        <motion.button
          className="w-full py-3 rounded-2xl text-sm"
          style={{ background: 'rgba(255,255,255,0.05)', color: 'rgba(242,240,255,0.5)' }}
          whileTap={{ scale: 0.97 }}
          onClick={() => setShowCapture(true)}
        >
          + Capture a thought
        </motion.button>
      </div>

      {/* Capture overlay */}
      <AnimatePresence>
        {showCapture && (
          <motion.div
            className="absolute inset-x-0 bottom-0 z-20 p-6 rounded-t-3xl"
            style={{ background: '#1A1825', boxShadow: '0 -20px 60px rgba(0,0,0,0.5)' }}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 400, damping: 40 }}
          >
            <p className="text-xs mb-3" style={{ color: 'rgba(242,240,255,0.4)' }}>
              Saved to inbox — stay focused
            </p>
            <input
              autoFocus
              className="w-full text-sm outline-none bg-transparent"
              style={{ color: '#F2F0FF' }}
              placeholder="What's on your mind?"
              value={captureText}
              onChange={e => setCaptureText(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter') { setCaptureText(''); setShowCapture(false); }
                if (e.key === 'Escape') setShowCapture(false);
              }}
            />
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
