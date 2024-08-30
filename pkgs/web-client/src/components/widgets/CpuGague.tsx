import { CSSProperties } from 'react';
import { CpuStats } from '../../types/stats.ts'

const CpuGague = ({ last, curr }: { last: CpuStats, curr: CpuStats }) => {
  const lastSum = last.stats.reduce((i, c) => i + c, 0);
  const currSum = curr.stats.reduce((i, c) => i + c, 0);
  const delta = currSum - lastSum;

  const idle = curr.stats[4] - last.stats[4];
  const used = delta - idle;
  const usage = 100 - (100 * used / delta);

  return (
    <div className="border-4 border-neutral bg-neutral text-primary radial-progress m-2" style={{ "--value": usage } as CSSProperties} role="progressbar">{usage.toFixed(0)}%</div>
  );
};

export default CpuGague
