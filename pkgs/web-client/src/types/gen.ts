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
  rev?: string,
})

export type FlakeLockNodeRoot = {
  inputs: Map<string, string>
}

export type FlakeLockNodeInput = {
  locked: FlakeLock,
  original: FlakeInput,
}

export type FlakeLockNode = FlakeLockNodeRoot | FlakeLockNodeInput

export interface FlakeMeta {
  description?: string,
  lastModified: number,
  locked: FlakeLock,
  locks: {
    nodes: {
      [key: string]: FlakeLockNode,
    },
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
}

export interface Generation {
  author: string,
  committer: string,
  content: string,
  message: string,
  metadata: FlakeMeta,
}

export interface GenerationInfo {
  nixVersion: string,
  branch: string,
  metadata: FlakeMeta,
}
