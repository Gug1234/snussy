/**
 * @file bodies/Identity/Voice.tsx
 * @description Identity → Voice row body.
 *
 * Voice + bark configuration. The dropdowns submit on selection
 * (non-autosave); colour/text fields autosave. Voice and Bark
 * preview buttons round-trip to the server via the shared widgets;
 * server handlers for `preview_voice`/`preview_bark` land alongside
 * this category in Step 14.
 */

import {
  Box,
  Dropdown,
  Input,
  Section,
  Slider,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { BarkPreviewButton, VoicePreviewButton } from '../../widgets';
import { usePrefField } from '../usePrefField';

const VOICE_TYPES = ['Masculine', 'Feminine', 'Andro'];
// Fallback list used only before the server emits
// `voice_pack_options`. The runtime list comes from GLOB.voice_packs_list
// keys via ui_static_data; server validator caps string length at 64.
const FALLBACK_VOICE_PACKS = ['Default'];

function VoiceBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const serverVoicePacks = data.voice_pack_options;
  const voicePackOptions =
    serverVoicePacks && serverVoicePacks.length > 0
      ? (serverVoicePacks as string[])
      : FALLBACK_VOICE_PACKS;
  const voicePack = usePrefField<string>(PREF_KEYS.VOICE_PACK, 'Default');
  const voiceType = usePrefField<string>(PREF_KEYS.VOICE_TYPE, 'Masculine');
  const voiceColor = usePrefField<string>(PREF_KEYS.VOICE_COLOR, '#a0a0a0');
  const voicePitch = usePrefField<number>(PREF_KEYS.VOICE_PITCH_X100, 100);
  const barkPitch = usePrefField<number>(PREF_KEYS.BARK_PITCH_X100, 100);
  const barkVariance = usePrefField<number>(PREF_KEYS.BARK_VARIANCE_X100, 20);
  const barkId = usePrefField<string>(PREF_KEYS.BARK_ID, 'mutedc3', {
    autosave: true,
  });
  const barkSpeed = usePrefField<number>(PREF_KEYS.BARK_SPEED, 4);
  const hearBarks = usePrefField<boolean>(PREF_KEYS.HEAR_BARKS, true);

  return (
    <Section title="Voice">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Voice pack</Box>
          <Dropdown
            options={voicePackOptions}
            selected={voicePack.value ?? 'Default'}
            onSelected={(val: string) => voicePack.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Voice type</Box>
          <Dropdown
            options={VOICE_TYPES}
            selected={voiceType.value ?? 'Masculine'}
            onSelected={(val: string) => voiceType.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Voice color</Box>
          <Input
            value={voiceColor.value ?? '#a0a0a0'}
            onChange={(val: string) => voiceColor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Voice pitch</Box>
          <Slider
            minValue={50}
            maxValue={150}
            step={5}
            value={voicePitch.value ?? 100}
            onChange={(_, val: number) => voicePitch.setValue(val)}
            unit="%"
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Bark sound</Box>
          <Input
            fluid
            value={barkId.value ?? 'mutedc3'}
            onChange={(val: string) => barkId.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Bark speed</Box>
          <Slider
            minValue={1}
            maxValue={10}
            step={1}
            value={barkSpeed.value ?? 4}
            onChange={(_, val: number) => barkSpeed.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Bark pitch</Box>
          <Slider
            minValue={10}
            maxValue={400}
            step={5}
            value={barkPitch.value ?? 100}
            onChange={(_, val: number) => barkPitch.setValue(val)}
            unit="%"
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Bark variance</Box>
          <Slider
            minValue={0}
            maxValue={200}
            step={5}
            value={barkVariance.value ?? 20}
            onChange={(_, val: number) => barkVariance.setValue(val)}
            unit="%"
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Hear barks</Box>
          <Dropdown
            options={['On', 'Off']}
            selected={hearBarks.value ? 'On' : 'Off'}
            onSelected={(val: string) => hearBarks.setValue(val === 'On')}
          />
        </Stack.Item>
        <Stack.Item>
          <VoicePreviewButton voiceId={voicePack.value} />{' '}
          <BarkPreviewButton barkId={barkId.value} />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'voice',
  label: 'Voice',
  component: VoiceBody,
});
