// const system = require ('system');
const fs = require ('fs');
const puppeteer = require ('puppeteer');


// function getPath() {
//   const path = fs.absolute(system.args[0])
//   const inx = path.lastIndexOf('/')
//   return fs.absolute(path.slice(0, inx) + '/..')
// }

// if (system.args.length !== 3 && system.args.length !== 4) {
//   console.log('Usage: typeset.js FILE STYLE [OUTPUT]')
//   browser.close();
//   console.log("Status: " + status);
// }
// const url = system.args[1];
const url = 'file:///mnt/c/Users/Thomas/Openstax/bakedpdf/u-physics-one-unit.xhtml';
// const style = fs.isAbsolute(system.args[0])
//   ? system.args[0]
//   : fs.absolute(root_path + '/' + system.args[0]);
// const output = system.args[3];
const stylemj = './intro-business.css';
const output = './out.html';

// const root_path = getPath();

(async () => {
  const browser = await puppeteer.launch({args: ['--no-sandbox']});
  const page = await browser.newPage();

  page.on('console', msg => console.log('PAGE LOG:', msg.text()));

  await page.goto(url);

  await page.evaluate(function() {
    window.__c = {
        done: false,
        status: 0,
    }
  });

  // Insert stylesheet

  await page.evaluate(style => {
      const c = window.__c;

      c.style = document.createElement('link');
      c.style.rel = 'stylesheet';
      c.style.href = style;
      document.body.appendChild(c.style);

      const meta = document.createElement('meta');
      meta.setAttribute('charset', 'utf-8');
      document.head.appendChild(meta);
  }, stylemj);

  // Typeset equations

  await page.evaluate(() => {
    const c = window.__c;

    const CONFIG = {
        extensions: ["mml2jax.js", "MatchWebFonts.js"],
        jax: ["input/MathML", "output/HTML-CSS"],
        showMathMenu: false,
        showMathMenuMSIE: false,
        mml2jax: {
            preview: 'none',
        },
        "AssistiveMML": {
            // AssistiveMML inserts additional MathML into the page, which
            // prince then rejects.
            disabled: true,
        },
        MatchWebFonts: {
            matchFor: {
                CommonHTML: true,
                "HTML-CSS": true,
                SVG: true,
            },
            fontCheckDelay: 2000,
            fontCheckTimeout: 30 * 1000,
        },
        CommonHTML: {
            linebreaks: {
                automatic: true,
            },
            scale: 100/1.27,
            minScaleAdjust: 75,
            // mtextFontInherit: true,
        },
        'HTML-CSS': {
            preferredFont: 'STIX-Web',
            imageFont: null,
            // mtextFontInherit: true,
            noReflows: false,
        },
        SVG: {
            font: 'STIX-Web',
            // mtextFontInherit: true,
        },
    };

    function typeset() {
        MathJax.Hub.Queue(function() {
            document.querySelector('body>:first-child').style.setProperty('display', 'none');
            c.done = true;
        })
        MathJax.Hub.setRenderer('HTML-CSS');
        MathJax.Hub.Config(CONFIG);
        
    };

    c.mjax = document.createElement('script');
    c.mjax.addEventListener('load', typeset);
    c.mjax.addEventListener('error', function(ev) {
        c.done = true;
        c.status = 1;
    });
    c.mjax.src = './node_modules/mathjax/unpacked/MathJax.js';
    document.body.appendChild(c.mjax);

  });

  async function sleep(ms) {
      return new Promise((resolve) => {
          setTimeout(resolve, ms);
      });
  }

  while(true) {
    var math_done = false;
    math_done = await page.evaluate(() => {
        const c = window.__c;
        return c.done;
    });
    await sleep(1000);
    if (math_done) {
        break;
    }
  }

//   console.log("MathJax Status: " + math_status);
  const htmlOut = await page.content();
  fs.writeFile('./out.html', htmlOut, function(err){}); 
 
  await browser.close();
})();
