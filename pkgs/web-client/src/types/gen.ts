export type FlakeInput = {
  type: 'git',
  rev: string,
  url: string,
} | {
  type: 'github',
  ref: string,
  repo: string,
  owner: string,
}

export type FlakeLock = {
  lastModified: number,
  narHash: string,
} & ({
  type: 'git',
  rev: string,
  revCount: number,
  url: string,
} | {
  type: 'github',
  owner: string,
  repo: string,
  rev: string,
})

export interface Generation {
  author: string,
  committer: string,
  content: string,
  message: string,
  metadata: {
    description?: string,
    lastModified: number,
    locked: FlakeLock,
    locks: {
      nodes: Map<string, {
        locked: FlakeLock,
        original: FlakeInput,
      }>,
      root: string,
      version: number,
    },
    original: FlakeInput,
    originalUrl: string,
    path: string,
    resolved: FlakeInput,
    revCount: string,
    revision: string,
    url: string,
  },
}
