import { notificationStore } from '$lib/stores/notifications.svelte';
import type { Task, CalendarEvent, CalendarTodo, Subscription } from '$lib/types';

export function checkAndCreateNotifications(
  tasks: Task[],
  calendarEvents: CalendarEvent[],
  calendarTodos: CalendarTodo[],
  subscriptions: Subscription[] = []
) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const inThreeDays = new Date(today);
  inThreeDays.setDate(inThreeDays.getDate() + 3);

  const inFiveDays = new Date(today);
  inFiveDays.setDate(inFiveDays.getDate() + 5);

  for (const task of tasks) {
    if (!task.due_date || task.status === 'done') continue;

    const dueDate = new Date(task.due_date);
    dueDate.setHours(0, 0, 0, 0);

    if (dueDate.getTime() === today.getTime()) {
      notificationStore.addNotification({
        type: 'urgent',
        title: 'Tarea para hoy',
        message: task.title,
        link: '/projects?tab=kanban'
      });
    } else if (dueDate > today && dueDate <= inThreeDays) {
      const daysLeft = Math.ceil((dueDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      notificationStore.addNotification({
        type: 'warning',
        title: `Tarea vence en ${daysLeft} día${daysLeft > 1 ? 's' : ''}`,
        message: task.title,
        link: '/projects?tab=kanban'
      });
    }
  }

  for (const event of calendarEvents) {
    if (event.type === 'special_day') continue;

    const eventDate = new Date(event.event_date);
    eventDate.setHours(0, 0, 0, 0);

    if (eventDate.getTime() === today.getTime()) {
      notificationStore.addNotification({
        type: 'urgent',
        title: 'Evento hoy',
        message: event.event_name,
        link: '/goals?tab=calendar'
      });
    } else if (eventDate > today && eventDate <= inThreeDays) {
      const daysLeft = Math.ceil((eventDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      notificationStore.addNotification({
        type: 'warning',
        title: `Evento en ${daysLeft} día${daysLeft > 1 ? 's' : ''}`,
        message: event.event_name,
        link: '/goals?tab=calendar'
      });
    }
  }

  for (const todo of calendarTodos) {
    const todoDate = new Date(todo.todo_date);
    todoDate.setHours(0, 0, 0, 0);

    if (todoDate.getTime() === today.getTime()) {
      notificationStore.addNotification({
        type: 'urgent',
        title: 'Tarea pendiente para hoy',
        message: todo.name,
        link: '/goals?tab=calendar'
      });
    } else if (todoDate > today && todoDate <= inThreeDays) {
      const daysLeft = Math.ceil((todoDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      notificationStore.addNotification({
        type: 'warning',
        title: `Tarea en ${daysLeft} día${daysLeft > 1 ? 's' : ''}`,
        message: todo.name,
        link: '/goals?tab=calendar'
      });
    }
  }

  for (const sub of subscriptions) {
    if (!sub.is_active) continue;

    const base = sub.last_paid_date || sub.start_date;
    const nextDate = new Date(base);
    nextDate.setMonth(nextDate.getMonth() + sub.period_months);
    nextDate.setHours(0, 0, 0, 0);

    if (nextDate.getTime() === today.getTime()) {
      notificationStore.addNotification({
        type: 'urgent',
        title: 'Suscripción vence hoy',
        message: `${sub.name} - ${formatSubCost(sub)}`,
        link: '/expenses'
      });
    } else if (nextDate > today && nextDate <= inFiveDays) {
      const daysLeft = Math.ceil((nextDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      notificationStore.addNotification({
        type: 'warning',
        title: `Suscripción en ${daysLeft} día${daysLeft > 1 ? 's' : ''}`,
        message: `${sub.name} - ${formatSubCost(sub)}`,
        link: '/expenses'
      });
    }
  }
}

function formatSubCost(sub: Subscription): string {
  const currency = typeof localStorage !== 'undefined' ? localStorage.getItem('vitacora_currency') : 'dollar';
  const symbol = currency === 'euro' ? '€' : '$';
  return currency === 'euro' ? `${sub.cost.toFixed(2)}${symbol}` : `${symbol}${sub.cost.toFixed(2)}`;
}