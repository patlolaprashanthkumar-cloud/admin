import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import { formatCurrency, formatDate } from './index';

interface PdfColumn {
  header: string;
  key: string;
}

interface PdfOptions {
  title: string;
  subtitle?: string;
  filename: string;
  columns: PdfColumn[];
  rows: Record<string, string | number>[];
  summary?: { label: string; value: string | number }[];
}

const NAVY: [number, number, number] = [15, 26, 54];
const INDIGO: [number, number, number] = [99, 102, 241];
const TEAL: [number, number, number] = [13, 148, 136];
const GRAY: [number, number, number] = [107, 114, 128];

export function exportPDF(options: PdfOptions): void {
  const { title, subtitle, filename, columns, rows, summary } = options;
  const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();
  const margin = 40;

  // Header band
  doc.setFillColor(...NAVY);
  doc.rect(0, 0, pageWidth, 60, 'F');

  doc.setTextColor(255, 255, 255);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(16);
  doc.text('IIECM', margin, 26);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(10);
  doc.text('International Institute of E-commerce and Management', margin, 42);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(13);
  doc.text(title, pageWidth - margin, 26, { align: 'right' });
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(9);
  if (subtitle) {
    doc.text(subtitle, pageWidth - margin, 42, { align: 'right' });
  }
  doc.text(`Generated: ${formatDate(new Date().toISOString())}`, pageWidth - margin, 54, { align: 'right' });

  let startY = 80;

  // Summary cards
  if (summary && summary.length > 0) {
    const cardWidth = (pageWidth - margin * 2 - (summary.length - 1) * 12) / summary.length;
    const cardHeight = 48;
    summary.forEach((item, i) => {
      const x = margin + i * (cardWidth + 12);
      doc.setFillColor(240, 244, 250);
      doc.roundedRect(x, startY, cardWidth, cardHeight, 6, 6, 'F');
      doc.setTextColor(...GRAY);
      doc.setFontSize(7);
      doc.setFont('helvetica', 'normal');
      doc.text(item.label.toUpperCase(), x + 10, startY + 16);
      doc.setTextColor(...NAVY);
      doc.setFontSize(13);
      doc.setFont('helvetica', 'bold');
      doc.text(String(item.value), x + 10, startY + 36);
    });
    startY += cardHeight + 16;
  }

  // Table
  autoTable(doc, {
    startY,
    head: [columns.map((c) => c.header)],
    body: rows.map((row) => columns.map((c) => String(row[c.key] ?? ''))),
    theme: 'striped',
    styles: {
      fontSize: 8,
      cellPadding: 6,
      lineColor: [217, 226, 241],
      lineWidth: 0.5,
    },
    headStyles: {
      fillColor: NAVY,
      textColor: 255,
      fontStyle: 'bold',
      fontSize: 8,
    },
    alternateRowStyles: {
      fillColor: [240, 244, 250],
    },
    margin: { left: margin, right: margin },
  });

  // Footer
  const pageCount = doc.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    const pageHeight = doc.internal.pageSize.getHeight();
    doc.setDrawColor(...[217, 226, 241]);
    doc.line(margin, pageHeight - 24, pageWidth - margin, pageHeight - 24);
    doc.setFontSize(7);
    doc.setTextColor(...GRAY);
    doc.setFont('helvetica', 'normal');
    doc.text('IIECM Admin Portal — Confidential', margin, pageHeight - 12);
    doc.text(`Page ${i} of ${pageCount}`, pageWidth - margin, pageHeight - 12, { align: 'right' });
  }

  doc.save(filename);
}

// Convenience wrappers for common report types

