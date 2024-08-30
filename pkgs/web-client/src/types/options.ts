export type OptionDefault = {
  _type: 'literaExpression',
  text: string
}

export interface Option {
  declarations: string[],
  default?: OptionDefault,
  description: string,
  loc: string[],
  pageId?: string,
  childOf?: string,
  children?: OptionsMap,
  isToplevel: boolean,
  readOnly: boolean,
  type: string,
}

export type OptionsMap = Record<string, Option>
