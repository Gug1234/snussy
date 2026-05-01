/**
 * @file bodies/Identity/Flavor.tsx
 * @description Identity → Flavor row body.
 *
 * Four free-form text blocks: SFW flavortext, OOC notes, NSFW
 * flavortext, and ERP/NSFW OOC notes. All four autosave on debounce so
 * a 2-4 KB block doesn't fire a server hop on every keystroke. Server
 * caps enforce length:
 *   flavortext        → IDENTITY_MAX_FLAVOR_LEN      (2048)
 *   ooc_notes         → IDENTITY_MAX_OOC_LEN         (1024)
 *   nsfw_flavortext   → IDENTITY_MAX_NSFW_FLAVOR_LEN (4096)
 *   erp_ooc_notes     → IDENTITY_MAX_ERP_OOC_LEN     (4096)
 *
 * The NSFW pair maps to the legacy `nsfwflavortext` and `erpprefs`
 * /datum/preferences vars (see modular/.../prefs_categories/identity.dm
 * setters); the wire keys are namespaced for readability.
 */

import {
  Box,
  Button,
  Input,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

function FlavorBody() {
  const { act } = useBackend();
  const flavor = usePrefField<string>(PREF_KEYS.FLAVORTEXT, '', {
    autosave: true,
  });
  const ooc = usePrefField<string>(PREF_KEYS.OOC_NOTES, '', { autosave: true });
  const nsfwFlavor = usePrefField<string>(PREF_KEYS.NSFW_FLAVORTEXT, '', {
    autosave: true,
  });
  const erpOoc = usePrefField<string>(PREF_KEYS.ERP_OOC_NOTES, '', {
    autosave: true,
  });
  const rumor = usePrefField<string>(PREF_KEYS.RUMOR, '', { autosave: true });
  const gossip = usePrefField<string>(PREF_KEYS.NOBLE_GOSSIP, '', {
    autosave: true,
  });
  const oocImage = usePrefField<string>(PREF_KEYS.OOC_IMAGE_URL, '', {
    autosave: true,
  });
  const nsfwOocImage = usePrefField<string>(PREF_KEYS.NSFW_OOC_IMAGE_URL, '', {
    autosave: true,
  });

  return (
    <Section title="Flavor">
      <Stack vertical fill>
        <Stack.Item>
          <Box mb={0.5}>Flavortext (in-character description)</Box>
          <TextArea
            width="100%"
            height="180px"
            value={flavor.value ?? ''}
            onChange={(val: string) => flavor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>OOC notes</Box>
          <TextArea
            width="100%"
            height="120px"
            value={ooc.value ?? ''}
            onChange={(val: string) => ooc.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Rumor</Box>
          <TextArea
            width="100%"
            height="100px"
            value={rumor.value ?? ''}
            onChange={(val: string) => rumor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Noble gossip (400 char max)</Box>
          <TextArea
            width="100%"
            height="80px"
            value={gossip.value ?? ''}
            onChange={(val: string) => gossip.setValue(val.slice(0, 400))}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>OOC image URL</Box>
          <Input
            fluid
            value={oocImage.value ?? ''}
            onChange={(val: string) => oocImage.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5} color="bad">
            NSFW Flavortext
          </Box>
          <TextArea
            width="100%"
            height="180px"
            value={nsfwFlavor.value ?? ''}
            onChange={(val: string) => nsfwFlavor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5} color="bad">
            NSFW / ERP OOC notes
          </Box>
          <TextArea
            width="100%"
            height="160px"
            value={erpOoc.value ?? ''}
            onChange={(val: string) => erpOoc.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5} color="bad">
            NSFW OOC image URL
          </Box>
          <Input
            fluid
            value={nsfwOocImage.value ?? ''}
            onChange={(val: string) => nsfwOocImage.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="eye"
            onClick={() => act('preview_examine')}
            tooltip="Show an examine panel for your preview body so you can see how your flavor stacks."
          >
            Preview in chat
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'flavor',
  label: 'Flavor',
  component: FlavorBody,
});
