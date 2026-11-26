import React, { useRef } from "react";

export function Form() {
  const input = useRef<HTMLInputElement>();
  const count = React.useRef<number>();
  const timer = useRef();

  // Already migrated: left alone
  const div = useRef<HTMLDivElement>(null);

  // Not React's hook: left alone
  const store = cache.useRef();

  return <input ref={input} />;
}
