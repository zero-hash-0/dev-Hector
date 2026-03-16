'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useState, useCallback } from 'react';
import TodayView from './TodayView';
import ProjectsView from './ProjectsView';
import ProfileView from './ProfileView';
import FocusMode from './FocusMode';
import MorningBrief from './MorningBrief';
import CaptureModal from './CaptureModal';
import { Task, EnergyLevel } from './types';
import { useAnalytics } from '@/app/providers';

// ─── Seed data ───────────────────────────────────────────────────────────────
const INITIAL_TASKS: Task[] = [
  { id: '1', title: 'Write proposal draft',    project: 'Work',   projectColor: '#F5A623', energy: 'high',   status: 'today',  dueTime: 'today' },
  { id: '2', title: 'Review Q2 metrics',       project: 'Work',   projectColor: '#F5A623', energy: 'medium', status: 'today' },
  { id: '3', title: 'Call with Sarah',         project: 'Work',   projectColor: '#F5A623', energy: 'medium', status: 'today',  dueTime: '2pm' },
  { id: '4', title: 'Update portfolio',        project: 'Side',   projectColor: '#5B3FA6', energy: 'low',    status: 'today' },
  { id: '5', title: 'Read chapter 4',          project: 'Learn',  projectColor: '#7EC8A0', energy: 'low',    status: 'today' },
  { id: '6', title: 'Expense report',          project: 'Work',   projectColor: '#F5A623', energy: 'low',    status: 'today' },
  { id: '7', title: 'Research AI tools',       project: 'Learn',  projectColor: '#7EC8A0', energy: 'medium', status: 'later' },
  { id: '8', title: 'Plan team offsite',       project: 'Work',   projectColor: '#F5A623', energy: 'high',   status: 'later' },
  { id: '9', title: 'Fix nav bug',             project: 'Side',   projectColor: '#5B3FA6', energy: 'high',   status: 'later' },
];

// ─── Tab nav config ──────────────────────────────────────────────────────────
const TABS = [
  { id: 'today',    label: 'Today',    icon: '◉' },
  { id: 'capture',  label: '',         icon: '+' },
  { id: 'projects', label: 'Projects', icon: '⊞' },
  { id: 'profile',  label: 'Profile',  icon: '◎' },
] as const;

type TabId = typeof TABS[number]['id'];

