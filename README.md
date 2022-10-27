# bakedpdf
Bake a PDF


Typeset

Run tests:
`npm test` which will run `npm run jest && standard --fix`

`cd typeset`

`node start --version`

`node start --help`
```
Options:
  --version     Show version number                                    [boolean]
  --xhtml, -i   Input XHTML File                                      [required]
  --css, -c     Input CSS File
  --output, -o  Output XHTML File                                     [required]
  --format, -f  Output format for MathJax Conversion: html, svg. Default: html
  --help        Show help                                              [boolean]
```

`npm install`

`node start -i input.xhtml -c style.css -o output.html -f html`

You can also create `.env` file for bunyan managment. Use `LOG_LEVEL=info` for proper errors.

MathJax will be injected to the input file and after this process content will be serialized.
