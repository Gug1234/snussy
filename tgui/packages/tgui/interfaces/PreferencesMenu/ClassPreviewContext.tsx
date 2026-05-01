import { createContext, useContext } from 'react';

interface ClassPreviewContextValue {
  classPreviewTitle: string | null;
  setClassPreviewTitle: (title: string | null) => void;
}

const ClassPreviewContext = createContext<ClassPreviewContextValue>({
  classPreviewTitle: null,
  setClassPreviewTitle: () => undefined,
});

export const ClassPreviewProvider = ClassPreviewContext.Provider;

export function useClassPreview(): ClassPreviewContextValue {
  return useContext(ClassPreviewContext);
}
