import { useEffect, useState } from 'react';
import { Box, Button, Input, Stack } from 'tgui-core/components';

export type ErpPreviewPerspective =
  | 'intimate-wearer'
  | 'intimate-bystander'
  | 'sex-giving'
  | 'sex-receiving';

export type ErpPreviewProfile = {
  userName: string;
  userThey: string;
  userThem: string;
  userTheir: string;
  targetPreset: string;
  targetName: string;
  targetThey: string;
  targetThem: string;
  targetTheir: string;
  penisType: string;
  sheath: string;
  sizeAdj: string;
  cockSize: string;
  vagAdj: string;
  vagType: string;
  cupAdj: string;
  cupSize: string;
  breastType: string;
  taur: string;
  genitalDesc: string;
  userCock: string;
  userShaft: string;
  userSize: string;
  userVag: string;
  userCupSize: string;
  userBreastType: string;
  targetCock: string;
  targetShaft: string;
  targetSize: string;
  targetVag: string;
  targetCupSize: string;
  targetBreastType: string;
  targetTaur: string;
  force: string;
  plug: string;
};

export type ErpPreviewProfileData = Partial<ErpPreviewProfile> & {
  user_name?: string;
  user_they?: string;
  user_them?: string;
  user_their?: string;
  target_preset?: string;
  target_name?: string;
  target_they?: string;
  target_them?: string;
  target_their?: string;
  penis_type?: string;
  size_adj?: string;
  cock_size?: string;
  vag_adj?: string;
  vag_type?: string;
  cup_adj?: string;
  cup_size?: string;
  breast_type?: string;
  genital_desc?: string;
  user_cock?: string;
  user_shaft?: string;
  user_size?: string;
  user_vag?: string;
  user_cup_size?: string;
  user_breast_type?: string;
  target_cock?: string;
  target_shaft?: string;
  target_size?: string;
  target_vag?: string;
  target_cup_size?: string;
  target_breast_type?: string;
  target_taur?: string;
};

export type CustomAnatomyTokenData = Partial<{
  cock: string;
  shaft: string;
  size: string;
  vag: string;
  cup_size: string;
  breast_type: string;
}>;

export type PreviewOptionsAct = (
  action: string,
  payload?: Record<string, string>,
) => void;

type TargetPresetId = 'john' | 'jane' | 'jean';

const TARGET_PRESETS: Record<
  TargetPresetId,
  Pick<
    ErpPreviewProfile,
    'targetName' | 'targetThey' | 'targetThem' | 'targetTheir'
  >
> = {
  john: {
    targetName: 'John Ratwood',
    targetThey: 'he',
    targetThem: 'him',
    targetTheir: 'his',
  },
  jane: {
    targetName: 'Jane Ratwood',
    targetThey: 'she',
    targetThem: 'her',
    targetTheir: 'her',
  },
  jean: {
    targetName: 'Jean Ratwood',
    targetThey: 'they',
    targetThem: 'them',
    targetTheir: 'their',
  },
};

const TARGET_ANATOMY_OPTIONS: Record<string, string[]> = {
  targetCock: ['barbed cock', 'knotted cock', 'equine cock', 'tapered cock'],
  targetShaft: ['barbed shaft', 'knotted shaft', 'equine shaft', 'plain shaft'],
  targetSize: ['modest', 'impressive', 'massive', 'obscene'],
  targetVag: ['smooth slit', 'furred slit', 'spaded cunt', 'cloacal vent'],
  targetCupSize: ['small', 'modest', 'generous', 'heavy'],
  targetBreastType: [
    'soft pair of breasts',
    'perky pair of breasts',
    'heavy breasts',
    'flat chest',
  ],
  targetTaur: ['none', 'taur body', 'lamia tail', 'arachnid abdomen'],
  plug: ['plug', 'beads', 'sounding rod', 'none'],
  force: ['gently', 'firmly', 'roughly', 'desperately'],
};

const DATA_TO_PROFILE_KEYS: Partial<
  Record<keyof ErpPreviewProfileData, keyof ErpPreviewProfile>
> = {
  user_name: 'userName',
  user_they: 'userThey',
  user_them: 'userThem',
  user_their: 'userTheir',
  target_preset: 'targetPreset',
  target_name: 'targetName',
  target_they: 'targetThey',
  target_them: 'targetThem',
  target_their: 'targetTheir',
  penis_type: 'penisType',
  size_adj: 'sizeAdj',
  cock_size: 'cockSize',
  vag_adj: 'vagAdj',
  vag_type: 'vagType',
  cup_adj: 'cupAdj',
  cup_size: 'cupSize',
  breast_type: 'breastType',
  genital_desc: 'genitalDesc',
  user_cock: 'userCock',
  user_shaft: 'userShaft',
  user_size: 'userSize',
  user_vag: 'userVag',
  user_cup_size: 'userCupSize',
  user_breast_type: 'userBreastType',
  target_cock: 'targetCock',
  target_shaft: 'targetShaft',
  target_size: 'targetSize',
  target_vag: 'targetVag',
  target_cup_size: 'targetCupSize',
  target_breast_type: 'targetBreastType',
  target_taur: 'targetTaur',
};

