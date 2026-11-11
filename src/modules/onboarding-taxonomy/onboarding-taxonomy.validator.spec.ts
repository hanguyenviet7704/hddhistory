import { IOnboardingTaxonomyTree } from './interface/onboarding-taxonomy.interface';
import { validateTaxonomyTree } from './onboarding-taxonomy.validator';

const branch = (code: string) => ({
  code,
  label: { vi: code },
  subtitle: {},
  iconUrl: '',
  imageUrl: '',
  order: 1,
  isSelectable: true,
  categoryId: null,
  isActive: true,
});
const pkg = (code: string, branchCode: string) => ({
  code,
  branchCode,
  problemLabel: { vi: 'p ' + code },
  desireLabel: { vi: 'd ' + code },
  order: 1,
  isActive: true,
});
const label = (code: string, packageCode: string) => ({
  code,
  packageCode,
  label: { vi: 'l ' + code },
  order: 1,
});

const valid: IOnboardingTaxonomyTree = {
  branches: [branch('CX')],
  packages: [pkg('CX-1', 'CX')],
  labels: [label('CX01', 'CX-1')],
};

describe('validateTaxonomyTree', () => {
  it('accepts a consistent tree', () => {
    expect(validateTaxonomyTree(valid)).toEqual([]);
  });

  it('rejects duplicated codes across the same entity', () => {
    const issues = validateTaxonomyTree({
      ...valid,
      labels: [label('CX01', 'CX-1'), label('CX01', 'CX-1')],
    });
    expect(issues).toEqual([
      expect.objectContaining({
        entity: 'label',
        code: 'CX01',
        message: expect.stringContaining('trùng'),
      }),
    ]);
  });

  it('rejects a package whose branch does not exist', () => {
    const issues = validateTaxonomyTree({
      ...valid,
      packages: [pkg('LV-1', 'LV')],
      labels: [label('LV01', 'LV-1')],
    });
    expect(issues.map(i => i.code)).toContain('LV-1');
  });

  it('rejects a label whose package does not exist', () => {
    const issues = validateTaxonomyTree({
      ...valid,
      labels: [label('CX01', 'CX-9')],
    });
    expect(issues.map(i => i.code)).toEqual(expect.arrayContaining(['CX01']));
  });

  it('rejects a package with no label and with blank vi labels', () => {
    const issues = validateTaxonomyTree({
      ...valid,
      packages: [{ ...pkg('CX-1', 'CX'), problemLabel: { vi: ' ' } }],
      labels: [],
    });
    expect(issues.filter(i => i.code === 'CX-1')).toHaveLength(2);
  });

  it('rejects malformed codes', () => {
    const issues = validateTaxonomyTree({
      branches: [branch('cx')],
      packages: [pkg('CX_1', 'cx')],
      labels: [label('CX-01', 'CX_1')],
    });
    expect(issues.length).toBeGreaterThanOrEqual(3);
  });
});
