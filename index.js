#!/usr/bin/env node

const readline = require("readline");
const { TexToMml } = require("./typeset/converters");

const main = async () => {
  const rl = readline.createInterface({ input: process.stdin });
  const converter = new TexToMml({});
  await converter.init();

  for await (const line of rl) {
    if (!line.trim()) continue;
    const batch = JSON.parse(line);
    const math = batch.map(({ mathSource }) => mathSource);
    const results = await converter.convert(math, 1000);
    results.forEach(({ math, error }, idx) => {
      const entry = batch[idx];
      if (error) {
        entry.error = [error.message, error.source].join("\n");
      } else if (math) {
        entry.substitution = math.replace(/&nbsp;/g, "&#160;");
      }
    });
    process.stdout.write(
      JSON.stringify(
        batch.map(({ mathSource, substitution, error, ...rest }) => ({
          ...rest,
          substitution: substitution ?? null,
          error: error ?? null,
        })),
      ) + "\n",
    );
  }
};

main();
