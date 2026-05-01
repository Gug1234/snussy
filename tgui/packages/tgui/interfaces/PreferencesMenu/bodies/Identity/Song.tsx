/**
 * @file bodies/Identity/Song.tsx
 * @description Identity → Song row body (I9).
 *
 * Combat-music track dropdown + preview button + optional custom link
 * input. Track options come from ui_static_data (`combat_music_options`)
 * which mirrors GLOB.cmode_tracks_by_type. The preview action pipes a
 * short audio sample to the prefs owner via SEND_SOUND on the lobby
 * channel.
 */

import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function SongBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const track = usePrefField<string>(PREF_KEYS.COMBAT_MUSIC_TRACK, '');
  // Legacy custom-link field — repurposes `song_artist` as a free-form
  // URL slot for a player-supplied BYOND-hostable music file.
  const customLink = usePrefField<string>(PREF_KEYS.SONG_ARTIST, '', {
    autosave: true,
  });

  const options = (data.combat_music_options ?? []) as {
    id: string;
    label: string;
    shortname?: string;
    credits?: string;
  }[];
  const labels = options.map((o) => o.label);
  const current =
    options.find((o) => o.id === track.value)?.label ?? labels[0] ?? '';
  const currentTrack = options.find((o) => o.label === current);

  return (
    <Section title="Combat Music">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Combat music track</Box>
          <Dropdown
            options={labels}
            selected={current}
            onSelected={(label: string) => {
              const match = options.find((o) => o.label === label);
              if (match) {
                track.setValue(match.id);
              }
            }}
          />
        </Stack.Item>
        {currentTrack?.credits && (
          <Stack.Item>
            <Box italic color="label">
              {currentTrack.credits}
            </Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Button
            icon="play"
            disabled={!currentTrack || currentTrack.id === ''}
            onClick={() =>
              currentTrack &&
              act('preview_combat_music', { track: currentTrack.id })
            }
          >
            Preview
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Custom music link (optional)</Box>
          <Input
            fluid
            value={customLink.value ?? ''}
            onChange={(val: string) => customLink.setValue(val)}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'song',
  label: 'Song',
  component: SongBody,
});
