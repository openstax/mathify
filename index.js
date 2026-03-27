const readline = require("readline");
const { convertMathML } = require("./typeset/mjnode");

const logger = new console.Console(process.stderr);

const main = async () => {
  const rl = readline.createInterface({ input: process.stdin });

  for await (const line of rl) {
    if (!line.trim()) continue;
    const batch = JSON.parse(line).map((record) => ({
      ...record,
      mathSource: record.math,
    }));
    await convertMathML(
      logger,
      batch,
      "mathml",
      1000,
      (pairs) => {
        pairs.forEach(([message, entry]) => {
          entry.error = message;
        });
      },
      {},
    );
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
