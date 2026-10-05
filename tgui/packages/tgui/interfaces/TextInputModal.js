/**
 * Text input box, as modern TGMC (tgui_input_text).
 */

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Input, Section, Stack, TextArea } from '../components';
import { Window } from '../layouts';
import { Loader } from './ListInput';

export const TextInputModal = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    max_length,
    message = '',
    multiline,
    placeholder = '',
    timeout,
    title,
  } = data;
  const [input, setInput] = useLocalState(context, 'input', placeholder || '');
  const tooLong = !!max_length && input.length > max_length;
  const submit = value => {
    if (max_length && value.length > max_length) {
      return;
    }
    act('submit', { entry: value });
  };
  // Dynamically resize the window for long messages and multiline input
  const windowHeight = 130
    + (message.length > 30 ? Math.ceil(message.length / 4) : 0)
    + (multiline ? 100 : 0);

  return (
    <Window title={title} width={325} height={windowHeight}>
      {timeout !== undefined && <Loader value={timeout} />}
      <Window.Content
        onKeyDown={e => {
          if (e.keyCode === 27) {
            act('cancel');
          }
        }}>
        <Section fill>
          <Stack fill vertical>
            <Stack.Item>
              <Box color="label">{message}</Box>
            </Stack.Item>
            <Stack.Item grow>
              {multiline ? (
                <TextArea
                  autoFocus
                  fluid
                  height="100%"
                  value={input}
                  onInput={(e, value) => setInput(value)} />
              ) : (
                <Input
                  autoFocus
                  fluid
                  value={input}
                  onInput={(e, value) => setInput(value)}
                  onEnter={(e, value) => submit(value)} />
              )}
            </Stack.Item>
            {!!max_length && (
              <Stack.Item>
                <Box color={tooLong ? 'bad' : 'label'} textAlign="right">
                  {input.length}/{max_length}
                </Box>
              </Stack.Item>
            )}
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
                    disabled={tooLong}
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
