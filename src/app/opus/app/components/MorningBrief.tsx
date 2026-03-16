'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';
import { EnergyLevel, Task } from './types';

interface MorningBriefProps {
  tasks: Task[];
  onComplete: (energy: EnergyLevel, selectedIds: string[]) => void;
  onSkip: () => void;
}

const steps = ['energy', 'tasks', 'confirm'] as const;

export default function MorningBrief({ tasks, onComplete, onSkip }: MorningBriefProps) {
  const [step, setStep] = useState<typeof steps[number]>('energy');
  const [energy, setEnergy] = useState<EnergyLevel | null>(null);
  const [cardIndex, setCardIndex] = useState(0);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const MAX = 7;

  const availableTasks = tasks.filter(t => t.status !== 'done');
  const currentTask = availableTasks[cardIndex];
  const confirmed = tasks.filter(t => selectedIds.includes(t.id));

  const handleEnergySelect = (e: EnergyLevel) => {
    setEnergy(e);
    setTimeout(() => setStep('tasks'), 400);
  };

  const handleAdd = () => {
    if (selectedIds.length < MAX && currentTask) {
      setSelectedIds(prev => [...prev, currentTask.id]);
    }
    if (cardIndex < availableTasks.length - 1) setCardIndex(i => i + 1);
    else setStep('confirm');
  };

  const handleSkipTask = () => {
    if (cardIndex < availableTasks.length - 1) setCardIndex(i => i + 1);
    else setStep('confirm');
  };

  const energyConfig = {
    low:    { label: 'Low',    color: '#7EC8A0', desc: 'Light day, steady pace' },
    medium: { label: 'Medium', color: '#5B3FA6', desc: 'Solid energy, focused' },
    high:   { label: 'High',   color: '#F5A623', desc: 'Peak state, go deep' },
  };

  return (
    <motion.div
      className="absolute inset-0 z-50 flex flex-col"
      style={{ background: 'linear-gradient(160deg, #1A0A3D 0%, #0F0E11 60%)' }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      {/* Skip */}
      <div className="flex justify-end p-5 pt-6">
        <button onClick={onSkip} className="text-xs" style={{ color: 'rgba(242,240,255,0.3)' }}>
          skip
        </button>
      </div>

      {/* Step indicators */}
      <div className="flex gap-1.5 px-6 mb-8">
        {steps.map((s, i) => (
          <motion.div
            key={s}
            className="h-1 rounded-full flex-1"
            style={{
              background: steps.indexOf(step) >= i ? '#F5A623' : 'rgba(255,255,255,0.1)'
            }}
            animate={{ background: steps.indexOf(step) >= i ? '#F5A623' : 'rgba(255,255,255,0.1)' }}
            transition={{ duration: 0.3 }}
          />
        ))}
      </div>

      <div className="flex-1 flex flex-col px-6">
        <AnimatePresence mode="wait">

          {/* STEP 1 — Energy */}
          {step === 'energy' && (
            <motion.div
              key="energy"
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }}
              className="flex flex-col flex-1"
            >
              <h2 className="text-2xl font-semibold mb-1" style={{ color: '#F2F0FF' }}>
                How&apos;s your energy<br />this morning?
              </h2>
              <p className="text-sm mb-10" style={{ color: 'rgba(242,240,255,0.4)' }}>
                We&apos;ll match your tasks to your capacity.
              </p>
              <div className="flex flex-col gap-3">
                {(Object.keys(energyConfig) as EnergyLevel[]).map((e) => (
                  <motion.button
                    key={e}
                    className="flex items-center gap-4 p-4 rounded-2xl border text-left"
                    style={{
                      borderColor: energy === e ? energyConfig[e].color : 'rgba(255,255,255,0.08)',
                      background: energy === e ? energyConfig[e].color + '15' : 'rgba(255,255,255,0.03)',
                    }}
                    whileTap={{ scale: 0.97 }}
                    onClick={() => handleEnergySelect(e)}
                  >
                    <div className="w-3 h-3 rounded-full flex-shrink-0" style={{ background: energyConfig[e].color }} />
                    <div>
                      <div className="font-medium text-sm" style={{ color: '#F2F0FF' }}>{energyConfig[e].label}</div>
                      <div className="text-xs mt-0.5" style={{ color: 'rgba(242,240,255,0.4)' }}>{energyConfig[e].desc}</div>
                    </div>
                  </motion.button>
                ))}
              </div>
            </motion.div>
          )}

          {/* STEP 2 — Task swipe */}
          {step === 'tasks' && currentTask && (
            <motion.div
              key="tasks"
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }}
              className="flex flex-col flex-1"
            >
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-xl font-semibold" style={{ color: '#F2F0FF' }}>
                  Build your day
                </h2>
                <span className="text-xs" style={{ color: 'rgba(242,240,255,0.4)' }}>
                  {selectedIds.length}/{MAX}
                </span>
              </div>

              {/* Task card */}
              <AnimatePresence mode="wait">
                <motion.div
                  key={currentTask.id}
                  initial={{ opacity: 0, scale: 0.95, y: 10 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95, y: -10 }}
                  className="rounded-3xl p-5 mb-6"
                  style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)' }}
                >
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-2 h-2 rounded-full" style={{
                      background: currentTask.energy === 'high' ? '#F5A623' : currentTask.energy === 'medium' ? '#5B3FA6' : '#7EC8A0'
                    }} />
                    <span className="text-xs" style={{ color: 'rgba(242,240,255,0.4)' }}>
                      {currentTask.energy} energy · {currentTask.project}
                    </span>
                  </div>
                  <p className="text-lg font-medium leading-snug" style={{ color: '#F2F0FF' }}>
                    {currentTask.title}
                  </p>
                  {currentTask.dueTime && (
                    <p className="text-xs mt-3" style={{ color: 'rgba(242,240,255,0.35)' }}>
                      Due {currentTask.dueTime}
                    </p>
                  )}
                </motion.div>
              </AnimatePresence>

              <div className="flex gap-3">
                <motion.button
                  className="flex-1 py-4 rounded-2xl text-sm font-medium"
                  style={{ background: 'rgba(255,255,255,0.06)', color: 'rgba(242,240,255,0.5)' }}
                  whileTap={{ scale: 0.97 }}
                  onClick={handleSkipTask}
                >
                  Skip
                </motion.button>
                <motion.button
                  className="flex-1 py-4 rounded-2xl text-sm font-semibold"
                  style={{
                    background: selectedIds.length >= MAX ? 'rgba(255,255,255,0.06)' : 'linear-gradient(135deg, #F5A623, #FF6B6B)',
                    color: selectedIds.length >= MAX ? 'rgba(242,240,255,0.3)' : '#0F0E11',
                  }}
                  whileTap={{ scale: 0.97 }}
                  onClick={handleAdd}
                  disabled={selectedIds.length >= MAX}
                >
                  Add to today →
                </motion.button>
              </div>
            </motion.div>
          )}

          {/* STEP 3 — Confirm */}
          {step === 'confirm' && (
            <motion.div
              key="confirm"
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }}
              className="flex flex-col flex-1"
            >
              <div className="flex items-center gap-2 mb-2">
                <h2 className="text-2xl font-semibold" style={{ color: '#F2F0FF' }}>Today&apos;s plan</h2>
                <span className="text-lg">✓</span>
              </div>
              <p className="text-sm mb-8" style={{ color: 'rgba(242,240,255,0.4)' }}>
                {confirmed.length} tasks · {energy} energy
              </p>
              <div className="flex flex-col gap-2 mb-8">
                {confirmed.map((t, i) => (
                  <motion.div
                    key={t.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.08 }}
                    className="flex items-center gap-3 py-2"
                  >
                    <div className="w-2 h-2 rounded-full flex-shrink-0" style={{
                      background: t.energy === 'high' ? '#F5A623' : t.energy === 'medium' ? '#5B3FA6' : '#7EC8A0'
                    }} />
                    <span className="text-sm" style={{ color: '#F2F0FF' }}>{t.title}</span>
                  </motion.div>
                ))}
              </div>
              <motion.button
                className="w-full py-4 rounded-2xl text-sm font-semibold mt-auto"
                style={{ background: 'linear-gradient(135deg, #F5A623, #FF6B6B)', color: '#0F0E11' }}
                whileTap={{ scale: 0.97 }}
                onClick={() => onComplete(energy || 'medium', selectedIds)}
              >
                Let&apos;s go →
              </motion.button>
            </motion.div>
          )}

        </AnimatePresence>
      </div>
    </motion.div>
  );
}
