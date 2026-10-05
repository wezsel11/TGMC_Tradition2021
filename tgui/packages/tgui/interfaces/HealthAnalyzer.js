import { round } from 'common/math';
import { useBackend } from '../backend';
import { Box, LabeledList, NoticeBox, Section, Table } from '../components';
import { Window } from '../layouts';

const DAMAGE_TYPES = [
  { name: 'Oxygen', color: 'blue' },
  { name: 'Toxin', color: 'green' },
  { name: 'Burns', color: 'orange' },
  { name: 'Brute', color: 'red' },
];

const AdviceList = props => {
  const { title, entries = [] } = props;
  if (!entries.length) {
    return null;
  }
  return (
    <Section title={title}>
      {entries.map((entry, i) => (
        <Box key={i} mb={0.5}>
          <Box inline bold color="bad">{entry.title}:</Box> {entry.text}
        </Box>
      ))}
    </Section>
  );
};

export const HealthAnalyzer = (props, context) => {
  const { data } = useBackend(context);
  const {
    patient,
    dead,
    health,
    damage = [],
    limbs,
    warnings = [],
    reagents = [],
    unknown_reagents,
    temperature = [],
    blood,
    pulse,
    advice = [],
    contraindications = [],
  } = data;
  return (
    <Window
      title={`Health Analyzer - ${patient}`}
      width={500}
      height={550}>
      <Window.Content scrollable>
        <Section title={patient}>
          <LabeledList>
            <LabeledList.Item label="Overall Status">
              {dead ? (
                <Box bold color="bad">DEAD</Box>
              ) : (
                <Box bold>{health}% healthy</Box>
              )}
            </LabeledList.Item>
            {DAMAGE_TYPES.map((type, i) => (
              <LabeledList.Item key={type.name} label={type.name}>
                <Box color={type.color} bold={damage[i] > 50}>
                  {round(damage[i], 0)}
                </Box>
              </LabeledList.Item>
            ))}
            <LabeledList.Item label="Body Temperature">
              {round(temperature[0], 1)}°C ({round(temperature[1], 1)}°F)
            </LabeledList.Item>
            {!!blood && (
              <LabeledList.Item label="Blood Level">
                <Box inline color={blood.status === 'normal' ? undefined : 'bad'} bold={blood.status !== 'normal'}>
                  {blood.status === 'normal' ? 'Normal' : `Warning: ${blood.status}`}
                  {': '}{round(blood.percent, 0)}% {blood.volume}cl.
                </Box>
                {' '}Type: {blood.type}
              </LabeledList.Item>
            )}
            {!!pulse && (
              <LabeledList.Item label="Pulse">
                <Box color={pulse.bad ? 'bad' : undefined}>
                  {pulse.bpm} bpm.
                </Box>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        {!!limbs && limbs.length > 0 && (
          <Section title="Limbs">
            <Table>
              <Table.Row header>
                <Table.Cell>Limb</Table.Cell>
                <Table.Cell collapsing color="orange">Burn</Table.Cell>
                <Table.Cell collapsing color="red">Brute</Table.Cell>
                <Table.Cell>Status</Table.Cell>
              </Table.Row>
              {limbs.map(limb => (
                <Table.Row key={limb.name} className="candystripe">
                  <Table.Cell>{limb.name}</Table.Cell>
                  {limb.missing ? (
                    <Table.Cell colspan={3} bold color="bad">Missing!</Table.Cell>
                  ) : (
                    <>
                      <Table.Cell collapsing color="orange" bold={limb.burn > 0}>
                        {limb.burn}{limb.untreated_burn ? ' {B}' : ''}
                      </Table.Cell>
                      <Table.Cell collapsing color="red" bold={limb.brute > 0}>
                        {limb.brute}{limb.untreated_brute ? ' {T}' : ''}
                      </Table.Cell>
                      <Table.Cell>
                        {[
                          limb.fracture && 'Fracture',
                          limb.infection && 'Infection',
                          limb.bleeding && 'Bleeding',
                          limb.necrotizing && 'Necrotizing',
                          limb.incision && 'Open surgical incision',
                          limb.advice,
                        ].filter(Boolean).map(text => (
                          <Box key={text} inline mr={1} color="bad" bold>
                            {text}
                          </Box>
                        ))}
                        {!!limb.splinted && <Box inline color="good">Splinted</Box>}
                        {!!limb.stabilized && <Box inline color="good">Stabilized</Box>}
                      </Table.Cell>
                    </>
                  )}
                </Table.Row>
              ))}
            </Table>
            <Box mt={1} color="label">
              Untreated: {'{B}'}=Burns, {'{T}'}=Trauma
            </Box>
          </Section>
        )}
        {warnings.length > 0 && (
          <Section title="Warnings">
            {warnings.map((warning, i) => (
              <Box key={i} color="bad">*{warning}</Box>
            ))}
          </Section>
        )}
        {(reagents.length > 0 || !!unknown_reagents) && (
          <Section title="Reagents">
            {reagents.map(reagent => (
              <Box key={reagent.name} bold color="#9773C4">
                {!!reagent.od && <Box inline color="bad" mr={1}>OD:</Box>}
                {reagent.amount}u {reagent.name}
              </Box>
            ))}
            {!!unknown_reagents && (
              <NoticeBox danger mt={1}>
                Warning: Unknown substance{unknown_reagents > 1 ? 's' : ''} detected in subject's blood.
              </NoticeBox>
            )}
          </Section>
        )}
        <AdviceList title="Medication Advice" entries={advice} />
        <AdviceList title="Contraindications" entries={contraindications} />
      </Window.Content>
    </Window>
  );
};
