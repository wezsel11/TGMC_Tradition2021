/**
 * Number input box, as modern TGMC (tgui_input_number).
 */

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Input, Section, Stack } from '../components';
import { Window } from '../layouts';
import { Loader } from './ListInput';

export const NumberInputModal = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    max_value,
    message = '',
    min_value,
    placeholder,
    timeout,
    title,
  } = data;
  const [input, setInput] = useLocalState(
    context, 'input', placeholder === null || placeholder === undefined
      ? '' : String(placeholder));
  const number = parseFloat(input);
  const valid = !isNaN(number);
  const submit = value => {
    if (isNaN(parseFloat(value))) {
      return;
    }
    act('submit', { entry: value });
  };
  const windowHeight = 140
    + (message.length > 30 ? Math.ceil(message.length / 3) : 0);

  return (
    <Window title={title} width={270} height={windowHeight}>
      {timeout !== undefined && <Loader value={timeout} />}
      <Window.Content
        onKeyDown={e => {
          if (e.keyCode === 27) {
            act('cancel');
          }
        }}>
        <Section fill>
          <Stack fill vertical>
            <Stack.Item grow>
              <Box color="label">{message}</Box>
            </Stack.Item>
            <Stack.Item>
              <Stack>
                {min_value !== null && min_value !== undefined && (
                  <Stack.Item>
                    <Button
                      icon="angle-double-left"
                      tooltip={'Minimum: ' + min_value}
                      onClick={() => setInput(String(min_value))} />
                  </Stack.Item>
                )}
                <Stack.Item grow>
                  <Input
                    autoFocus
                    fluid
                    value={input}
                    onInput={(e, value) => setInput(value)}
                    onEnter={(e, value) => submit(value)} />
                </Stack.Item>
                {max_value !== null && max_value !== undefined && (
                  <Stack.Item>
                    <Button
                      icon="angle-double-right"
                      tooltip={'Maximum: ' + max_value}
                      onClick={() => setInput(String(max_value))} />
                  </Stack.Item>
                )}
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Stack textAlign="center">
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color="bad"
                    lineHeight={2}
                    content="Cancel"
                    onClick={() => act('cancel')} />
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color="good"
                    lineHeight={2}
                    content="Submit"
                    disabled={!valid}
                    onClick={() => submit(input)} />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
