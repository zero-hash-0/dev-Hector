'use client';
import { motion } from 'framer-motion';
import { useState } from 'react';

interface CaptureModalProps {
  onCapture: (title: string) => void;
  onClose: () => void;
}

const SUGGESTIONS = [
  'Review Q2 metrics',
  'Call with Sarah · 2pm',
  'Ship landing page',
  'Write standup notes',
];

export default function CaptureModal({ onCapture, onClose }: CaptureModalProps) {
  const [text, setText] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = () => {
    if (!text.trim()) return;
    setSubmitted(true);
    setTimeout(() => {
      onCapture(text.trim());
      onClose();
    }, 400);
  };

  return (
    <>
      {/* Backdrop */}
      <motion.div
        className="absolute inset-0 z-40"
        style={{ background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)' }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />

      {/* Sheet */}
      <motion.div
        className="absolute inset-x-0 bottom-0 z-50 rounded-t-3xl overflow-hidden"
        style={{
          background: 'linear-gradient(180deg, #221F30 0%, #1A1825 100%)',
          boxShadow: '0 -20px 60px rgba(0,0,0,0.6)',
        }}
        initial={{ y: '100%' }}
        animate={{ y: submitted ? '100%' : 0 }}
        exit={{ y: '100%' }}
        transition={{ type: 'spring', stiffness: 420, damping: 42 }}
      >
        {/* Handle bar */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-8 h-1 rounded-full" style={{ background: 'rgba(255,255,255,0.15)' }} />
        </div>

        <div className="px-5 pt-3 pb-4">
          <p className="text-xs mb-3" style={{ color: 'rgba(242,240,255,0.35)' }}>
            New task — press return to save
          </p>

          {/* Input */}
          <input
            autoFocus
            className="w-full text-lg font-medium outline-none bg-transparent mb-5"
            style={{ color: '#F2F0FF' }}
            placeholder="What needs to happen?"
            value={text}
            onChange={e => setText(e.target.value)}
            onKeyDown={e => {
              if (e.key === 'Enter') handleSubmit();
              if (e.key === 'Escape') onClose();
            }}
          />

          {/* AI hint */}
          {text.length > 3 && (
            <motion.div
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex items-center gap-2 mb-5 px-3 py-2 rounded-xl"
              style={{ background: 'rgba(91,63,166,0.15)', border: '1px solid rgba(91,63,166,0.25)' }}
            >
              <span className="text-xs" style={{ color: '#5B3FA6' }}>AI</span>
              <span className="text-xs" style={{ color: 'rgba(242,240,255,0.5)' }}>
                Detected: <span style={{ color: '#F2F0FF' }}>Work project · Medium energy</span>
              </span>
            </motion.div>
          )}

          {/* Suggestions */}
          {text.length === 0 && (
            <div className="flex flex-wrap gap-2 mb-5">
              {SUGGESTIONS.map((s, i) => (
                <motion.button
                  key={i}
                  className="text-xs px-3 py-1.5 rounded-full"
                  style={{ background: 'rgba(255,255,255,0.06)', color: 'rgba(242,240,255,0.5)' }}
                  initial={{ opacity: 0, y: 5 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.06 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => setText(s)}
                >
                  {s}
                </motion.button>
              ))}
            </div>
          )}

          {/* Meta row */}
          <div className="flex items-center gap-3 mb-5">
            {['📅 Today', '⚡ Medium', '📁 Work'].map((tag, i) => (
              <motion.button
                key={i}
                className="text-xs px-3 py-1.5 rounded-full"
                style={{ background: 'rgba(255,255,255,0.05)', color: 'rgba(242,240,255,0.45)' }}
                whileTap={{ scale: 0.95 }}
              >
                {tag}
              </motion.button>
            ))}
          </div>

          {/* Submit */}
          <motion.button
            className="w-full py-4 rounded-2xl text-sm font-semibold"
            style={{
              background: text.trim()
                ? 'linear-gradient(135deg, #F5A623, #FF6B6B)'
                : 'rgba(255,255,255,0.06)',
              color: text.trim() ? '#0F0E11' : 'rgba(242,240,255,0.25)',
            }}
            whileTap={{ scale: 0.97 }}
            animate={{ scale: submitted ? [1, 0.97, 1.03, 1] : 1 }}
            onClick={handleSubmit}
          >
            {submitted ? 'Saved ✓' : 'Save task'}
          </motion.button>
        </div>
      </motion.div>
    </>
  );
}
