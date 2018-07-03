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
  --format, -f  Output format for MathJax Conversion: HTML-CSS, SVG. Default:
                HTML-CSS
  --xhtml, -i   Input XHTML File                                      [required]
  --css, -c     Input CSS File
  --output, -o  Output XHTML File                                     [required]
  --help        Show help                                              [boolean]
```

`npm install`

`node start -i input.xhtml -c style.css -o output.html`

OR add `-f FORMAT` to set output format for MathJax conversion. Default `HTML-CSS`.

`node start -f SVG -i input.xhtml -c style.css -o output-svg.html`

You can also create `.env` file for bunyan managment. Use `LOG_LEVEL=info` for proper errors.

MathJax will be injected to the input file and after this process content will be serialized.

//Assumptions//
We asume that input is xhtml file without &nbsp (non-breaking characters) because if it is not then browser will crash and puppeteer will not be able to see whole content.
