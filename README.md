# bakedpdf
Bake a PDF


Typeset

Run tests:
`npm test` which will run `standard --fix && npm run jest`

`cd typeset`

`node start --version`

`node start --help`
```
Options:
  --version     Show version number                                    [boolean]
  --help        Show help                                              [boolean]
  --xhtml, -i   Path to input file.                                   [required]
  --css, -c     Path to css file.
  --output, -o  Path and name with extension to output file.          [required]
```

`npm install`

`node start -i input.xhtml -c style.css -o output.html`

You can also create `.env` file for bunyan managment. Use `LOG_LEVEL=info` for proper errors.

MathJax will be injected to the input file and after this process content will be serialized.

//Assumptions//
We asume that input is xhtml file without &nbsp (non-breaking characters) because if it is not then browser will crash and puppeteer will not be able to see whole content.
