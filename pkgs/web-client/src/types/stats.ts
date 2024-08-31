export interface CpuStats {
  processor: number,
  bogomips: number,
  features: string[],
  stats: number[],
}

export interface MemStats {
  MemTotal: number,
  MemFree: number,
  MemAvailable: number,
  Cached: number,
}

export interface NetStats {
  name: string,
  stats: {
    rx: number,
    tx: number,
  },
}

export interface SystemStats {
  loadavg: [ number, number, number ],
  cpu: CpuStats[],
  mem: MemStats,
  net: NetStats[],
}
