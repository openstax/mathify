# bakedpdf
Bake a PDF


Typeset
`cd typeset`

`node start typeset --version`

`node start typeset --help`
```
Options:
  --version     Show version number                                    [boolean]
  --help        Show help                                              [boolean]
  --input, -i   Path to input file.                                   [required]
  --css, -c     Path to css file.                                     [required]
  --output, -o  Path and name with extension to output file.          [required]
```

`npm install`

`node start typeset -i input.xhtml -c style.css -o output.html`

MathJax will be injected to the input file and after this process content will be serialized.

//Assumptions//
We asume that input is xhtml file without &nbsp (non-breaking characters) because if it is not then browser will crash and puppeteer will not be able to see whole content.
