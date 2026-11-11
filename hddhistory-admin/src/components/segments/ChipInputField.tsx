import React from "react";
import { Autocomplete, Chip, TextField } from "@mui/material";

interface Props {
  label: string;
  values: string[];
  onChange: (values: string[]) => void;
  /** Return the normalized chip value, or `null` to reject the entry. */
  transform?: (raw: string) => string | null;
  helperText?: string;
  placeholder?: string;
}

/**
 * Free-entry chip input for criteria that have no fixed option list (country
 * codes, numeric ids): type a value, Enter (or blur) commits it as a chip.
 * `transform` normalizes/validates each entry — invalid text is dropped
 * silently rather than shown as an error, since there is nothing to submit
 * until the operator presses Enter anyway.
 */
const ChipInputField: React.FC<Props> = ({
  label,
  values,
  onChange,
  transform,
  helperText,
  placeholder,
}) => {
  const commit = (raw: (string | string)[]) => {
    const next = raw
      .map((v) => (transform ? transform(v) : v.trim()))
      .filter((v): v is string => Boolean(v));
    onChange(Array.from(new Set(next)));
  };

  return (
    <Autocomplete<string, true, false, true>
      multiple
      freeSolo
      autoSelect
      size="small"
      options={[]}
      value={values}
      onChange={(_, selected) => commit(selected)}
      renderTags={(value, getTagProps) =>
        value.map((option, index) => {
          const { key, ...tagProps } = getTagProps({ index });
          return <Chip size="small" label={option} key={key} {...tagProps} />;
        })
      }
      renderInput={(params) => (
        <TextField {...params} label={label} placeholder={placeholder} helperText={helperText} />
      )}
    />
  );
};

export default ChipInputField;
