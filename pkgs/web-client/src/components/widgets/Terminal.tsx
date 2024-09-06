import { ReactNode } from 'react'

const ESC = '\u001B';
const CSI = ESC + '[';

const colors: TerminalCharColor[] = [
  'black',
  'red',
  'green',
  'yellow',
  'blue',
  'magenta',
  'cyan',
  'white',
  'default',
];

type TerminalCharColor = 'black' | 'red' | 'green' | 'yellow' | 'blue'
  | 'magenta' | 'cyan' | 'white' | 'default';

type TerminalCharAttrib = {
  type: 'foreground' | 'background',
  color: TerminalCharColor,
} | {
  type: 'normal' | 'bold' | 'underline' | 'blink'
    | 'inverse' | 'invisible'
};

type TerminalInput = TerminalCharAttrib[] | string;

const parseInput = (text: string) => {
  let value: TerminalInput[] = [];

  let i = 0;
  let curr = text;
  while ((i = curr.indexOf(CSI)) > -1) {
    if (i > 0) {
      value = value.concat(curr.substring(0, i).split('\n'));
    }

    const end = curr.indexOf('m', i);
    const attribs = curr.substring(i + 2, end).split(';').map((e) => parseInt(e));

    value.push(attribs.map<TerminalCharAttrib | null>((attrib) => {
      if (attrib > 30 && attrib < 40) {
        return {
          type: 'foreground',
          color: colors[attrib - 30],
        };
      }

      if (attrib > 39 && attrib < 50) {
        return {
          type: 'background',
          color: colors[attrib - 40],
        };
      }

      switch (attrib) {
        case 0: return { type: 'normal' };
        case 1: return { type: 'bold' };
        case 4: return { type: 'underline' };
        case 5: return { type: 'blink' };
        case 7: return { type: 'inverse' };
        case 8: return { type: 'invisible' };
      }
      return null;
    }).filter((x) => x !== null));

    curr = curr.substring(end + 1);
  }

  if (curr.length > 0) {
    value = value.concat(curr.split('\n'));
  }
  return value;
};

const nodesFromInput = (input: TerminalInput[]) => {
  const nodes: ReactNode[] = [];

  let el: TerminalInput | undefined;
  let classNames: string[] = [];
  let lineNum = 0;
  while ((el = input.pop()) !== undefined) {
    // TODO: handle tabs.
    if (el instanceof Array) {
      for (const attrib of el) {
        switch (attrib.type) {
          case 'background':
          case 'foreground':
            {
              const prefix = `${attrib.type == 'background' ? 'bg' : 'text'}-`;
              classNames = classNames.filter((className) => !className.startsWith(prefix));
              switch (attrib.color) {
                case 'default':
                  classNames.push(`${prefix}neutral`);
                  break;
                case 'red':
                  classNames.push(`${prefix}error`);
                  break;
                case 'green':
                  classNames.push(`${prefix}success`);
                  break;
                case 'blue':
                  classNames.push(`${prefix}info`);
                  break;
                case 'cyan':
                  classNames.push(`${prefix}accent`);
                  break;
                case 'black':
                  classNames.push(`${prefix}black`);
                  break;
                case 'white':
                  classNames.push(`${prefix}white`);
                  break;
                case 'yellow':
                  classNames.push(`${prefix}warning`);
                  break;
                case 'magenta':
                  classNames.push(`${prefix}secondary`);
                  break;
              }
            }
            break;
          case 'normal':
            classNames = [];
            break;
          case 'bold':
            classNames.push('font-bold');
            break;
          case 'underline':
            classNames.push('underline');
            break;
        }
      }
    } else if (typeof el === 'string') {
      for (const line of el.split('\n')) {
        nodes.push(<pre data-prefix={(lineNum + 1).toString()} className={classNames.join(' ')}><code>{line}</code></pre>);
        lineNum++;
      }
    }
  }
  return nodes;
};

const Terminal = ({ input }: { input: string }) => (
  <div className="mockup-code">
    {nodesFromInput(parseInput(input))}
  </div>
);

export default Terminal