export function createDefaultErpPreviewProfile(): ErpPreviewProfile {
  return {
    userName: 'Wearer',
    userThey: 'they',
    userThem: 'them',
    userTheir: 'their',
    targetPreset: 'john',
    targetName: 'John Ratwood',
    targetThey: 'he',
    targetThem: 'him',
    targetTheir: 'his',
    penisType: 'knotted cock',
    sheath: 'sheath',
    sizeAdj: 'heavy',
    cockSize: 'thick, aching cock',
    vagAdj: 'slick',
    vagType: 'furred cunt',
    cupAdj: 'generous',
    cupSize: 'generous breasts',
    breastType: 'soft pair of breasts',
    taur: 'taur body',
    genitalDesc: 'aroused body',
    userCock: 'knotted cock',
    userShaft: 'knotted shaft',
    userSize: 'impressive',
    userVag: 'delicate slit',
    userCupSize: 'plump',
    userBreastType: 'perky pair of breasts',
    targetCock: 'barbed cock',
    targetShaft: 'barbed shaft',
    targetSize: 'modest',
    targetVag: 'glistening slit',
    targetCupSize: 'ample',
    targetBreastType: 'heavy breasts',
    targetTaur: 'none',
    force: 'firmly',
    plug: 'plug',
  };
}

export function normalizeErpPreviewProfile(
  profile?: ErpPreviewProfileData,
): ErpPreviewProfile {
  const normalized = createDefaultErpPreviewProfile();
  if (!profile) {
    return normalized;
  }
  for (const [rawKey, rawValue] of Object.entries(profile)) {
    if (typeof rawValue !== 'string') {
      continue;
    }
    const key =
      DATA_TO_PROFILE_KEYS[rawKey as keyof ErpPreviewProfileData] ||
      (rawKey as keyof ErpPreviewProfile);
    if (key in normalized) {
      normalized[key] = rawValue;
    }
  }
  return normalized;
}

export function applyTargetPresetToPreviewProfile(
  profile: ErpPreviewProfile,
  preset: string,
): ErpPreviewProfile {
  const targetPreset = (preset in TARGET_PRESETS ? preset : 'john') as
    | 'john'
    | 'jane'
    | 'jean';
  return {
    ...profile,
    targetPreset,
    ...TARGET_PRESETS[targetPreset],
  };
}

