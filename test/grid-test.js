const {Builder, By, Key, until} = require('selenium-webdriver');

(async function example() {
let driver = await new Builder().forBrowser('chrome').usingServer('http://XXXX:4444/wd/hub').build();

try {
    await driver.get('https://www.google.com/');
    await driver.wait(until.elementLocated(By.name('q')));
    await driver.findElement(By.name('q')).sendKeys('webdriver', Key.RETURN);
    await driver.wait(until.titleIs('webdriver - Google Search'), 1000);
} finally {
    await driver.quit();
}
})();

