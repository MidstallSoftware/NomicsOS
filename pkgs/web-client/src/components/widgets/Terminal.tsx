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
  const value: TerminalInput[] = [];

  let i = 0;
  let curr = text;
  while ((i = curr.indexOf(CSI)) > -1) {
    if (i > 0) {
      value.push(curr.substring(0, i));
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
    value.push(curr);
  }
  return value;
};

const nodesFromInput = (input: TerminalInput[]) => {
  let lines: ReactNode[][] = [];

  let el: TerminalInput | undefined;
  let classNames: string[] = [];
  let hasNewline = false;
  while ((el = input.shift()) !== undefined) {
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
      const value = (text: string) => <span className={classNames.join(' ')}><code>{text}</code></span>;

      if (!hasNewline && lines.length > 0) {
        const i = el.indexOf('\n');
        if (i == -1) {
          lines[lines.length - 1].push(value(el));
        } else {
          if (i > 0) {
            lines[lines.length - 1].push(el.substring(0, i));
          }

          const e = el.lastIndexOf('\n');
          if (e > i && e == el.length - 1) {
            lines = lines.concat(el.substring(i + 1, e).split('\n').map(value).map((row) => [ row ]));
          } else if (e == i && e == el.length - 1) {
            // Do nothing
          } else {
            lines = lines.concat(el.substring(i + 1).split('\n').map(value).map((row) => [ row ]));
          }
        }
      } else {
        lines = lines.concat(el.split('\n').map(value).map((row) => [ row ]));
      }

      hasNewline = el.lastIndexOf('\n') == el.length - 1;
    }
  }

  return lines.map((line, i) => (
    <pre data-prefix={(i + 1).toString()}>{line}</pre>
  ));
};

const Terminal = ({ input }: { input: string }) => (
  <div className="mockup-code">
    {nodesFromInput(parseInput(input))}
  </div>
);

export default Terminal