export function resolveErpPreviewTokens(
  text: string,
  perspective: ErpPreviewPerspective,
  profileData?: ErpPreviewProfileData,
  anatomyTokens?: CustomAnatomyTokenData,
): string {
  const profile = applyCustomAnatomyTokensToPreviewProfile(
    normalizeErpPreviewProfile(profileData),
    anatomyTokens,
    perspective,
  );
  const userIsYou =
    perspective === 'intimate-wearer' || perspective === 'sex-giving';
  const targetIsYou = perspective === 'sex-receiving';
  const resolved = text
    .replace(
      /\[USERPOS\]/g,
      userIsYou ? 'your' : withNamePossessive(profile.userName),
    )
    .replace(/\[USER\]/g, userIsYou ? 'you' : profile.userName)
    .replace(/\[TARGET\]/g, targetIsYou ? 'You' : profile.targetName)
    .replace(/\[THEY\]/g, userIsYou ? 'you' : profile.userThey)
    .replace(/\[THEM\]/g, userIsYou ? 'you' : profile.userThem)
    .replace(
      /\[THEIR_CAP\]/g,
      userIsYou ? 'Your' : capitalize(profile.userTheir),
    )
    .replace(/\[THEIR\]/g, userIsYou ? 'your' : profile.userTheir)
    .replace(/\[TTHEY\]/g, targetIsYou ? 'you' : profile.targetThey)
    .replace(/\[TTHEM\]/g, targetIsYou ? 'you' : profile.targetThem)
    .replace(/\[TTHEIR\]/g, targetIsYou ? 'your' : profile.targetTheir)
    .replace(/\[PENIS_TYPE\]/g, profile.penisType)
    .replace(/\[SHEATH\]/g, profile.sheath)
    .replace(/\[SIZEADJ\]/g, profile.sizeAdj)
    .replace(/\[COCKSIZE\]/g, profile.cockSize)
    .replace(/\[VAGADJ\]/g, profile.vagAdj)
    .replace(/\[VAGTYPE\]/g, profile.vagType)
    .replace(/\[CUPADJ\]/g, profile.cupAdj)
    .replace(/\[CUPSIZE\]/g, profile.cupSize)
    .replace(/\[BREASTTYPE\]/g, profile.breastType)
    .replace(/\[TAUR\]/g, profile.taur)
    .replace(/\[GENITAL_DESC\]/g, profile.genitalDesc)
    .replace(
      /\[UCOCK\]/g,
      withPossessive(profile.userCock, profile.userTheir, userIsYou),
    )
    .replace(
      /\[TCOCK\]/g,
      withPossessive(profile.targetCock, profile.targetTheir, targetIsYou),
    )
    .replace(
      /\[USHAFT\]/g,
      withPossessive(profile.userShaft, profile.userTheir, userIsYou),
    )
    .replace(
      /\[TSHAFT\]/g,
      withPossessive(profile.targetShaft, profile.targetTheir, targetIsYou),
    )
    .replace(
      /\[USIZE\]/g,
      withPossessive(profile.userSize, profile.userTheir, userIsYou),
    )
    .replace(
      /\[TSIZE\]/g,
      withPossessive(profile.targetSize, profile.targetTheir, targetIsYou),
    )
    .replace(
      /\[UVAG\]/g,
      withPossessive(profile.userVag, profile.userTheir, userIsYou),
    )
    .replace(
      /\[TVAG\]/g,
      withPossessive(profile.targetVag, profile.targetTheir, targetIsYou),
    )
    .replace(
      /\[UCUPSIZE\]/g,
      withPossessive(profile.userCupSize, profile.userTheir, userIsYou),
    )
    .replace(
      /\[TCUPSIZE\]/g,
      withPossessive(profile.targetCupSize, profile.targetTheir, targetIsYou),
    )
    .replace(
      /\[UBREASTTYPE\]/g,
      withPossessive(profile.userBreastType, profile.userTheir, userIsYou),
    )
    .replace(
      /\[TBREASTTYPE\]/g,
      withPossessive(
        profile.targetBreastType,
        profile.targetTheir,
        targetIsYou,
      ),
    )
    .replace(/\[FORCE\]/g, profile.force)
    .replace(/\[PLUG\]/g, profile.plug);
  return capitalizeInitialSecondPerson(
    normalizeSecondPersonPreviewGrammar(resolved),
  );
}

