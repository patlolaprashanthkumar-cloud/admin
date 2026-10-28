import type { ReactNode } from 'react';
import { AlertTriangle } from 'lucide-react';
import { Modal } from './Modal';

interface ConfirmDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
}

export function ConfirmDialog({
  open, onClose, onConfirm, title, message,
  confirmLabel = 'Confirm', cancelLabel = 'Cancel', danger = true,
}: ConfirmDialogProps) {
  return (
    <Modal open={open} onClose={onClose} size="sm"
      footer={
        <>
          <button className="btn-secondary" onClick={onClose}>{cancelLabel}</button>
          <button className={danger ? 'btn-danger' : 'btn-primary'} onClick={() => { onConfirm(); onClose(); }}>
            {confirmLabel}
          </button>
        </>
      }
    >
      <div className="flex gap-4">
        {danger && (
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-100 text-red-600">
            <AlertTriangle size={20} />
          </div>
        )}
        <div>
          <h3 className="text-base font-semibold text-navy-900">{title}</h3>
          <p className="mt-1 text-sm text-navy-600">{message}</p>
        </div>
      </div>
    </Modal>
  );
}