export function exportStudentRosterPDF(
  students: Array<{
    studentId: string; fullName: string; email: string; phone: string;
    subscriptionPlan: string; subscriptionStatus: string; accountStatus: string;
    preferredCategory: string; createdAt: string;
  }>,
  dateRange?: { from: string; to: string },
): void {
  const filtered = dateRange?.from
    ? students.filter((s) => {
        const d = new Date(s.createdAt);
        const from = new Date(dateRange.from);
        const to = dateRange.to ? new Date(dateRange.to) : new Date();
        return d >= from && d <= to;
      })
    : students;

  exportPDF({
    title: 'Student Roster Report',
    subtitle: dateRange?.from ? `${formatDate(dateRange.from)} — ${dateRange.to ? formatDate(dateRange.to) : 'Present'}` : 'All time',
    filename: 'iiecm-student-roster.pdf',
    columns: [
      { header: 'Student ID', key: 'studentId' },
      { header: 'Full Name', key: 'fullName' },
      { header: 'Email', key: 'email' },
      { header: 'Phone', key: 'phone' },
      { header: 'Category', key: 'preferredCategory' },
      { header: 'Plan', key: 'subscriptionPlan' },
      { header: 'Sub. Status', key: 'subscriptionStatus' },
      { header: 'Account', key: 'accountStatus' },
      { header: 'Joined', key: 'createdAt' },
    ],
    rows: filtered.map((s) => ({
      studentId: s.studentId,
      fullName: s.fullName,
      email: s.email,
      phone: s.phone,
      preferredCategory: s.preferredCategory,
      subscriptionPlan: s.subscriptionPlan,
      subscriptionStatus: s.subscriptionStatus,
      accountStatus: s.accountStatus,
      createdAt: formatDate(s.createdAt),
    })),
    summary: [
      { label: 'Total Students', value: filtered.length },
      { label: 'Active', value: filtered.filter((s) => s.accountStatus === 'active').length },
      { label: 'Premium Plans', value: filtered.filter((s) => s.subscriptionPlan === 'premium').length },
      { label: 'Enterprise Plans', value: filtered.filter((s) => s.subscriptionPlan === 'enterprise').length },
    ],
  });
}

export function exportFinancialReportPDF(
  payments: Array<{
    transactionRef: string; studentName: string; courseName?: string;
    amount: number; paymentMethod: string; status: string; paymentDate: string;
    subscriptionPlan?: string;
  }>,
  dateRange?: { from: string; to: string },
): void {
  const filtered = dateRange?.from
    ? payments.filter((p) => {
        const d = new Date(p.paymentDate);
        const from = new Date(dateRange.from);
        const to = dateRange.to ? new Date(dateRange.to) : new Date();
        return d >= from && d <= to;
      })
    : payments;

  const verified = filtered.filter((p) => p.status === 'verified');
  const pending = filtered.filter((p) => p.status === 'pending');
  const refunded = filtered.filter((p) => p.status === 'refunded');
  const totalRevenue = verified.reduce((s, p) => s + p.amount, 0);
  const pendingAmount = pending.reduce((s, p) => s + p.amount, 0);
  const refundedAmount = refunded.reduce((s, p) => s + p.amount, 0);

  exportPDF({
    title: 'Financial Report',
    subtitle: dateRange?.from ? `${formatDate(dateRange.from)} — ${dateRange.to ? formatDate(dateRange.to) : 'Present'}` : 'All time',
    filename: 'iiecm-financial-report.pdf',
    columns: [
      { header: 'Reference', key: 'transactionRef' },
      { header: 'Student', key: 'studentName' },
      { header: 'Course / Plan', key: 'courseName' },
      { header: 'Amount', key: 'amount' },
      { header: 'Method', key: 'paymentMethod' },
      { header: 'Status', key: 'status' },
      { header: 'Date', key: 'paymentDate' },
    ],
    rows: filtered.map((p) => ({
      transactionRef: p.transactionRef,
      studentName: p.studentName,
      courseName: p.courseName ?? p.subscriptionPlan ?? '—',
      amount: formatCurrency(p.amount),
      paymentMethod: p.paymentMethod.replace('_', ' '),
      status: p.status,
      paymentDate: formatDate(p.paymentDate),
    })),
    summary: [
      { label: 'Total Revenue', value: formatCurrency(totalRevenue) },
      { label: 'Pending Amount', value: formatCurrency(pendingAmount) },
      { label: 'Refunded', value: formatCurrency(refundedAmount) },
      { label: 'Total Transactions', value: filtered.length },
    ],
  });
}
