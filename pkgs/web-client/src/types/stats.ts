export interface CpuStats {
  processor: number,
  bogomips: number,
  features: string[],
  stats: number[],
}

export interface SystemStats {
  loadavg: [ number, number, number ],
  cpu: CpuStats[],
}
