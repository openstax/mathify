# bakedpdf
Bake a PDF

npm install

node start input.xhtml style.css output.html

MathJax will be injected to the input file and after this process content will be serialized.

//Assumptions//
We asume that input is xhtml file without &nbsp (non-breaking characters) because if it is not then browser will crash and puppeteer will not be able to see whole content.
