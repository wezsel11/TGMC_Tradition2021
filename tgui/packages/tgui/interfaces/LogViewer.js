import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Input, Section, Table } from '../components';
import { Window } from '../layouts';

export const LogViewer = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    categories = [],
    entries = [],
    search,
    total,
    max_shown,
  } = data;
  const [searchText, setSearchText] = useLocalState(context, 'search', search);
  return (
    <Window
      title="Log Viewer"
      width={900}
      height={650}>
      <Window.Content scrollable>
        <Section
          title="Filters"
          buttons={(
            <>
              <Button
                icon="sync"
                content="Refresh"
                onClick={() => act('refresh')} />
              <Button
                content="Show all"
                onClick={() => act('show_all')} />
              <Button
                content="Hide all"
                onClick={() => act('hide_all')} />
            </>
          )}>
          <Box mb={1}>
            {categories.map(category => (
              <Button.Checkbox
                key={category.name}
                checked={category.shown}
                content={category.name}
                onClick={() => act('toggle_category', {
                  category: category.name,
                })} />
            ))}
          </Box>
          <Flex>
            <Flex.Item grow={1}>
              <Input
                fluid
                placeholder="Search..."
                value={searchText}
                onChange={(e, value) => setSearchText(value)}
                onEnter={(e, value) => act('search', { search: value })} />
            </Flex.Item>
            <Flex.Item ml={1}>
              <Button
                icon="search"
                content="Search"
                onClick={() => act('search', { search: searchText })} />
            </Flex.Item>
          </Flex>
        </Section>
        <Section
          title={`Entries (newest first, ${entries.length} of ${total}`
            + ` shown, at most ${max_shown})`}>
          <Table>
            {entries.map((entry, i) => (
              <Table.Row key={i} className="candystripe">
                <Table.Cell collapsing color="label" verticalAlign="top">
                  {entry[0]}
                </Table.Cell>
                <Table.Cell collapsing bold verticalAlign="top" px={1}>
                  {entry[1]}
                </Table.Cell>
                <Table.Cell style={{ 'word-break': 'break-word' }}>
                  {entry[2]}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