export function ErpPreviewOptionsButton({
  profile,
  anatomyTokens,
  act,
}: {
  profile?: ErpPreviewProfileData;
  anatomyTokens?: CustomAnatomyTokenData;
  act: PreviewOptionsAct;
}) {
  const [open, setOpen] = useState(false);
  const normalized = normalizeErpPreviewProfile(profile);
  const normalizedAnatomyTokens = normalizeCustomAnatomyTokens(anatomyTokens);

  function setToken(key: keyof ErpPreviewProfile, value: string) {
    act('set_preview_token', { key: toServerKey(key), value });
  }

  function setAnatomyToken(key: keyof CustomAnatomyTokenData, value: string) {
    const trimmed = value.trim();
    if (!trimmed) {
      act('clear_anatomy_token', { key });
      return;
    }
    act('set_anatomy_token', { key, value: trimmed });
  }

  function setTargetPreset(preset: string) {
    act('set_preview_target_preset', { preset });
  }

  return (
    <Box mt={0.75}>
      <Button compact icon="cog" selected={open} onClick={() => setOpen(!open)}>
        Preview Options
      </Button>
      {open && (
        <Box
          mt={0.5}
          p={0.75}
          style={{
            background: 'rgba(255,255,255,0.045)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: '3px',
          }}
        >
          <Stack vertical>
            <Stack.Item>
              <Stack align="center">
                <Stack.Item grow>
                  <Box fontSize="10px" opacity={0.65}>
                    Saved per character slot. Live previews use this profile
                    until you change it or refresh features.
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    compact
                    icon="sync"
                    onClick={() => act('refresh_preview_tokens')}
                  >
                    Refresh Features
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Box bold fontSize="11px" mb={0.25}>
                Shared Anatomy
              </Box>
              <Stack wrap>
                {(
                  [
                    ['cock', 'Cock'],
                    ['shaft', 'Shaft'],
                    ['size', 'Size'],
                    ['vag', 'Vag'],
                    ['cup_size', 'Cup'],
                    ['breast_type', 'Breasts'],
                  ] as const
                ).map(([key, label]) => (
                  <TextTokenField
                    key={key}
                    label={label}
                    value={normalizedAnatomyTokens[key] ?? ''}
                    placeholder="Feature default"
                    onChange={(value) => setAnatomyToken(key, value)}
                  />
                ))}
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Box bold fontSize="11px" mb={0.25}>
                User
              </Box>
              <Stack wrap>
                <TextTokenField
                  label="Name"
                  value={normalized.userName}
                  onChange={(value) => setToken('userName', value)}
                />
                <TextTokenField
                  label="They"
                  value={normalized.userThey}
                  onChange={(value) => setToken('userThey', value)}
                />
                <TextTokenField
                  label="Them"
                  value={normalized.userThem}
                  onChange={(value) => setToken('userThem', value)}
                />
                <TextTokenField
                  label="Their"
                  value={normalized.userTheir}
                  onChange={(value) => setToken('userTheir', value)}
                />
                <TextTokenField
                  label="Penis"
                  value={normalized.penisType}
                  onChange={(value) => setToken('penisType', value)}
                />
                <TextTokenField
                  label="Sheath"
                  value={normalized.sheath}
                  onChange={(value) => setToken('sheath', value)}
                />
                <TextTokenField
                  label="Cock Size"
                  value={normalized.cockSize}
                  onChange={(value) => setToken('cockSize', value)}
                />
                <TextTokenField
                  label="Vag Type"
                  value={normalized.vagType}
                  onChange={(value) => setToken('vagType', value)}
                />
                <TextTokenField
                  label="Cup"
                  value={normalized.cupSize}
                  onChange={(value) => setToken('cupSize', value)}
                />
                <TextTokenField
                  label="Breasts"
                  value={normalized.breastType}
                  onChange={(value) => setToken('breastType', value)}
                />
                <TextTokenField
                  label="Taur"
                  value={normalized.taur}
                  onChange={(value) => setToken('taur', value)}
                />
                <TextTokenField
                  label="Genitals"
                  value={normalized.genitalDesc}
                  onChange={(value) => setToken('genitalDesc', value)}
                />
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Box bold fontSize="11px" mb={0.25}>
                Target
              </Box>
              <Stack wrap>
                <SelectTokenField
                  label="Name"
                  value={normalized.targetPreset}
                  options={[
                    ['john', 'John Ratwood'],
                    ['jane', 'Jane Ratwood'],
                    ['jean', 'Jean Ratwood'],
                  ]}
                  onChange={setTargetPreset}
                />
                {(
                  [
                    ['targetCock', 'Cock'],
                    ['targetShaft', 'Shaft'],
                    ['targetSize', 'Size'],
                    ['targetVag', 'Vag'],
                    ['targetCupSize', 'Cup'],
                    ['targetBreastType', 'Breasts'],
                    ['targetTaur', 'Taur'],
                    ['plug', 'Plug'],
                    ['force', 'Force'],
                  ] as const
                ).map(([key, label]) => (
                  <SelectTokenField
                    key={key}
                    label={label}
                    value={normalized[key]}
                    options={TARGET_ANATOMY_OPTIONS[key].map((value) => [
                      value,
                      value,
                    ])}
                    onChange={(value) => setToken(key, value)}
                  />
                ))}
              </Stack>
            </Stack.Item>
          </Stack>
        </Box>
      )}
    </Box>
  );
}

function TextTokenField({
  label,
  value,
  placeholder,
  onChange,
}: {
  label: string;
  value: string;
  placeholder?: string;
  onChange: (value: string) => void;
}) {
  const [draft, setDraft] = useState(value);
  useEffect(() => setDraft(value), [value]);
  return (
    <Stack.Item width="118px" mr={0.5} mb={0.5}>
      <Box fontSize="9px" opacity={0.6} mb={0.25}>
        {label}
      </Box>
      <Input
        fluid
        value={draft}
        placeholder={placeholder}
        onChange={setDraft}
        onBlur={() => onChange(draft)}
      />
    </Stack.Item>
  );
}

function SelectTokenField({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: [string, string][];
  onChange: (value: string) => void;
}) {
  return (
    <Stack.Item width="132px" mr={0.5} mb={0.5}>
      <Box fontSize="9px" opacity={0.6} mb={0.25}>
        {label}
      </Box>
      <select
        value={value}
        onChange={(event) => onChange(event.currentTarget.value)}
        style={{
          width: '100%',
          padding: '4px',
          background: 'rgba(0,0,0,0.5)',
          color: '#ddd',
          border: '1px solid rgba(255,255,255,0.2)',
          borderRadius: '3px',
          fontSize: '11px',
        }}
      >
        {options.map(([optionValue, label]) => (
          <option key={optionValue} value={optionValue}>
            {label}
          </option>
        ))}
      </select>
    </Stack.Item>
  );
}

