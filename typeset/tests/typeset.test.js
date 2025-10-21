const path = require('node:path')
const fs = require('fs')
const { createHash } = require('crypto')

const { execSync } = require('node:child_process')
const startPath = path.join(__dirname, '..', 'start.js')

function getHashFile (fpath) {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256')
    const reader = fs.createReadStream(fpath).setEncoding('utf8')
    reader.on('data', chunk => hash.update(chunk))
    reader.on('error', err => reject(err))
    reader.on('end', () => {
      resolve(hash.digest('hex'))
    })
  })
}

test('tex-mml-svg snapshot', async () => {
  const inputPath = path.join(__dirname, 'seed', 'test.baked.xhtml')
  const outputPath = path.join(__dirname, 'svg.output.xhtml')
  await fs.promises.rm(outputPath, { force: true })
  execSync(
    `${process.argv[0]} ${startPath} -i ${inputPath} -o ${outputPath} -f svg`,
    { stdio: [0, 0, 0] }
  );
  expect(await getHashFile(outputPath)).toMatchInlineSnapshot(`"784f5b89f7d2c338f397858099f23f20f50080760e0ebed980c7b00a7168d1eb"`)
}, 30000)

test('tex-mml snapshot', async () => {
  const inputPath = path.join(__dirname, 'seed', 'test-latex.xhtml')
  const outputPath = path.join(__dirname, 'mathml.output.xhtml')
  await fs.promises.rm(outputPath, { force: true })
  execSync(`${process.argv[0]} ${startPath} -i ${inputPath} -o ${outputPath} -f mathml`);
  expect(await getHashFile(outputPath)).toMatchInlineSnapshot(`"0df93f18fc7850a784fc3947cf7b0084e05f3aaa4fbfead8bc36e8fab2fcd527"`)
}, 30000)
