import React, { useRef } from "react";

export function Form() {
  const input = useRef<HTMLInputElement>(undefined);
  const count = React.useRef<number>(undefined);
  const timer = useRef(undefined);

  // Already migrated: left alone
  const div = useRef<HTMLDivElement>(null);

  // Not React's hook: left alone
  const store = cache.useRef();

  return <input ref={input} />;
}
