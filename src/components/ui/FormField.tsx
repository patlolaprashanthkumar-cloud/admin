import type { InputHTMLAttributes, SelectHTMLAttributes, TextareaHTMLAttributes, ReactNode } from 'react';
import { classNames } from '@/utils';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
  icon?: ReactNode;
}

export function Input({ label, error, hint, icon, className, id, ...props }: InputProps) {
  const inputId = id || props.name;
  return (
    <div>
      {label && <label htmlFor={inputId} className="label-base">{label}</label>}
      <div className="relative">
        {icon && <span className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400">{icon}</span>}
        <input
          id={inputId}
          className={classNames('input-base', icon ? 'pl-10' : '', error && 'border-red-400 focus:border-red-500 focus:ring-red-500/20', className)}
          {...props}
        />
      </div>
      {error ? <p className="mt-1 text-xs text-red-600">{error}</p> : hint ? <p className="mt-1 text-xs text-navy-400">{hint}</p> : null}
    </div>
  );
}

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  options: { value: string; label: string }[];
  placeholder?: string;
}

export function Select({ label, error, options, placeholder, className, id, ...props }: SelectProps) {
  const selectId = id || props.name;
  return (
    <div>
      {label && <label htmlFor={selectId} className="label-base">{label}</label>}
      <select id={selectId} className={classNames('input-base', error && 'border-red-400', className)} {...props}>
        {placeholder && <option value="">{placeholder}</option>}
        {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
    </div>
  );
}

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export function Textarea({ label, error, hint, className, id, ...props }: TextareaProps) {
  const textareaId = id || props.name;
  return (
    <div>
      {label && <label htmlFor={textareaId} className="label-base">{label}</label>}
      <textarea id={textareaId} className={classNames('input-base resize-y', error && 'border-red-400', className)} {...props} />
      {error ? <p className="mt-1 text-xs text-red-600">{error}</p> : hint ? <p className="mt-1 text-xs text-navy-400">{hint}</p> : null}
    </div>
  );
}

interface CheckboxProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
}

export function Checkbox({ label, className, ...props }: CheckboxProps) {
  return (
    <label className="flex items-center gap-2 cursor-pointer">
      <input type="checkbox" className={classNames('h-4 w-4 rounded border-navy-300 text-indigo-600 focus:ring-indigo-500/20', className)} {...props} />
      {label && <span className="text-sm text-navy-700">{label}</span>}
    </label>
  );
}