function withPossessive(
  text: string,
  thirdPersonPossessive: string,
  secondPerson: boolean,
): string {
  const trimmed = text.trim();
  if (!trimmed || trimmed === 'none') {
    return trimmed;
  }
  return `${secondPerson ? 'your' : thirdPersonPossessive} ${trimmed}`;
}

function normalizeCustomAnatomyTokens(
  tokens?: CustomAnatomyTokenData,
): CustomAnatomyTokenData {
  const normalized: CustomAnatomyTokenData = {};
  if (!tokens) {
    return normalized;
  }
  for (const key of [
    'cock',
    'shaft',
    'size',
    'vag',
    'cup_size',
    'breast_type',
  ] as const) {
    const value = tokens[key];
    if (typeof value === 'string' && value.trim()) {
      normalized[key] = value.trim();
    }
  }
  return normalized;
}

function applyCustomAnatomyTokensToPreviewProfile(
  profile: ErpPreviewProfile,
  tokens: CustomAnatomyTokenData | undefined,
  perspective: ErpPreviewPerspective,
): ErpPreviewProfile {
  const anatomy = normalizeCustomAnatomyTokens(tokens);
  const userIsYou =
    perspective === 'intimate-wearer' || perspective === 'sex-giving';
  const targetIsYou = perspective === 'sex-receiving';

  return {
    ...profile,
    penisType: anatomy.cock ?? profile.penisType,
    vagType: anatomy.vag ?? profile.vagType,
    cupSize: anatomy.cup_size ?? profile.cupSize,
    breastType: anatomy.breast_type ?? profile.breastType,
    userCock: userIsYou ? (anatomy.cock ?? profile.userCock) : profile.userCock,
    userShaft: userIsYou
      ? (anatomy.shaft ?? profile.userShaft)
      : profile.userShaft,
    userSize: userIsYou ? (anatomy.size ?? profile.userSize) : profile.userSize,
    userVag: userIsYou ? (anatomy.vag ?? profile.userVag) : profile.userVag,
    userCupSize: userIsYou
      ? (anatomy.cup_size ?? profile.userCupSize)
      : profile.userCupSize,
    userBreastType: userIsYou
      ? (anatomy.breast_type ?? profile.userBreastType)
      : profile.userBreastType,
    targetCock: targetIsYou
      ? (anatomy.cock ?? profile.targetCock)
      : profile.targetCock,
    targetShaft: targetIsYou
      ? (anatomy.shaft ?? profile.targetShaft)
      : profile.targetShaft,
    targetSize: targetIsYou
      ? (anatomy.size ?? profile.targetSize)
      : profile.targetSize,
    targetVag: targetIsYou
      ? (anatomy.vag ?? profile.targetVag)
      : profile.targetVag,
    targetCupSize: targetIsYou
      ? (anatomy.cup_size ?? profile.targetCupSize)
      : profile.targetCupSize,
    targetBreastType: targetIsYou
      ? (anatomy.breast_type ?? profile.targetBreastType)
      : profile.targetBreastType,
  };
}

function withNamePossessive(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) {
    return "someone's";
  }
  return `${trimmed}'s`;
}

function capitalize(text: string): string {
  if (!text) {
    return text;
  }
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function normalizeSecondPersonPreviewGrammar(text: string): string {
  const replacements: Record<string, string> = {
    adjusts: 'adjust',
    bites: 'bite',
    freezes: 'freeze',
    goes: 'go',
    grabs: 'grab',
    guides: 'guide',
    hisses: 'hiss',
    keeps: 'keep',
    lets: 'let',
    moves: 'move',
    passes: 'pass',
    saunters: 'saunter',
    shifts: 'shift',
    shivers: 'shiver',
    staggers: 'stagger',
    stops: 'stop',
    strides: 'stride',
    takes: 'take',
    tenses: 'tense',
    trembles: 'tremble',
    walks: 'walk',
  };
  return text.replace(
    /\b(You|you) ([a-z]+)\b/g,
    (match, pronoun: string, verb: string) => {
      return replacements[verb] ? `${pronoun} ${replacements[verb]}` : match;
    },
  );
}

function capitalizeInitialSecondPerson(text: string): string {
  if (text.startsWith('you ')) {
    return `You ${text.slice(4)}`;
  }
  return text;
}

function toServerKey(key: keyof ErpPreviewProfile): string {
  return key.replace(/[A-Z]/g, (match) => `_${match.toLowerCase()}`);
}
