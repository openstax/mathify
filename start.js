const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('file://C:/Users/Piotr/Documents/GitHub/bakedpdf/testhtml.xhtml');
  await page.addScriptTag({path: './node_modules/mathjax/MathJax.js'});

  const texts = await page.evaluate(() => {
    var script = document.createElement("script");
    script.setAttribute('src','https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.4/MathJax.js?config=TeX-MML-AM_CHTML');
    document.getElementsByTagName('body')[0].appendChild(script);
    console.log(document.getElementsByTagName('script'));
  });

  const htmlOut = await page.content();

  page.once('load', () => {
    fs.writeFile('./out.html', htmlOut, function(err){});
  });

  await browser.close();
})();