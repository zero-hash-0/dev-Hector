export type EnergyLevel = 'low' | 'medium' | 'high';
export type TaskStatus = 'today' | 'later' | 'done';

export interface Task {
  id: string;
  title: string;
  project: string;
  projectColor: string;
  energy: EnergyLevel;
  dueTime?: string;
  status: TaskStatus;
  subtasks?: { id: string; title: string; done: boolean }[];
}

export interface Trophy {
  id: string;
  icon: string;
  title: string;
  description: string;
  earned: boolean;
}

export type Screen = 'today' | 'projects' | 'profile' | 'focus' | 'capture';
export type ModalType = 'morningBrief' | 'capture' | 'focus' | null;