export default function OpusApp() {
  const { track } = useAnalytics();
  const [tasks, setTasks]           = useState<Task[]>(INITIAL_TASKS);
  const [tab, setTab]               = useState<TabId>('today');
  const [momentum, setMomentum]     = useState(74);
  const [streak]                    = useState(14);
  const [focusTask, setFocusTask]   = useState<Task | null>(null);
  const [showBrief, setShowBrief]   = useState(false);
  const [showCapture, setShowCapture] = useState(false);
  const [completedBurst, setCompletedBurst] = useState(false);

  // Complete a task
  const handleComplete = useCallback((id: string) => {
    const task = tasks.find(t => t.id === id);
    setTasks(prev => prev.map(t => t.id === id ? { ...t, status: 'done' } : t));
    setMomentum(m => Math.min(100, m + Math.floor(Math.random() * 5) + 3));
    track('task_completed', { energy: task?.energy, project: task?.project });
    setCompletedBurst(true);
    setTimeout(() => setCompletedBurst(false), 900);
  }, [tasks, track]);

  // Add a new task
  const handleCapture = useCallback((title: string) => {
    const newTask: Task = {
      id: Date.now().toString(),
      title,
      project: 'Work',
      projectColor: '#F5A623',
      energy: 'medium',
      status: 'today',
    };
    setTasks(prev => [newTask, ...prev]);
    track('task_captured', { has_ai_hint: title.length > 3 });
  }, [track]);

  // Morning brief completion
  const handleBriefComplete = useCallback((energy: EnergyLevel, selectedIds: string[]) => {
    setTasks(prev => prev.map(t =>
      selectedIds.includes(t.id) ? { ...t, status: 'today' } : t
    ));
    track('morning_brief_completed', { energy_level: energy, tasks_selected: selectedIds.length });
    setShowBrief(false);
  }, [track]);

  const handleTabPress = (id: TabId) => {
    if (id === 'capture') {
      setShowCapture(true);
      track('capture_modal_opened');
      return;
    }
    setTab(id);
    track('tab_changed', { tab: id });
  };

  return (
    <div
      className="relative flex flex-col overflow-hidden"
      style={{
        width: '100%',
        height: '100%',
        background: '#0F0E11',
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
      }}
    >
      {/* Global completion bloom */}
      <AnimatePresence>
        {completedBurst && (
          <motion.div
            className="absolute inset-0 z-30 pointer-events-none"
            initial={{ opacity: 0 }}
            animate={{ opacity: [0, 0.35, 0] }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.8 }}
            style={{ background: 'radial-gradient(circle at 50% 60%, rgba(126,200,160,0.5) 0%, transparent 60%)' }}
          />
        )}
      </AnimatePresence>

      {/* Main content */}
      <div className="flex flex-col flex-1 overflow-hidden">
        <AnimatePresence mode="wait">
          <motion.div
            key={tab}
            className="flex-1 flex flex-col overflow-hidden"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
          >
            {tab === 'today' && (
              <TodayView
                tasks={tasks}
                momentum={momentum}
                streak={streak}
                onComplete={handleComplete}
                onFocus={(t) => { setFocusTask(t); track('focus_mode_started', { task_title: t.title, energy: t.energy }); }}
                onMorningBrief={() => setShowBrief(true)}
              />
            )}
            {tab === 'projects' && <ProjectsView />}
            {tab === 'profile' && <ProfileView />}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Tab Bar */}
      <div
        className="flex-shrink-0 flex items-center px-4 pb-safe"
        style={{
          paddingTop: 10,
          paddingBottom: 20,
          background: 'linear-gradient(0deg, rgba(15,14,17,1) 70%, rgba(15,14,17,0) 100%)',
          backdropFilter: 'blur(12px)',
          borderTop: '1px solid rgba(255,255,255,0.05)',
        }}
      >
        {TABS.map((t) => {
          const isCapture = t.id === 'capture';
          const isActive = tab === t.id;

          return (
            <motion.button
              key={t.id}
              className="flex flex-col items-center justify-center flex-1"
              whileTap={{ scale: 0.88 }}
              onClick={() => handleTabPress(t.id)}
            >
              {isCapture ? (
                <div
                  className="w-12 h-12 rounded-full flex items-center justify-center text-xl font-light mb-0.5"
                  style={{ background: 'linear-gradient(135deg, #F5A623, #FF6B6B)', color: '#0F0E11', marginTop: -16 }}
                >
                  +
                </div>
              ) : (
                <>
                  <motion.span
                    className="text-lg mb-0.5"
                    animate={{ color: isActive ? '#F5A623' : 'rgba(242,240,255,0.3)' }}
                    transition={{ duration: 0.2 }}
                  >
                    {t.icon}
                  </motion.span>
                  <motion.span
                    className="text-xs"
                    animate={{ color: isActive ? '#F5A623' : 'rgba(242,240,255,0.3)' }}
                    transition={{ duration: 0.2 }}
                  >
                    {t.label}
                  </motion.span>
                </>
              )}
            </motion.button>
          );
        })}
      </div>

      {/* Overlays */}
      <AnimatePresence>
        {showBrief && (
          <MorningBrief
            tasks={tasks}
            onComplete={handleBriefComplete}
            onSkip={() => setShowBrief(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {focusTask && (
          <FocusMode
            task={focusTask}
            onDone={() => { handleComplete(focusTask.id); setFocusTask(null); }}
            onExit={() => { track('focus_mode_exited', { task_title: focusTask.title }); setFocusTask(null); }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showCapture && (
          <CaptureModal
            onCapture={handleCapture}
            onClose={() => setShowCapture(false)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
