import { useState } from 'react';
import { useMockStore } from '@/hooks/useMockStore';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui';
import { Badge } from '@/components/ui/Badge';
import { Pencil, Trash2, Eye, EyeOff } from 'lucide-react';

export function CategoryListPage() {
  const store = useMockStore();
  const categories = store.courseCategories;

  const [isModalOpen, setModalOpen] = useState(false);
  const [editId, setEditId] = useState('');
  const [name, setName] = useState('');
  const [desc, setDesc] = useState('');
  const [color, setColor] = useState('#064B3E');

  const openAddModal = () => {
    setEditId('');
    setName('');
    setDesc('');
    setColor('#064B3E');
    setModalOpen(true);
  };

  const openEditModal = (c: any) => {
    setEditId(c.id);
    setName(c.name);
    setDesc(c.description);
    setColor(c.color);
    setModalOpen(true);
  };

  const handleSave = () => {
    if (editId) {
      store.updateCategory(editId, { name, description: desc, color });
    } else {
      store.addCategory({ name, description: desc, color, isActive: true, courseCount: 0 });
    }
    setModalOpen(false);
  };

  const handleToggleActive = (c: any) => {
    store.toggleCategoryActive(c.id, !c.isActive);
  };

  const handleDelete = (c: any) => {
    store.deleteCategory(c.id);
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold font-display text-navy-900">Course Categories</h1>
        <Button onClick={openAddModal}>Add Category</Button>
      </div>
      <div className="card overflow-hidden">
        <table className="min-w-full table-auto border-collapse">
          <thead className="table-header">
            <tr>
              <th className="px-4 py-3 text-left">Name</th>
              <th className="px-4 py-3 text-left">Description</th>
              <th className="px-4 py-3 text-left">Color</th>
              <th className="px-4 py-3 text-left">Active</th>
              <th className="px-4 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-navy-100">
            {categories.map((c) => (
              <tr key={c.id} className="hover:bg-navy-50/50 transition-colors">
                <td className="table-cell font-medium text-navy-900">{c.name}</td>
                <td className="table-cell text-navy-600">{c.description}</td>
                <td className="table-cell">
                  <div className="w-6 h-6 rounded-md shadow-xs border border-navy-200" style={{ backgroundColor: c.color }} />
                </td>
                <td className="table-cell">
                  <Badge variant={c.isActive ? 'success' : 'neutral'}>{c.isActive ? 'Active' : 'Inactive'}</Badge>
                </td>
                <td className="table-cell flex space-x-2 items-center text-navy-500">
                  <button onClick={() => openEditModal(c)} className="hover:text-forest-600 transition-colors" title="Edit">
                    <Pencil size={16} />
                  </button>
                  <button onClick={() => handleDelete(c)} className="hover:text-red-600 transition-colors" title="Delete">
                    <Trash2 size={16} />
                  </button>
                  <button onClick={() => handleToggleActive(c)} className="hover:text-navy-900 transition-colors" title={c.isActive ? 'Deactivate' : 'Activate'}>
                    {c.isActive ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Modal open={isModalOpen} onClose={() => setModalOpen(false)} title={editId ? 'Edit Category' : 'Add Category'}>
        <div className="space-y-4">
          <Input label="Name" value={name} onChange={(e) => setName(e.target.value)} />
          <Input label="Description" value={desc} onChange={(e) => setDesc(e.target.value)} />
          <label className="flex items-center gap-2 text-sm font-medium text-navy-700">
            <span>Color:</span>
            <input type="color" value={color} onChange={(e) => setColor(e.target.value)} className="h-10 w-10 p-0 border border-navy-200 rounded cursor-pointer" />
          </label>
        </div>
        <div className="flex justify-end space-x-2 mt-4">
          <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
          <Button onClick={handleSave}>Save</Button>
        </div>
      </Modal>
    </div>
  );
}
