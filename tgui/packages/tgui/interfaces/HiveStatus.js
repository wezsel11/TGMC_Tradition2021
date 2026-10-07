import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section, Table } from '../components';
import { Window } from '../layouts';

const healthColor = (health, max) => {
  const ratio = health / max;
  if (ratio < 0.33) {
    return 'bad';
  }
  if (ratio < 0.66) {
    return 'average';
  }
  return 'good';
};

export const HiveStatus = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    hive_name,
    can_watch,
    xenos = [],
    total,
    tiers = [],
    larva,
    queen,
    hivemind,
    burrowed,
    silos = [],
  } = data;
  return (
    <Window
      title={`Hive Status - ${hive_name}`}
      width={650}
      height={650}>
      <Window.Content scrollable>
        <Section title={`Total Living Sisters: ${total}`}>
          <LabeledList>
            {tiers.map(tier => (
              <LabeledList.Item key={tier.name} label={tier.name}>
                {tier.limit !== undefined
                  ? `${tier.count}/${tier.limit}`
                  : tier.count}
                {tier.castes.map(caste => (
                  <Box key={caste.name} inline ml={1} color="label">
                    | {caste.name}: {caste.count}
                  </Box>
                ))}
              </LabeledList.Item>
            ))}
            <LabeledList.Item label="Larvas">{larva}</LabeledList.Item>
            <LabeledList.Item label="Queen">{queen}</LabeledList.Item>
            <LabeledList.Item label="Hivemind">
              {hivemind ? 'Active' : 'Inactive'}
            </LabeledList.Item>
            {burrowed !== null && (
              <LabeledList.Item label="Burrowed Larva">
                {burrowed}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        <Section title="Sisters">
          <Table>
            <Table.Row header>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell collapsing>Health</Table.Cell>
              <Table.Cell>Location</Table.Cell>
            </Table.Row>
            {xenos.map(xeno => (
              <Table.Row key={xeno.ref} className="candystripe">
                <Table.Cell>
                  {xeno.leader && <Box inline bold mr={1}>(-L-)</Box>}
                  {can_watch ? (
                    <Button
                      color="transparent"
                      content={xeno.name}
                      onClick={() => act('watch', { xeno: xeno.ref })} />
                  ) : xeno.name}
                  {xeno.ssd && <Box inline italic ml={1} color="label">(SSD)</Box>}
                </Table.Cell>
                <Table.Cell collapsing>
                  <ProgressBar
                    width="120px"
                    value={Math.max(xeno.health, 0) / xeno.max_health}
                    color={healthColor(xeno.health, xeno.max_health)}>
                    {xeno.health}/{xeno.max_health}
                  </ProgressBar>
                </Table.Cell>
                <Table.Cell>{xeno.location}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
        <Section title="Resin Silos">
          {silos.length === 0 && <Box color="label">None</Box>}
          <Table>
            {silos.map((silo, i) => (
              <Table.Row key={i} className="candystripe">
                <Table.Cell>{silo.name}</Table.Cell>
                <Table.Cell collapsing>
                  <ProgressBar
                    width="120px"
                    value={silo.health / silo.max_health}
                    color={healthColor(silo.health, silo.max_health)}>
                    {silo.health}/{silo.max_health}
                  </ProgressBar>
                </Table.Cell>
                <Table.Cell>{silo.location}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
